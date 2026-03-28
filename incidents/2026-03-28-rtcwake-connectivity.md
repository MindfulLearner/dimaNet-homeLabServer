# Incident Report - 2026-03-28: Connettività persa + QEMU freeze VM 105

## Sommario

Due problemi distinti investigati il 28 marzo 2026:

| # | Problema | Causa | Stato |
|---|----------|-------|-------|
| 1 | Irraggiungibilità post-rtcwake (boot 11:59, 31 sec) | Non determinata: ARP stale / IP pubblico cambiato / e1000e wake anomaly | **Aperto** |
| 2 | QEMU freeze VM 105 (~19 min uptime) | `iothread=1` su `virtio-scsi-single` -> deadlock I/O -> host irraggiungibile | **Risolto** |

---

## Cronologia Boot (28 marzo 2026)

| Boot        | Inizio          | Fine            | Durata     | Note |
|-------------|-----------------|-----------------|------------|------|
| `404a6e91`  | Ven 27/03 11:42 | Sab 28/03 04:02 | ~16h 20min | Boot normale; shutdown pulito via `rtcwake` (`systemd-poweroff`) |
| **GAP**     | 04:02           | 11:59           | ~7h 57min  | Server off - `rtcwake -m off 8h` |
| `ceedc288`  | 11:59:39        | 12:00:10        | **31 sec** | Wake rtcwake - servizi OK, host irraggiungibile; force power-off |
| `39891094`  | 13:24:45        | 13:24:45        | 0 sec      | Reset immediato post force-off (BIOS/hardware) |
| `526fa91c`  | 13:29:32        | 13:33:41        | 4 min      | VM 105 avviata (13:31); WireGuard OK; shutdown manuale |
| **GAP**     | 13:33:41        | 13:40:16        | ~6 min     | Server off - check Mac mini LAN alle 13:39 -> server era già spento |
| `25b037ce`  | 13:40:16        | -               | stabile    | Boot attuale |

---

## Problema 1 - Irraggiungibilità post-rtcwake (boot `ceedc288`)

### Cosa è successo

Il server si è svegliato normalmente. Tutti i servizi sono partiti senza errori:
- NIC `eno1` up a 1000 Mbps Full Duplex
- `vmbr0` in forwarding state
- `wg-quick@wg0` -> OK (IP 10.118.240.1/24, porta 51820)
- `pve-firewall`, `fail2ban`, `pvedaemon`, `pveproxy` -> tutti OK
- Boot completato in 21.5 secondi, NTP sincronizzato

Nonostante tutto OK nei log, il server era irraggiungibile sia via VPN che via LAN (Proxmox UI `8006` non rispondeva dal Mac mini). Force power-off dalla corrente a ~12:00 (31 secondi dopo il boot).

### Causa - non determinata

Ipotesi in ordine di probabilità:

1. **ARP stale** - dopo 8h offline, il gateway potrebbe aver impiegato qualche secondo ad aggiornare la tabella ARP per `192.168.1.100`
2. **IP pubblico cambiato** - l'ISP potrebbe aver riassegnato l'IP durante le 8h di spegnimento (spiegherebbe il VPN fail, non il LAN fail)
3. **e1000e post-ACPI wake** - il driver Intel sulla HP EliteDesk 800 G3 può avere anomalie nei primi secondi dopo wake da S4/S5

> **Nota:** il check LAN dal Mac mini alle 13:39 non è correlato a questo problema: il server era già spento (gap 13:33->13:40).

### Da fare al prossimo rtcwake

Eseguire subito dopo il wake:
```bash
ping 192.168.1.1        # verifica routing LAN
wg show                 # verifica tunnel WireGuard
```

---

## Problema 2 - QEMU freeze VM 105 ✓ Risolto

### Cos'è la VM 105

| Parametro | Valore |
|-----------|--------|
| VMID | 105 |
| Nome | `cs33-32bit-debianHAcked` |
| OS | Debian 12 bookworm, **32-bit** (i386), GNOME |
| Scopo | Lab vittima per CVE-2024-6387 (regreSSHion) |
| OpenSSH | `9.2p1-2+deb12u2` (versione vulnerabile, downgraded) |
| sshd_config | `MaxAuthTries 200`, `PubkeyAcceptedAlgorithms +ssh-rsa` |
| Utenti | `root`, `swagvict` (josh) |

### Timeline eventi VM 105 (notte 27->28 marzo)

| Orario   | Evento     | Risultato |
|----------|------------|-----------|
| 01:30:39 | qmstart    | OK |
| 01:49:37 | qmshutdown | **ERRORE: VM quit/powerdown failed - got timeout** |
| 01:51:17 | qmshutdown | **ERRORE: VM quit/powerdown failed - got timeout** |
| 01:52:14 | qmstop     | **ERRORE: can't lock file `/var/lock/qemu-server/lock-105.conf`** |
| 01:52:49 | qmstart    | tentativo restart |
| 01:54:16 | qmshutdown | OK |
| 01:57:50 | qmstart    | OK |
| 04:02:51 | -          | Server spento (rtcwake) |
| 14:11:09 | qmstart    | OK - test con fix applicato |

La VM ha funzionato ~19 minuti (01:30->01:49), poi il QEMU si è freezato. Proxmox non riusciva più a spegnerla né ad acquisire il lock. Con QEMU freezato, la coda virtio-net rimane bloccata nel kernel del host -> networking host irraggiungibile.

### Causa tecnica

Config problematica al momento del freeze:

```
cpu: kvm32              <- emulazione 32-bit su host 64-bit (meno stabile)
memory: 4050            <- valore non-standard, non potenza di 2
scsi0: ...,iothread=1   <- iothread attivo
scsihw: virtio-scsi-single
```

L'`iothread=1` su `virtio-scsi-single` è la causa principale: il thread I/O del disco si blocca in certi scenari di carico, freezando l'intero processo QEMU.

> Il freeze avviene anche senza workload exploit: è un problema di config hardware emulata, non dell'attività nella VM.

### Fix applicato

```diff
- memory: 4050
+ memory: 4096

- scsi0: local-lvm:vm-105-disk-0,iothread=1,size=40G
+ scsi0: local-lvm:vm-105-disk-0,iothread=0,size=40G
```

### Verifica

VM 105 avviata alle 14:11 con config corretta, monitorata oltre 20 minuti senza freeze. QEMU (PID 7362) stabile al 20% CPU, nessun timeout nei log. **Fix confermato.**

---

## Stato Finale Server

| Parametro       | Valore |
|-----------------|--------|
| Boot attuale    | `25b037ce` - 13:40:16, stabile |
| RAM             | 1.5 GB / 15 GB |
| Disco root      | 55 GB / 94 GB (62%) |
| Swap            | 0 B |
| WireGuard       | UP - handshake peer attivo |
| fail2ban        | 0 banned |
| Servizi failed  | Nessuno |
| OpenSSH host    | `9.2p1-2+deb12u7` (patched, non vulnerabile a CVE-2024-6387) |

---

## Open Items

- [x] ~~QEMU freeze VM 105~~ - risolto (iothread=0, memory=4096, verificato 14:11–14:32)
- [ ] Investigare irraggiungibilità post-rtcwake - al prossimo wake eseguire `ping 192.168.1.1` e `wg show` subito dopo il boot
- [ ] Valutare `PersistentKeepalive = 25` nel peer WireGuard per mantenere il tunnel attivo dopo wake da sleep lungo
