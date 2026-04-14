#!/bin/bash
# ==============================================
# daily-check.sh
# Lanciare dal Mac - controlla Proxmox + narutoPi
# Usage: bash scripts/daily-check.sh
# ==============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[0;36m'
NC='\033[0m'

LOG_DIR="$(dirname "$0")/../logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/daily-check-$(date '+%Y-%m-%d').log"

HOURS=${1:-24}

log() { echo -e "$1" | tee -a "$LOG_FILE"; }

header() {
    log ""
    log "${BLUE}============================================${NC}"
    log "${BLUE}  $1${NC}"
    log "${BLUE}============================================${NC}"
}

section() { log "${YELLOW}>>> $1${NC}"; }

ok()   { log "  ${GREEN}[OK]${NC}  $1"; }
warn() { log "  ${YELLOW}[WARN]${NC} $1"; }
fail() { log "  ${RED}[FAIL]${NC} $1"; }

# Svuota il log del giorno se esiste gia'
> "$LOG_FILE"

log "${CYAN}Daily homelab check - $(date '+%Y-%m-%d %H:%M:%S')${NC}"
log "Log salvato in: $LOG_FILE"

# ==============================================
# PROXMOX (192.168.1.100)
# ==============================================
header "PROXMOX - 192.168.1.100"

PROXMOX_OUT=$(ssh -o ConnectTimeout=10 proxmox bash <<'ENDSSH'
echo "=UPTIME=$(uptime -p)"
echo "=LOAD=$(cut -d' ' -f1-3 /proc/loadavg)"
echo "=RAM=$(free -m | awk '/Mem/{printf "%s/%s MB", $3, $2}')"
echo "=SWAP=$(free -m | awk '/Swap/{printf "%s/%s MB", $3, $2}')"
echo "=DISK=$(df -h / | awk 'NR==2{printf "%s used of %s (%s)", $3, $2, $5}')"
echo "=DISK_PCT=$(df / | awk 'NR==2{print $5}' | tr -d '%')"
echo "=VMs=$(qm list 2>/dev/null | tail -n +2 | awk '{printf "%s:%s ", $2, $3}')"
echo "=CTs=$(pct list 2>/dev/null | tail -n +2 | awk '{printf "%s:%s ", $3, $2}')"
# servizi
for svc in pve-cluster pvedaemon pveproxy pve-firewall fail2ban; do
    st=$(systemctl is-active "$svc" 2>/dev/null)
    echo "=SVC_${svc}=${st}"
done
# failed units
echo "=FAILED_UNITS=$(systemctl --failed --no-legend 2>/dev/null | wc -l | tr -d ' ')"
# SSH failed logins
echo "=SSH_FAILS=$(journalctl _SYSTEMD_UNIT=ssh.service --since '24 hours ago' 2>/dev/null | grep -c 'Failed password' || echo 0)"
# fail2ban
if systemctl is-active --quiet fail2ban; then
    echo "=F2B_BANNED=$(fail2ban-client status sshd 2>/dev/null | grep 'Currently banned' | awk '{print $NF}')"
else
    echo "=F2B_BANNED=OFFLINE"
fi
ENDSSH
2>/dev/null)

if [ -z "$PROXMOX_OUT" ]; then
    fail "Impossibile raggiungere Proxmox via SSH"
else
    parse() { echo "$PROXMOX_OUT" | grep "^=${1}=" | cut -d'=' -f3-; }

    section "Sistema"
    log "  Uptime   : $(parse UPTIME)"
    log "  Load     : $(parse LOAD)"
    log "  RAM      : $(parse RAM)"
    log "  Swap     : $(parse SWAP)"

    DISK_INFO=$(parse DISK)
    DISK_PCT=$(parse DISK_PCT)
    if [ "$DISK_PCT" -ge 90 ]; then
        fail "Disco: $DISK_INFO !! CRITICO"
    elif [ "$DISK_PCT" -ge 75 ]; then
        warn "Disco: $DISK_INFO - WARNING"
    else
        ok "Disco: $DISK_INFO"
    fi
    log ""

    section "VMs e CTs"
    VMS=$(parse VMs)
    CTS=$(parse CTs)
    [ -n "$VMS" ] && log "  VMs: $VMS" || log "  VMs: nessuna"
    [ -n "$CTS" ] && log "  CTs: $CTS" || log "  CTs: nessuna"
    log ""

    section "Servizi Proxmox"
    for svc in pve-cluster pvedaemon pveproxy pve-firewall fail2ban; do
        st=$(echo "$PROXMOX_OUT" | grep "^=SVC_${svc}=" | cut -d'=' -f3-)
        if [ "$st" = "active" ]; then
            ok "$svc"
        else
            fail "$svc -> $st"
        fi
    done
    log ""

    section "Sicurezza"
    FAILED_UNITS=$(parse FAILED_UNITS)
    if [ "$FAILED_UNITS" -eq 0 ]; then
        ok "Nessun servizio systemd in errore"
    else
        fail "$FAILED_UNITS servizio/i systemd in errore"
    fi

    SSH_FAILS=$(parse SSH_FAILS)
    if [ "$SSH_FAILS" -eq 0 ]; then
        ok "Nessun login SSH fallito (ultime ${HOURS}h)"
    else
        warn "$SSH_FAILS tentativi SSH falliti (ultime ${HOURS}h)"
    fi

    F2B=$(parse F2B_BANNED)
    if [ "$F2B" = "OFFLINE" ]; then
        fail "fail2ban non attivo"
    else
        ok "fail2ban attivo - IP bannati: ${F2B:-0}"
    fi
fi

# ==============================================
# NARUTOPI (192.168.1.31)
# ==============================================
header "narutoPi - 192.168.1.31"

NARUTO_OUT=$(ssh -o ConnectTimeout=10 naruto@192.168.1.31 bash <<'ENDSSH'
echo "=UPTIME=$(uptime -p)"
echo "=LOAD=$(cut -d' ' -f1-3 /proc/loadavg)"
echo "=RAM=$(free -m | awk '/Mem/{printf "%s/%s MB", $3, $2}')"
echo "=DISK=$(df -h / | awk 'NR==2{printf "%s used of %s (%s)", $3, $2, $5}')"
echo "=DISK_PCT=$(df / | awk 'NR==2{print $5}' | tr -d '%')"
# Pi-hole
FTL_ACTIVE=$(systemctl is-active pihole-FTL 2>/dev/null)
echo "=PIHOLE_FTL=${FTL_ACTIVE}"
PIHOLE_STATUS=$(pihole status 2>/dev/null | grep -E "blocking is (enabled|disabled)" | grep -oE "enabled|disabled")
echo "=PIHOLE_BLOCK=${PIHOLE_STATUS:-unknown}"
# servizi
for svc in pihole-FTL fail2ban ssh; do
    st=$(systemctl is-active "$svc" 2>/dev/null)
    echo "=SVC_${svc}=${st}"
done
# SSH failed logins
echo "=SSH_FAILS=$(journalctl _SYSTEMD_UNIT=ssh.service --since '24 hours ago' 2>/dev/null | grep -c 'Failed password' || echo 0)"
# fail2ban
if systemctl is-active --quiet fail2ban; then
    echo "=F2B_BANNED=$(sudo fail2ban-client status sshd 2>/dev/null | grep 'Currently banned' | awk '{print $NF}')"
else
    echo "=F2B_BANNED=OFFLINE"
fi
# Wazuh agent
WAZUH_ST=$(systemctl is-active wazuh-agent 2>/dev/null)
echo "=WAZUH=${WAZUH_ST}"
ENDSSH
2>/dev/null)

if [ -z "$NARUTO_OUT" ]; then
    fail "Impossibile raggiungere narutoPi via SSH"
else
    parse_n() { echo "$NARUTO_OUT" | grep "^=${1}=" | cut -d'=' -f3-; }

    section "Sistema"
    log "  Uptime   : $(parse_n UPTIME)"
    log "  Load     : $(parse_n LOAD)"
    log "  RAM      : $(parse_n RAM)"

    DISK_INFO=$(parse_n DISK)
    DISK_PCT=$(parse_n DISK_PCT)
    if [ "$DISK_PCT" -ge 90 ]; then
        fail "Disco: $DISK_INFO !! CRITICO"
    elif [ "$DISK_PCT" -ge 75 ]; then
        warn "Disco: $DISK_INFO - WARNING"
    else
        ok "Disco: $DISK_INFO"
    fi
    log ""

    section "Pi-hole"
    FTL=$(parse_n PIHOLE_FTL)
    BLOCK=$(parse_n PIHOLE_BLOCK)
    if [ "$FTL" = "active" ]; then
        ok "FTL in ascolto su porta 53"
    else
        fail "FTL non attivo ($FTL)"
    fi
    if [ "$BLOCK" = "enabled" ]; then
        ok "Blocking abilitato"
    else
        warn "Blocking: $BLOCK"
    fi
    log ""

    section "Servizi"
    for svc in pihole-FTL fail2ban ssh; do
        st=$(echo "$NARUTO_OUT" | grep "^=SVC_${svc}=" | cut -d'=' -f3-)
        if [ "$st" = "active" ]; then
            ok "$svc"
        else
            fail "$svc -> $st"
        fi
    done
    log ""

    section "Wazuh agent"
    WAZUH=$(parse_n WAZUH)
    if [ "$WAZUH" = "active" ]; then
        ok "wazuh-agent attivo - eventi inviati a cs42"
    elif [ "$WAZUH" = "inactive" ] || [ "$WAZUH" = "stopped" ]; then
        warn "wazuh-agent fermo - gli eventi generati ora NON vengono registrati su Wazuh"
    else
        warn "wazuh-agent: $WAZUH (non installato o stato sconosciuto)"
    fi
    log ""

    section "Sicurezza SSH"
    SSH_FAILS=$(parse_n SSH_FAILS)
    if [ "$SSH_FAILS" -eq 0 ]; then
        ok "Nessun login SSH fallito (ultime ${HOURS}h)"
    else
        warn "$SSH_FAILS tentativi SSH falliti (ultime ${HOURS}h)"
    fi

    F2B=$(parse_n F2B_BANNED)
    if [ "$F2B" = "OFFLINE" ]; then
        fail "fail2ban non attivo"
    else
        ok "fail2ban attivo - IP bannati: ${F2B:-0}"
    fi
fi

# ==============================================
# CS42 - SOC Ubuntu (192.168.1.5)
# ==============================================
header "cs42 SOC - 192.168.1.5"

CS42_OUT=$(ssh -o ConnectTimeout=10 cs42 bash <<'ENDSSH'
echo "=UPTIME=$(uptime -p)"
echo "=LOAD=$(cut -d' ' -f1-3 /proc/loadavg)"
echo "=RAM=$(free -m | awk '/Mem/{printf "%s/%s MB", $3, $2}')"
echo "=DISK=$(df -h / | awk 'NR==2{printf "%s used of %s (%s)", $3, $2, $5}')"
echo "=DISK_PCT=$(df / | awk 'NR==2{print $5}' | tr -d '%')"
# servizi Wazuh
for svc in wazuh-manager wazuh-indexer wazuh-dashboard; do
    st=$(systemctl is-active "$svc" 2>/dev/null)
    echo "=SVC_${svc}=${st}"
done
# servizi base
for svc in fail2ban ssh; do
    st=$(systemctl is-active "$svc" 2>/dev/null)
    echo "=SVC_${svc}=${st}"
done
# failed units
echo "=FAILED_UNITS=$(systemctl --failed --no-legend 2>/dev/null | wc -l | tr -d ' ')"
# SSH failed logins
echo "=SSH_FAILS=$(journalctl _SYSTEMD_UNIT=ssh.service --since '24 hours ago' 2>/dev/null | grep -c 'Failed password' || echo 0)"
# fail2ban
if systemctl is-active --quiet fail2ban; then
    echo "=F2B_BANNED=$(sudo fail2ban-client status sshd 2>/dev/null | grep 'Currently banned' | awk '{print $NF}')"
else
    echo "=F2B_BANNED=OFFLINE"
fi
# agenti Wazuh connessi
AGENTS=$(sudo /var/ossec/bin/agent_control -l 2>/dev/null | grep -c "Active" || echo "N/A")
echo "=WAZUH_AGENTS=${AGENTS}"
ENDSSH
2>/dev/null)

if [ -z "$CS42_OUT" ]; then
    fail "Impossibile raggiungere cs42 via SSH"
else
    parse_c() { echo "$CS42_OUT" | grep "^=${1}=" | cut -d'=' -f3-; }

    section "Sistema"
    log "  Uptime   : $(parse_c UPTIME)"
    log "  Load     : $(parse_c LOAD)"
    log "  RAM      : $(parse_c RAM)"

    DISK_INFO=$(parse_c DISK)
    DISK_PCT=$(parse_c DISK_PCT)
    if [ "$DISK_PCT" -ge 90 ]; then
        fail "Disco: $DISK_INFO !! CRITICO"
    elif [ "$DISK_PCT" -ge 75 ]; then
        warn "Disco: $DISK_INFO - WARNING"
    else
        ok "Disco: $DISK_INFO"
    fi
    log ""

    section "Wazuh (SIEM)"
    for svc in wazuh-manager wazuh-indexer wazuh-dashboard; do
        st=$(echo "$CS42_OUT" | grep "^=SVC_${svc}=" | cut -d'=' -f3-)
        if [ "$st" = "active" ]; then
            ok "$svc"
        else
            fail "$svc -> $st"
        fi
    done
    AGENTS=$(parse_c WAZUH_AGENTS)
    log "  Agenti attivi: ${AGENTS}"
    log ""

    section "Servizi base"
    for svc in fail2ban ssh; do
        st=$(echo "$CS42_OUT" | grep "^=SVC_${svc}=" | cut -d'=' -f3-)
        if [ "$st" = "active" ]; then
            ok "$svc"
        else
            fail "$svc -> $st"
        fi
    done
    log ""

    section "Sicurezza"
    FAILED_UNITS=$(parse_c FAILED_UNITS)
    if [ "$FAILED_UNITS" -eq 0 ]; then
        ok "Nessun servizio systemd in errore"
    else
        fail "$FAILED_UNITS servizio/i systemd in errore"
    fi

    SSH_FAILS=$(parse_c SSH_FAILS)
    if [ "$SSH_FAILS" -eq 0 ]; then
        ok "Nessun login SSH fallito (ultime ${HOURS}h)"
    else
        warn "$SSH_FAILS tentativi SSH falliti (ultime ${HOURS}h)"
    fi

    F2B=$(parse_c F2B_BANNED)
    if [ "$F2B" = "OFFLINE" ]; then
        fail "fail2ban non attivo"
    else
        ok "fail2ban attivo - IP bannati: ${F2B:-0}"
    fi
fi

# ==============================================
# FINE
# ==============================================
log ""
log "${CYAN}============================================${NC}"
log "${CYAN}  Check completato: $(date '+%H:%M:%S')${NC}"
log "${CYAN}  Log: $LOG_FILE${NC}"
log "${CYAN}============================================${NC}"
