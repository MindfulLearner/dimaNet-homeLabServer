# PoC (Proof of Concept)

Proof of concept in home lab (Proxmox VE): ambiente, passi, risultati, anche fallimenti.

## Indice

| # | Voce | Tipo | Target / note | Stato |
|---|------|------|---------------|-------|
| 1 | [CVE-2024-6387](1.CVE-2024-6387-cs33/README.md) | regreSSHion (OpenSSH) | Ubuntu 22.04 x64, Debian 12 i386 | Documentato, RCE non riprodotto |
| 2 | [CVE-2006-5051](CVE-2006-5051-ubuntu-6.06/notes.md) | signal handler OpenSSH (pam_start) | Ubuntu 6.06 i386 | Planned |
| 3 | [Botnet lab](botnet-lab-from-scratch/README.md) | C2 + agent Python | Ubuntu, Debian, LXC | In progress |
| 4 | [CVE-2016-4450: k3s, nginx DoS, roadmap lab](6.CVE-2016-4450-k3s-nginx-dos/README.md) | Proxmox, k3s, botnet, HTTP/1.1, STATUS pin | LAN | Planned |

Struttura tipica: `README.md` (overview), `attempts/`, `scripts/`, `STATUS.md` dove serve.
