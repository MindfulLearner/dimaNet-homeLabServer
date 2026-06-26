# OSINT Framework

Raccolta strutturata di strumenti OSINT open source, organizzati per categoria.

Sito ufficiale: https://osintframework.com
GitHub: https://github.com/lockfale/OSINT-Framework
Alternativa curata: https://github.com/jivoi/awesome-osint

---

## Categorie principali

| Categoria | Cosa si trova |
|-----------|---------------|
| Username | Ricerca account su piattaforme social e forum |
| Email Address | Verifica esistenza, breach, provider |
| Domain Name | WHOIS, DNS, subdomini, certificati |
| IP Address | Geolocalizzazione, ASN, abuse contact |
| Images / Video | Reverse image search, metadata EXIF |
| Social Networks | Profili pubblici, connessioni, post |
| People Search | Aggregatori di dati pubblici |
| Phone Numbers | Carrier lookup, spam DB |
| Dark Web | Onion search, paste site monitoring |
| Threat Intelligence | IOC, malware hash, reputation |
| Exploits / CVEs | Exploit-DB, NVD, Vulners |

---

## Strumenti notevoli per categoria

### Ricognizione domini e IP

| Tool | URL | Funzione |
|------|-----|----------|
| Shodan | https://www.shodan.io | Scansione dispositivi esposti su Internet |
| Censys | https://search.censys.io | Ricerca certificati e host |
| VirusTotal | https://www.virustotal.com | Reputazione IP/dominio/hash |
| SecurityTrails | https://securitytrails.com | DNS history, subdomini |
| DNSDumpster | https://dnsdumpster.com | DNS recon gratuito |
| BGP.he.net | https://bgp.he.net | ASN, BGP, WHOIS |

### Threat Intelligence

| Tool | URL | Funzione |
|------|-----|----------|
| OTX AlienVault | https://otx.alienvault.com | IOC condivisi dalla community |
| AbuseIPDB | https://www.abuseipdb.com | Reputazione IP |
| Talos Intelligence | https://talosintelligence.com | Cisco threat intel |
| MalwareBazaar | https://bazaar.abuse.ch | Sample malware con hash |
| URLhaus | https://urlhaus.abuse.ch | URL malware attivi |

### Username e persone

| Tool | URL | Funzione |
|------|-----|----------|
| Sherlock | https://github.com/sherlock-project/sherlock | Username su 300+ siti (CLI) |
| Maigret | https://github.com/soxoj/maigret | Username + profilo aggregato |
| Holehe | https://github.com/megadose/holehe | Verifica email su siti |

### Immagini e metadata

| Tool | URL | Funzione |
|------|-----|----------|
| ExifTool | https://exiftool.org | Estrai metadata da file |
| TinEye | https://tineye.com | Reverse image search |
| Google Images | https://images.google.com | Reverse image search |

---

## Uso in contesto difensivo

- Verificare esposizione pubblica dei propri asset (Shodan, Censys)
- Controllare se un IP/dominio e' presente in blacklist (VirusTotal, AbuseIPDB)
- Monitorare IOC legati alle campagne studiate in `../botnet-lab-from-scratch/`
