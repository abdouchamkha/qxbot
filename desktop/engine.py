"""GUI engine: runs bot.Bot in an asyncio loop thread for the web UI.

The trading logic stays in bot.py; this only keeps the state the UI shows, routes print()
to the GUI log (LogSink) and Quotex's PIN prompt to the GUI (read_line).
"""

import asyncio
import collections
import io
import json
import threading
import time
from datetime import datetime, timedelta, timezone

import bot as qx
from signals import list_timezone, parse_signals


class LogSink(io.TextIOBase):
    """sys.stdout/stderr in GUI mode: each printed line goes to the GUI log, a log file and the old stream."""

    def __init__(self, path=None, echo=None):
        self.lines: collections.deque = collections.deque(maxlen=3000)  # (seq, "HH:MM:SS text")
        self.seq, self.buf = 0, ""
        self.cond = threading.Condition()
        self.file = open(path, "a", encoding="utf-8", buffering=1) if path else None
        self.echo = echo

    def writable(self) -> bool:
        return True

    def write(self, s: str) -> int:
        if self.echo:
            try:
                self.echo.write(s)
                self.echo.flush()
            except Exception:
                pass
        with self.cond:
            *done, self.buf = (self.buf + s).split("\n")
            for line in done:
                if line.strip():
                    self.seq += 1
                    self.lines.append((self.seq, f"{datetime.now():%H:%M:%S} {line.rstrip()}"))
                    if self.file:
                        self.file.write(f"{datetime.now():%Y-%m-%d} {self.lines[-1][1]}\n")
            if done:
                self.cond.notify_all()
        return len(s)

    def since(self, seq: int, wait: float = 0) -> list[tuple[int, str]]:
        with self.cond:
            if wait and self.seq <= seq:
                self.cond.wait(wait)
            return [x for x in self.lines if x[0] > seq]


def clean_settings(d: dict) -> dict:
    """Form values (strings from the UI) -> config.json types; raises ValueError with a readable message."""
    out = {}
    for k, default in qx.DEFAULTS.items():
        v = d.get(k, default)
        if k == "pre_entry_ms":
            v = "auto" if str(v).strip().lower() in ("", "auto") else int(float(v))
        elif isinstance(default, str):
            v = str(v).strip()
            if default in ("y", "n"):
                v = "y" if v in ("y", "true", "True", "1", True) else "n"
        else:
            try:
                v = type(default)(float(str(v).replace(",", ".").replace("−", "-") or 0))
            except ValueError:
                raise ValueError(f"{k}: not a number") from None
        out[k] = v
    out["account"] = out["account"].upper()
    if out["account"] not in ("PRACTICE", "REAL"):
        raise ValueError("Account must be PRACTICE or REAL")
    if out["amount"] <= 0:
        raise ValueError("Amount must be > 0")
    if out["gales"] < 0 or out["gale_multiplier"] <= 0 or out["min_payout"] < 0:
        raise ValueError("Martingale and payout must be positive")
    return out


def label(steps: list[dict]) -> str:
    """WIN / WIN G1 / LOSS / DRAW for one signal's trade steps (last step decides)."""
    last = steps[-1]
    tag = f" G{last['level']}" if str(last["level"]) not in ("0", "") else ""
    return {"win": "WIN", "loss": "LOSS"}.get(last["result"], "DRAW") + ("" if last["result"] == "loss" else tag)


def result_cards(rows: list[dict]) -> list[dict]:
    """trades.csv rows -> one card per signal (its gales folded in), newest first."""
    groups: dict[str, list[dict]] = {}
    for r in rows:
        groups.setdefault(r["signal"], []).append(r)
    cards = [{"time": steps[0]["time"], "asset": steps[0]["asset"], "direction": steps[0]["direction"],
              "amount": sum(float(s["amount"]) for s in steps), "profit": round(sum(float(s["profit"]) for s in steps), 2),
              "result": label(steps), "steps": len(steps)} for steps in groups.values()]
    return sorted(cards, key=lambda c: c["time"], reverse=True)


def sig_json(s: qx.Signal) -> dict:
    return {"at": s.at.timestamp(), "time": f"{s.at:%H:%M}", "date": f"{s.at:%Y-%m-%d}", "asset": s.asset,
            "direction": s.direction, "duration": s.duration}


class Engine:
    def __init__(self, sink: LogSink):
        self.sink = sink
        self.loop: asyncio.AbstractEventLoop | None = None
        self.bot: qx.Bot | None = None
        self.cfg: dict = {}
        self.status, self.error = "offline", ""
        self.pin: asyncio.Future | None = None
        self.schedule: list[dict] = []
        self.keepalive: asyncio.Task | None = None
        self.clients, self.last_client = 0, time.time()
        self.closing = False  # window close asked while trades are scheduled
        self.window = None  # pywebview window, if any
        qx.read_line = self.read_line  # browser_session asks the PIN through this

    # ---------------------------------------------------------- loop plumbing
    def start(self) -> None:
        self.loop = asyncio.new_event_loop()
        threading.Thread(target=self.loop.run_forever, daemon=True, name="engine").start()

    def run(self, coro, timeout: float = 600):
        return asyncio.run_coroutine_threadsafe(coro, self.loop).result(timeout)

    async def read_line(self, prompt: str) -> str:
        print(prompt)
        self.pin = asyncio.get_running_loop().create_future()
        try:
            return await self.pin
        finally:
            self.pin = None

    def submit_pin(self, code: str) -> dict:
        pin = self.pin
        if not pin or not code.strip():
            raise ValueError("No PIN requested")
        self.loop.call_soon_threadsafe(lambda: pin.done() or pin.set_result(code.strip()))
        return {}

    # ---------------------------------------------------------- profiles
    def profiles(self) -> dict:
        saved = qx.read_config()
        return {"names": list(saved["profiles"]), "last": saved["last"], "lang": saved.get("lang", "en")}

    def profile(self, name: str) -> dict:
        d = qx.DEFAULTS | qx.read_config()["profiles"].get(name, {})
        return {k: v for k, v in d.items() if k != "password"} | {"name": name, "has_password": bool(d.get("password"))}

    def save_profile(self, form: dict) -> dict:
        """Save settings (and the password if `remember`) to config.json; returns the full settings incl. password."""
        name = (form.get("name") or "default").strip()
        saved = qx.read_config()
        old = saved["profiles"].get(name, {})
        d = clean_settings(qx.DEFAULTS | old | form)
        password = form.get("password") or old.get("password", "")
        if form.get("remember", True) and password:
            d["password"] = password
        saved["profiles"][name], saved["last"] = d, name
        qx.CONFIG_FILE.write_text(json.dumps(saved, indent=2))
        qx.CONFIG_FILE.chmod(0o600)  # may hold the password
        if self.bot and name == self.cfg.get("profile"):  # trade settings apply to the next trades at once
            for k in ("amount", "utc_offset", "gales", "gale_multiplier", "safe_pips", "pre_entry_ms", "overlap",
                      "min_payout", "pending", "stop_loss", "take_profit"):
                self.cfg[k] = d[k]
        return d | {"password": password, "profile": name}

    def set_lang(self, lang: str) -> dict:
        saved = qx.read_config()
        saved["lang"] = "ar" if lang == "ar" else "en"
        qx.CONFIG_FILE.write_text(json.dumps(saved, indent=2))
        qx.CONFIG_FILE.chmod(0o600)
        return {}

    # ---------------------------------------------------------- session
    def connect(self, form: dict) -> dict:
        if self.status == "connecting":
            raise ValueError("Already connecting")
        cfg = self.save_profile(form)
        if not cfg["email"] or not cfg["password"]:
            raise ValueError("Email and password are needed")
        self.status, self.error = "connecting", ""
        asyncio.run_coroutine_threadsafe(self._connect(cfg), self.loop)
        return {}

    async def _connect(self, cfg: dict) -> None:
        try:
            await self._disconnect()
            self.status = "connecting"
            qx.patch_pyquotex(cfg["proxy"])
            b = qx.Bot(cfg)
            await b.connect()
            self.bot, self.cfg, self.status = b, b.cfg, "online"
            self.keepalive = qx.spawn(b.keepalive(), "keepalive")
        except BaseException as e:
            self.status, self.error = "error", str(e) or repr(e)
            print(f"Login failed: {e!r}")
            if not isinstance(e, Exception):
                raise

    async def _disconnect(self) -> None:
        if self.bot:
            await self._stop()
            if self.keepalive:
                self.keepalive.cancel()
            try:
                await self.bot.broker.close()
            except Exception:
                pass
        self.bot, self.status = None, "offline"

    def disconnect(self) -> dict:
        self.run(self._disconnect())
        print("Logged out.")
        return {}

    # ---------------------------------------------------------- signals
    def tz(self, profile: str | None = None) -> timezone:
        cfg = self.cfg or self.profile(profile or self.profiles()["last"])
        return timezone(timedelta(hours=float(cfg["utc_offset"])))

    def names(self) -> list | None:
        if not self.bot:
            return None
        return [(i[1], i[2]) for i in self.bot.broker.api.instruments] or None

    def preview(self, text: str, profile: str | None = None) -> dict:
        """Dry parse for the live preview: upcoming, passed, not-understood lines, same-minute duplicates."""
        unknown, passed = [], []
        signals = parse_signals(text, self.tz(profile), datetime.now(timezone.utc), self.names(), unknown=unknown,
                                passed=passed)
        overlap = (self.cfg or self.profile(profile or self.profiles()["last"]))["overlap"] == "y"
        taken = set(self.bot.taken) if self.bot else set()
        out = []
        for s in signals:
            j = sig_json(s)
            j["dup"] = not overlap and s.at.timestamp() in taken
            taken.add(s.at.timestamp())
            out.append(j)
        tz = list_timezone(text)
        return {"signals": out, "passed": [sig_json(s) for s in passed], "unknown": unknown,
                "tz": str(tz or self.tz(profile)), "tz_from_list": tz is not None, "checked": self.bot is not None}

    def need_bot(self) -> qx.Bot:
        if not self.bot or self.status != "online":
            raise ValueError("Not connected to Quotex")
        return self.bot

    def start_list(self, text: str) -> dict:
        b = self.need_bot()

        async def go():
            pairs = await qx.start_list(b, text, self.tz())
            for s, task in pairs:
                item = sig_json(s) | {"state": "waiting", "task": task}
                task.add_done_callback(lambda t, item=item: item.update(state="cancelled" if t.cancelled() else "done"))
                self.schedule.append(item)
            return len(pairs)

        return {"scheduled": self.run(go())}

    async def _stop(self) -> int:
        tasks = [x["task"] for x in self.schedule if x["state"] == "waiting"]
        async with self.bot.pending_lock:  # no pending order is half-created while we cancel
            for t in tasks:
                t.cancel()
            await self.bot.cancel_pending()
        # shortcut: a task cancelled in the ms between sending a direct order and its reply leaves that trade
        # untracked (it still runs on Quotex, see Quotex history); fine for a Stop button.
        self.bot.taken.clear()
        if tasks:
            print(f"Stopped: {len(tasks)} scheduled trades cancelled. Trades already open finish normally.")
        return len(tasks)

    def stop(self) -> dict:
        return {"cancelled": self.run(self._stop()) if self.bot else 0}

    def backtest(self, text: str, offsets: str = "") -> dict:
        b = self.need_bot()
        try:
            offs = [float(o.replace("−", "-")) for o in offsets.replace(",", " ").split()]
        except ValueError:
            raise ValueError("Timezones: numbers like -3 +1 5.5") from None
        out = []
        for tz, rows in self.run(qx.backtest_list(b, text, offs, self.tz())):
            res = [r for _, r in rows]
            wins, losses = sum(r.startswith("WIN") for r in res), res.count("LOSS")
            out.append({"tz": tz, "rows": [sig_json(s) | {"result": r} for s, r in rows], "wins": wins,
                        "losses": losses, "draws": sum(r.startswith("DRAW") for r in res)})
        return {"runs": out}

    # ---------------------------------------------------------- analytics
    def my_trades(self) -> list[dict]:
        if self.bot:
            return self.bot.my_trades()
        p = self.profiles()["last"]
        acc = self.profile(p)["account"]
        return [r for r in qx.read_trades() if r["profile"] == p and r["account"] == acc]

    def stats(self) -> dict:
        rows = self.my_trades()
        today = datetime.now().date().isoformat()
        pairs = [{"asset": a} | qx.summarize([r for r in rows if r["asset"] == a]) for a in {r["asset"] for r in rows}]
        return {
            "session": qx.summarize([r for r in rows if self.bot and r["time"] >= self.bot.started]),
            "today": qx.summarize([r for r in rows if r["time"].startswith(today)]),
            "all": qx.summarize(rows),
            "levels": [{"level": lv, "wins": sum(r["result"] == "win" for r in rows if r["level"] == lv),
                        "trades": sum(r["level"] == lv for r in rows)} for lv in sorted({r["level"] for r in rows})],
            "pairs": sorted(pairs, key=lambda m: -m["net"]),
        }

    def history(self) -> dict:
        b = self.need_bot()
        rows = self.run(b.quotex_history(datetime.now(timezone.utc).date().isoformat()))
        return {"summary": qx.summarize(rows), "rows": rows[::-1]}

    # ---------------------------------------------------------- UI state
    def waiting(self) -> int:
        return sum(x["state"] == "waiting" for x in self.schedule)

    def snapshot(self) -> dict:
        b = self.bot
        rows = self.my_trades()
        today = datetime.now().date().isoformat()
        p = self.profiles()
        return {
            "status": self.status, "error": self.error, "pin": self.pin is not None, "lang": p["lang"],
            "profile": self.cfg.get("profile") or p["last"], "account": self.cfg.get("account"),
            "email": self.cfg.get("email"), "balance": b.balance if b else None,
            "clock": b.clock if b else "", "clock_ok": b.clock_ok if b else None,
            "today": round(sum(float(r["profit"]) for r in rows if r["time"].startswith(today)), 2),
            "schedule": [{k: v for k, v in x.items() if k != "task"} for x in self.schedule[-200:]],
            "waiting": self.waiting(), "results": result_cards([r for r in rows if r["time"].startswith(today)])[:100],
            "closing": self.closing,
        }
