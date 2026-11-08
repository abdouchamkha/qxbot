"""QXBot desktop GUI: `pythonw -m desktop` (QXBot.exe runs exactly this).

Engine (bot.Bot) in a background asyncio loop, a local web UI on 127.0.0.1, shown in a native
window (pywebview + Edge WebView2); without WebView2 it opens the default browser instead.
"""

import json
import os
import secrets
import subprocess
import sys
import threading
import time
import urllib.request
import webbrowser
from pathlib import Path

PORT = 47821  # fixed, so a second launch finds the running one
ROOT = Path(__file__).resolve().parent.parent


class App:
    def __init__(self, engine, url: str):
        self.engine, self.url = engine, url
        self.window = None
        self.stopping = False

    def on_closing(self):
        """Window X: with trades scheduled, ask in the UI first (returning False keeps the window)."""
        if self.engine.waiting() and not self.stopping:
            self.engine.closing = True
            return False
        self.stopping = True
        return True

    def quit(self, stop: bool = False) -> dict:
        if stop and self.engine.bot:
            self.engine.stop()  # cancels pending orders on Quotex too
        self.stopping = True
        threading.Thread(target=self._exit, daemon=True).start()
        return {}

    def _exit(self):
        time.sleep(0.3)  # let the HTTP reply go out
        if self.window:
            self.window.destroy()
        else:
            os._exit(0)

    def focus(self):
        if self.window:
            self.window.restore()
            self.window.show()
        else:
            webbrowser.open(self.url)

    def shortcut(self) -> dict:
        """Desktop shortcut to QXBot.exe (Windows)."""
        exe = ROOT / "QXBot.exe"
        if os.name != "nt" or not exe.exists():
            raise ValueError("Only in the Windows app")
        q = lambda p: "'" + str(p).replace("'", "''") + "'"
        ps = ("$s=(New-Object -ComObject WScript.Shell).CreateShortcut([Environment]::GetFolderPath('Desktop')+'\\QXBot.lnk');"
              f"$s.TargetPath={q(exe)};$s.WorkingDirectory={q(ROOT)};$s.IconLocation={q(exe)};$s.Save()")
        subprocess.run(["powershell", "-NoProfile", "-NonInteractive", "-Command", ps], check=True,
                       creationflags=subprocess.CREATE_NO_WINDOW, timeout=30)
        return {}


def running_instance() -> bool:
    """True if QXBot already serves on PORT (then it was asked to show itself)."""
    try:
        with urllib.request.urlopen(f"http://127.0.0.1:{PORT}/api/ping", timeout=2) as r:
            if json.load(r) != "qxbot":
                return False
        urllib.request.urlopen(urllib.request.Request(f"http://127.0.0.1:{PORT}/api/focus", b"{}"), timeout=5)
        return True
    except Exception:
        return False


def native_window(app: App) -> bool:
    """pywebview window on Edge WebView2; False if unavailable (no pywebview or no WebView2 runtime)."""
    try:
        import webview
        if os.name == "nt":
            from webview.platforms import winforms
            if not winforms.is_chromium:  # pywebview would fall back to Internet Explorer
                return False
        app.window = webview.create_window("QXBot", app.url, width=1240, height=820, min_size=(960, 640),
                                           background_color="#0B0F17")
        app.window.events.closing += app.on_closing
        webview.start(icon=str(ROOT / "desktop" / "launcher" / "qxbot.ico"))
        return True
    except Exception as e:
        print(f"Native window not available ({e!r}), using the browser.")
        app.window = None
        return False


def main(port: int = PORT, window: bool = True) -> None:
    if running_instance():
        return
    from desktop.engine import Engine, LogSink

    sink = LogSink(ROOT / "qxbot.log", echo=sys.__stdout__)
    sys.stdout = sys.stderr = sink  # all engine print() output reaches the GUI log
    engine = Engine(sink)
    engine.start()
    token = secrets.token_urlsafe(16)
    from desktop.server import make_server

    app = App(engine, "")
    try:
        server = make_server(engine, app, port, token)
    except OSError:  # port taken by something else
        server = make_server(engine, app, 0, token)
    app.url = f"http://127.0.0.1:{server.server_address[1]}/?t={token}"
    print(f"QXBot GUI on {app.url.split('?')[0]}")
    if window and native_window(app):
        os._exit(0)  # window closed (pywebview/.NET threads can keep a normal exit waiting)
    webbrowser.open(app.url)
    # browser mode: exit once no tab is open for 30s and nothing is scheduled
    while not app.stopping:
        time.sleep(2)
        if engine.clients == 0 and time.time() - engine.last_client > 30 and not engine.waiting():
            break
    os._exit(0)


if __name__ == "__main__":
    main(window="--browser" not in sys.argv)
