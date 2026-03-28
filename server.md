# Home Lab Server - Context & Instructions

## Connection

All commands on this server must be run via:

```
ssh root@192.capy.1.capy "<command>"
```

Never suggest the user run commands manually unless absolutely necessary. Always execute directly via SSH using the Bash tool.

## Server Profile

| Property        | Value                          |
|-----------------|-------------------------------|
| Host            | `192.capy.1.capy`               |
| User            | `root`                        |
| Hostname        | `[capybara-priv]`             |
| OS              | Proxmox VE (Debian-based)     |
| Kernel          | `[capybara-priv]`                 |
| RAM             | 16 GB                         |
| Disk (root)     | 94 GB (`/dev/mapper/pve-root`)|
| Swap            | 8 GB                          |
| VPN             | WireGuard (via PiVPN)         |
| VPN IP range    | `[capybara-priv]`                |
| Firewall        | `pve-firewall` + `fail2ban`   |

## Key Services

- **Proxmox VE** - hypervisor/VM management (`pvestatd`, `pmxcfs`)
- **fail2ban** - brute-force protection on SSH
- **pve-firewall** - network firewall
- **WireGuard** - VPN tunnel (`wg0`)

## How to Help

When the user asks anything about this server (health, logs, services, configs, VMs, networking, security, etc.):

1. Connect via `ssh root@192.capy.1.capy "<command>"` using the Bash tool
2. Run the relevant command(s) directly - do not ask the user to run them
3. Interpret the output and present a clean, concise summary
4. Flag anything anomalous (high disk, failed services, suspicious logins, etc.)

## Common Commands Reference

```bash
# Health check
uptime && free -h && df -h

# Failed SSH logins (last 24h)
journalctl _SYSTEMD_UNIT=ssh.service --since '24h ago' | grep -i 'failed\|invalid'

# Failed systemd services
systemctl list-units --type=service --state=failed

# Active VMs / containers
qm list && pct list

# Logs (last 50 lines)
journalctl -n 50 --no-pager

# WireGuard status
wg show

# fail2ban status
fail2ban-client status sshd

# Disk usage by directory
du -sh /* 2>/dev/null | sort -rh | head -15

# Listening ports
ss -tlnp

# Top CPU/RAM processes
ps aux --sort=-%cpu | head -10
ps aux --sort=-%mem | head -10
```

## Notes

- Always prefer `journalctl` over reading raw log files
- Proxmox web UI runs on `https://192.capy.1.capy:8006`
- User's WireGuard IP: `[capybara-priv]`
- Root login via SSH is enabled (direct key auth)
