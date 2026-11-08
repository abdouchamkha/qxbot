"""Local web server for the GUI: static files, a JSON API and a server-sent-events stream (state + log).

Bound to 127.0.0.1 only. Every API call needs the per-run token (X-Token header, or ?t= for the event
stream), so a web page in the user's browser can't drive the bot (CSRF).
"""

import json
import mimetypes
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

WEB = Path(__file__).parent / "web"


def routes(engine, app) -> dict:
    """POST /api/<name> -> handler(body dict) -> JSON-able."""
    return {
        "profiles": lambda b: engine.profiles(),
        "profile": lambda b: engine.profile(b.get("name") or engine.profiles()["last"]),
        "settings": lambda b: {k: v for k, v in engine.save_profile(b).items() if k != "password"},
        "lang": lambda b: engine.set_lang(b.get("lang", "en")),
        "connect": lambda b: engine.connect(b),
        "disconnect": lambda b: engine.disconnect(),
        "pin": lambda b: engine.submit_pin(str(b.get("pin", ""))),
        "preview": lambda b: engine.preview(b.get("text", ""), b.get("profile")),
        "start": lambda b: engine.start_list(b.get("text", "")),
        "stop": lambda b: engine.stop(),
        "backtest": lambda b: engine.backtest(b.get("text", ""), b.get("offsets", "")),
        "stats": lambda b: engine.stats(),
        "history": lambda b: engine.history(),
        "log": lambda b: {"lines": [t for _, t in engine.sink.since(0)]},
        "quit": lambda b: app.quit(stop=bool(b.get("stop"))),
        "cancel_quit": lambda b: setattr(engine, "closing", False) or {},
        "shortcut": lambda b: app.shortcut(),
    }


def make_server(engine, app, port: int, token: str) -> ThreadingHTTPServer:
    api = routes(engine, app)

    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *a):  # keep the GUI log for the bot
            pass

        def send(self, code: int, body: bytes, ctype: str = "application/json") -> None:
            self.send_response(code)
            self.send_header("Content-Type", ctype)
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(body)

        def do_GET(self):
            url = urlparse(self.path)
            if url.path == "/api/ping":
                return self.send(200, b'"qxbot"')
            if url.path == "/api/events":
                if parse_qs(url.query).get("t") != [token]:
                    return self.send(403, b'{"error": "bad token"}')
                return self.events()
            f = (WEB / (url.path.lstrip("/") or "index.html")).resolve()
            if not f.is_file() or WEB.resolve() not in f.parents:
                return self.send(404, b"not found", "text/plain")
            self.send(200, f.read_bytes(), mimetypes.guess_type(f.name)[0] or "application/octet-stream")

        def do_POST(self):
            name = urlparse(self.path).path.removeprefix("/api/")
            if name == "focus":  # a second launch asks this one to show itself
                app.focus()
                return self.send(200, b"{}")
            if self.headers.get("X-Token") != token:
                return self.send(403, b'{"error": "bad token"}')
            if name not in api:
                return self.send(404, b'{"error": "no such call"}')
            try:
                body = json.loads(self.rfile.read(int(self.headers.get("Content-Length") or 0)) or b"{}")
                self.send(200, json.dumps(api[name](body)).encode())
            except Exception as e:
                self.send(400, json.dumps({"error": str(e) or repr(e)}).encode())

        def events(self):
            """State whenever it changes (checked every second) and log lines as they come."""
            self.send_response(200)
            self.send_header("Content-Type", "text/event-stream")
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            engine.clients += 1
            seq, last, quiet = max(0, engine.sink.seq - 500), None, time.time()
            try:
                while not app.stopping:
                    lines = engine.sink.since(seq, wait=1.0)
                    out = ""
                    if lines:
                        seq = lines[-1][0]
                        out += f"event: log\ndata: {json.dumps([t for _, t in lines])}\n\n"
                    state = json.dumps(engine.snapshot())
                    if state != last or time.time() - quiet > 10:  # resend now and then: detects a closed window
                        last, quiet = state, time.time()
                        out += f"event: state\ndata: {json.dumps(json.loads(state) | {'now': time.time()})}\n\n"
                    if out:
                        self.wfile.write(out.encode())
                        self.wfile.flush()
            except OSError:
                pass
            finally:
                engine.clients -= 1
                engine.last_client = time.time()

    server = ThreadingHTTPServer(("127.0.0.1", port), Handler)
    server.daemon_threads = True
    threading.Thread(target=server.serve_forever, daemon=True, name="http").start()
    return server
