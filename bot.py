"""Quotex signal-list auto trader.

Flow: Edge (Patchright) logs in (passes Cloudflare) -> token + cookies + UA handed to
pyquotex -> one websocket kept open -> each signal is fired so it reaches the
server at the exact candle time.
"""

import asyncio
import csv
import getpass
import itertools
import json
import os
import re
import statistics
import time
from collections import deque
from datetime import datetime, timedelta, timezone
from pathlib import Path
from urllib.parse import urlparse

from dataclasses import replace

from signals import TZ_RE, Signal, list_timezone, parse_signals

HERE = Path(__file__).parent
CONFIG_FILE = HERE / "config.json"
PROFILE_DIR = HERE / "login_profile"
TRADES_FILE = HERE / "trades.csv"
TRADE_FIELDS = ["time", "profile", "account", "signal", "asset", "direction", "level", "amount",
                "entry", "delay_ms", "open_price", "result", "profit"]

def is_losing(direction: str, open_price: float, price: float) -> bool:
    """Equal price is a refund (draw) on Quotex, so not a loss."""
    return price < open_price if direction == "call" else price > open_price


def backtest_result(s: Signal, candles: dict[int, dict], gales: int) -> str:
    """Result of a past signal from 1-minute candles keyed by open time: WIN, WIN G1, LOSS, DRAW, or no data.
    A level loses on the candle(s) of its expiry; a loss goes to the next gale, like live trading."""
    t = int(s.at.timestamp())
    for level in range(gales + 1):
        first, last = candles.get(t), candles.get(t + s.duration - 60)
        if not first or not last:
            return "no data"
        if last["close"] == first["open"]:
            return "DRAW" + (f" G{level}" if level else "")
        if not is_losing(s.direction, first["open"], last["close"]):
            return "WIN" + (f" G{level}" if level else "")
        t += s.duration
    return "LOSS"


def past_signals(text: str, tz: timezone, now: datetime, names: list[tuple[str, str]] | None = None,
                 force_tz: bool = False) -> list[Signal]:
    """Every signal of a list at its latest time before `now` (within 24h), for a backtest.
    force_tz: use `tz` even if the list names its own timezone (to try other timezones)."""
    if force_tz:
        text = TZ_RE.sub(" ", text.upper())
    passed: list[Signal] = []
    future = parse_signals(text, tz, now, names, passed=passed)
    return sorted(passed + [replace(s, at=s.at - timedelta(days=1)) for s in future], key=lambda s: s.at)


def median_gap(ticks: list[dict]) -> float:
    """Typical seconds between price updates over the last 10 ticks (inf if unknown)."""
    times = [float(t["time"]) for t in ticks[-11:]]
    gaps = sorted(b - a for a, b in zip(times, times[1:]))
    return gaps[len(gaps) // 2] if len(gaps) >= 3 else float("inf")


def pip(asset: str, digits: int | None = None) -> float:
    """A pip is 10 of the pair's smallest price steps (Quotex sends the decimals per pair)."""
    return 10.0 ** (1 - digits) if digits else (0.01 if "JPY" in asset else 0.0001)


def safe_price(direction: str, price: float | None, target: float) -> bool:
    """CALL enters at or below the target, PUT at or above it."""
    return price is not None and (price <= target if direction == "call" else price >= target)


# ---------------------------------------------------------------- analytics

def log_trade(row: dict) -> None:
    new = not TRADES_FILE.exists()
    with TRADES_FILE.open("a", newline="") as f:
        w = csv.DictWriter(f, TRADE_FIELDS)
        if new:
            w.writeheader()
        w.writerow(row)


def read_trades() -> list[dict]:
    if not TRADES_FILE.exists():
        return []
    with TRADES_FILE.open(newline="") as f:
        return list(csv.DictReader(f))


def summarize(rows: list[dict]) -> dict:
    results = [r["result"] for r in rows]
    profits = [float(r["profit"]) for r in rows]
    final = list({r["signal"]: r["result"] for r in rows}.values())  # a signal's last step decides it
    equity = peak = drawdown = 0.0
    streak = worst_streak = 0
    for p, res in zip(profits, results):
        equity += p
        peak, drawdown = max(peak, equity), max(drawdown, peak - equity)
        streak = streak + 1 if res == "loss" else 0
        worst_streak = max(worst_streak, streak)
    wins, losses = results.count("win"), results.count("loss")
    staked = sum(float(r["amount"]) for r in rows)
    return {
        "trades": len(rows), "wins": wins, "losses": losses, "draws": len(rows) - wins - losses,
        "win_rate": 100 * wins / (wins + losses) if wins + losses else 0.0,
        "net": sum(profits), "staked": staked, "roi": 100 * sum(profits) / staked if staked else 0.0,
        "signals_won": final.count("win"), "signals_lost": final.count("loss"),
        "max_drawdown": drawdown, "loss_streak": worst_streak,
    }


def stats_line(label: str, rows: list[dict]) -> str:
    m = summarize(rows)
    sig = m["signals_won"] + m["signals_lost"]
    return (f"{label:8} {m['trades']:3} trades {m['wins']}W {m['losses']}L {m['draws']}D ({m['win_rate']:.0f}%) | "
            f"signals {m['signals_won']}/{sig} won | net {m['net']:+.2f} on {m['staked']:.2f} ({m['roi']:+.0f}%) | "
            f"max drawdown {m['max_drawdown']:.2f}, worst streak {m['loss_streak']}L")


def print_stats(rows: list[dict], since: str) -> None:
    if not rows:
        print("No trades yet.")
        return
    today = datetime.now().date().isoformat()
    print("\n" + stats_line("Session", [r for r in rows if r["time"] >= since]))
    print(stats_line("Today", [r for r in rows if r["time"].startswith(today)]))
    print(stats_line("All time", rows))
    levels = sorted({r["level"] for r in rows})
    print("Wins by step: " + ", ".join(
        f"G{lv} {sum(r['result'] == 'win' for r in rows if r['level'] == lv)}/"
        f"{sum(r['level'] == lv for r in rows)}" for lv in levels))
    for kind, label in (("pending", "pending orders (opened by Quotex)"), ("open", "direct orders")):
        delays = [int(r["delay_ms"]) for r in rows if r["entry"] == kind]
        if delays:
            print(f"Entry vs candle open, {label}: avg {sum(delays) / len(delays):+.0f}ms, "
                  f"worst {max(delays, key=abs):+d}ms ({len(delays)} trades)")
    print("Pairs:")
    for asset in sorted({r["asset"] for r in rows}, key=lambda a: -summarize([r for r in rows if r["asset"] == a])["net"]):
        m = summarize([r for r in rows if r["asset"] == asset])
        print(f"  {asset:12} {m['trades']:3} trades {m['win_rate']:4.0f}% win  net {m['net']:+.2f}")


# ---------------------------------------------------------------- config

def ask(prompt: str, default):
    raw = input(f"{prompt} [{default}]: ").strip()
    return type(default)(raw) if raw else default


DEFAULTS = {
    "email": "", "host": "quotex.com", "account": "PRACTICE", "amount": 1.0,
    "utc_offset": -3.0, "gales": 0, "gale_multiplier": 2.2, "proxy": "",
    "headless": "n", "safe_pips": 0.0, "pre_entry_ms": "auto", "overlap": "n", "min_payout": 80,
    "pending": "y", "stop_loss": 0.0, "take_profit": 0.0,
}


def read_config() -> dict:
    saved = json.loads(CONFIG_FILE.read_text()) if CONFIG_FILE.exists() else {}
    if "profiles" not in saved:  # old single-account file
        saved = {"last": "default", "profiles": {"default": saved} if saved else {}}
    return saved


def load_settings() -> dict:
    """Named profiles (account + settings) in config.json; Enter on a saved profile starts at once."""
    saved = read_config()
    profiles = saved["profiles"]
    if profiles:
        print("Saved profiles:", ", ".join(profiles))
    name = ask("Profile", saved["last"])
    d = DEFAULTS | profiles.get(name, {})
    if name not in profiles or ask("Change settings? y/n", "n") == "y":
        print("Settings (Enter keeps the value in brackets)")
        d["email"] = ask("Email", d["email"])
        d["host"] = ask("Quotex host", d["host"])
        d["account"] = ask("Account PRACTICE/REAL", d["account"]).upper()
        d["amount"] = ask("Amount per trade", float(d["amount"]))
        d["utc_offset"] = ask("Signal list timezone, UTC offset hours (-3 = Brasilia, 1 = Algeria)", float(d["utc_offset"]))
        d["gales"] = ask("Martingale levels (0 = off)", int(d["gales"]))
        if d["gales"]:
            d["gale_multiplier"] = ask("Martingale multiplier", float(d["gale_multiplier"]))
        d["safe_pips"] = ask("Safe entry pips: wait up to half the candle for price to move this far "
                             "against the signal, else skip (0 = off)", float(d["safe_pips"]))
        d["pending"] = ask("OTC entries as Quotex pending orders, opened by Quotex itself at exactly :00 "
                           "(needs the signal > 70s ahead)? y/n", d["pending"])
        d["pre_entry_ms"] = ask("Direct entries: send this many ms early so the order reaches Quotex at :00 "
                                "(auto = half the measured ping, 0 = wait for the candle's first price)", str(d["pre_entry_ms"]))
        if d["pre_entry_ms"] != "auto":
            d["pre_entry_ms"] = int(d["pre_entry_ms"])
        d["stop_loss"] = ask("Daily stop-loss $: stop trading today after losing this much (0 = off)", float(d["stop_loss"]))
        d["take_profit"] = ask("Daily take-profit $: stop trading today after winning this much (0 = off)", float(d["take_profit"]))
        d["overlap"] = ask("Allow several trades in the same minute? y/n (n = first list signal only, "
                           "and a martingale gives way to a list signal)", d["overlap"])
        d["min_payout"] = ask("Minimum payout % (pairs paying less are skipped, 0 = trade all)", int(d["min_payout"]))
        d["proxy"] = ask("Proxy http://user:pass@host:port (empty = local IP)", d["proxy"])
        d["headless"] = ask("Hide browser? y/n", d["headless"])
        if d.get("password") and ask("Change saved password? y/n", "n") == "y":
            d.pop("password")
    if d["account"] not in ("PRACTICE", "REAL"):
        raise SystemExit("Account must be PRACTICE or REAL")
    if d["amount"] <= 0:
        raise SystemExit("Amount must be > 0")
    password = d.get("password") or getpass.getpass("Password (hidden): ")
    if "password" not in d and ask("Save password in config.json? y/n", "y") == "y":
        d["password"] = password
    profiles[name], saved["last"] = d, name
    CONFIG_FILE.write_text(json.dumps(saved, indent=2))
    CONFIG_FILE.chmod(0o600)  # may hold the password
    print(f"Using profile '{name}': {d['email']} {d['account']} ${d['amount']} UTC{d['utc_offset']:+g} "
          f"gales={d['gales']}x{d['gale_multiplier']:g} pending={d['pending']} pre_entry={d['pre_entry_ms']} "
          f"overlap={d['overlap']} min_payout={d['min_payout']}% safe_pips={d['safe_pips']:g} "
          f"stop_loss={d['stop_loss']:g} take_profit={d['take_profit']:g}")
    return d | {"password": password, "profile": name}


# ---------------------------------------------------------------- browser login

def playwright_proxy(url: str) -> dict | None:
    if not url:
        return None
    p = urlparse(url)
    return {"server": f"{p.scheme}://{p.hostname}:{p.port}", "username": p.username or "", "password": p.password or ""}


async def launch_browser(p, cfg: dict):
    """First installed of Edge, Chrome, Brave on Windows; Patchright's own Chromium elsewhere.
    Patchright's stealth advice: real browser, no custom UA or viewport."""
    opts = {"no_viewport": True, "headless": cfg["headless"] == "y", "proxy": playwright_proxy(cfg["proxy"])}
    choices = [{}]
    if os.name == "nt":
        brave = Path(os.environ.get("PROGRAMFILES", r"C:\Program Files")) / r"BraveSoftware\Brave-Browser\Application\brave.exe"
        choices = [{"channel": "msedge"}, {"channel": "chrome"}, {"executable_path": str(brave)}]
    for extra in choices:
        try:
            return await p.chromium.launch_persistent_context(str(PROFILE_DIR), **opts, **extra)
        except Exception as e:
            error = e
    raise RuntimeError("No browser found: install Microsoft Edge or Google Chrome.") from error


async def browser_session(cfg: dict) -> tuple[str, str]:
    """Log in with the system Edge (Windows) via Patchright; returns (token, cookie header).
    The profile is persistent, so after the first login it usually skips the form."""
    from patchright.async_api import async_playwright

    base = f"https://{cfg['host']}/en"
    async with async_playwright() as p, await launch_browser(p, cfg) as ctx:
        page = ctx.pages[0] if ctx.pages else await ctx.new_page()
        await page.goto(f"{base}/demo-trade", wait_until="domcontentloaded", timeout=90_000)
        await page.wait_for_timeout(3000)
        if "sign-in" in page.url:
            print("Logging in (solve any Cloudflare check in the browser window if shown)...")
            await page.fill('input[name="email"]:visible', cfg["email"])
            await page.fill('input[name="password"]:visible', cfg["password"])
            await page.press('input[name="password"]:visible', "Enter")
            for _ in range(120):
                if "/trade" in page.url:
                    break
                if await page.locator('input[name="code"]:visible').count():
                    await page.fill('input[name="code"]:visible', (await read_line("Quotex PIN sent to your email: ")).strip())
                    await page.press('input[name="code"]:visible', "Enter")
                await page.wait_for_timeout(1000)
            else:
                raise RuntimeError("Login did not reach the trade page (wrong password or blocked).")
            await page.goto(f"{base}/demo-trade", wait_until="domcontentloaded", timeout=90_000)
        token = None
        for _ in range(30):
            # token sits in an inline <script> JSON blob, not on window
            m = re.search(r'"token":"([^"]+)"', await page.content())
            token = m and m.group(1)
            if token:
                break
            await page.wait_for_timeout(1000)
        if not token:
            raise RuntimeError("Could not read the session token from the trade page.")
        cookies = "; ".join(f"{c['name']}={c['value']}" for c in await ctx.cookies(f"https://{cfg['host']}"))
        return token, cookies


# ---------------------------------------------------------------- broker

def patch_pyquotex(proxy: str) -> None:
    """pyquotex's websocket ignores `proxies` when a token is injected; route it
    through the same proxy as the browser so the session stays on one IP."""
    if not proxy:
        return
    from curl_cffi.requests import AsyncSession
    from pyquotex.network import navigator

    navigator.AsyncSession = lambda **kw: AsyncSession(**kw, proxies={"http": proxy, "https": proxy})


class Bot:
    def __init__(self, cfg: dict):
        self.cfg = cfg
        self.broker = None
        self.orders: dict[str, asyncio.Future] = {}
        self.started = datetime.now().isoformat(timespec="seconds")
        self.request_ids = itertools.count(int(time.time() * 1000))
        # Quotex ignores orders for a pair the account's chart is not on, and only streams
        # that pair's ticks. shortcut: one chart per account, so same-minute signals queue
        # (each waits for the previous send, a safe-entry wait delays the next by up to half a candle).
        self.chart = asyncio.Lock()
        self.taken: set[float] = set()
        self.reconnecting = asyncio.Lock()
        self.pings: deque[float] = deque(maxlen=20)  # order round trips, seconds
        self.balance = 0.0
        self.pending_lock = asyncio.Lock()  # Quotex's pending/create reply has no request id: one at a time
        self.pending_reply: asyncio.Future | None = None
        self.pending_opened: dict[str, asyncio.Future] = {}  # ticket -> open result
        self.limit_said = False
        self.clock, self.clock_ok = "", None  # last clock check, for the GUI
        self.clock_gaps: deque[tuple[float, float]] = deque(maxlen=2000)  # (received, received - Quotex stamp)

    @property
    def ping(self) -> float:
        return statistics.median(self.pings) if self.pings else 0.5

    def pre_ms(self) -> int:
        """Direct-entry head start: half the measured round trip when set to auto."""
        v = self.cfg["pre_entry_ms"]
        return int(min(600, max(50, self.ping * 500))) if v == "auto" else int(v)

    def today_net(self) -> float:
        today = datetime.now().date().isoformat()
        return sum(float(r["profit"]) for r in self.my_trades() if r["time"].startswith(today))

    def limit_reason(self, open_loss: float = 0.0) -> str | None:
        """Daily stop-loss / take-profit on realised profit, minus a trade that is losing right now."""
        net = self.today_net() - open_loss
        if self.cfg["stop_loss"] and net <= -self.cfg["stop_loss"]:
            return f"daily stop-loss reached (today {net:+.2f})"
        if self.cfg["take_profit"] and net >= self.cfg["take_profit"]:
            return f"daily take-profit reached (today {net:+.2f})"
        return None

    def can_trade(self, s: Signal, amount: float, open_loss: float = 0.0) -> bool:
        reason = self.limit_reason(open_loss)
        if reason is None and amount > self.balance:
            reason = f"balance {self.balance:.2f} can't cover {amount:.2f}"
        if reason:
            print(f"  {s.at:%H:%M} {s.asset} {s.direction.upper()} skipped: {reason}")
        return reason is None

    def schedule(self, signals: list[Signal]) -> list[Signal]:
        """Without overlap, keep only the first list signal per candle start."""
        kept = []
        for s in signals:
            at = s.at.timestamp()
            if self.cfg["overlap"] != "y" and at in self.taken:
                print(f"  {s.at:%H:%M} {s.asset} {s.direction.upper()} skipped: another signal has this minute (overlap off)")
                continue
            self.taken.add(at)
            kept.append(s)
        return kept

    def gale_blocked(self, at: float) -> bool:
        """Without overlap, a list signal wins the candle over a martingale."""
        return self.cfg["overlap"] != "y" and at in self.taken

    async def connect(self) -> None:
        from pyquotex.stable_api import Quotex

        if self.broker:
            try:
                await self.broker.close()
            except Exception:
                pass
        token, cookies = await browser_session(self.cfg)
        self.cookies = cookies
        b = Quotex(email=self.cfg["email"], password=self.cfg["password"], host=self.cfg["host"], lang="en",
                   proxies=self.cfg["proxy"] or None)
        # Cloudflare 403s the ws upgrade for browser UAs but allows the Quotex app UA
        b.set_session("Quotex/1.0", cookies, token)
        b.set_account_mode(self.cfg["account"])
        ok, reason = await b.connect()
        if not ok:
            raise RuntimeError(f"Websocket connect failed: {reason}")
        self.broker = b
        self._hook(b.api)
        self.balance = float(await b.get_balance() or 0)
        print(f"Connected. {self.cfg['account']} balance: {self.balance}")
        await self.clock_check()

    async def clock_check(self, asset: str = "EURUSD_otc") -> None:
        """Entry timing uses this PC's clock. Each tick reaches us `latency + clock error` after its
        Quotex timestamp; the smallest such gap over a few seconds is close to the clock error."""
        await self.broker.start_candles_stream(asset, 60)
        gaps, last = [], 0.0
        end = time.time() + 6
        while time.time() < end:
            t = self.tick_time(asset)
            if t != last:
                last = t
                gaps.append(time.time() - t)
            await asyncio.sleep(0.005)
        if len(gaps) < 4:
            self.clock = "Clock check skipped (no price ticks)."
            print(self.clock)
            return
        gap = min(gaps[1:])  # first value is a stale tick
        self.clock_ok = True
        if abs(CLOCK_OFFSET) >= 0.3:
            self.clock = (f"This PC clock is {abs(CLOCK_OFFSET):.1f}s {'behind' if CLOCK_OFFSET < 0 else 'ahead of'} Quotex: "
                          "trades are timed on Quotex's clock instead (syncing the PC clock is still better).")
        else:
            self.clock = f"Clock OK (ticks arrive {gap * 1000:.0f}ms after Quotex stamps them)."
        print(self.clock)

    def clock_sample(self, server_ts: float) -> None:
        """A price tick stamped `server_ts` by Quotex arrived now. The fastest tick of the last minute
        arrived `one-way latency + clock error` late, so the clock error = that gap minus the latency."""
        global CLOCK_OFFSET
        t = time.time()
        gap = t - server_ts
        if abs(gap) > 60:  # a stale or wrong timestamp
            return
        self.clock_gaps.append((t, gap))
        while self.clock_gaps[0][0] < t - 60:
            self.clock_gaps.popleft()
        error = min(g for _, g in self.clock_gaps) - 0.15  # 0.15s: measured one-way latency with a synced clock
        # Small errors are latency noise: left at 0 (entries measured fine there); seconds are a wrong clock.
        CLOCK_OFFSET = error if abs(error) >= 0.3 else 0.0

    def _hook(self, api) -> None:
        set_event = api.event_registry.set_event

        async def capture(key, data=None):
            if key == "pending_confirmed" and self.pending_reply and not self.pending_reply.done():
                self.pending_reply.set_result(data if isinstance(data, dict) else {})
            if key == "buy_confirmed" and isinstance(data, dict):
                if "accountBalance" in data:
                    self.balance = float(data["accountBalance"])
                fut = self.pending_opened.pop(str(data.get("id")), None) or self.orders.pop(str(data.get("requestId")), None)
                if not fut and not data.get("closePrice"):  # pyquotex also fires this for closed deals: skip those
                    fut = self.orders.pop(data.get("asset", ""), None)
                if fut and not fut.done():
                    fut.set_result(data)
            return await set_event(key, data)

        api.event_registry.set_event = capture

        # pyquotex drops "f_pending/opened" (a pending order that failed when it fired); catch it here.
        on_message, failed = api._on_message, False

        async def raw(msg):
            nonlocal failed
            text = msg.decode("utf-8", "ignore") if isinstance(msg, bytes) else str(msg)
            if text[:3] in ('[["', '\x04[['):  # price ticks: [["EURUSD_otc", 1794.., 1.1, 0], ...]
                try:
                    for row in json.loads(text.lstrip("\x04")):
                        self.clock_sample(float(row[1]))
                except (ValueError, TypeError, IndexError):
                    pass
            if text.startswith('451-["f_pending/opened"'):
                failed = True
            elif failed:
                failed = False
                try:
                    data = json.loads(text)
                    fut = self.pending_opened.pop(str(data.get("ticket")), None)
                    # Quotex sometimes sends this without an error code and opens the order anyway:
                    # only a real error code is a failure, else entering directly would double the trade.
                    if fut and not fut.done() and data.get("error"):
                        fut.set_result({"error": f"pending failed (code {data.get('error')})"})
                except ValueError:
                    pass
            return await on_message(msg)

        api._on_message = raw

    async def keepalive(self) -> None:
        """pyquotex already pings every 5s; this only rebuilds a dead session."""
        while True:
            await asyncio.sleep(30)
            await self.ensure_connected()

    def alive(self) -> bool:
        """pyquotex's check_connect() only reports the login state, not a dead socket."""
        from pyquotex.global_value import WebsocketStatus

        api = self.broker.api
        return api.state.status == WebsocketStatus.CONNECTED and time.monotonic() - api.last_message_at < 20

    async def ensure_connected(self) -> bool:
        async with self.reconnecting:  # keepalive and signals must not log in twice at once
            try:
                for _ in range(10):  # give pyquotex's own quick reconnect a few seconds first
                    if self.alive():
                        return True
                    await asyncio.sleep(1)
                print("Connection lost, logging in again...")
                await self.connect()
                return True
            except Exception as e:
                print(f"Reconnect failed: {e!r}")
                return False

    def price(self, asset: str) -> float | None:
        ticks = self.broker.api.realtime_price.get(asset)
        return float(ticks[-1]["price"]) if ticks else None

    def tick_time(self, asset: str) -> float:
        ticks = self.broker.api.realtime_price.get(asset)
        return float(ticks[-1]["time"]) if ticks else 0.0

    async def show(self, s: Signal, at: float) -> None:
        """Put the account's chart on this pair for the candle starting at `at`. Hold self.chart."""
        await self.broker.start_candles_stream(s.asset, s.duration)
        await self.broker.api.settings_apply(s.asset, s.duration, True, end_time=int(at) + s.duration)

    async def place(self, s: Signal, at: float, amount: float, margin: float = 0.0) -> dict | None:
        api = self.broker.api
        request_id = str(next(self.request_ids))  # unique even for orders built in the same ms
        payload = {
            "asset": s.asset, "amount": amount, "time": int(at) + s.duration, "action": s.direction,
            "isDemo": int(api.account_type), "tournamentId": api.tournament_id,
            "requestId": int(request_id), "optionType": 3,
        }
        await sleep_until(at - self.lead())
        async with self.chart:
            if not await self.wait_entry(s, at, margin):
                return None
            fut = asyncio.get_running_loop().create_future()
            self.orders[request_id] = self.orders[s.asset] = fut
            await api.send_websocket_request(f'42["orders/open",{json.dumps(payload)}]')
            sent = now()
        try:
            data = await asyncio.wait_for(fut, 10)
            ping = (now() - sent) * 1000
            self.pings.append(ping / 1000)
        except asyncio.TimeoutError:
            print(f"  {s.asset} order not confirmed (asset closed or amount invalid?)")
            return None
        finally:
            self.orders.pop(request_id, None)
            self.orders.pop(s.asset, None)
        if "error" in data:  # "open_time" = pair closed now (OTC pairs close while the real market is open)
            print(f"  {s.asset} {s.direction.upper()} REJECTED by Quotex: {data['error']}")
            return None
        opened = data["openTimestamp"] + data.get("openMs", 0) / 1000
        data["delay_ms"] = round((opened - at) * 1000)
        print(f"  {s.asset} {s.direction.upper()} ${amount} opened {data['delay_ms']:+d}ms vs "
              f"{datetime.fromtimestamp(at):%H:%M:%S} (sent {(sent - at) * 1000:+.0f}ms, ping {ping:.0f}ms) "
              f"open={data.get('openPrice')}{' SAFE ENTRY' if margin else ''}")
        return data

    def lead(self) -> float:
        """Seconds before the candle that the order step starts (chart switch + pre-entry)."""
        return max(0.5, self.pre_ms() / 1000 + 0.3)

    async def wait_entry(self, s: Signal, at: float, margin: float) -> bool:
        """Hold self.chart. Returns once it is time to send; False = skip this signal.
        Quotex opens an order on the latest price tick it holds when the order arrives.
        Default: wait until we have a tick stamped >= T (the server has it too), so it opens
        in the new candle, ping late. Pre-entry: send early so it arrives at about :00; it then
        opens on the last tick before :00 or the first after it (same expiry either way)."""
        if self.broker.api.current_asset != s.asset:
            await self.show(s, at)
        if self.pre_ms() and not margin:
            await sleep_until(at - self.pre_ms() / 1000)
            # Fast pair (new price more often than our ping): arriving at :00 opens within one tick of it.
            # Slow pair: the last price can be seconds old, so wait for the candle's first price instead;
            # the order then lands on that price (the candle's open) before the next one comes.
            if median_gap(self.broker.api.realtime_price.get(s.asset, [])) < self.ping:
                return True
        while self.tick_time(s.asset) < at and now() < at + 1.5:
            await asyncio.sleep(0.001)
        if not margin:
            return True
        candle_open = self.price(s.asset)
        if candle_open is None:
            print(f"  {s.asset} SKIPPED: no price for safe entry")
            return False
        target = candle_open - margin if s.direction == "call" else candle_open + margin
        deadline = at + s.duration / 2 - 1  # only enter in the first half of the candle
        while not safe_price(s.direction, self.price(s.asset), target):
            if now() > deadline:
                print(f"  {s.asset} {s.direction.upper()} SKIPPED: price never reached safe entry "
                      f"{target:.6g} (candle open {candle_open}) in the first half of the candle")
                return False
            await asyncio.sleep(0.002)
        return True

    def losing(self, s: Signal, data: dict) -> bool:
        price, open_price = self.price(s.asset), data.get("openPrice")
        return price is not None and open_price is not None and is_losing(s.direction, float(open_price), price)

    async def place_pending(self, s: Signal, at: float, amount: float) -> dict | None:
        """Quotex pending order by time: Quotex itself opens it at `at` (OTC only, >= 60s ahead).
        Returns the opened order, {"error": ...} if Quotex refused or failed it, None if no answer."""
        payload = {"openType": 0, "asset": s.asset, "timeframe": s.duration, "command": s.direction, "amount": amount,
                   "openTime": datetime.fromtimestamp(at, timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.000Z")}
        async with self.pending_lock:
            self.pending_reply = asyncio.get_running_loop().create_future()
            sent = now()
            await self.broker.api.send_websocket_request(f'42["pending/create",{json.dumps(payload)}]')
            try:
                reply = await asyncio.wait_for(self.pending_reply, 10)
            except asyncio.TimeoutError:
                return {"error": "no reply to pending/create"}
            self.pings.append(now() - sent)
        if "error" in reply:
            return reply
        ticket = str(reply.get("pending", {}).get("ticket"))
        fut = self.pending_opened[ticket] = asyncio.get_running_loop().create_future()
        print(f"  {s.asset} {s.direction.upper()} ${amount} pending order set for "
              f"{datetime.fromtimestamp(at):%H:%M:%S} (Quotex opens it)")
        await sleep_until(at - 3)
        if reason := self.limit_reason():  # e.g. stop-loss hit by another trade meanwhile
            await self.broker.api.send_websocket_request(f'42["pending/cancel",{json.dumps({"ticket": ticket})}]')
            print(f"  {s.asset} pending order cancelled: {reason}")
            return {"error": "cancelled", "cancelled": True}
        try:
            data = await asyncio.wait_for(fut, at + 15 - now())
        except asyncio.TimeoutError:
            return None
        finally:
            self.pending_opened.pop(ticket, None)
        if "error" in data:
            return data
        data["delay_ms"] = round((data["openTimestamp"] + data.get("openMs", 0) / 1000 - at) * 1000)
        print(f"  {s.asset} {s.direction.upper()} ${amount} opened {data['delay_ms']:+d}ms vs "
              f"{datetime.fromtimestamp(at):%H:%M:%S} by Quotex (pending) open={data.get('openPrice')}")
        return data

    async def run_signal(self, s: Signal) -> None:
        at, amount = s.at.timestamp(), self.cfg["amount"]
        signal = f"{s.at:%Y-%m-%d %H:%M} {s.asset} {s.direction}"
        use_pending = (self.cfg["pending"] == "y" and s.asset.endswith("_otc") and not self.cfg["safe_pips"]
                       and at - now() > 70)
        await sleep_until(at - (70 if use_pending else 15))
        if not await self.ensure_connected():
            print(f"  {s.at:%H:%M} {s.asset} skipped: not connected")
            return
        info = await self.instrument(s)
        if info is None:
            print(f"  {s.at:%H:%M} {s.asset} skipped: pair not found on Quotex (check the name and -OTC)")
            return
        if not info[14]:
            print(f"  {s.at:%H:%M} {s.asset} skipped: Quotex has this pair closed right now")
            return
        payout = self.broker.get_payout_by_asset(s.asset, "1" if s.duration < 300 else "5")
        if payout is not None and payout < self.cfg["min_payout"]:
            print(f"  {s.at:%H:%M} {s.asset} {s.direction.upper()} skipped: payout {payout}% < {self.cfg['min_payout']}%")
            return
        if not self.can_trade(s, amount):
            return
        margin = self.cfg["safe_pips"] * pip(s.asset, info[4])
        data, kind = None, "pending"
        if use_pending:
            data = await self.place_pending(s, at, amount)
            if data and data.get("cancelled"):
                return
            if not data or "error" in data:
                print(f"  {s.asset} pending order {'not confirmed' if data is None else data['error']}: "
                      f"{'checking' if data is None else 'entering directly'}")
                if data is None:  # no answer: don't risk a double entry
                    return
                data = None
        if data is None:
            async with self.chart:
                await self.show(s, at)
        for level in range(self.cfg["gales"] + 1):
            if data is None:
                data = await self.place(s, at, amount, margin if level == 0 else 0.0)
                kind = "safe" if margin and not level else "open"
            if not data:
                return
            spawn(self.report(s, data, level, amount, signal, kind), f"result of {s.asset}")
            if level == self.cfg["gales"]:
                return
            end = at + s.duration
            await sleep_until(end - 5)
            if not self.gale_blocked(end):
                async with self.chart:  # chart on this pair: live price for the gale call, next candle ready
                    await self.show(s, end)
                if self.losing(s, data):
                    print(f"  {s.asset} losing with 5s left, gale {level + 1} ready")
            # final call just before expiry: a late reversal can still save it
            await sleep_until(end - self.lead())
            if not self.losing(s, data):
                return
            if self.gale_blocked(end):
                print(f"  gale on {s.asset} cancelled: a list signal has {datetime.fromtimestamp(end):%H:%M} (overlap off)")
                return
            next_amount = round(amount * self.cfg["gale_multiplier"], 2)
            if not self.can_trade(s, next_amount, open_loss=amount):
                return
            at, amount, data = end, next_amount, None
            print(f"  gale {level + 1} on {s.asset}: ${amount}")

    async def instrument(self, s: Signal) -> list | None:
        """Fresh Quotex row for the pair: [id, name, label, type, decimals, ...]; payouts change during the day."""
        await self.broker.api.send_websocket_request('42["instruments/get"]')
        await asyncio.sleep(2)
        return next((i for i in self.broker.api.instruments if i[1] == s.asset), None)

    async def cancel_pending(self) -> None:
        """Cancel every pending order Quotex holds for us (GUI Stop). Hold self.pending_lock so none is half-created."""
        for ticket in list(self.pending_opened):
            self.pending_opened.pop(ticket, None)
            await self.broker.api.send_websocket_request(f'42["pending/cancel",{json.dumps({"ticket": ticket})}]')
            print(f"  pending order {ticket} cancelled")

    async def report(self, s: Signal, data: dict, level: int, amount: float, signal: str, entry: str) -> None:
        _, profit = await self.broker.check_win(str(data["id"]), s.duration)
        result = "win" if profit > 0 else "loss" if profit < 0 else "draw"
        tag = f" G{level}" if level else ""
        print(f"[{datetime.now():%H:%M:%S}] {s.asset} {s.direction.upper()}{tag}: {result.upper()} {profit:+.2f}")
        log_trade({
            "time": datetime.fromtimestamp(data["openTimestamp"]).isoformat(timespec="seconds"),
            "profile": self.cfg["profile"], "account": self.cfg["account"], "signal": signal, "asset": s.asset,
            "direction": s.direction, "level": level, "amount": amount, "entry": entry,
            "delay_ms": data["delay_ms"], "open_price": data.get("openPrice"), "result": result, "profit": profit,
        })
        print("  " + stats_line("Session", [r for r in self.my_trades() if r["time"] >= self.started]))

    async def backtest(self, signals: list[Signal]) -> list[tuple[Signal, str]]:
        """Score signals whose time already passed against Quotex's 1-minute candle history."""
        # shortcut: candle open/close, not the exact tick a live order would get; fine for a past-list check
        print(f"Backtest of {len(signals)} past signals (Quotex candles, gales={self.cfg['gales']}):")
        results = []
        for asset in dict.fromkeys(s.asset for s in signals):
            first = min(s.at.timestamp() for s in signals if s.asset == asset)
            async with self.chart:  # loading history switches the chart stream
                rows = await self.broker.get_historical_candles(
                    asset, int(time.time() - first) + 600, 60, max_workers=1)
            candles = {int(c["time"]): c for c in rows or []}
            for s in signals:
                if s.asset == asset:
                    results.append((s, backtest_result(s, candles, self.cfg["gales"])))
        for s, r in sorted(results, key=lambda x: x[0].at):
            print(f"  {s.at:%H:%M} {s.asset:12} {s.direction.upper():4} {r}")
        rs = [r for _, r in results]
        wins = sum(r.startswith("WIN") for r in rs)
        losses, draws = rs.count("LOSS"), sum(r.startswith("DRAW") for r in rs)
        print(f"  Backtest: {wins}W {losses}L {draws}D" + (f", {rs.count('no data')} no data" if "no data" in rs else "")
              + (f" ({wins * 100 // (wins + losses)}% won)" if wins + losses else ""))
        return sorted(results, key=lambda x: x[0].at)

    async def quotex_history(self, day: str) -> list[dict]:
        """Quotex's own trade history for one day (YYYY-MM-DD, UTC), as trades.csv-style rows."""
        from curl_cffi.requests import AsyncSession

        kind = "demo" if self.cfg["account"] == "PRACTICE" else "live"
        proxies = {"http": self.cfg["proxy"], "https": self.cfg["proxy"]} if self.cfg["proxy"] else None
        rows = []
        async with AsyncSession(impersonate="chrome", proxies=proxies) as http:
            for page in range(1, 50):
                r = await http.get(f"https://{self.cfg['host']}/api/v1/cabinets/trades/history/type/{kind}"
                                   f"?page={page}&dateFrom={day}&dateTo={day}",
                                   headers={"Cookie": self.cookies, "Accept": "application/json"})
                r.raise_for_status()
                items = r.json().get("data") or []
                for t in items:
                    profit = float(t["profit"])
                    rows.append({"time": datetime.fromtimestamp(t["open_time_timestamp"]).isoformat(timespec="seconds"),
                                 "signal": t["ticket"], "asset": t["symbol"], "level": "0", "entry": "",
                                 "amount": t["amount"], "profit": profit,
                                 "result": "win" if profit > 0 else "loss" if profit < 0 else "draw"})
                if len(items) < 10:
                    break
        return sorted(rows, key=lambda r: r["time"])

    def my_trades(self) -> list[dict]:
        return [r for r in read_trades() if r["profile"] == self.cfg["profile"] and r["account"] == self.cfg["account"]]


CLOCK_OFFSET = 0.0  # this PC's clock minus Quotex's, seconds (Bot.clock_sample)


def now() -> float:
    """Quotex time (unix s): every entry and gale is timed on it, not on this PC's clock."""
    return time.time() - CLOCK_OFFSET


TASKS: set[asyncio.Task] = set()  # asyncio keeps only weak refs to tasks


def spawn(coro, what: str) -> asyncio.Task:
    """Run in the background; an error is printed instead of silently killing the trade."""
    async def run():
        try:
            await coro
        except Exception as e:
            print(f"  ERROR in {what}: {e!r}")
    task = asyncio.create_task(run())
    TASKS.add(task)
    task.add_done_callback(TASKS.discard)
    return task


async def sleep_until(t: float) -> None:
    """Coarse sleep, then a 1ms-step finish for accuracy."""
    while (left := t - now()) > 0.05:
        await asyncio.sleep(left - 0.05)
    while now() < t:
        await asyncio.sleep(0.001)


LINES: asyncio.Queue | None = None  # stdin lines, read by one background thread


def start_stdin_reader() -> None:
    global LINES
    LINES = asyncio.Queue()
    loop = asyncio.get_running_loop()

    def pump():
        while True:
            try:
                line = input()
            except EOFError:
                line = None
            loop.call_soon_threadsafe(LINES.put_nowait, line)
            if line is None:
                return

    import threading
    threading.Thread(target=pump, daemon=True).start()


async def read_line(prompt: str) -> str:
    if LINES is None:
        return await asyncio.to_thread(input, prompt)
    print(prompt, end="", flush=True)
    line = await LINES.get()
    if line is None:
        raise SystemExit("Input closed.")
    return line


async def read_list() -> str:
    """A paste ends when no new line arrives for 0.6s after an empty line, so blank lines
    inside a list (between signal blocks, after a header) don't cut it."""
    print("\nPaste the signal list, then an empty line (or type: stats / history / backtest [-3 +6 ...]):")
    lines: list[str] = []
    while True:
        wait = 0.6 if lines and not lines[-1].strip() else None
        try:
            line = await asyncio.wait_for(LINES.get(), wait)
        except asyncio.TimeoutError:
            return "\n".join(lines)
        if line is None:
            raise SystemExit("Input closed.")
        if not lines and (line.strip().lower() in ("stats", "history") or line.strip().lower().startswith("backtest")):
            return line.strip().lower()
        if lines or line.strip():
            lines.append(line)


async def backtest_list(bot: Bot, text: str, offsets: list[float], tz: timezone) -> list[tuple[str, list]]:
    """Backtest a list once per UTC offset (none = the list's own or the profile's timezone)."""
    names = [(i[1], i[2]) for i in bot.broker.api.instruments]
    out = []
    for off in offsets or [None]:
        btz = timezone(timedelta(hours=off)) if off is not None else (list_timezone(text) or tz)
        print(f"\n== Times read as {btz} ==")
        try:
            out.append((str(btz), await bot.backtest(past_signals(text, btz, datetime.now(timezone.utc), names or None,
                                                                   force_tz=off is not None))))
        except Exception as e:
            print(f"  Backtest failed: {e!r}")
    return out


async def start_list(bot: Bot, text: str, tz: timezone) -> list[tuple[Signal, asyncio.Task]]:
    """Parse a pasted list, backtest its passed signals, schedule the upcoming ones."""
    if list_tz := list_timezone(text):
        print(f"  (times read as {list_tz}, written in the list)")
    names = [(i[1], i[2]) for i in bot.broker.api.instruments]
    unknown: list[str] = []
    passed: list[Signal] = []
    signals = bot.schedule(parse_signals(text, tz, datetime.now(timezone.utc), names or None,
                                         unknown=unknown, passed=passed))
    for line in unknown:
        print(f"  not understood (pair not on Quotex?): {line}")
    if passed:
        try:
            await bot.backtest(passed)
        except Exception as e:
            print(f"  Backtest failed: {e!r}")
    if not signals:
        print("No upcoming signals found.")
        return []
    for s in signals:
        print(f"  {s.at:%Y-%m-%d %H:%M} {s.asset:12} {s.direction.upper():4} M{s.duration // 60}")
    print(f"Scheduled {len(signals)} trades. You can paste another list any time.")
    return [(s, spawn(bot.run_signal(s), f"{s.at:%H:%M} {s.asset}")) for s in signals]


async def main() -> None:
    cfg = load_settings()
    patch_pyquotex(cfg["proxy"])
    tz = timezone(timedelta(hours=cfg["utc_offset"]))
    bot = Bot(cfg)
    start_stdin_reader()
    await bot.connect()
    spawn(bot.keepalive(), "keepalive")
    while True:
        text = await read_list()
        if text == "stats":
            print_stats(bot.my_trades(), bot.started)
            continue
        if text == "history":  # Quotex's own records: every trade today, also ones made by hand
            try:
                rows = await bot.quotex_history(datetime.now(timezone.utc).date().isoformat())
                print(stats_line("Quotex today", rows) if rows else "No trades on Quotex today.")
            except Exception as e:
                print(f"Could not load Quotex history: {e!r}")
            continue
        if text.startswith("backtest"):  # backtest [UTC offsets]: score any list on the last 24h of candles
            try:
                offsets = [float(o.replace("−", "-")) for o in text.split()[1:]]
            except ValueError:
                print("Usage: backtest   or   backtest -3 +6 5.5   (UTC offsets to try)")
                continue
            print("Backtest: paste the list (times count as their last occurrence in the past 24h).")
            await backtest_list(bot, await read_list(), offsets, tz)
            continue
        await start_list(bot, text, tz)


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\nStopped.")
