# VPN Setup - WireGuard + PiVPN + No-IP DDNS

Configurazione accesso remoto al homelab via [VPN](#vpn).

---

## Architettura

```
[MacBook / Client remoto]
        |
        | tunnel WireGuard cifrato (UDP 51820)
        |
[Internet]
        |
[Router casa] <- Mappatura Porte (UDP 51820) -> Proxmox
        |
[Proxmox 192.capy.1.capy] <- WireGuard server (wg0)
        |
[Rete VPN 10.x.x.x]
```

---

## Componenti

### WireGuard

Protocollo [VPN](#vpn) che crea un tunnel cifrato tra il client (MacBook) e il server ([Proxmox](#proxmox)).

- Interfaccia: [`wg0`](#wg0)
- Porta: `51820` UDP
- [Subnet](#subnet) VPN: `10.x.x.x/24`
- IP server nella VPN: `10.x.x.1`
- IP client nella VPN: `10.x.x.2` (MacBook)

### PiVPN

Script per installare e gestire WireGuard senza configurare chiavi e file a mano.

<details>
  <summary>Comandi</summary>

```bash
pivpn add          # aggiunge un nuovo client (peer)
pivpn -l           # lista client attivi
pivpn -r           # rimuove un client
pivpn -qr          # mostra QR code per connettere telefono
pivpn -d           # debug connessione
```

Config: `/etc/pivpn/wireguard/setupVars.conf`
Client configs: `/etc/wireguard/configs/`

</details>

### No-IP DDNS

Il router ha un [IP dinamico](#ip-dinamico) che cambia al riavvio o quando l'[ISP](#isp) lo riassegna. No-IP mantiene un hostname fisso (`<hostname>.ddns.net`) aggiornato con l'IP corrente.

- Piano gratuito: richiede conferma dell'hostname ogni 30 giorni via email
- Il router ha un client [DDNS](#ddns) integrato - nessuna configurazione aggiuntiva su [Proxmox](#proxmox) necessaria.

---

## Le chiavi WireGuard

WireGuard usa crittografia a chiave pubblica/privata (come SSH).

| Chiave | Scopo |
|---|---|
| **[Private key](#private-key)** | Decifra il traffico ricevuto |
| **[Public key](#public-key)** | Il [peer](#peer) la usa per cifrare il traffico verso di te |
| **[Preshared key](#preshared-key)** | Layer extra di sicurezza simmetrica (opzionale) |

Le chiavi stanno in:
- `/etc/wireguard/wg0.conf` - private key del server + public key di ogni peer
- `/etc/wireguard/configs/` - config dei client (generati da [PiVPN](#pivpn))

---

## Port Forwarding (Mappatura Porte)

Il router blocca le connessioni in entrata. La porta 51820 UDP va inoltrata all'IP del [Proxmox](#proxmox).

Su **Router**: Impostazioni -> Avanzate -> **Mappatura Porte**

- Porta esterna: `51820`
- Porta interna: `51820`
- Protocollo: `UDP`
- IP: `192.capy.1.capy` (IP locale del Proxmox)

Il [NAT](#nat) Statico non viene usato perché manderebbe tutto il traffico in entrata verso quell'IP, non solo la porta 51820, rompendo la connettività degli altri dispositivi.

---

## Split Tunnel vs Full Tunnel

| Modalità | AllowedIPs nel client | Comportamento |
|---|---|---|
| **[Split tunnel](#split-tunnel)** | `10.x.x.0/24` | Solo il traffico verso la VPN passa nel tunnel. Internet normale. |
| **[Full tunnel](#full-tunnel)** | `0.0.0.0/0` | Tutto il traffico passa per il server. Richiede [NAT](#nat) sul Proxmox. |

Usiamo lo **[split tunnel](#split-tunnel)**.

---

## TODO / Da testare

- Verificare che la VPN si riconnetta automaticamente dopo aver spento e riacceso il WiFi sul MacBook
- Verificare comportamento dopo riavvio del router (cambio [IP dinamico](#ip-dinamico) [ISP](#isp))

---

## Glossario

### VPN
Tunnel cifrato tra due dispositivi attraverso internet.

### WireGuard
Protocollo VPN basato su crittografia a chiave pubblica.

### PiVPN
Script che semplifica l'installazione e gestione di WireGuard su Linux.

### DDNS
Dynamic DNS - aggiorna automaticamente un hostname con l'IP pubblico corrente quando cambia.

### ISP
Internet Service Provider - il fornitore di connessione internet. Assegna l'IP pubblico al router.

### IP dinamico
IP pubblico che può cambiare nel tempo, tipico dei contratti casa. Richiede DDNS per mantenere un hostname raggiungibile.

### Port forwarding
Regola sul router che inoltra il traffico su una porta specifica a un IP interno.

### NAT
Network Address Translation - il router traduce l'IP pubblico in IP privati interni (192.168.x.x). Il port forwarding è una regola NAT.

### Peer
Dispositivo partecipante alla VPN WireGuard. Ha una coppia di chiavi e un IP assegnato nella rete VPN.

### Handshake
Fase in cui due peer WireGuard si autenticano e stabiliscono il tunnel. Visibile con `wg show`.

### Private key
Chiave segreta del dispositivo. Decifra il traffico ricevuto.

### Public key
Chiave pubblica derivata dalla private key, condivisa con i peer per cifrare il traffico.

### Preshared key
Chiave simmetrica opzionale tra due peer. Generata da PiVPN automaticamente.

### Split tunnel
Solo il traffico verso la rete VPN passa nel tunnel. Il resto esce direttamente.

### Full tunnel
Tutto il traffico passa nel tunnel. Richiede che il server sia configurato come router NAT.

### wg0
Interfaccia di rete virtuale creata da WireGuard. Visibile con `ip link show` o `wg show`.

### Proxmox
Hypervisor installato su bare metal. Gestisce VM e container LXC.

### LXC
Linux Container - container leggero gestito da Proxmox, più leggero di una VM.

### Subnet
Porzione di rete IP (es. `10.x.x.0/24` = 254 indirizzi). La `/24` indica la maschera di rete.
