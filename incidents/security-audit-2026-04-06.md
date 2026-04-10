# Security audit 2026-04-06

Proxmox, router ISP, Mac, WireGuard. Dettagli IP/MAC in `network-map.md` (locale, `.gitignore`, non in repo).

## Esito

| Area | Prima | Dopo |
|------|-------|------|
| Hypervisor | Parziale | `pve-firewall` + servizi ridotti |
| Mac | Parziale | Firewall OS da abilitare |
| Router | Pannello esposto | Password forte; firewall basso (alto rompe WebRTC); barriera reale su Proxmox |
| WireGuard | Non funzionante | OK (DDNS + whitelist DNS) |

## Interventi

- Router: password admin; FTP off; firewall alto provato poi basso (WebRTC/UDP).
- Proxmox: firewall ON; SSH/UI solo LAN + VPN; utente inattivo bloccato; rpcbind off.
- WG: DDNS No-IP + blocklist resolver: risolto con whitelist dominio.

## Router (CPE)

Su WAN spesso HTTP servizio, admin/TR-069: tipico. Mitigazione: CPE in bridge + firewall proprio. Port forward: solo WG UDP verso nodo (dettaglio in `network-map.md`).

## Proxmox (schema)

`policy_in DROP`; SSH e 8006 da LAN e WireGuard; `51820/udp` VPN. Log SSH: burst LAN e tentativo da internet quando SSH fu esposto; auth solo chiave.

## Mac

FileVault/SIP/Gatekeeper OK; firewall macOS; AnyDesk da chiudere se inutile.

## WireGuard

Whitelist FQDN DDNS sul resolver; provider DDNS senza scadenze corte se possibile.

## Pendenza

| Priorità | Azione |
|----------|--------|
| Alta | Firewall macOS |
| Media | Aggiornamento macOS, DDNS stabile |
| Bassa | Firewall dopo CPE |
