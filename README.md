# dimaNet - Home Lab Server

## About

Il progetto dimaNet nasce dall'esigenza di avere un ambiente centralizzato accessibile da remoto, indipendente dal dispositivo in uso. Gestione remota tramite DDNS e WireGuard, pentesting lab su rete isolata, e sperimentazione su virtualizzazione e sicurezza.

Sistema operativo host: **Proxmox VE 8.2** su bare metal.

## Custom Proxmox UI

<img width="1914" height="560" alt="custom proxmox ui" src="https://github.com/user-attachments/assets/20fb6451-bd81-4366-9d9f-73e1aaf5b561" />

---

## PICTURE FIRST PROTOTYPE HAND CREATION BELOW MERMID
<img width="7568" height="6234" alt="image" src="https://github.com/user-attachments/assets/6a2892d6-0900-4b57-9744-f1237b0f318d" />



## Infrastructure Overview

```mermaid
graph TD
    INTERNET([Internet])
    ATTACKER([Attacker])
    HONEYPOT[Honeypot - Cowrie LXC]
    ROUTER[Router]
    FW[Firewall]
    GH[GitHub]

    SERVER[DIMANET/SERVER\nProxmox VE]

    subgraph CONTAINERS[Containers - LXC]
        ARCH[Arch Linux]
        WIP1[... WIP]
    end

    subgraph VMS[Virtual Machines]
        VM_BASE[Base VM]
        UBUNTU[Ubuntu]
        KALI[Kali Linux]
        WIN[Windows - WIP]
    end

    REMOTE[Remote Work\nMacBook / Fedora]
    MAIN[Main Computer\nArch Linux]
    FRIEND[Friend Computer]

    STORAGE_MAIN[(Local Storage)]
    STORAGE_REMOTE[(Remote Storage)]
    STORAGE_FRIEND[(Storage)]

    INTERNET --> ATTACKER
    INTERNET --> ROUTER
    ATTACKER -->|attack attempt| HONEYPOT
    ROUTER --> HONEYPOT
    ROUTER --> FW
    ROUTER --> GH
    FW --> SERVER
    FW --> MAIN

    SERVER -->|SSH| ARCH
    SERVER --> WIP1
    SERVER --> VM_BASE
    VM_BASE --> UBUNTU
    VM_BASE --> KALI
    VM_BASE --> WIN

    REMOTE -->|SSH| SERVER
    STORAGE_REMOTE --> REMOTE

    MAIN --> STORAGE_MAIN
    FRIEND --> STORAGE_FRIEND
```

## Container in View

![containers](https://github.com/user-attachments/assets/55c11777-531d-49b5-8527-bf7fc1802a34)

---



### Accesso remoto
- WireGuard VPN gestito tramite PiVPN
- DDNS per IP dinamico No-IP con hostname dedicato
- Port forwarding sul router (Mappatura Porte, porta 51820 UDP)
- Documentazione dettagliata: [vpn-setup/README.md](vpn-setup/README.md)

### Gestione alimentazione remota
Il server non è sempre acceso. L'accensione è gestita tramite `rtcwake`, che usa il Real Time Clock hardware per programmare il wake del sistema a un orario preciso, senza bisogno di Wake-on-LAN o intervento fisico.

Comando tipico (spegni e svegliati tra N secondi):
```bash
rtcwake -m off -s <secondi>
```

Questo permette di gestire il server da remoto (es. da Praga) programmando finestre di accensione pianificate, riducendo consumo energetico e usura.

### Link utili

- [Nvim config](https://github.com/MindfulLearner/josh-nvim-config)
- [Tmux config](https://github.com/MindfulLearner/dimaNet-Tmux-COnf)
- [pfSense hardening guide by Celes](https://github.com/celesrenata/pfsense-ultimate-config)

---

## Roadmap

Legenda: `done` `wip` `planned`

### 1. Web Server
- `wip` Apache/Nginx - hosting su VM o container LXC
- `wip` Stack LAMP/LEMP

### 2. Database Server
- `wip` MySQL / PostgreSQL / MongoDB
- `wip` Replica del database

### 3. File Server
- `wip` Samba
- `wip` NFS
- `wip` FTP/SFTP

### 4. Virtualizzazione e Container
- `done` Proxmox VE
- `wip` Docker
- `done` LXC

### 5. Gestione Cloud
- `done` OpenStack
- `wip` MAAS
- `wip` Juju

### 6. Servizi di Rete
- `wip` DNS (BIND)
- `wip` DHCP
- `wip` Proxy Server (Squid)

### 7. Mail Server
- `wip` Postfix / Dovecot
- `wip` SpamAssassin

### 8. Sicurezza e Monitoraggio
- `wip` Firewall (iptables/ufw)
- `wip` IDS (Snort/Suricata)
- `wip` Monitoring (Prometheus/Zabbix)

### 9. Ambiente di Sviluppo
- `wip` Git server
- `wip` CI/CD (Jenkins/GitLab CI)
- `wip` Node.js / Rails / Django

### 10. Media Server
- `wip` Plex / Emby
- `wip` Nextcloud

### 11. Backup
- `done` rsync + cron
- `done` Bacula

### 12. Automazione
- `done` Ansible
- `done` Shell scripting

### 13. VPN
- `done` WireGuard / OpenVPN

### 14. Game Server
- `planned` Minecraft / Counter-Strike

### 15. AI / ML
- `planned` TensorFlow / PyTorch

### 16. IoT
- `planned` MQTT Broker
