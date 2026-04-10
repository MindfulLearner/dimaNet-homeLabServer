# Privesc con linPEAS (Arch Linux, lab LAN)

**Tipo:** post-exploitation · **Tool:** [linPEAS / PEASS-ng](https://github.com/carlospolop/PEASS-ng/tree/master/linPEAS)  
**Solo sistemi di tua proprietà.** Sostituisci `<TARGET_IP>` con l’IP della VM nel tuo lab.

## Presupposto

Shell non-root via SSH (es. utente `learner`).

## Ricognizione (nmap)

Se l’host non risponde al ping: `-Pn`. Solo SSH tipico:

```bash
nmap -sV -Pn <TARGET_IP>
# Scan veloce porte, poi dettaglio solo sulle porte aperte:
# nmap -Pn -p- --min-rate 5000 <TARGET_IP> -oA nmap/portscan
# nmap -Pn -sC -sV -p 22 <TARGET_IP> -oA nmap/detailed
```

## linPEAS

```bash
scp linpeas.sh user@<TARGET_IP>:/tmp/linpeas.sh
ssh user@<TARGET_IP> 'chmod +x /tmp/linpeas.sh && /tmp/linpeas.sh 2>/dev/null | tee /tmp/linpeas_out.txt'
```

**Lettura:** rosso/giallo = priorità; controlla `sudo -l`, SUID, capabilities, cron scrivibili, processi root.

**Falso positivo frequente:** capabilities su `sshd`: normale che sshd sia root sulla 22.

## Caso documentato: `sudo` troppo permissivo

Output linPEAS in rosso, conferma con `sudo -l`:

```text
User learner may run the following commands on host:
    (ALL) ALL
```

Significa: stesso utente può eseguire qualsiasi comando come chiunque → `sudo su` / `sudo -i` → root. Nessuna CVE, solo cattiva configurazione.

## Mitigazione

Least privilege in `/etc/sudoers` (`visudo`): solo i comandi necessari, no `(ALL) ALL` generico; logging sudo; evitare `NOPASSWD` se non serve.
