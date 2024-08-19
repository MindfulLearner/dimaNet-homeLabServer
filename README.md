# dimaNet-homeLabServer

Il progetto dimaNet nasce dall'esigenza di avere diversi dispositivi collegati alla rete domestica. Mi capita spesso di trovarmi in situazioni in cui, quando sono a casa di un amico o in un bar, non riesco a lavorare con il mio ambiente abituale. Ad esempio, quando utilizzo Fedora sul MacBook, ho difficoltà a eseguire chiamate API su Lua in ArchLinux, problema causato dalla differenza di aggiornamento di LuaRocks.

Oltre a questo, la voglia di fare PenTesting su altri PC rende dimaNet un ambiente perfetto per contenere dati personali, lavorarci da remoto da diversi dispositivi e svolgere attività di PenTesting.

Il server avrà come sistema operativo Ubuntu, con virtualizzazione e containerizzazione di Kali Linux e Windows.
Al momento, queste sono le uniche idee che ho.

## per il miglior utilizzo LINK di cose utili:

### Nvim Setup by Me.
https://github.com/MindfulLearner/josh-nvim-config

### TMUX SETUP BYUME.
https://github.com/MindfulLearner/dimaNet-Tmux-COnf

### Documentation by Celes:
https://github.com/celesrenata/pfsense-ultimate-config


# Network Basato su Ubuntu Server

## Glossario dei Simboli

- ✅ **Completato:** L'attività è stata completata con successo.
- 🚧 **In Lavorazione:** L'attività è attualmente in corso.
- 🔲 **Non in Piano:** L'attività non è prevista o non è stata ancora pianificata.

## Attività

### 1. **Web Server**
   - 🔲 **Apache/Nginx:** Hosting di siti web e applicazioni web utilizzando server web popolari come Apache o Nginx.
   - 🔲 **Stack LAMP/LEMP:** Configurazione di uno stack LAMP (Linux, Apache, MySQL, PHP) o LEMP (Linux, Nginx, MySQL, PHP) per l'hosting di siti web dinamici.

### 2. **Database Server**
   - 🔲 **MySQL/PostgreSQL/MongoDB:** Installazione e gestione di database relazionali (ad esempio, MySQL, PostgreSQL) o NoSQL (ad esempio, MongoDB) per la memorizzazione e il recupero dei dati.
   - 🔲 **Replica del Database:** Configurazione della replica del database per garantire la ridondanza e la disponibilità dei dati.

### 3. **File Server**
   - 🔲 **Samba:** Condivisione di file e directory attraverso la rete utilizzando il protocollo Samba, consentendo la condivisione tra sistemi operativi Windows.
   - 🔲 **NFS:** Utilizzo di Network File System (NFS) per condividere directory tra sistemi Unix/Linux.
   - 🔲 **FTP/SFTP:** Configurazione di server FTP o SFTP per trasferimenti di file sicuri.

### 4. **Virtualizzazione e Container**
   - 🔲 **KVM/QEMU:** Esecuzione di macchine virtuali multiple utilizzando KVM (Kernel-based Virtual Machine) e QEMU per la virtualizzazione completa.
   - 🔲 **Docker:** Gestione di applicazioni containerizzate con Docker, consentendo un uso efficiente delle risorse e un facile deployment.
   - 🔲 **LXD:** Utilizzo di LXD per container di sistema che offrono un ambiente simile a una macchina virtuale, ma con minori risorse richieste.

### 5. **Gestione Cloud e Virtualizzazione**
   - 🔲 **OpenStack:** Deploy e gestione di cloud privati con OpenStack.
   - 🔲 **MAAS:** Configurazione di Metal as a Service (MAAS) per il provisioning di server fisici.
   - 🔲 **Juju:** Orchestrazione di servizi e applicazioni attraverso vari ambienti utilizzando Juju.

### 6. **Servizi di Rete**
   - 🔲 **DNS:** Hosting di un server DNS con BIND o altri servizi DNS.
   - 🔲 **DHCP:** Configurazione di un server DHCP per assegnare automaticamente indirizzi IP ai dispositivi sulla rete.
   - 🔲 **Proxy Server:** Utilizzo di Squid o altri software proxy per controllare e ottimizzare l'accesso a Internet per gli utenti.

### 7. **Mail Server**
   - 🔲 **Postfix/Dovecot:** Esecuzione di un server di posta completo utilizzando Postfix per l'invio delle email e Dovecot per la ricezione.
   - 🔲 **SpamAssassin:** Integrazione di misure anti-spam con SpamAssassin e altri strumenti.

### 8. **Sicurezza e Monitoraggio**
   - 🔲 **Firewall:** Configurazione e gestione di iptables/ufw (Uncomplicated Firewall) per proteggere il server.
   - 🔲 **Rilevamento Intrusioni:** Utilizzo di strumenti come Snort o Suricata per il rilevamento delle intrusioni.
   - 🔲 **Monitoraggio:** Implementazione di monitoraggio del server con strumenti come Nagios, Zabbix o Prometheus per tracciare la salute e le prestazioni del server.

### 9. **Ambiente di Sviluppo**
   - 🔲 **Controllo di Versione:** Configurazione di server Git per gestire e collaborare sul codice.
   - 🔲 **CI/CD:** Utilizzo di Jenkins, GitLab CI, o altri strumenti di integrazione continua/deployment continuo per automatizzare i flussi di lavoro di sviluppo.
   - 🔲 **Framework di Sviluppo:** Hosting di framework di sviluppo come Node.js, Ruby on Rails o Django per test e deployment.

### 10. **Media Server**
   - 🔲 **Plex/Emby:** Utilizzo di software di media server come Plex o Emby per lo streaming di video, musica e altri contenuti multimediali su vari dispositivi.
   - 🔲 **OwnCloud/NextCloud:** Configurazione di soluzioni di cloud storage personale per accedere e condividere file ovunque.

### 11. **Backup Server**
   - 🔲 **rsync:** Automazione dei backup con rsync e cron job.
   - 🔲 **Bacula:** Utilizzo di Bacula o software simile per la gestione di soluzioni di backup su larga scala.

### 12. **Automazione e Scripting**
   - 🔲 **Ansible:** Automazione delle attività di gestione del server con Ansible.
   - 🔲 **Script Shell:** Scrittura e pianificazione di script shell personalizzati per varie attività automatizzate.

### 13. **VPN Server**
   - 🔲 **OpenVPN/WireGuard:** Configurazione di un server VPN per consentire l'accesso remoto sicuro alla rete.

### 14. **Game Server**
   - 🔲 **Minecraft/Counter-Strike:** Hosting di server di gioco dedicati per vari giochi multiplayer come Minecraft, Counter-Strike o altri.

### 15. **AI e Machine Learning**
   - 🔲 **TensorFlow/PyTorch:** Deploy e gestione di modelli AI/ML utilizzando framework come TensorFlow o PyTorch.

### 16. **IoT Hub**
   - 🔲 **MQTT Broker:** Gestione di dispositivi IoT utilizzando un broker MQTT per facilitare la comunicazione tra i dispositivi.


