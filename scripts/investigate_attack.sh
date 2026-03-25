#!/bin/bash
# ==============================================
# SSH Attack Investigation Script
# ==============================================
# Usage:
#   bash investigate_attack.sh              # last 7 days
#   bash investigate_attack.sh 2.57.122.238 # specific IP
#   bash investigate_attack.sh "" 30        # last 30 days
# ==============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

TARGET_IP=${1:-""}
DAYS=${2:-7}

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  SSH Attack Investigation${NC}"
echo -e "${BLUE}  Window: last ${DAYS} days${NC}"
[ -n "$TARGET_IP" ] && echo -e "${BLUE}  Target IP: $TARGET_IP${NC}"
echo -e "${BLUE}  Date: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

SINCE="${DAYS} days ago"

# ── TOP ATTACKING IPs ─────────────────────────
echo -e "${YELLOW}>>> TOP ATTACKING IPs (last ${DAYS}d)${NC}"
journalctl _SYSTEMD_UNIT=ssh.service --since "$SINCE" 2>/dev/null \
    | grep "Failed password\|Invalid user" \
    | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' \
    | sort | uniq -c | sort -rn | head -15 \
    | while read count ip; do
        echo -e "  ${RED}$count attempts${NC}  $ip"
    done
echo ""

# ── TOP USERNAMES ATTEMPTED ───────────────────
echo -e "${YELLOW}>>> TOP USERNAMES ATTEMPTED (last ${DAYS}d)${NC}"
journalctl _SYSTEMD_UNIT=ssh.service --since "$SINCE" 2>/dev/null \
    | grep "Failed password\|Invalid user" \
    | grep -oE "(Invalid user |Failed password for (invalid user )?)\K\w+" \
    | sort | uniq -c | sort -rn | head -20
echo ""

# ── CRYPTO-RELATED ATTEMPTS ───────────────────
echo -e "${YELLOW}>>> CRYPTO / KNOWN BOT USERNAMES${NC}"
CRYPTO=$(journalctl _SYSTEMD_UNIT=ssh.service --since "$SINCE" 2>/dev/null \
    | grep -iE "sol|bitcoin|btc|eth|admin|ubuntu|deploy|git|test|user|pi|oracle|postgres|mysql|ftpuser|guest|support")
if [ -z "$CRYPTO" ]; then
    echo -e "${GREEN}None found${NC}"
else
    echo "$CRYPTO" | grep -oE "(Invalid user |for (invalid user )?)\K\S+" \
        | sort | uniq -c | sort -rn | head -20
fi
echo ""

# ── SPECIFIC IP INVESTIGATION ─────────────────
if [ -n "$TARGET_IP" ]; then
    echo -e "${YELLOW}>>> FULL ACTIVITY FROM $TARGET_IP${NC}"

    TOTAL=$(journalctl _SYSTEMD_UNIT=ssh.service --since "$SINCE" 2>/dev/null \
        | grep "$TARGET_IP" | wc -l)
    echo "Total log entries : $TOTAL"
    echo ""

    echo "Usernames tried:"
    journalctl _SYSTEMD_UNIT=ssh.service --since "$SINCE" 2>/dev/null \
        | grep "$TARGET_IP" \
        | grep -oE "(Invalid user |Failed password for (invalid user )?)\K\w+" \
        | sort | uniq -c | sort -rn
    echo ""

    echo "Timeline (first and last attempt):"
    journalctl _SYSTEMD_UNIT=ssh.service --since "$SINCE" 2>/dev/null \
        | grep "$TARGET_IP" | head -1
    journalctl _SYSTEMD_UNIT=ssh.service --since "$SINCE" 2>/dev/null \
        | grep "$TARGET_IP" | tail -1
    echo ""

    echo "Did they succeed?"
    SUCCESS=$(journalctl _SYSTEMD_UNIT=ssh.service --since "$SINCE" 2>/dev/null \
        | grep "Accepted" | grep "$TARGET_IP")
    if [ -z "$SUCCESS" ]; then
        echo -e "${GREEN}No — all attempts failed${NC}"
    else
        echo -e "${RED}!! YES — successful login detected:${NC}"
        echo "$SUCCESS"
    fi
    echo ""
else
    # Auto-investigate top attacker
    TOP_IP=$(journalctl _SYSTEMD_UNIT=ssh.service --since "$SINCE" 2>/dev/null \
        | grep "Failed password\|Invalid user" \
        | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' \
        | sort | uniq -c | sort -rn \
        | head -1 | awk '{print $2}')

    if [ -n "$TOP_IP" ]; then
        echo -e "${YELLOW}>>> AUTO-INVESTIGATING TOP ATTACKER: $TOP_IP${NC}"

        TOTAL=$(journalctl _SYSTEMD_UNIT=ssh.service --since "$SINCE" 2>/dev/null \
            | grep "$TOP_IP" | wc -l)
        echo "Total attempts : $TOTAL"
        echo ""

        echo "Usernames tried:"
        journalctl _SYSTEMD_UNIT=ssh.service --since "$SINCE" 2>/dev/null \
            | grep "$TOP_IP" \
            | grep -oE "(Invalid user |Failed password for (invalid user )?)\K\w+" \
            | sort | uniq -c | sort -rn
        echo ""

        echo "Did they succeed?"
        SUCCESS=$(journalctl _SYSTEMD_UNIT=ssh.service --since "$SINCE" 2>/dev/null \
            | grep "Accepted" | grep "$TOP_IP")
        if [ -z "$SUCCESS" ]; then
            echo -e "${GREEN}No — all attempts failed${NC}"
        else
            echo -e "${RED}!! YES — successful login detected:${NC}"
            echo "$SUCCESS"
        fi
        echo ""
    fi
fi

# ── ATTACK TIMELINE ───────────────────────────
echo -e "${YELLOW}>>> ATTACK TIMELINE (attempts per hour)${NC}"
journalctl _SYSTEMD_UNIT=ssh.service --since "$SINCE" 2>/dev/null \
    | grep "Failed password\|Invalid user" \
    | awk '{print $1, $2, $3}' \
    | cut -d: -f1 \
    | sort | uniq -c \
    | tail -24
echo ""

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Investigation complete: $(date '+%H:%M:%S')${NC}"
echo -e "${BLUE}============================================${NC}"
