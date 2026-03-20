# Project #1: Build Your Own SOC (SIEM Lab)

## Machines

| Name | Type | OS | Role |
|------|------|----|------|
| cs20 | VM | Kali Linux | Attacker — Red Team |
| cs33 | Container | Ubuntu | Victim — Wazuh Agent (user: `swagvict`, password: `victim`) |
| cs55 | VM | Ubuntu | Wazuh Manager + Dashboard |

---


<img width="4422" height="4322" alt="image" src="https://github.com/user-attachments/assets/bb6581b2-1e22-4a25-b74b-841d8f88d864" />


## Architecture

```mermaid
flowchart LR
    subgraph RED["🔴 Red Team"]
        A([cs20\nKali Linux])
    end

    subgraph BLUE["🔵 Blue Team"]
        B[cs33\nUbuntu Container\nWazuh Agent]
        C[cs55\nUbuntu VM\nWazuh Manager]
        D[Wazuh Dashboard]
    end

    subgraph ANALYST["👁️ SOC Analyst"]
        E([You])
    end

    A -->|"SSH brute force\nnmap scan\nexploit"| B
    B -->|logs| C
    C -->|visualize| D
    C -->|alert| E
    D --> E
```

---

## Checklist

- [x] cs55 — install Wazuh Manager + Dashboard + Indexer (all-in-one script)
- [x] cs33 — install Wazuh Agent, connect to cs55
- [x] cs20 — first attack: SSH brute force with Hydra + nmap scan
- [x] verify alerts on Wazuh Dashboard

## Startup sequence (mandatory order)

1. cs55: `wazuh-indexer` → `wazuh-manager` → `wazuh-dashboard`
2. cs33: `wazuh-agent`

> All services are enabled with `systemctl enable` — they start automatically on boot.
