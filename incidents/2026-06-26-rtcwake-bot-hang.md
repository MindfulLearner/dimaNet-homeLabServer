# Incident Report - 2026-06-26: /healthcheck hang + irraggiungibilita' post-rtcwake

## Sommario

| # | Problema | Causa | Stato |
|---|----------|-------|-------|
| 1 | /healthcheck bloccato a tempo indeterminato | `subprocess.check_output` + `top -bn1` in ambienti headless | **Risolto** |
| 2 | SSH e porta 8006 irraggiungibili dopo rtcwake | WireGuard re-handshake: sessione scaduta dopo 2h di server off | **Documentato** |
| 3 | /rtc 2 invece di 7 o 8 (presunto errore umano) | Log bot non registravano i comandi ricevuti | **Non determinabile** |

---

## Cronologia

| Orario (CEST) | Evento |
|---------------|--------|
| 26/06 17:47:12 | `/rtc 2` eseguito dal bot, `rtcwake` avviato |
| 26/06 17:47:13 | RTC programmato per wakeup alle 17:47:13 UTC (= 19:47:13 CEST) |
| 26/06 17:47:17 | `sshd` fermato da systemd (SIGTERM), server off |
| 26/06 19:47:28 | RTC sveglia il server (esattamente 2h) |
| 26/06 19:47:28 | `wg-quick@wg0`, `sshd`, `dimanet-bot` tutti avviati |
| 26/06 19:47+ | `/ping` risponde via Telegram, `/healthcheck` si blocca |
| 26/06 19:47+ | `ssh 192.168.1.100` e porta 8006 danno "connection refused" da Praha |
| 27/06 11:12 | Riavvio fisico da Milano |
| 27/06 11:xx | Deploy bot con fix, problema 1 risolto |

---

## Problema 1 - /healthcheck bloccato (Risolto)

### Cos'e' successo

Il comando `/healthcheck` via Telegram non rispondeva mai. Il bot continuava a girare (rispondeva a `/ping`) ma rimaneva bloccato indefinitamente su `/healthcheck`.

### Causa tecnica

Doppio difetto nel codice del bot (`_run()`):

**Difetto A: `subprocess.check_output` + orfani**

```python
# vecchio codice (bug)
out = subprocess.check_output(cmd, shell=True, stderr=subprocess.STDOUT,
                              timeout=30, text=True)
```

Quando `check_output` va in timeout, lancia `TimeoutExpired` ma il processo shell figlio (con i suoi sottoprocessi: `top`, `grep`) rimane in vita e tiene aperta la pipe. `check_output` alla ripresa dell'eccezione aspetta comunque che la pipe si chiuda, bloccando per sempre. Il timeout non funzionava.

**Difetto B: `top -bn1` in ambiente headless**

In Proxmox senza terminale, `top -bn1` non si chiude correttamente dopo una iterazione. Si blocca in attesa di un terminale che non esiste. Questo amplificava il problema A.

### Fix applicato

Commit `d193d46` - `feat(bot): add /sshrestart and /off, fix healthcheck hang`

```python
# nuovo codice (corretto)
proc = subprocess.Popen(
    cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
    text=True, preexec_fn=os.setsid          # nuovo process group
)
out, _ = proc.communicate(timeout=timeout)
# ...
except subprocess.TimeoutExpired:
    os.killpg(os.getpgid(proc.pid), signal.SIGKILL)  # uccide tutto il group
    proc.wait()
```

`os.setsid()` crea un nuovo process group per il processo figlio. In caso di timeout, `os.killpg()` uccide l'intero group (shell + top + grep + qualsiasi figlio), eliminando il blocco sulla pipe.

`top -bn1` sostituito con `cat /proc/loadavg` (non blocca mai).
`df -h` avvolto con `timeout 5` per evitare blocchi su `pmxcfs` di Proxmox.

### Verifica

Bot riavviato su burgerking (PID 2379). `/healthcheck` risponde correttamente entro 5 secondi.

---

## Problema 2 - SSH e 8006 irraggiungibili dopo rtcwake

### Cos'e' successo

Dopo il wakeup RTC alle 19:47:28, tutti i servizi erano partiti correttamente:

- `wg-quick@wg0`: UP, IP `10.118.240.1/24` assegnato
- `sshd`: in ascolto su `0.0.0.0:22`
- `pve-firewall`: permette `10.118.240.0/24` su porte 22 e 8006

Nonostante questo, da Praha `ssh 192.168.1.100` e la UI Proxmox su porta 8006 davano "connection refused".

`/ping` Telegram continuava a funzionare perche' passa per `api.telegram.org` via internet, non per WireGuard.

### Causa tecnica

Il Mac instrada `192.168.1.0/24` attraverso `utun5` (WireGuard) in base alla configurazione `AllowedIPs`. Quando il server era off per 2 ore, la sessione WireGuard era scaduta. Al momento del wakeup, il server aveva avviato una nuova sessione WireGuard, ma il Mac aveva ancora lo stato della sessione vecchia. 

WireGuard rinegozia automaticamente (re-handshake) ma ci vogliono alcuni secondi. Il NAT del router di Milano puo' aver scaduto anche il mapping UDP della porta 51820 dopo 2h di inattivita', aggiungendo latenza al re-handshake. Durante questa finestra, le connessioni TCP verso 192.168.1.100 arrivano a burgerking ma la risposta non torna al Mac correttamente.

Stesso problema gia' osservato in [marzo 2026](2026-03-28-rtcwake-connectivity.md) (Problema 1, causa non determinata - ora piu' chiara).

### Cosa non era il problema

- Il pve-firewall NON bloccava WireGuard: regole `RETURN` esistono per `10.118.240.0/24` su porte 22 e 8006
- SSH NON era crashato: `sshd` in ascolto confermato dai log
- Non era un virus o accesso non autorizzato: `sshd` fermato da SIGTERM di systemd durante shutdown ordinato, non per crash

### Fix consigliato

Aggiungere `PersistentKeepalive = 25` nel peer WireGuard del Mac (`/etc/wireguard/wg0.conf` o Wireguard app) per mantenere attivo il mapping NAT e velocizzare il re-handshake dopo un riavvio lungo del server.

```ini
[Peer]
# ...
PersistentKeepalive = 25
```

> Gia' identificato come open item nell'incident di marzo 2026. Da applicare.

---

## Problema 3 - /rtc 2 invece di durata maggiore

### Cos'e' successo

Il server si e' svegliato dopo 2 ore invece delle 7-8 ore probabilmente intese.

### Causa

Il vecchio bot non loggava i comandi ricevuti via Telegram. Il journal mostra solo il risultato dell'esecuzione di `rtcwake` alle 17:47:12, non quale argomento fu passato al comando `/rtc`.

`journalctl --boot=-2 -u dimanet-bot` mostra solo:
```
Jun 26 17:47:12 dimanet python3[329114]: rtcwake: wakeup from "off" using /dev/rtc0 at Fri Jun 26 17:47:13 2026
```

Il timestamp UTC `17:47:13` corrisponde a `19:47:13 CEST`, cioe' esattamente 2h dal momento dell'invio (17:47 CEST). L'argomento passato al comando era quasi certamente `/rtc 2`.

### Fix applicato

Aggiunto logging ricevuto comandi al bot: da valutare come miglioramento futuro.

---

## Comandi aggiunti al bot

Come risultato di questo incident, aggiunti due comandi di sicurezza:

| Comando | Funzione |
|---------|----------|
| `/sshrestart` | Riavvia `sshd` tramite systemctl, utile se SSH non risponde |
| `/off` | Spegne il server immediatamente senza timer RTC |

---

## Stato finale server (27/06/2026 ~11:30)

| Parametro | Valore |
|-----------|--------|
| Uptime | Stabile dopo riavvio fisico |
| WireGuard | UP, handshake attivo |
| sshd | Attivo |
| dimanet-bot | Attivo (PID 2379), versione con fix |
| /healthcheck | Funzionante, risposta < 5s |

---

## Open Items

- [ ] Applicare `PersistentKeepalive = 25` nel peer WireGuard del Mac
- [ ] Aggiungere logging dei comandi ricevuti al bot (per tracciabilita' futura)
