# dimaNet-homeLabServer

CUSTOM PROXMOX UI      
<img width="1914" height="560" alt="image" src="https://github.com/user-attachments/assets/20fb6451-bd81-4366-9d9f-73e1aaf5b561" />


Structure:
![image](https://github.com/user-attachments/assets/0d59c93b-380f-475c-bb52-890dc0ead69d)

Container In view:
![image](https://github.com/user-attachments/assets/55c11777-531d-49b5-8527-bf7fc1802a34)

### Come ho imparato? 
debuggando la mia rete... 

### DA FARE una lista dei miei Container e VM, attivi 24 su 24 
- per coleggarmi in remoto DDNS e WIREGUARD

Il progetto dimaNet nasce dall'esigenza di avere diversi dispositivi collegati alla rete domestica. Mi capita spesso di trovarmi in situazioni in cui, quando sono a casa di un amico o in un bar, non riesco a lavorare con il mio ambiente abituale. Ad esempio, quando utilizzo Fedora sul MacBook, ho difficoltà a eseguire chiamate API su Lua in ArchLinux, problema causato dalla differenza di aggiornamento di LuaRocks.

Oltre a questo, la voglia di fare PenTesting su altri PC rende dimaNet un ambiente perfetto per contenere dati personali, lavorarci da remoto da diversi dispositivi e svolgere attività di PenTesting.

Il server avrà come sistema operativo PROXMOX, con virtualizzazione e containerizzazione di Kali Linux e Windows.
Al momento, queste sono le uniche idee che ho.

### PER collegarmi in remoto?
- utilizzo..

## per il miglior utilizzo LINK di cose utili:

### Nvim Setup by Me.
https://github.com/MindfulLearner/josh-nvim-config

### TMUX SETUP BYUME.
https://github.com/MindfulLearner/dimaNet-Tmux-COnf

### Documentation SULLA SICUREZZA ancora da leggere e applicare sul mio serverby Celes:
https://github.com/celesrenata/pfsense-ultimate-config


# Network Basato su PROXMOX COSE DA FARE!!!
## Glossario dei Simboli
- ✅ **Completato:** L'attività è stata completata con successo.
- 🚧 **In Lavorazione:** L'attività è attualmente in corso.
- 🔲 **Non in Piano:** L'attività non è prevista o non è stata ancora pianificata.
## Attività

### 1. **Web Server**
   - 🚧 **Apache/Nginx:** Hosting di siti web e applicazioni web utilizzando server web popolari come Apache o Nginx su macchine virtuali (VM) o container LXC gestiti da Proxmox VE.
   - 🚧 **Stack LAMP/LEMP:** Configurazione di uno stack LAMP (Linux, Apache, MySQL, PHP) o LEMP (Linux, Nginx, MySQL, PHP) per l'hosting di siti web dinamici su VM o container in Proxmox.

### 2. **Database Server**
   - 🚧 **MySQL/PostgreSQL/MongoDB:** Installazione e gestione di database relazionali (ad esempio, MySQL, PostgreSQL) o NoSQL (ad esempio, MongoDB) all'interno di VM o container LXC su Proxmox VE.
   - 🚧 **Replica del Database:** Configurazione della replica del database per garantire la ridondanza e la disponibilità dei dati utilizzando VM in Proxmox.

### 3. **File Server**
   - 🚧 **Samba:** Condivisione di file e directory attraverso la rete utilizzando il protocollo Samba all'interno di VM gestite da Proxmox VE.
   - 🚧 **NFS:** Utilizzo di Network File System (NFS) per condividere directory tra sistemi Unix/Linux all'interno di VM o container in Proxmox.
   - 🚧 **FTP/SFTP:** Configurazione di server FTP o SFTP per trasferimenti di file sicuri utilizzando VM o container LXC in Proxmox.

### 4. **Virtualizzazione e Container**
   - ✅ **Proxmox VE:** Esecuzione e gestione di macchine virtuali multiple utilizzando Proxmox VE, una piattaforma di virtualizzazione open source basata su KVM e LXC.
   - 🚧 **Docker:** Gestione di applicazioni containerizzate con Docker su VM create in Proxmox VE.
   - ✅ **LXD:** Utilizzo di container di sistema LXC in Proxmox VE che offrono un ambiente simile a una macchina virtuale, ma con minori risorse richieste.

### 5. **Gestione Cloud e Virtualizzazione**
   - ✅ **OpenStack:** Deploy e gestione di cloud privati con OpenStack all'interno di VM in Proxmox.
   - 🚧 **MAAS:** Configurazione di Metal as a Service (MAAS) per il provisioning di server fisici in un ambiente virtualizzato con Proxmox.
   - 🚧 **Juju:** Orchestrazione di servizi e applicazioni attraverso vari ambienti utilizzando Juju all'interno di VM su Proxmox.

### 6. **Servizi di Rete**
   - 🚧 **DNS:** Hosting di un server DNS con BIND o altri servizi DNS in VM gestite da Proxmox.
   - 🚧 **DHCP:** Configurazione di un server DHCP per assegnare automaticamente indirizzi IP ai dispositivi sulla rete utilizzando VM in Proxmox.
   - 🚧 **Proxy Server:** Utilizzo di Squid o altri software proxy per controllare e ottimizzare l'accesso a Internet per gli utenti tramite VM in Proxmox.

### 7. **Mail Server**
   - 🚧 **Postfix/Dovecot:** Esecuzione di un server di posta completo utilizzando Postfix per l'invio delle email e Dovecot per la ricezione in una VM su Proxmox.
   - 🚧 **SpamAssassin:** Integrazione di misure anti-spam con SpamAssassin e altri strumenti in VM gestite da Proxmox.

### 8. **Sicurezza e Monitoraggio**
   - 🚧 **Firewall:** Configurazione e gestione di firewall software come iptables/ufw all'interno di VM in Proxmox per proteggere l'infrastruttura.
   - 🚧 **Rilevamento Intrusioni:** Utilizzo di strumenti come Snort o Suricata per il rilevamento delle intrusioni in VM su Proxmox.
   - 🚧 **Monitoraggio:** Implementazione di monitoraggio del server con strumenti come Nagios, Zabbix o Prometheus per tracciare la salute e le prestazioni delle VM in Proxmox.

### 9. **Ambiente di Sviluppo**
   - 🚧 **Controllo di Versione:** Configurazione di server Git per gestire e collaborare sul codice all'interno di VM in Proxmox.
   - 🚧 **CI/CD:** Utilizzo di Jenkins, GitLab CI, o altri strumenti di integrazione continua/deployment continuo per automatizzare i flussi di lavoro di sviluppo in VM su Proxmox.
   - 🚧 **Framework di Sviluppo:** Hosting di framework di sviluppo come Node.js, Ruby on Rails o Django per test e deployment in VM o container LXC su Proxmox.

### 10. **Media Server**
   - 🚧 **Plex/Emby:** Utilizzo di software di media server come Plex o Emby per lo streaming di video, musica e altri contenuti multimediali su vari dispositivi tramite VM in Proxmox.
   - 🚧 **OwnCloud/NextCloud:** Configurazione di soluzioni di cloud storage personale per accedere e condividere file ovunque tramite VM in Proxmox.

### 11. **Backup Server**
   - ✅ **rsync:** Automazione dei backup con rsync e cron job utilizzando VM in Proxmox.
   - ✅ **Bacula:** Utilizzo di Bacula o software simile per la gestione di soluzioni di backup su larga scala in VM su Proxmox.

### 12. **Automazione e Scripting**
   - ✅ **Ansible:** Automazione delle attività di gestione del server con Ansible per orchestrare le VM e container LXC in Proxmox.
   - ✅ **Script Shell:** Scrittura e pianificazione di script shell personalizzati per varie attività automatizzate all'interno di VM o container in Proxmox.

### 13. **VPN Server**
   - ✅ **OpenVPN/WireGuard:** Configurazione di un server VPN per consentire l'accesso remoto sicuro alla rete tramite VM in Proxmox.

### 14. **Game Server**
   - 🚧 **Minecraft/Counter-Strike:** Hosting di server di gioco dedicati per vari giochi multiplayer come Minecraft, Counter-Strike o altri su VM in Proxmox.

### 15. **AI e Machine Learning**
   - 🚧 **TensorFlow/PyTorch:** Deploy e gestione di modelli AI/ML utilizzando framework come TensorFlow o PyTorch in VM su Proxmox.

### 16. **IoT Hub**
   - 🚧 **MQTT Broker:** Gestione di dispositivi IoT utilizzando un broker MQTT per facilitare la comunicazione tra i dispositivi tramite VM in Proxmox.



