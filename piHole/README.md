# Pi-hole

## Setup

- **Host:** narutoPi (`<PI_IP>`)
- **User:** naruto
- **OS:** Raspbian Linux 6.12.47 armv7l (trixie)
- **Rete:** eth0 (cavo)
- **Pi-hole:** v6.x -- bare-metal, web server integrato in pihole-FTL (CivetWeb)
- **Admin:** `http://<PI_IP>/admin`

## Decisioni

**Bare-metal, no Docker**
Docker scartato per due motivi: il repo ufficiale non supporta Raspbian trixie, e il Pi Zero W ha solo 512MB RAM -- troppo poco per Docker + Portainer + Pi-hole insieme. Portainer scartato di conseguenza.

**IP statico**
Configurato `<PI_IP>/24` su eth0 via `/etc/dhcpcd.conf` (gateway `<GATEWAY_IP>`). Era gia `.31` via DHCP, solo fissato.

**DNS del router**
Primario: `<PI_IP>` (Pi-hole). Secondario: `1.1.1.1` come fallback. Tutto il traffico DNS della rete passa per Pi-hole.

## Come funzionano le blocklist

Pi-hole intercetta le query DNS e le confronta con liste di domini malevoli/pubblicitari (blocklist), mantenute da community e bot. Se il dominio e in lista, risponde `0.0.0.0` bloccando la connessione prima che parta.

**Pi-hole non blocca tutto.** Blocca solo i domini presenti nelle sue liste. I provider creano continuamente nuovi domini o ruotano sottodomini per eludere i blocchi. Nessuna lista e completa al 100%. Inoltre alcuni browser usano DNS-over-HTTPS (DoH), bypassando Pi-hole completamente.

Lista di default: StevenBlack unified list (inclusa nell'installer).

Liste piu aggressive:
- `firebog.net` -- raccolta per categoria, da leggera ad aggressiva
- `oisd.nl` -- buon bilanciamento copertura/falsi positivi

Piu la lista e aggressiva, piu e probabile bloccare siti legittimi (falsi positivi).

## Note Pi-hole v6

La v6 ha cambiato tutto rispetto alla v5:

| Cosa | v5 | v6 |
|------|----|----|
| Web server | lighttpd | pihole-FTL (CivetWeb) |
| Config web server | `/etc/lighttpd/external.conf` | `/etc/pihole/pihole.toml` |
| API | `/admin/api.php?summary` | `/api/stats/summary` + auth |
| Auth API | nessuna (o token opzionale) | `POST /api/auth` -> `X-FTL-SID` |
| File extra serviti | alias lighttpd | `serve_all = true` in pihole.toml |

Tutta la documentazione online di Pi-hole fa riferimento alla v5 -- verificare sempre la versione installata prima di seguire guide.

## Pagina custom Naruto

Aggiunta una pagina fullscreen (`/naruto/`) con l'immagine Naruto + Raspberry Pi, accessibile tramite un bottone icona (sigillo di Naruto) in alto a sinistra nel header dell'admin.

## Prossimi step

- [ ] Valutare blocklist piu aggressiva (firebog.net o oisd.nl)
- [ ] Testare blocco ads da dispositivi della rete
- [ ] Verificare query log nella web UI
