#!/bin/bash
# Deploy SSH Telegram notify su burgerking (Proxmox 192.168.1.100)
# Riusa le credenziali Telegram gia' presenti in /usr/local/bin/rtc.
# Usage: bash scripts/deploy-ssh-notify.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BURGERKING="burgerking"
REMOTE_SCRIPT="/usr/local/bin/ssh-telegram-notify.sh"
REMOTE_CONF="/etc/telegram-notify.conf"
PAM_FILE="/etc/pam.d/sshd"
PAM_LINE="session optional pam_exec.so ${REMOTE_SCRIPT}"

echo -e "${YELLOW}Deploy SSH Telegram notify su ${BURGERKING}...${NC}"

echo "  Leggo credenziali Telegram da ${BURGERKING}:/usr/local/bin/rtc"
EXISTING_TOKEN=$(ssh "$BURGERKING" "grep '^TOKEN=' /usr/local/bin/rtc | cut -d'\"' -f2")
EXISTING_CHAT=$(ssh "$BURGERKING" "grep '^CHAT_ID=' /usr/local/bin/rtc | cut -d'\"' -f2")

if [ -z "$EXISTING_TOKEN" ] || [ -z "$EXISTING_CHAT" ]; then
    echo -e "${RED}ERROR: Credenziali non trovate in /usr/local/bin/rtc${NC}"
    exit 1
fi

echo "  Copia script -> ${REMOTE_SCRIPT}"
scp -q "$REPO_ROOT/scripts/ssh-telegram-notify.sh" "${BURGERKING}:${REMOTE_SCRIPT}"
ssh "$BURGERKING" "chmod 755 ${REMOTE_SCRIPT}"

echo "  Crea config credenziali -> ${REMOTE_CONF}"
ssh "$BURGERKING" "printf 'TOKEN=\"%s\"\nCHAT_ID=\"%s\"\n' '${EXISTING_TOKEN}' '${EXISTING_CHAT}' > ${REMOTE_CONF} && chmod 600 ${REMOTE_CONF}"

echo "  Configura PAM -> ${PAM_FILE}"
ssh "$BURGERKING" "grep -qF '${REMOTE_SCRIPT}' ${PAM_FILE} || echo '${PAM_LINE}' >> ${PAM_FILE}"

echo ""
echo -e "${GREEN}Deploy completato.${NC}"
echo "Test: apri una nuova connessione SSH a burgerking e controlla Telegram."
echo ""
echo "Per rimuovere:"
echo "  ssh burgerking \"sed -i '\\|${REMOTE_SCRIPT}|d' ${PAM_FILE} && rm -f ${REMOTE_SCRIPT} ${REMOTE_CONF}\""
