# Privesc con linPEAS (Arch Linux, lab LAN)

**Tipo:** post-exploitation · **Tool:** [linPEAS / PEASS-ng](https://github.com/carlospolop/PEASS-ng/tree/master/linPEAS)  
**Solo sistemi di tua proprietà.** Sostituisci `capybara-redacted` con l’IP della VM nel tuo lab.

## Presupposto

Shell non-root via SSH (es. utente `learner`).

## Ricognizione (nmap)

Se l’host non risponde al ping: `-Pn`. Solo SSH tipico:

```bash
nmap -sV -Pn capybara-redacted
# Scan veloce porte, poi dettaglio solo sulle porte aperte:
# nmap -Pn -p- --min-rate 5000 capybara-redacted -oA nmap/portscan
# nmap -Pn -sC -sV -p 22 capybara-redacted -oA nmap/detailed
```

## linPEAS

```bash
scp linpeas.sh user@capybara-redacted:/tmp/linpeas.sh
ssh user@capybara-redacted 'chmod +x /tmp/linpeas.sh && /tmp/linpeas.sh 2>/dev/null | tee /tmp/linpeas_out.txt'
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
