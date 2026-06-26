> **Disclaimer - Educational Lab Only**
> This lab exists exclusively inside an isolated Proxmox LXC network with no outbound internet access.
> All agents, C2 traffic, and payloads are confined to VMs/containers I own and control.
> The purpose is to understand botnet mechanics for defensive/SOC purposes - not to deploy malware.
> **Do not replicate outside a controlled, isolated environment.**

---

<img width="1600" height="1563" alt="image" src="https://github.com/user-attachments/assets/c8e27c67-e5fe-42b3-a89f-c35119750224" />

# Botnet Lab - From Scratch

Lab didattico su architetture botnet/worm in ambiente isolato (Proxmox LXC).

**Goal:** build a minimal C2 + Python agent from the ground up to understand:
- how beaconing, tasking, and exfiltration work at the protocol level
- how defenders detect C2 traffic (SOC/SIEM perspective)
- how network segmentation and honeypots reduce blast radius

**Stack:** Python (agent + C2 server), Ubuntu/Debian/Arch LXC nodes, isolated VLAN inside Proxmox.

**Status:** in progress

Documentazione: [`analysis/notes.md`](analysis/notes.md)

---

## Materiale di studio - Botnet e Worm attuali

| Nome | Anno | Fonte | Note |
|------|------|-------|------|
| [Kimwolf](https://krebsonsecurity.com/2026/01/the-kimwolf-botnet-is-stalking-your-local-network/) | 2026 | Krebs on Security | Android-based, 2M+ dispositivi, DDoS, abusa proxy residenziali |
| [BadBox 2.0](https://krebsonsecurity.com/2026/01/who-operates-the-badbox-2-0-botnet/) | 2026 | Krebs on Security | Android ad fraud, infrastruttura DDoS condivisa |
| [CanisterWorm](https://krebsonsecurity.com/2026/03/canisterworm-springs-wiper-attack-targeting-iran/) | 2026 | Krebs / JFrog / StepSecurity | Worm npm self-propagating, C2 blockchain ICP, wiper anti-Iran |
| [SANDWORM_MODE](https://www.kodemsecurity.com/resources/sandworm-mode-a-new-shai-hulud-style-npm-worm-threatening-developer-ai-toolchain-security) | 2026 | Kodem Security | Worm npm stile Shai-Hulud, colpisce toolchain AI/dev |
| [Wormable XMRig](https://thehackernews.com/2026/02/wormable-xmrig-campaign-uses-byovd.html) | 2026 | The Hacker News | BYOVD exploit + logic bomb temporale, miner wormable |
| [Phorpiex / Twizt](https://securityboulevard.com/2026/01/botnet-threat-update-july-to-december-2025/) | 2025/2026 | Barracuda / Bitsight | Ibrido C2+P2P, propagazione via drive rimovibili, 1.7M IP tracciati |
| [GoBruteforcer](https://thehackernews.com/2026/01/gobruteforcer-botnet-targets-crypto.html) | 2026 | The Hacker News / CPR | Botnet Go, brute force SSH/Telnet su database crypto |
| [Aisuru + JackSkid](https://krebsonsecurity.com/2026/03/feds-disrupt-iot-botnets-behind-huge-ddos-attacks/) | 2026 | Krebs on Security | IoT DDoS botnet, smantellati da FBI/CA/DE |
| [Shai-Hulud](https://www.sysdig.com/blog) | 2025 | Kaspersky / Datadog | Worm multi-piattaforma, v2.0 con nuovi moduli C2 |
| [ZynorRAT](https://www.sysdig.com/blog) | 2025 | Sysdig | RAT cloud-native, container escape, persistenza cron |
| [SORVEPOTEL](https://www.blackpointcyber.com) | 2025 | Blackpoint Cyber | Worm Windows, lateral movement via SMB |

### Feed per tenersi aggiornati

- [The Hacker News - botnet](https://thehackernews.com/search/label/botnet)
- [Krebs on Security](https://krebsonsecurity.com/)
- [Barracuda - Botnet Threat Update H2 2025](https://blog.barracuda.com/2026/04/13/top-threat-trends-of-the-2025-botnet-landscape)
- [OTX AlienVault](https://otx.alienvault.com/)
