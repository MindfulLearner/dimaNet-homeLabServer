# dimaNet Telegram Bot

Bot di controllo remoto per burgerking (Proxmox VE). Gira come servizio systemd e usa polling verso Telegram (nessuna porta esposta).

## Setup

**Servizio:** `dimanet-bot.service`
**Script:** `/usr/local/bin/dimanet-bot.py`
**Credenziali:** `/etc/telegram-notify.conf` (TOKEN e CHAT_ID, non committare)

```
# /etc/telegram-notify.conf
TOKEN="..."
CHAT_ID="..."
```

Comandi utili:

```bash
systemctl status dimanet-bot
systemctl restart dimanet-bot
journalctl -u dimanet-bot -f
```

## Sicurezza

Il bot risponde solo all'utente in whitelist (CHAT_ID nel conf). Qualsiasi altro utente viene ignorato silenziosamente. Nessuna porta aperta: usa solo connessioni uscenti verso api.telegram.org:443.

## Comandi

### /ping

Verifica che il bot sia attivo e risponda.

```
Tu:  /ping
Bot: online
```

### /healthcheck

Mostra lo stato di sistema: uptime, CPU, RAM, disco.

```
Tu:  /healthcheck
Bot: eseguo healthcheck...
     === SYSTEM ===
     up 21:01, load average: 0.02, 0.01, 0.00

     === CPU ===
     %Cpu(s):  0.0 us, ...

     === RAM ===
     Mem: 15Gi total, 1.6Gi used

     === DISK ===
     /dev/mapper/pve-root  94G  62G  28G  70%  /
```

### /containers

Lista i container LXC attivi su Proxmox.

```
Tu:  /containers
Bot: VMID  Status   Lock  Name
     134   running        mr-edgar
```

### /rtc

Spegne il server e lo riaccende automaticamente dopo il tempo indicato tramite `rtcwake`. Utile per gestire burgerking da remoto (es. da Praga).

**Sintassi:**

```
/rtc <ore>
/rtc <ore>.<minuti>
```

**Esempi:**

```
/rtc 8      spegne e riaccende dopo 8 ore
/rtc 8.30   spegne e riaccende dopo 8 ore e 30 minuti
/rtc 1.5    spegne e riaccende dopo 1 ora e 50 minuti
```

Nota: con il punto, la parte decimale a cifra singola viene moltiplicata x10
(es. `.3` = 30 minuti, `.5` = 50 minuti). Due cifre vengono usate direttamente
(es. `.30` = 30 minuti).

**Risposta del bot:**

```
dimanet SPENTO
Spegnimento: 26/06/2026 alle 17:33 CEST
Durata: 8h
Riaccensione prevista: 27/06/2026 alle 01:33 CEST
```

Dopo il messaggio il server si spegne immediatamente. Il chip RTC gestisce la riaccensione in modo autonomo, senza dipendere da rete o software.

## Aggiungere un comando

Nel file `/usr/local/bin/dimanet-bot.py`:

```python
async def cmd_esempio(update: Update, ctx: ContextTypes.DEFAULT_TYPE) -> None:
    if not _guard(update.effective_user.id):
        return
    out = _run("comando-da-eseguire")
    await update.message.reply_text(f"<pre>{out}</pre>", parse_mode="HTML")
```

Poi registrarlo nel `main()`:

```python
app.add_handler(CommandHandler("esempio", cmd_esempio))
```

E riavviare il servizio:

```bash
cp dimanet-bot.py /usr/local/bin/dimanet-bot.py
systemctl restart dimanet-bot
```
