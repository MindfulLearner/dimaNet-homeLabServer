# TODO — dimaNet Home Lab Server

## Skill da imparare — HIGH PRIORITY

> Profilo attuale: SE TypeScript / Vue / Nuxt, prodotti con business logic pesante

- [ ] **Backend solido** — Node/Bun, database design (SQL + relazioni), API design REST/tRPC, event-driven. Il TypeScript si porta tutto, espandi verso server-side
- [ ] **Security applicativa** — OWASP Top 10, auth/authz (JWT, OAuth, session), input validation, secure API design. Complementa il percorso homelab applicandolo al codice
- [ ] **Docker + Kubernetes** — containerizzazione, deployments, services, ingress. Estensione naturale del homelab, un SE che sa deployare quello che scrive vale doppio
- [ ] **AI integration** — costruire prodotti con LLM: tool use, RAG, agenti con Claude API. Non ML, ma il layer applicativo sopra i modelli

---

## Health Check System

### Script `pve-health-check.sh`
- [ ] Creare `/usr/local/bin/pve-health-check.sh` sul server `192.capy.1.capy`
- [ ] LXC running → raccoglie metriche via `pct exec`: disk %, RAM %, load avg, failed services
- [ ] QEMU running → raccoglie metriche via `qm agent exec` (richiede guest agent installato)
- [ ] VM/CT stopped → preserva i dati dell'ultimo check senza sovrascrivere
- [ ] Output JSON in `/usr/share/pve-manager/js/health-status.json` (accessibile dalla dashboard)
- [ ] Aggiungere cron job notturno (es. `0 3 * * *`)

### JSON format previsto
```json
{
  "generated": "2026-03-25T03:00:00",
  "checks": {
    "100": {
      "vmid": 100,
      "name": "dimorega-net-ct",
      "type": "lxc",
      "last_check": "2026-03-20T03:00:00",
      "last_status": "stopped",
      "disk_pct": 45,
      "mem_pct": 32,
      "load_1m": 0.2,
      "failed_services": 0,
      "days_since_check": 5
    }
  }
}
```

### Dashboard — Badge sui nodi
- [ ] Verde — controllato < 3 giorni fa, tutto ok
- [ ] Giallo — 3-6 giorni senza check, oppure warning (disk > 80% o failed services > 0)
- [ ] Rosso — 7+ giorni senza check, o mai controllato
- [ ] Grigio — stopped, in attesa di prossimo avvio

### Dashboard — Popup
- [ ] Aggiungere campo `LAST CHECK` con data + "X days ago"
- [ ] Aggiungere `DISK %` dall'ultimo check
- [ ] Aggiungere `LOAD AVG` dall'ultimo check
- [ ] Aggiungere `FAILED SERVICES` dall'ultimo check
- [ ] Aggiungere `STOPPED FOR` — quanti giorni è spento

### Extra (opzionale)
- [ ] Soglia disco configurabile in cima allo script (default `DISK_WARN=80`)
- [ ] Modalità "manutenzione" — flag per ignorare il warning 7 giorni su un nodo specifico

---

## Wake-on-LAN (accensione remota dal MacBook)

### Stato
- [x] WoL abilitato sulla NIC `eno1` (`Wake-on: g`)
- [x] `wakeonlan` installato sul MacBook via Homebrew
- [x] Alias `wakelab` aggiunto a `~/.zshrc` sul MacBook

### Dettagli
| Proprietà | Valore |
|---|---|
| Interface server | `eno1` |
| MAC address | `[capybara-priv]` |
| Broadcast | `192.capy.1.capy` |
| Comando MacBook | `wakelab` |

### Comando completo
```bash
wakeonlan -i 192.capy.1.capy [capybara-priv]
```

### Limitazioni
- Funziona solo dalla **rete locale** (WiFi di casa)
- Fuori casa via VPN il broadcast non passa — serve un device sempre acceso in rete come relay (es. router OpenWrt, Raspberry Pi)
- Verificare che nel **BIOS** sia abilitato WoL (`PCI Wake` o `Wake-on-LAN` nelle impostazioni risparmio energia)

### TODO
- [ ] Valutare relay WoL per accensione remota fuori rete (via VPN)

---

## Hardening SSH Hypervisor

### Problema
SSH ascolta su `0.0.0.0:22` — raggiungibile anche dai CT/VM sul bridge `vmbr0`.
Un container compromesso potrebbe tentare di accedere in SSH all'hypervisor.

### Soluzione
Bloccare SSH in ingresso dall'interfaccia `vmbr0` (bridge CT/VM) tramite iptables,
lasciando libero l'accesso da LAN e WireGuard.

```bash
iptables -I INPUT -i vmbr0 -p tcp --dport 22 -j DROP
```

### Accessi dopo la modifica
| Source | SSH hypervisor |
|---|---|
| MacBook LAN `192.capy.1.capy` | ✅ |
| MacBook VPN `[capybara-priv]` | ✅ |
| CT/VM su `vmbr0` | ❌ bloccato |

### TODO
- [ ] Applicare regola iptables su `vmbr0`
- [ ] Rendere la regola persistente (via `iptables-save` o regola Proxmox Firewall)
- [ ] Verificare che il MacBook in LAN e VPN acceda ancora correttamente dopo la modifica

---

## Honeypot

### Architettura
- VM QEMU dentro Proxmox (più isolata di un CT per questo scopo)
- IP statico `192.capy.1.capy` — credibile come secondo server nella rete
- Hostname `dimanet-2` o `proxmox-node2` per sembrare legittimo
- Rete su VLAN separata o isolata da `vmbr0` dei CT reali

### Servizi fake da esporre
- Porta `22` — SSH fake tramite **Cowrie** (logga tutto: credenziali, comandi)
- Porta `8006` — Proxmox UI fake (logga chi tenta di accedere)
- Porta `80/443` — HTTP fake opzionale

### Integrazione SIEM
- Log di Cowrie → forwarded al `soc-siem-lab` già presente nella repo
- Alert se qualcuno si connette all'IP `192.capy.1.capy`

### TODO
- [ ] Creare VM dedicata con IP statico `192.capy.1.capy`
- [ ] Installare e configurare **Cowrie** (SSH honeypot)
- [ ] Esporre porta `8006` fake con redirect e logging
- [ ] Collegare i log al SIEM
- [ ] Aggiungere regola firewall: traffico verso `192.capy.1.capy` → alert immediato
