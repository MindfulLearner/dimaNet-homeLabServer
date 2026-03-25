# Incident Report — SSH Brute Force Attack
**Data:** 2026-03-24 | **Severity:** Low | **Host:** dimanet — Proxmox VE 8.2 | **Esito:** Attacco fallito

---

## 1. Scoperta

Durante l'esecuzione manuale di `scripts/proxmox_health_check.sh` è apparso:

```
>>> SSH FAILED LOGINS (last 24h)
Top offending IPs:
      1 solv
      1 solana
      1 sol
```

Domanda immediata: **sono entrati?**

```bash
journalctl _SYSTEMD_UNIT=ssh.service --since "7 days ago" | grep "Accepted"
```

Risultato: tutti i login accettati erano da IP interni (LAN e VPN). Nessun accesso esterno.

---

## 2. Analisi Attacco

**IP attaccante:** `[capybara-priv]` — Repubblica Ceca
**Tipo:** Bot automatico specializzato in username crypto

| Orario | Evento |
|---|---|
| Mar 23 16:05:06 | Port scan — connessione chiusa subito |
| Mar 23 16:07:29 | Tentativo `sol` — fallito |
| Mar 23 16:09:48 | Tentativo `solana` — fallito |
| Mar 23 16:11:58 | Tentativo `solv` — fallito |

**Durata:** ~7 minuti

### Obiettivo del bot

Cercare server con utenti legati a **Solana** (criptovaluta):
1. Scansiona internet su porta 22
2. Prova username tipici di nodi/wallet Solana
3. Se entra → ruba chiavi private, installa miner, usa il server come relay

### Perché ha fallito

- Nessun utente `sol`/`solana`/`solv` esiste su dimaNet
- Configurazione SSH vulnerabile ma nessun username corrispondente trovato

---

## 3. Analisi Rete

### Topologia

```
MacBook (admin)
    │
    ▼
Router Tenda ([capybara-priv]) — UPnP attivo
    │  Port forwarding: 51820/UDP → [SERVER-LAN-IP]  (WireGuard)
    │  Port forwarding: 22         → NON configurato manualmente
    │  UPnP: può aprire porte automaticamente senza intervento utente
    │
    ▼
Internet
    │
    ▼
dimaNet — Proxmox VE ([SERVER-LAN-IP])
    ├── vmbr0 (bridge LAN)
    └── WireGuard ([VPN-IP]/24)
```

### Come il bot ha raggiunto la porta 22

| Check | Risultato |
|---|---|
| Port forwarding 22 sul router | Non configurato manualmente |
| DMZ abilitato | Non presente |
| IPv6 pubblico su Proxmox | Non presente |
| Porta 22 raggiungibile da DDNS | Non risponde (check post-hardening) |
| UPnP attivo sul router Tenda | **Confermato** |

**Ipotesi più probabile — confermata:** il router Tenda con UPnP attivo ha aperto
automaticamente la porta 22 quando Proxmox ha avviato `ssh.service`, senza alcuna
configurazione manuale. L'IP pubblico del server è diventato raggiungibile su porta 22
dall'esterno, e i bot di scansione internet lo hanno trovato in poche ore.

```
Proxmox avvia ssh.service
    │
    ▼ richiesta UPnP automatica
Router Tenda (UPnP attivo)
    │  apre porta 22 esterna → [SERVER-LAN-IP]:22
    │
    ▼
Internet — bot di massa scansionano tutti i 4 miliardi di IP
    │
    ▼
[capybara-priv] trova porta 22 aperta → lancia attacco brute force
```

> La rete era **privata con password WPA** (casa propria, non rete pubblica).
> WPA cifra il traffico radio ma non impedisce al router di vedere le destinazioni
> né di operare tramite UPnP. Il problema è il router stesso, non altri utenti.

### Vulnerabilità documentate del router Tenda

La ricerca post-incidente ha identificato CVE note sui router Tenda rilevanti a questo caso:

| CVE | CVSS | Tipo | Impatto |
|---|---|---|---|
| **CVE-2022-42053** | 7.8 | RCE via UPnP | Command injection tramite `portMappingServer` — UPnP è un vettore di attacco diretto |
| **CVE-2022-40845** | 8.8 | Info Disclosure | Endpoint non autenticato espone configurazione completa inclusa PSK WPA in chiaro |
| **CVE-2022-40843** | 9.9 | Info Disclosure | Hash MD5 password admin accessibile senza autenticazione via syslog |
| **CVE-2023-2649** | 8.8 | RCE | Command injection via UDP porta 7329 — pattern backdoor presente anche in modelli recenti |
| **CVE-2020-12695** | — | UPnP (CallStranger) | SUBSCRIBE callback UPnP permette SSRF e data exfiltration attraverso firewall |

**Backdoor firmware 2013 (no CVE assegnato):** La funzione `MfgThread()` nel firmware
Tenda (W302R, W330R e altri) espone UDP porta 7329 che esegue comandi root da chiunque
sia in LAN. Documentata da [Bitdefender](https://www.bitdefender.com/en-us/blog/hotforsecurity/tenda-wireless-routers-feature-backdoor)
e [The Hacker News](https://thehackernews.com/2013/10/backdoor-found-in-chinese-tenda.html).
CVE-2023-2649 conferma lo stesso pattern in modelli AC23 più recenti.

> **Nota:** Tenda storicamente non risponde ai ricercatori di sicurezza —
> le vulnerabilità rimangono non patchate. Fonte: [boschko.ca](https://boschko.ca/tenda_ac1200_router/),
> [CERT/CC VU#304455](https://www.kb.cert.org/vuls/id/304455)

---

## 4. Vulnerabilità trovate

| Criticità | Problema |
|---|---|
| **Alta** | `PasswordAuthentication yes` (default) + `PermitRootLogin yes` — brute force libero |
| **Alta** | Router Tenda con UPnP attivo — apre porte automaticamente senza autorizzazione utente |
| **Alta** | Firmware Tenda potenzialmente non aggiornato — CVE critici non patchati (vendor non risponde) |
| **Media** | `fail2ban` installato ma non funzionante (journald vs file di log) |
| **Bassa** | IP pubblico visibile dall'esterno quando UPnP espone porte attive |

---

## 5. Hardening Eseguito

### SSH — autenticazione con chiave

```bash
ssh-keygen -t ed25519 -C "descrizione-dispositivo"
```

Chiave `[ADMIN-KEY-FINGERPRINT]` aggiunta a `/root/.ssh/authorized_keys`.

Script `scripts/harden_ssh.sh` eseguito:
- Safety check: non disabilita password se non c'è già una chiave
- Backup automatico di `sshd_config`
- `PasswordAuthentication no`
- `PermitRootLogin prohibit-password`
- Validazione con `sshd -t` prima di riavviare

### fail2ban — fix per Proxmox

Proxmox usa journald, non `/var/log/auth.log`. Creato `/etc/fail2ban/jail.local`:

```ini
[sshd]
enabled = true
backend = systemd
journalmatch = _SYSTEMD_UNIT=ssh.service
maxretry = 5
findtime = 10m
bantime = 1h
```

### Stato finale

| Impostazione | Prima | Dopo |
|---|---|---|
| `PasswordAuthentication` | `yes` (default) | `no` |
| `PermitRootLogin` | `yes` | `prohibit-password` |
| `fail2ban` | non funzionante | attivo (backend systemd) |
| Login method | Password | Solo chiave ED25519 |

---

## 6. Script Creati

| Script | Funzione |
|---|---|
| `scripts/harden_ssh.sh` | Hardening SSH con safety check anti-lockout |
| `scripts/security_health_check.sh` | Health + intrusion check combinato |
| `scripts/investigate_attack.sh` | Indagine dettagliata attacchi SSH |

---

## 7. Lezioni Apprese

- Il monitoring attivo ha rilevato l'attacco — senza lo script non lo avremmo saputo
- Un server su internet viene trovato dai bot in ore: i bot scansionano tutti i 4 miliardi di IP pubblici in rotazione continua
- `fail2ban` installato ma non configurato = falsa sicurezza
- **UPnP attivo sul router di casa = port forwarding automatico non controllato** — equivale ad avere porte aperte senza saperlo
- WPA con password non protegge da vulnerabilità del router stesso (CVE-2022-40845 espone la PSK WPA in chiaro)
- Firmware Tenda raramente viene aggiornato e il vendor non risponde ai ricercatori — le CVE rimangono aperte indefinitamente
- **Limitare SSH a `wg0` only su nodo singolo crea rischio lockout** — senza console seriale configurata o accesso alternativo, un problema VPN taglia fuori completamente dal server

---

## Prossimi Passi

- [x] ~~Bloccare SSH solo su interfaccia WireGuard~~ — **revertito** (2026-03-25): su nodo singolo senza console seriale configurata crea rischio lockout totale. Da rivalutare dopo aver configurato accesso di emergenza alternativo.
- [ ] **Disabilitare UPnP sul router Tenda** — pannello admin → impostazioni avanzate
- [ ] **Aggiornare firmware Tenda** — verificare versione e scaricare aggiornamento dal sito ufficiale
- [x] ~~Verificare mapping UPnP attivi~~ — **verificato** (2026-03-25): nessun servizio UPnP installato su Proxmox. UPnP opera solo a livello router.
- [ ] Cron giornaliero su `security_health_check.sh` con alert email
- [ ] Cambiare porta SSH da 22 a una non standard
