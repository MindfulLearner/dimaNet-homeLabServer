#!/usr/bin/env python3
"""
dimaNet Telegram bot — polling, whitelist, no exposed ports.
Credenziali lette da /etc/telegram-notify.conf (TOKEN, CHAT_ID).
ALLOWED_USER_IDS sovrascrivibile via env var omonima.
"""

import os
import re
import subprocess
from telegram import Update
from telegram.ext import Application, CommandHandler, ContextTypes

# ── credenziali ───────────────────────────────────────────────────────────────
CONF = "/etc/telegram-notify.conf"
_env = {}
if os.path.exists(CONF):
    with open(CONF) as f:
        for line in f:
            m = re.match(r'^(\w+)="?([^"]*)"?', line.strip())
            if m:
                _env[m.group(1)] = m.group(2)

TOKEN = os.environ.get("TELEGRAM_BOT_TOKEN") or _env.get("TOKEN", "")
_default_ids = _env.get("CHAT_ID", "")
ALLOWED = set(
    int(x) for x in
    os.environ.get("ALLOWED_USER_IDS", _default_ids).split(",")
    if x.strip().lstrip("-").isdigit()
)

if not TOKEN:
    raise SystemExit("ERROR: TOKEN non trovato in env TELEGRAM_BOT_TOKEN o in " + CONF)

# ── helpers ───────────────────────────────────────────────────────────────────
ANSI = re.compile(r"\x1b\[[0-9;]*m")

def _run(cmd: str, timeout: int = 30) -> str:
    try:
        out = subprocess.check_output(
            cmd, shell=True, stderr=subprocess.STDOUT,
            timeout=timeout, text=True
        )
    except subprocess.CalledProcessError as e:
        out = e.output or "(nessun output)"
    except subprocess.TimeoutExpired:
        out = "(timeout)"
    return ANSI.sub("", out).strip()[:4000]

def _guard(uid: int) -> bool:
    return uid in ALLOWED

# ── comandi ───────────────────────────────────────────────────────────────────
async def cmd_ping(update: Update, ctx: ContextTypes.DEFAULT_TYPE) -> None:
    if not _guard(update.effective_user.id):
        return
    await update.message.reply_text("online")

async def cmd_healthcheck(update: Update, ctx: ContextTypes.DEFAULT_TYPE) -> None:
    if not _guard(update.effective_user.id):
        return
    await update.message.reply_text("eseguo healthcheck...")
    out = _run(
        "echo '=== SYSTEM ===' && uptime && echo && "
        "echo '=== CPU ===' && top -bn1 | grep 'Cpu(s)' && echo && "
        "echo '=== RAM ===' && free -h && echo && "
        "echo '=== DISK ===' && df -h | grep -vE 'tmpfs|udev|overlay|shm'",
        timeout=20
    )
    await update.message.reply_text(f"<pre>{out}</pre>", parse_mode="HTML")

async def cmd_containers(update: Update, ctx: ContextTypes.DEFAULT_TYPE) -> None:
    if not _guard(update.effective_user.id):
        return
    out = _run("pct list 2>/dev/null || echo 'pct non disponibile'")
    await update.message.reply_text(f"<pre>{out}</pre>", parse_mode="HTML")

async def cmd_rtc(update: Update, ctx: ContextTypes.DEFAULT_TYPE) -> None:
    if not _guard(update.effective_user.id):
        return
    arg = ctx.args[0] if ctx.args else "8"
    if "." in arg:
        hours, minutes_raw = arg.split(".", 1)
        minutes = int(minutes_raw) * 10 if len(minutes_raw) == 1 else int(minutes_raw)
    else:
        hours, minutes = arg, 0
    try:
        secs = int(hours) * 3600 + int(minutes) * 60
    except ValueError:
        await update.message.reply_text("Uso: /rtc 8  oppure  /rtc 8.30")
        return
    h, m = int(hours), int(minutes)
    duration = f"{h}h {m}m" if m else f"{h}h"
    now = _run("date '+%d/%m/%Y alle %H:%M %Z'")
    wake_time = _run(f"date -d '+{secs} seconds' '+%d/%m/%Y alle %H:%M %Z'")
    host = _run("hostname")
    msg = (
        f"<b>{host} SPENTO</b>\n"
        f"Spegnimento: {now}\n"
        f"Durata: {duration}\n"
        f"Riaccensione prevista: {wake_time}"
    )
    await update.message.reply_text(msg, parse_mode="HTML")
    subprocess.Popen(["rtcwake", "-m", "off", "-s", str(secs)])

# ── main ──────────────────────────────────────────────────────────────────────
def main() -> None:
    app = Application.builder().token(TOKEN).build()
    app.add_handler(CommandHandler("ping", cmd_ping))
    app.add_handler(CommandHandler("healthcheck", cmd_healthcheck))
    app.add_handler(CommandHandler("containers", cmd_containers))
    app.add_handler(CommandHandler("rtc", cmd_rtc))
    print(f"Bot avviato. Whitelist: {ALLOWED}")
    app.run_polling(drop_pending_updates=True)

if __name__ == "__main__":
    main()
