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
import time
import unicodedata
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from pathlib import Path
from urllib.parse import urlparse

HERE = Path(__file__).parent
CONFIG_FILE = HERE / "config.json"
PROFILE_DIR = HERE / "login_profile"
TRADES_FILE = HERE / "trades.csv"
TRADE_FIELDS = ["time", "profile", "account", "signal", "asset", "direction", "level", "amount",
                "entry", "delay_ms", "open_price", "result", "profit"]

# one line = one signal; fields in any order: "M1 NZDJPY-OTC 00:03 PUT" or "NZDJPY-OTC,00:03 M1 PUT"
SIGNAL_FIELDS = [re.compile(r"\bM(\d+)\b", re.I), re.compile(r"\b([A-Z]{6})(-OTC)?\b", re.I),
                 re.compile(r"\b(\d{1,2}):(\d{2})\b"), re.compile(r"\b(CALL|PUT)\b", re.I)]


@dataclass
class Signal:
    duration: int  # seconds
    asset: str  # pyquotex name, e.g. NZDJPY_otc
    at: datetime  # aware entry time
    direction: str  # call | put


# ---------------------------------------------------------------- parsing

def parse_signals(text: str, tz: timezone, now: datetime) -> list[Signal]:
    """Parse 'M1 NZDJPY-OTC 00:03 PUT' lines. Past times within 12h are dropped
    (already happened today); older ones roll to tomorrow (list for next day)."""
    out = []
    for line in unicodedata.normalize("NFKC", text).splitlines():  # NFKC: fancy Telegram fonts -> ASCII
        found = [r.search(line) for r in SIGNAL_FIELDS]
        if not all(found):
            continue
        (mins,), (pair, otc), (hh, mm), (direction,) = (m.groups() for m in found)
        if int(hh) > 23 or int(mm) > 59:
            continue
        at = now.astimezone(tz).replace(hour=int(hh), minute=int(mm), second=0, microsecond=0)
        if at <= now:
            if now - at < timedelta(hours=12):
                continue
            at += timedelta(days=1)
        asset = pair.upper() + ("_otc" if otc else "")
        out.append(Signal(int(mins) * 60, asset, at, direction.lower()))
    return sorted(out, key=lambda s: s.at)


def is_losing(direction: str, open_price: float, price: float) -> bool:
    """Equal price is a refund (draw) on Quotex, so not a loss."""
    return price < open_price if direction == "call" else price > open_price


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
    delays = [int(r["delay_ms"]) for r in rows if r["entry"] == "open"]
    if delays:
        print(f"Entry delay at candle open: avg {sum(delays) / len(delays):+.0f}ms, max {max(delays):+d}ms")
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
    "headless": "n", "safe_pips": 0.0, "pre_entry_ms": 0, "overlap": "n", "min_payout": 80,
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
        d["pre_entry_ms"] = ask("Pre-entry ms: send this early so the order reaches Quotex at :00, about half "
                                "the ping the bot prints (0 = wait for the candle's first tick)", int(d["pre_entry_ms"]))
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
    print(f"Using profile '{name}': {d['email']} {d['account']} ${d['amount']} UTC{d['utc_offset']:+g} gales={d['gales']} safe_pips={d['safe_pips']:g} "
          f"pre_entry={d['pre_entry_ms']}ms overlap={d['overlap']} "
          f"min_payout={d['min_payout']}%")
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
                    await page.fill('input[name="code"]:visible', input("Quotex PIN sent to your email: ").strip())
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
        self.ping = 0.5  # last measured order round trip, seconds  # candle starts that have a list signal

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
        print(f"Connected. {self.cfg['account']} balance: {await b.get_balance()}")

    def _hook(self, api) -> None:
        set_event = api.event_registry.set_event

        async def capture(key, data=None):
            if key == "buy_confirmed" and isinstance(data, dict):
                fut = self.orders.pop(str(data.get("requestId")), None)
                if not fut and not data.get("closePrice"):  # pyquotex also fires this for closed deals: skip those
                    fut = self.orders.pop(data.get("asset", ""), None)
                if fut and not fut.done():
                    fut.set_result(data)
            return await set_event(key, data)

        api.event_registry.set_event = capture

    async def keepalive(self) -> None:
        """pyquotex already pings every 5s; this only rebuilds a dead session."""
        while True:
            await asyncio.sleep(30)
            try:
                if not await self.broker.check_connect():
                    print("Connection lost, reconnecting...")
                    await self.connect()
            except Exception as e:
                print(f"Reconnect failed: {e!r}; retrying in 30s")

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
            sent = time.time()
        try:
            data = await asyncio.wait_for(fut, 10)
            self.ping = time.time() - sent
            ping = self.ping * 1000
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
        return max(0.5, self.cfg["pre_entry_ms"] / 1000 + 0.3)

    async def wait_entry(self, s: Signal, at: float, margin: float) -> bool:
        """Hold self.chart. Returns once it is time to send; False = skip this signal.
        Quotex opens an order on the latest price tick it holds when the order arrives.
        Default: wait until we have a tick stamped >= T (the server has it too), so it opens
        in the new candle, ping late. Pre-entry: send early so it arrives at about :00; it then
        opens on the last tick before :00 or the first after it (same expiry either way)."""
        if self.broker.api.current_asset != s.asset:
            await self.show(s, at)
        if self.cfg["pre_entry_ms"] and not margin:
            await sleep_until(at - self.cfg["pre_entry_ms"] / 1000)
            # Fast pair (new price more often than our ping): arriving at :00 opens within one tick of it.
            # Slow pair: the last price can be seconds old, so wait for the candle's first price instead;
            # the order then lands on that price (the candle's open) before the next one comes.
            if median_gap(self.broker.api.realtime_price.get(s.asset, [])) < self.ping:
                return True
        while self.tick_time(s.asset) < at and time.time() < at + 1.5:
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
            if time.time() > deadline:
                print(f"  {s.asset} {s.direction.upper()} SKIPPED: price never reached safe entry "
                      f"{target:.6g} (candle open {candle_open}) in the first half of the candle")
                return False
            await asyncio.sleep(0.002)
        return True

    def losing(self, s: Signal, data: dict) -> bool:
        price, open_price = self.price(s.asset), data.get("openPrice")
        return price is not None and open_price is not None and is_losing(s.direction, float(open_price), price)

    async def run_signal(self, s: Signal) -> None:
        at, amount = s.at.timestamp(), self.cfg["amount"]
        signal = f"{s.at:%Y-%m-%d %H:%M} {s.asset} {s.direction}"
        await sleep_until(at - 15)
        info = await self.instrument(s)
        payout = info and self.broker.get_payout_by_asset(s.asset, "1" if s.duration < 300 else "5")
        if payout is not None and payout < self.cfg["min_payout"]:
            print(f"  {s.at:%H:%M} {s.asset} {s.direction.upper()} skipped: payout {payout}% < {self.cfg['min_payout']}%")
            return
        margin = self.cfg["safe_pips"] * pip(s.asset, info and info[4])
        async with self.chart:
            await self.show(s, at)
        for level in range(self.cfg["gales"] + 1):
            data = await self.place(s, at, amount, margin if level == 0 else 0.0)
            if not data:
                return
            asyncio.create_task(self.report(s, data, level, amount, signal, "safe" if margin and not level else "open"))
            if level == self.cfg["gales"]:
                return
            end = at + s.duration
            await sleep_until(end - 5)
            if not self.gale_blocked(end):
                async with self.chart:  # chart back on this pair: live price for the gale call, next candle ready
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
            at = end
            amount = round(amount * self.cfg["gale_multiplier"], 2)
            print(f"  gale {level + 1} on {s.asset}: ${amount}")

    async def instrument(self, s: Signal) -> list | None:
        """Fresh Quotex row for the pair: [id, name, label, type, decimals, ...]; payouts change during the day."""
        await self.broker.api.send_websocket_request('42["instruments/get"]')
        await asyncio.sleep(2)
        return next((i for i in self.broker.api.instruments if i[1] == s.asset), None)

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

    def my_trades(self) -> list[dict]:
        return [r for r in read_trades() if r["profile"] == self.cfg["profile"] and r["account"] == self.cfg["account"]]


async def sleep_until(t: float) -> None:
    """Coarse sleep, then a 1ms-step finish for accuracy."""
    while (left := t - time.time()) > 0.05:
        await asyncio.sleep(left - 0.05)
    while time.time() < t:
        await asyncio.sleep(0.001)


def read_list() -> str:
    print("\nPaste the signal list, then an empty line (or type: stats):")
    lines = []
    while (line := input()).strip() or not lines:
        if not lines and line.strip().lower() == "stats":
            return "stats"
        lines.append(line)
    return "\n".join(lines)


async def main() -> None:
    cfg = load_settings()
    patch_pyquotex(cfg["proxy"])
    tz = timezone(timedelta(hours=cfg["utc_offset"]))
    bot = Bot(cfg)
    await bot.connect()
    asyncio.create_task(bot.keepalive())
    while True:
        text = await asyncio.to_thread(read_list)
        if text == "stats":
            print_stats(bot.my_trades(), bot.started)
            continue
        signals = bot.schedule(parse_signals(text, tz, datetime.now(timezone.utc)))
        if not signals:
            print("No upcoming signals found.")
            continue
        for s in signals:
            print(f"  {s.at:%Y-%m-%d %H:%M} {s.asset:12} {s.direction.upper():4} M{s.duration // 60}")
        print(f"Scheduled {len(signals)} trades. You can paste another list any time.")
        for s in signals:
            asyncio.create_task(bot.run_signal(s))


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\nStopped.")
