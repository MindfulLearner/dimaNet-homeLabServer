#!/bin/bash
set -e
# Esporta prima: export PROXMOX_SSH=root@<IP-LAN-Proxmox>
HOST="${PROXMOX_SSH:?Imposta PROXMOX_SSH (es. export PROXMOX_SSH=root@10.0.0.1)}"
REMOTE_CSS="/usr/share/pve-manager/css/custom-dashboard.css"
REMOTE_JS="/usr/share/pve-manager/js/custom-dashboard.js"
REMOTE_TPL="/usr/share/pve-manager/index.html.tpl"

DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Deploying to $HOST..."

scp "$DIR/custom-dashboard.css" "$HOST:$REMOTE_CSS"
echo "  css deployed"

scp "$DIR/custom-dashboard.js"  "$HOST:$REMOTE_JS"
echo "  js deployed"

scp "$DIR/index.html.tpl"       "$HOST:$REMOTE_TPL"
echo "  template deployed"

echo "Done. Hard-refresh the browser (Cmd+Shift+R) to see changes."
