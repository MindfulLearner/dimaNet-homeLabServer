> **Disclaimer - Educational Lab Only**
> This lab exists exclusively inside an isolated Proxmox LXC network with no outbound internet access.
> All agents, C2 traffic, and payloads are confined to VMs/containers I own and control.
> The purpose is to understand botnet mechanics for defensive/SOC purposes - not to deploy malware.
> **Do not replicate outside a controlled, isolated environment.**

---

# Botnet Lab - from scratch

**Goal:** build a minimal C2 + Python agent from the ground up to understand:
- how beaconing, tasking, and exfiltration work at the protocol level
- how defenders detect C2 traffic (SOC/SIEM perspective)
- how network segmentation and honeypots reduce blast radius

**Stack:** Python (agent + C2 server), Ubuntu/Debian/Arch LXC nodes, isolated VLAN inside Proxmox.

**Status:** in progress

---

![image](https://github.com/user-attachments/assets/c8e27c67-e5fe-42b3-a89f-c35119750224)
