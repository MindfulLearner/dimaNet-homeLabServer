#!/bin/bash
# ==============================================
# Proxmox Health & Intrusion Check Script
# ==============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

REPORT_DATE=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)
HOURS=${1:-24} # default: last 24h, pass arg to override e.g. bash script.sh 48

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Health & Intrusion Report${NC}"
echo -e "${BLUE}  Host: $HOSTNAME${NC}"
echo -e "${BLUE}  Date: $REPORT_DATE${NC}"
echo -e "${BLUE}  Window: last ${HOURS}h${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# ── SYSTEM HEALTH ─────────────────────────────
echo -e "${YELLOW}>>> SYSTEM HEALTH${NC}"
echo "Uptime     : $(uptime -p)"
echo "Load avg   : $(cut -d' ' -f1-3 /proc/loadavg)"
free -h | awk '/Mem/{printf  "RAM        : %s used / %s total\n", $3, $2}'
free -h | awk '/Swap/{printf "Swap       : %s used / %s total\n", $3, $2}'
echo ""

# ── DISK USAGE ────────────────────────────────
echo -e "${YELLOW}>>> DISK USAGE${NC}"
df -h | grep -vE "tmpfs|udev|overlay|shm" | awk 'NR==1{print} NR>1{
    usage=$5+0
    if (usage >= 90) flag=" !! CRITICAL"
    else if (usage >= 75) flag=" ! WARNING"
    else flag=""
    print $0 flag
}'
echo ""

# ── ZFS ───────────────────────────────────────
if command -v zpool &>/dev/null; then
    echo -e "${YELLOW}>>> ZFS POOLS${NC}"
    ZFS_ERRORS=$(zpool status 2>/dev/null | grep -E "DEGRADED|FAULTED|OFFLINE|REMOVED|UNAVAIL")
    if [ -n "$ZFS_ERRORS" ]; then
        echo -e "${RED}!! ZFS ISSUES:${NC}"
        echo "$ZFS_ERRORS"
    else
        echo -e "${GREEN}All pools ONLINE${NC}"
    fi
    echo ""
fi

# ── FAILED SERVICES ───────────────────────────
echo -e "${YELLOW}>>> FAILED SERVICES${NC}"
FAILED=$(systemctl --failed --no-legend 2>/dev/null)
if [ -z "$FAILED" ]; then
    echo -e "${GREEN}No failed services${NC}"
else
    echo -e "${RED}$FAILED${NC}"
fi
echo ""

# ==============================================
# INTRUSION SECTION
# ==============================================

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Intrusion & Access Report${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# ── SUCCESSFUL LOGINS ─────────────────────────
echo -e "${YELLOW}>>> SUCCESSFUL SSH LOGINS (last ${HOURS}h)${NC}"
ACCEPTED=$(journalctl _SYSTEMD_UNIT=ssh.service --since "${HOURS} hours ago" 2>/dev/null \
    | grep "Accepted")
if [ -z "$ACCEPTED" ]; then
    echo -e "${GREEN}No logins in this window${NC}"
else
    # Flag any non-RFC1918 (external) IPs in red
    while IFS= read -r line; do
        IP=$(echo "$line" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}')
        if echo "$IP" | grep -qE '^(10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.)'; then
            echo -e "  ${GREEN}[LAN/VPN]${NC} $line"
        else
            echo -e "  ${RED}[EXTERNAL !!]${NC} $line"
        fi
    done <<< "$ACCEPTED"
fi
echo ""

# ── FAILED LOGINS ─────────────────────────────
echo -e "${YELLOW}>>> FAILED SSH LOGINS (last ${HOURS}h)${NC}"
FAILED_LOGINS=$(journalctl _SYSTEMD_UNIT=ssh.service --since "${HOURS} hours ago" 2>/dev/null \
    | grep "Failed password" \
    | awk '{print $11}' \
    | sort | uniq -c | sort -rn | head -15)
if [ -z "$FAILED_LOGINS" ]; then
    echo -e "${GREEN}No failed logins${NC}"
else
    echo -e "${RED}Top offending IPs:${NC}"
    echo "$FAILED_LOGINS"
fi
echo ""

# ── USERNAMES ATTEMPTED ───────────────────────
echo -e "${YELLOW}>>> USERNAMES ATTEMPTED (last ${HOURS}h)${NC}"
USERNAMES=$(journalctl _SYSTEMD_UNIT=ssh.service --since "${HOURS} hours ago" 2>/dev/null \
    | grep "Failed password" \
    | awk '{print $9}' \
    | sort | uniq -c | sort -rn | head -15)
if [ -z "$USERNAMES" ]; then
    echo -e "${GREEN}None${NC}"
else
    echo "$USERNAMES"
fi
echo ""

# ── INVALID USER ATTEMPTS ─────────────────────
echo -e "${YELLOW}>>> INVALID USER ATTEMPTS (last ${HOURS}h)${NC}"
INVALID=$(journalctl _SYSTEMD_UNIT=ssh.service --since "${HOURS} hours ago" 2>/dev/null \
    | grep "Invalid user" \
    | awk '{print $10, "from", $12}' \
    | sort | uniq -c | sort -rn | head -10)
if [ -z "$INVALID" ]; then
    echo -e "${GREEN}None${NC}"
else
    echo "$INVALID"
fi
echo ""

# ── CURRENTLY LOGGED IN ───────────────────────
echo -e "${YELLOW}>>> CURRENTLY LOGGED IN${NC}"
who
echo ""

# ── RECENT LOGINS ─────────────────────────────
echo -e "${YELLOW}>>> RECENT LOGINS (last 10)${NC}"
last | head -10
echo ""

# ── FAIL2BAN STATUS ───────────────────────────
echo -e "${YELLOW}>>> FAIL2BAN${NC}"
if command -v fail2ban-client &>/dev/null && systemctl is-active --quiet fail2ban; then
    BANNED=$(fail2ban-client status sshd 2>/dev/null | grep "Banned IP")
    TOTAL=$(fail2ban-client status sshd 2>/dev/null | grep "Total banned")
    echo -e "${GREEN}fail2ban active${NC}"
    echo "  $TOTAL"
    echo "  $BANNED"
else
    echo -e "${RED}!! fail2ban is NOT running${NC}"
fi
echo ""

# ── SSH CONFIG SANITY ─────────────────────────
echo -e "${YELLOW}>>> SSH CONFIG${NC}"
PA=$(grep -E "^PasswordAuthentication" /etc/ssh/sshd_config | awk '{print $2}')
PRL=$(grep -E "^PermitRootLogin" /etc/ssh/sshd_config | awk '{print $2}')

[ "$PA" = "no" ] \
    && echo -e "  PasswordAuthentication : ${GREEN}no (good)${NC}" \
    || echo -e "  PasswordAuthentication : ${RED}${PA:-yes (default!)} — RISK${NC}"

[ "$PRL" = "prohibit-password" ] || [ "$PRL" = "no" ] \
    && echo -e "  PermitRootLogin        : ${GREEN}${PRL} (good)${NC}" \
    || echo -e "  PermitRootLogin        : ${RED}${PRL:-yes (default!)} — RISK${NC}"
echo ""

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Check complete: $(date '+%H:%M:%S')${NC}"
echo -e "${BLUE}============================================${NC}"
