#!/bin/bash
# ==============================================
# gen-dashboard.sh
# Raccoglie dati SSH da proxmox, naruto, cs42
# e genera dashboard/dashboard.html
# Usage: bash scripts/gen-dashboard.sh
# ==============================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STATIC_DIR="$SCRIPT_DIR"
OUT_HTML="$STATIC_DIR/dashboard.html"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[1;34m'; NC='\033[0m'

echo -e "${BLUE}[dashboard]${NC} Raccolta dati in corso..."

# ──────────────────────────────────────────────
# SSH in parallelo
# ──────────────────────────────────────────────

TMP_PROXMOX=$(mktemp)
TMP_NARUTO=$(mktemp)
TMP_CS42=$(mktemp)

_get_proxmox() {
ssh -o ConnectTimeout=10 -o BatchMode=yes proxmox bash 2>/dev/null >"$TMP_PROXMOX" <<'ENDSSH'
echo "=UPTIME=$(uptime -p)"
echo "=LOAD=$(cut -d' ' -f1-3 /proc/loadavg)"
echo "=RAM_USED=$(free -m | awk '/Mem/{print $3}')"
echo "=RAM_TOTAL=$(free -m | awk '/Mem/{print $2}')"
echo "=DISK_PCT=$(df / | awk 'NR==2{print $5}' | tr -d '%')"
echo "=DISK_USED=$(df -h / | awk 'NR==2{print $3}')"
echo "=DISK_TOTAL=$(df -h / | awk 'NR==2{print $2}')"
for svc in pve-cluster pvedaemon pveproxy pve-firewall fail2ban; do
    st=$(systemctl is-active "$svc" 2>/dev/null)
    echo "=SVC_${svc}=${st}"
done
echo "=FAILED=$(systemctl --failed --no-legend 2>/dev/null | wc -l | tr -d ' ')"
echo "=SSH_FAILS=$(journalctl _SYSTEMD_UNIT=ssh.service --since '24 hours ago' 2>/dev/null | grep -c 'Failed password' || echo 0)"
if systemctl is-active --quiet fail2ban; then
    echo "=F2B=$(fail2ban-client status sshd 2>/dev/null | grep 'Currently banned' | awk '{print $NF}')"
else
    echo "=F2B=OFFLINE"
fi
VMS=$(qm list 2>/dev/null | tail -n +2 | awk '{print $2"|||"$3}' | paste -sd '~~~')
echo "=VMs=${VMS}"
CTS=$(pct list 2>/dev/null | tail -n +2 | awk '{print $4"|||"$2}' | paste -sd '~~~')
echo "=CTs=${CTS}"
APT_COUNT=$(apt-get -s upgrade 2>/dev/null | grep -c "^Inst" || echo 0)
echo "=APT_COUNT=${APT_COUNT}"
APT_LIST=$(apt list --upgradable 2>/dev/null | grep -v "Listing" | cut -d'/' -f1 | paste -sd '~~~' || echo "")
echo "=APT_LIST=${APT_LIST}"
ENDSSH
}

_get_naruto() {
ssh -o ConnectTimeout=10 -o BatchMode=yes naruto bash 2>/dev/null >"$TMP_NARUTO" <<'ENDSSH'
echo "=UPTIME=$(uptime -p)"
echo "=LOAD=$(cut -d' ' -f1-3 /proc/loadavg)"
echo "=RAM_USED=$(free -m | awk '/Mem/{print $3}')"
echo "=RAM_TOTAL=$(free -m | awk '/Mem/{print $2}')"
echo "=DISK_PCT=$(df / | awk 'NR==2{print $5}' | tr -d '%')"
echo "=DISK_USED=$(df -h / | awk 'NR==2{print $3}')"
echo "=DISK_TOTAL=$(df -h / | awk 'NR==2{print $2}')"
for svc in pihole-FTL fail2ban ssh wazuh-agent; do
    st=$(systemctl is-active "$svc" 2>/dev/null)
    echo "=SVC_${svc}=${st}"
done
PIHOLE_STATUS=$(pihole status 2>/dev/null | grep -E "blocking is (enabled|disabled)" | grep -oE "enabled|disabled")
echo "=PIHOLE_BLOCK=${PIHOLE_STATUS:-unknown}"
echo "=SSH_FAILS=$(journalctl _SYSTEMD_UNIT=ssh.service --since '24 hours ago' 2>/dev/null | grep -c 'Failed password' || echo 0)"
if systemctl is-active --quiet fail2ban; then
    echo "=F2B=$(sudo fail2ban-client status sshd 2>/dev/null | grep 'Currently banned' | awk '{print $NF}')"
else
    echo "=F2B=OFFLINE"
fi
APT_COUNT=$(apt-get -s upgrade 2>/dev/null | grep -c "^Inst" || echo 0)
echo "=APT_COUNT=${APT_COUNT}"
APT_LIST=$(apt list --upgradable 2>/dev/null | grep -v "Listing" | cut -d'/' -f1 | paste -sd '~~~' || echo "")
echo "=APT_LIST=${APT_LIST}"
ENDSSH
}

_get_cs42() {
ssh -o ConnectTimeout=10 -o BatchMode=yes cs42 bash 2>/dev/null >"$TMP_CS42" <<'ENDSSH'
echo "=UPTIME=$(uptime -p)"
echo "=LOAD=$(cut -d' ' -f1-3 /proc/loadavg)"
echo "=RAM_USED=$(free -m | awk '/Mem/{print $3}')"
echo "=RAM_TOTAL=$(free -m | awk '/Mem/{print $2}')"
echo "=DISK_PCT=$(df / | awk 'NR==2{print $5}' | tr -d '%')"
echo "=DISK_USED=$(df -h / | awk 'NR==2{print $3}')"
echo "=DISK_TOTAL=$(df -h / | awk 'NR==2{print $2}')"
for svc in wazuh-manager wazuh-indexer wazuh-dashboard fail2ban ssh; do
    st=$(systemctl is-active "$svc" 2>/dev/null)
    echo "=SVC_${svc}=${st}"
done
echo "=FAILED=$(systemctl --failed --no-legend 2>/dev/null | wc -l | tr -d ' ')"
echo "=SSH_FAILS=$(journalctl _SYSTEMD_UNIT=ssh.service --since '24 hours ago' 2>/dev/null | grep -c 'Failed password' || echo 0)"
if systemctl is-active --quiet fail2ban; then
    echo "=F2B=$(sudo fail2ban-client status sshd 2>/dev/null | grep 'Currently banned' | awk '{print $NF}')"
else
    echo "=F2B=OFFLINE"
fi
AGENTS=$(sudo /var/ossec/bin/agent_control -l 2>/dev/null | grep -c "Active" || echo "0")
echo "=WAZUH_AGENTS=${AGENTS}"
APT_COUNT=$(apt-get -s upgrade 2>/dev/null | grep -c "^Inst" || echo 0)
echo "=APT_COUNT=${APT_COUNT}"
APT_LIST=$(apt list --upgradable 2>/dev/null | grep -v "Listing" | cut -d'/' -f1 | paste -sd '~~~' || echo "")
echo "=APT_LIST=${APT_LIST}"
ENDSSH
}

# Lancia SSH in parallelo (</dev/null evita conflitti heredoc su stdin)
{ _get_proxmox; } </dev/null &
PID1=$!
{ _get_naruto; } </dev/null &
PID2=$!
{ _get_cs42; } </dev/null &
PID3=$!
wait $PID1 $PID2 $PID3

PROXMOX_RAW=$(cat "$TMP_PROXMOX")
NARUTO_RAW=$(cat "$TMP_NARUTO")
CS42_RAW=$(cat "$TMP_CS42")
rm -f "$TMP_PROXMOX" "$TMP_NARUTO" "$TMP_CS42"

echo -e "${GREEN}[dashboard]${NC} Dati raccolti. Generazione HTML..."

# ──────────────────────────────────────────────
# Parser: raw -> JSON
# ──────────────────────────────────────────────

parse_val() {
  # $1 = raw, $2 = key
  echo "$1" | grep "^=${2}=" | head -1 | cut -d'=' -f3-
}

raw_to_json() {
  local raw="$1"
  local role="$2"   # proxmox | naruto | cs42

  if [ -z "$raw" ]; then
    echo '{"reachable":false}'
    return
  fi

  local uptime   load  ram_used  ram_total  disk_pct  disk_used  disk_total
  local failed  ssh_fails  f2b  apt_count  apt_list
  uptime=$(parse_val "$raw" "UPTIME")
  load=$(parse_val "$raw" "LOAD")
  ram_used=$(parse_val "$raw" "RAM_USED")
  ram_total=$(parse_val "$raw" "RAM_TOTAL")
  disk_pct=$(parse_val "$raw" "DISK_PCT")
  disk_used=$(parse_val "$raw" "DISK_USED")
  disk_total=$(parse_val "$raw" "DISK_TOTAL")
  failed=$(parse_val "$raw" "FAILED")
  ssh_fails=$(parse_val "$raw" "SSH_FAILS")
  f2b=$(parse_val "$raw" "F2B")
  apt_count=$(parse_val "$raw" "APT_COUNT")
  apt_list_raw=$(parse_val "$raw" "APT_LIST")

  # Servizi -> oggetto JSON
  local svcs_json
  svcs_json="{"
  while IFS= read -r line; do
    if [[ "$line" =~ ^=SVC_(.+)=(.+)$ ]]; then
      sname="${BASH_REMATCH[1]}"
      sval="${BASH_REMATCH[2]}"
      svcs_json+="\"${sname}\":\"${sval}\","
    fi
  done <<< "$raw"
  svcs_json="${svcs_json%,}}"

  # APT list -> JSON array
  local apt_json="[]"
  if [ -n "$apt_list_raw" ]; then
    apt_json="["
    IFS='~~~' read -ra pkgs <<< "$apt_list_raw"
    for pkg in "${pkgs[@]}"; do
      pkg="${pkg// /}"
      [ -n "$pkg" ] && apt_json+="\"${pkg}\","
    done
    apt_json="${apt_json%,}]"
  fi

  # Campi specifici per role
  local extra=""
  case "$role" in
    proxmox)
      vms_raw=$(parse_val "$raw" "VMs")
      cts_raw=$(parse_val "$raw" "CTs")
      # VMs -> array
      vms_json="["
      if [ -n "$vms_raw" ]; then
        IFS='~~~' read -ra arr <<< "$vms_raw"
        for item in "${arr[@]}"; do
          name="${item%%|||*}"; status="${item##*|||}"
          [ -n "$name" ] && vms_json+="{\"name\":\"${name}\",\"status\":\"${status}\"},"
        done
      fi
      vms_json="${vms_json%,}]"
      cts_json="["
      if [ -n "$cts_raw" ]; then
        IFS='~~~' read -ra arr <<< "$cts_raw"
        for item in "${arr[@]}"; do
          name="${item%%|||*}"; status="${item##*|||}"
          [ -n "$name" ] && cts_json+="{\"name\":\"${name}\",\"status\":\"${status}\"},"
        done
      fi
      cts_json="${cts_json%,}]"
      extra="\"vms\":${vms_json},\"cts\":${cts_json},\"failed_units\":${failed:-0},"
      ;;
    naruto)
      pihole_block=$(parse_val "$raw" "PIHOLE_BLOCK")
      extra="\"pihole_block\":\"${pihole_block}\","
      ;;
    cs42)
      wazuh_agents=$(parse_val "$raw" "WAZUH_AGENTS")
      extra="\"wazuh_agents\":\"${wazuh_agents}\",\"failed_units\":${failed:-0},"
      ;;
  esac

  cat <<EOF
{
  "reachable": true,
  "uptime": "$(echo "$uptime" | sed 's/"/\\"/g')",
  "load": "$(echo "$load" | sed 's/"/\\"/g')",
  "ram": {"used": ${ram_used:-0}, "total": ${ram_total:-1}},
  "disk": {"pct": ${disk_pct:-0}, "used": "${disk_used}", "total": "${disk_total}"},
  "services": ${svcs_json},
  ${extra}
  "ssh_fails": ${ssh_fails:-0},
  "f2b_banned": "$(echo "$f2b" | sed 's/"/\\"/g')",
  "apt": {"count": ${apt_count:-0}, "list": ${apt_json}}
}
EOF
}

PROXMOX_JSON=$(raw_to_json "$PROXMOX_RAW" "proxmox")
NARUTO_JSON=$(raw_to_json "$NARUTO_RAW"   "naruto")
CS42_JSON=$(raw_to_json "$CS42_RAW"       "cs42")

# ──────────────────────────────────────────────
# Genera dashboard.html
# ──────────────────────────────────────────────

# Legge CSS e JS per embed inline
CSS_CONTENT=$(cat "$STATIC_DIR/style.css")
JS_CONTENT=$(cat "$STATIC_DIR/app.js")

cat > "$OUT_HTML" <<HTMLEOF
<!DOCTYPE html>
<html lang="it">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Homelab Dashboard</title>
  <style>
$CSS_CONTENT
  </style>
</head>
<body>
  <header>
    <div class="header-left">
      <span class="logo">&#9632;</span>
      <h1>Homelab Dashboard</h1>
    </div>
    <div class="header-right">
      <span id="last-check">generato: $(date '+%d/%m/%Y %H:%M:%S')</span>
      <button id="refresh-btn" onclick="rerunScript()">
        <span id="refresh-icon">&#8635;</span> Refresh
      </button>
    </div>
  </header>

  <main id="main">
    <div id="cards" class="cards-grid"></div>
  </main>

  <script>
  window.__DATA__ = {
    proxmox: $PROXMOX_JSON,
    naruto:  $NARUTO_JSON,
    cs42:    $CS42_JSON
  };

  function rerunScript() {
    alert('Per aggiornare i dati riesegui:\\n\\n  bash dashboard/gen-dashboard.sh\\n\\nPoi ricarica la pagina (Cmd+R).');
  }

$JS_CONTENT
  </script>
</body>
</html>
HTMLEOF

echo -e "${GREEN}[dashboard]${NC} HTML generato: $OUT_HTML"

# Apri nel browser
if command -v open &>/dev/null; then
  open "$OUT_HTML"
  echo -e "${GREEN}[dashboard]${NC} Aperto nel browser."
fi
