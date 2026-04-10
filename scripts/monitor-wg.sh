#!/bin/bash
# Esporta prima: export PROXMOX_SSH=root@<IP-LAN-Proxmox>
SERVER="${PROXMOX_SSH:?Imposta PROXMOX_SSH (es. export PROXMOX_SSH=root@10.0.0.1)}"
INTERVAL=5

echo "=== WireGuard Monitor ==="
echo "Aggiornamento ogni ${INTERVAL}s - CTRL+C per uscire"
echo ""

while true; do
    clear
    echo "=== WireGuard Monitor - $(date '+%H:%M:%S') ==="
    echo ""

    STATUS=$(ssh -o ConnectTimeout=5 -o BatchMode=yes "$SERVER" "wg show" 2>/dev/null)

    if [ $? -ne 0 ]; then
        echo "ERRORE: Server non raggiungibile"
        sleep "$INTERVAL"
        continue
    fi

    HANDSHAKE=$(echo "$STATUS" | grep "latest handshake")
    TRANSFER=$(echo "$STATUS" | grep "transfer")
    ENDPOINT=$(echo "$STATUS" | grep "endpoint")

    if [ -z "$HANDSHAKE" ]; then
        echo "Peer: NON CONNESSO"
    else
        echo "Peer: CONNESSO"
        echo "$ENDPOINT"
        echo "$HANDSHAKE"
        echo "$TRANSFER"
    fi

    echo ""
    echo "--- Raw ---"
    echo "$STATUS"

    sleep "$INTERVAL"
done
