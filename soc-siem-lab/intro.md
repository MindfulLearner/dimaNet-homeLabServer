# Project #1: Build Your Own SOC (SIEM Lab)

## Machines

| Name | Type | OS | Role |
|------|------|----|------|
| cs20 | VM | Kali Linux | Attacker — Red Team |
| cs33 | Container | Ubuntu | Victim — Wazuh Agent |
| cs55 | VM | Ubuntu | Wazuh Manager + Kibana |

---

<img width="512" height="512" alt="image" src="https://github.com/user-attachments/assets/64c55f6d-0f05-4b21-9afa-c7f8485cb054" />

## Architecture

```mermaid
flowchart LR
    subgraph RED["🔴 Red Team"]
        A([cs20\nKali Linux])
    end

    subgraph BLUE["🔵 Blue Team"]
        B[cs33\nUbuntu Container\nWazuh Agent]
        C[cs55\nUbuntu VM\nWazuh Manager]
        D[Kibana Dashboard]
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

## Next Steps

- [ ] cs55 — installare Wazuh Manager + Kibana
- [ ] cs33 — installare Wazuh Agent, collegarlo a cs55
- [ ] cs20 — primo attacco: brute force SSH con Hydra + nmap scan
- [ ] verificare alert su Kibana
