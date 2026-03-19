#!/bin/bash
# ==============================================
# Proxmox Daily Health & Security Check Script
# ==============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

REPORT_DATE=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Proxmox Health & Security Report${NC}"
echo -e "${BLUE}  Host: $HOSTNAME${NC}"
echo -e "${BLUE}  Date: $REPORT_DATE${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# ── SYSTEM INFO ──────────────────────────────
echo -e "${YELLOW}>>> SYSTEM INFO${NC}"
echo "Uptime     : $(uptime -p)"
echo "Load avg   : $(cut -d' ' -f1-3 /proc/loadavg)"
echo "Proxmox ver: $(pveversion 2>/dev/null | head -1 || echo 'N/A')"
echo ""

# ── CPU & MEMORY ─────────────────────────────
echo -e "${YELLOW}>>> CPU & MEMORY${NC}"
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
echo "CPU usage  : ${CPU_USAGE}%"
free -h | awk '/Mem/{printf "RAM        : %s used / %s total\n", $3, $2}'
free -h | awk '/Swap/{printf "Swap       : %s used / %s total\n", $3, $2}'
echo ""

# ── DISK USAGE ───────────────────────────────
echo -e "${YELLOW}>>> DISK USAGE${NC}"
df -h | grep -vE "tmpfs|udev|overlay|shm" | awk 'NR==1{print} NR>1{
    usage=$5+0
    if (usage >= 90) flag=" !! CRITICAL"
    else if (usage >= 75) flag=" ! WARNING"
    else flag=""
    print $0 flag
}'
echo ""

# ── ZFS POOLS ────────────────────────────────
if command -v zpool &>/dev/null; then
    echo -e "${YELLOW}>>> ZFS POOLS${NC}"
    zpool list -o name,size,alloc,free,health 2>/dev/null
    echo ""
    ZFS_ERRORS=$(zpool status 2>/dev/null | grep -E "DEGRADED|FAULTED|OFFLINE|REMOVED|UNAVAIL")
    if [ -n "$ZFS_ERRORS" ]; then
        echo -e "${RED}!! ZFS ISSUES DETECTED:${NC}"
        echo "$ZFS_ERRORS"
    else
        echo -e "${GREEN}ZFS: All pools ONLINE${NC}"
    fi
    echo ""
fi

# ── LVM VOLUMES ──────────────────────────────
if command -v pvs &>/dev/null; then
    echo -e "${YELLOW}>>> LVM${NC}"
    vgs --noheadings -o vg_name,vg_size,vg_free 2>/dev/null | \
        awk '{printf "VG %-20s size: %-10s free: %s\n", $1, $2, $3}'
    echo ""
fi

# ── SMART DISK HEALTH ────────────────────────
if command -v smartctl &>/dev/null; then
    echo -e "${YELLOW}>>> DISK S.M.A.R.T HEALTH${NC}"
    for disk in /dev/sd[a-z] /dev/nvme[0-9]; do
        [ -e "$disk" ] || continue
        result=$(smartctl -H "$disk" 2>/dev/null | grep -E "result:|test result")
        if echo "$result" | grep -qi "PASSED\|OK"; then
            echo -e "  $disk : ${GREEN}PASSED${NC}"
        elif [ -n "$result" ]; then
            echo -e "  $disk : ${RED}$result${NC}"
        else
            echo "  $disk : SMART not available"
        fi
    done
    echo ""
fi

# ── SERVICES ─────────────────────────────────
echo -e "${YELLOW}>>> PROXMOX SERVICES${NC}"
for svc in pve-cluster pvedaemon pvestatd pveproxy pve-firewall; do
    status=$(systemctl is-active "$svc" 2>/dev/null)
    if [ "$status" = "active" ]; then
        echo -e "  $svc : ${GREEN}active${NC}"
    else
        echo -e "  $svc : ${RED}$status${NC}"
    fi
done
echo ""

# ── FAILED SYSTEMD UNITS ─────────────────────
echo -e "${YELLOW}>>> FAILED SERVICES${NC}"
FAILED=$(systemctl --failed --no-legend 2>/dev/null)
if [ -z "$FAILED" ]; then
    echo -e "${GREEN}No failed services${NC}"
else
    echo -e "${RED}$FAILED${NC}"
fi
echo ""

# ── SECURITY: SSH FAILED LOGINS ──────────────
echo -e "${YELLOW}>>> SSH FAILED LOGINS (last 24h)${NC}"
FAILED_LOGINS=$(journalctl _SYSTEMD_UNIT=ssh.service --since "24 hours ago" 2>/dev/null \
    | grep "Failed password" \
    | awk '{print $11}' \
    | sort | uniq -c | sort -rn | head -10)
if [ -z "$FAILED_LOGINS" ]; then
    echo -e "${GREEN}No failed logins${NC}"
else
    echo -e "${RED}Top offending IPs:${NC}"
    echo "$FAILED_LOGINS"
fi
echo ""

# ── SECURITY: CURRENT LOGINS ─────────────────
echo -e "${YELLOW}>>> CURRENTLY LOGGED IN${NC}"
who
echo ""

# ── SECURITY: RECENT LOGINS ──────────────────
echo -e "${YELLOW}>>> RECENT LOGINS (last 10)${NC}"
last | head -10
echo ""

# ── OPEN PORTS ───────────────────────────────
echo -e "${YELLOW}>>> LISTENING PORTS${NC}"
ss -tlnp | grep LISTEN | awk '{printf "  %-30s %s\n", $4, $6}'
echo ""

# ── UPDATES ──────────────────────────────────
echo -e "${YELLOW}>>> AVAILABLE UPDATES${NC}"
apt-get -qq update 2>/dev/null
UPDATES=$(apt list --upgradable 2>/dev/null | grep -v "Listing...")
COUNT=$(echo "$UPDATES" | grep -c . || true)
if [ "$COUNT" -eq 0 ]; then
    echo -e "${GREEN}System is up to date${NC}"
else
    echo -e "${YELLOW}$COUNT package(s) can be upgraded:${NC}"
    echo "$UPDATES" | head -20
fi
echo ""

# ── CLUSTER STATUS ───────────────────────────
echo -e "${YELLOW}>>> CLUSTER STATUS${NC}"
pvecm status 2>/dev/null || echo "Standalone node (no cluster)"
echo ""

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Check complete: $(date '+%H:%M:%S')${NC}"
echo -e "${BLUE}============================================${NC}"
