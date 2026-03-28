# PoC - Proof of Concept

Raccolta di proof of concept riprodotti in home lab su dimaNet (Proxmox VE).
Ogni PoC è documentato con ambiente, steps, risultati e osservazioni, inclusi i fallimenti.

---

## Indice

| # | CVE | Vulnerabilità | Target testati | Stato |
|---|-----|---------------|----------------|-------|
| 1 | [CVE-2024-6387](hacking-cs33-openssh-8.9p1-CVE-2024-6387/README.md) | regreSSHion - OpenSSH RCE non autenticato | Ubuntu 22.04 x86_64, Debian 12 i386 | Documentato - RCE non riprodotto su sistemi moderni |
| 2 | [CVE-2006-5051](hacking-ubuntu-6.06-CVE-2006-5051/notes.md) | Bug originale 2006 - OpenSSH signal handler (pam_start) | Ubuntu 6.06 i386 | Planned |

---

## Note metodologiche
```
attempts/   <- tentativi progressivi con note su ogni errore
scripts/    <- strumenti di ricognizione e test
README.md   <- documentazione completa: CVE, meccanismo, risultati, osservazioni reali
```
