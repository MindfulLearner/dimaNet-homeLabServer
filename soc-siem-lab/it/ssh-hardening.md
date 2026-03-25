# SSH Hardening — dimaNet Proxmox

**Data:** 2026-03-24
**Host:** dimanet (Proxmox VE 8.2)

---

## Contesto — Cosa è successo

Durante un health check del server è stato rilevato un attacco brute force SSH attivo.

**IP attaccante:** `[capybara-priv]`
**Data attacco:** 23 Marzo 2026, 16:07–16:12
**Username tentati:** `sol`, `solana`, `solv`

### Tecnica usata

Bot automatico che scansiona internet cercando server con utenti legati a **Solana** (criptovaluta). Lo schema tipico:
- Cerca username comuni nei nodi/wallet Solana (`sol`, `solana`, `solv`)
- Tenta password di default o deboli
- Se entra: ruba chiavi private, installa miner, usa il server come relay

### Risultato

Tutti i tentativi **falliti** — nessun utente `sol`/`solana` esiste su dimaNet.

---

## Vulnerabilità trovate prima dell'hardening

| Impostazione | Valore | Rischio |
|---|---|---|
| `PasswordAuthentication` | commentato (default `yes`) | Chiunque poteva provare password |
| `PermitRootLogin` | `yes` | Root direttamente attaccabile via brute force |
| `fail2ban` | installato ma non configurato | Nessun ban automatico degli attaccanti |

---

## Hardening eseguito

### 1. Autenticazione SSH con chiave

Generata chiave ED25519 sul Mac dell'amministratore:
```bash
ssh-keygen -t ed25519 -C "my-mac"
```

Chiave pubblica aggiunta a `/root/.ssh/authorized_keys` su Proxmox.

### 2. Disabilitata autenticazione via password

`/etc/ssh/sshd_config`:
```
PasswordAuthentication no
PermitRootLogin prohibit-password
```

Script usato: `scripts/harden_ssh.sh`
Backup automatico del config originale in `/etc/ssh/sshd_config.bak.*`

### 3. Configurato fail2ban per Proxmox

Proxmox usa **journald** invece di `/var/log/auth.log`, quindi fail2ban richiedeva configurazione esplicita.

`/etc/fail2ban/jail.local`:
```ini
[sshd]
enabled = true
backend = systemd
journalmatch = _SYSTEMD_UNIT=ssh.service
maxretry = 5
findtime = 10m
bantime = 1h
```

---

## Risultato finale

| Impostazione | Valore | Stato |
|---|---|---|
| `PasswordAuthentication` | `no` | Sicuro |
| `PermitRootLogin` | `prohibit-password` | Sicuro |
| `fail2ban` | attivo, backend systemd | Attivo |
| Login method | Solo chiave ED25519 | Attivo |

---

## Script creati

| Script | Funzione |
|---|---|
| `scripts/harden_ssh.sh` | Hardening SSH con safety check (non disabilita password se non c'è già una chiave) |
| `scripts/security_health_check.sh` | Health check + controllo intrusioni (login riusciti, falliti, fail2ban, config SSH) |
| `scripts/investigate_attack.sh` | Indagine dettagliata su IP attaccanti, username tentati, timeline |

---

## Gestione remota dal Mac

Con la chiave configurata, è possibile eseguire comandi sul server direttamente dal Mac senza aprire una sessione interattiva:

```bash
ssh root@192.capy.1.capy "comando"
```

Questo evita di dover installare tool di gestione sul server stesso.

---

## Come aggiungere/revocare accesso

**Aggiungere un nuovo dispositivo:**
```bash
echo "ssh-ed25519 AAAA... descrizione" >> /root/.ssh/authorized_keys
```

**Revocare accesso:**
```bash
nano /root/.ssh/authorized_keys
# cancellare la riga corrispondente
```

**Vedere chi ha accesso:**
```bash
cat /root/.ssh/authorized_keys
```
