#!/bin/bash
# Deployato su burgerking: /usr/local/bin/ssh-telegram-notify.sh
# Triggerato da PAM ad ogni login SSH riuscito.
# Credenziali lette da /etc/telegram-notify.conf (TOKEN e CHAT_ID).

[ "$PAM_TYPE" = "open_session" ] || exit 0

CONF="/etc/telegram-notify.conf"
[ -f "$CONF" ] && source "$CONF"
[ -z "$TOKEN" ] || [ -z "$CHAT_ID" ] && exit 0

HOST=$(hostname)
TS=$(date '+%d/%m/%Y alle %H:%M %Z')

curl -s "https://api.telegram.org/bot${TOKEN}/sendMessage" \
  -d chat_id="${CHAT_ID}" \
  -d parse_mode="HTML" \
  --data-urlencode text="burgerking SSH LOGIN
Utente: ${PAM_USER}
IP: ${PAM_RHOST}
${TS}" > /dev/null

exit 0
