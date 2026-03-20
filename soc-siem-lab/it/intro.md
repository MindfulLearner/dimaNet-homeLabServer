# Progetto #1: Costruisci il tuo SOC (SIEM Lab)

## Macchine

| Nome | Tipo | OS | Ruolo |
|------|------|----|-------|
| cs20 | VM | Kali Linux | Attaccante - Red Team |
| cs33 | Container | Ubuntu | Vittima - Wazuh Agent (utente: `swagvict`, password: `victim`) |
| cs55 | VM | Ubuntu | Wazuh Manager + Dashboard |

---


<img width="4422" height="4322" alt="image" src="https://github.com/user-attachments/assets/bb6581b2-1e22-4a25-b74b-841d8f88d864" />



## Architettura

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

    subgraph ANALYST["👁️ Analista SOC"]
        E([Tu])
    end

    A -->|"SSH brute force\nnmap scan\nexploit"| B
    B -->|log| C
    C -->|visualizza| D
    C -->|alert| E
    D --> E
```

---

## Checklist

- [x] cs55 - installare Wazuh Manager + Dashboard + Indexer (script all-in-one)
- [x] cs33 - installare Wazuh Agent, collegarlo a cs55
- [x] cs20 - primo attacco: brute force SSH con Hydra + nmap scan
- [x] verificare alert su Wazuh Dashboard

## Sequenza di avvio (ordine obbligatorio)

1. cs55: `wazuh-indexer` → `wazuh-manager` → `wazuh-dashboard`
2. cs33: `wazuh-agent`

> Tutti i servizi sono abilitati con `systemctl enable` - partono automaticamente all'accensione.
