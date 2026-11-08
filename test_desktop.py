import asyncio
import json
import urllib.request
from datetime import datetime, timedelta, timezone

import pytest

import bot as qx
from desktop.engine import Engine, LogSink, clean_settings, result_cards
from desktop.server import make_server


@pytest.fixture
def engine(tmp_path, monkeypatch):
    monkeypatch.setattr(qx, "CONFIG_FILE", tmp_path / "config.json")
    monkeypatch.setattr(qx, "TRADES_FILE", tmp_path / "trades.csv")
    e = Engine(LogSink())
    e.start()
    yield e
    e.loop.call_soon_threadsafe(e.loop.stop)


class FakeApp:
    stopping = False

    def quit(self, stop=False):
        return {}

    def focus(self):
        pass

    def shortcut(self):
        return {}


def test_log_sink_splits_lines_and_routes_print(tmp_path):
    sink = LogSink(tmp_path / "gui.log")
    print("first\nsecond", file=sink)
    sink.write("partial ")
    sink.write("done\n\n")
    texts = [x[1][9:] for x in sink.since(0)]
    assert texts == ["first", "second", "partial done"]
    assert sink.since(2)[0][1].endswith("partial done") and sink.since(3) == []
    assert "partial done" in (tmp_path / "gui.log").read_text()


def test_clean_settings_types_and_validation():
    d = clean_settings({"amount": "2,5", "gales": "1", "utc_offset": "−3", "pending": True, "pre_entry_ms": "120",
                        "account": "practice"})
    assert d["amount"] == 2.5 and d["gales"] == 1 and d["utc_offset"] == -3.0 and d["pending"] == "y"
    assert d["pre_entry_ms"] == 120 and d["account"] == "PRACTICE" and clean_settings({})["pre_entry_ms"] == "auto"
    with pytest.raises(ValueError):
        clean_settings({"amount": "0"})
    with pytest.raises(ValueError):
        clean_settings({"account": "LIVE"})


def test_result_cards_fold_gales():
    row = lambda sig, lv, res, p, t: {"signal": sig, "level": str(lv), "result": res, "profit": str(p), "amount": "1",
                                      "time": t, "asset": "EURUSD_otc", "direction": "call"}
    cards = result_cards([row("A", 0, "loss", -1, "2026-11-08T10:00:00"), row("A", 1, "win", 0.85, "2026-11-08T10:01:00"),
                          row("B", 0, "loss", -1, "2026-11-08T10:05:00"), row("C", 0, "draw", 0, "2026-11-08T10:07:00")])
    assert [(c["result"], c["profit"], c["amount"]) for c in cards] == [("DRAW", 0, 1), ("LOSS", -1, 1), ("WIN G1", -0.15, 2)]


def test_profile_save_keeps_password_only_when_remembered(engine):
    engine.save_profile({"name": "p1", "email": "a@b.c", "password": "x", "remember": True, "amount": "3"})
    assert json.loads(qx.CONFIG_FILE.read_text())["profiles"]["p1"]["password"] == "x"
    assert "password" not in engine.profile("p1")
    assert engine.profile("p1")["has_password"] and engine.profile("p1")["amount"] == 3.0
    engine.save_profile({"name": "p1", "remember": False})
    assert "password" not in json.loads(qx.CONFIG_FILE.read_text())["profiles"]["p1"]
    engine.set_lang("ar")
    assert engine.profiles() == {"names": ["p1"], "last": "p1", "lang": "ar"}


def test_pin_prompt_goes_through_gui(engine):
    fut = asyncio.run_coroutine_threadsafe(qx.read_line("Quotex PIN: "), engine.loop)  # what browser_session calls
    for _ in range(100):
        if engine.snapshot()["pin"]:
            break
        asyncio.run(asyncio.sleep(0.01))
    assert engine.snapshot()["pin"]
    engine.submit_pin(" 123456 ")
    assert fut.result(2) == "123456" and not engine.snapshot()["pin"]
    with pytest.raises(ValueError):
        engine.submit_pin("1")


def test_preview_upcoming_passed_unknown_and_duplicates(engine):
    engine.save_profile({"name": "default", "utc_offset": "0"})
    now = datetime.now(timezone.utc)
    soon, later, past = [(now + d).strftime("%H:%M") for d in (timedelta(minutes=30), timedelta(minutes=30),
                                                                  timedelta(minutes=-30))]
    p = engine.preview(f"M1 EURUSD-OTC {soon} CALL\nM1 GBPUSD-OTC {later} PUT\nM1 EURUSD {past} PUT\nM1 ABC/XYZ 10:00 CALL")
    assert [s["asset"] for s in p["signals"]] == ["EURUSD_otc", "GBPUSD_otc"]
    assert [s["dup"] for s in p["signals"]] == [False, True]  # overlap off: same minute is skipped
    assert [s["asset"] for s in p["passed"]] == ["EURUSD"] and p["unknown"] == ["M1 ABC/XYZ 10:00 CALL"]
    assert p["tz"] == "UTC" and not p["checked"]
    with pytest.raises(ValueError):
        engine.start_list("M1 EURUSD 10:00 CALL")  # not connected


def test_server_token_static_api_and_events(engine):
    server = make_server(engine, FakeApp(), 0, "tok")
    base = f"http://127.0.0.1:{server.server_address[1]}"

    def post(name, body, token="tok"):
        req = urllib.request.Request(f"{base}/api/{name}", json.dumps(body).encode(), {"X-Token": token})
        try:
            with urllib.request.urlopen(req, timeout=5) as r:
                return r.status, json.load(r)
        except urllib.error.HTTPError as e:
            return e.code, json.load(e)

    try:
        assert b"<title>QXBot</title>" in urllib.request.urlopen(base + "/", timeout=5).read()
        assert urllib.request.urlopen(base + "/fonts/Cairo-400.ttf", timeout=5).status == 200
        with pytest.raises(urllib.error.HTTPError):
            urllib.request.urlopen(base + "/../bot.py", timeout=5)
        assert post("profiles", {}, token="bad")[0] == 403
        assert post("profiles", {}) == (200, {"names": [], "last": "default", "lang": "en"})
        assert post("settings", {"name": "x", "amount": "-1"})[0] == 400
        status, body = post("preview", {"text": "nothing here"})
        assert status == 200 and body["signals"] == []
        assert post("start", {"text": "M1 EURUSD 10:00 CALL"}) == (400, {"error": "Not connected to Quotex"})
        print("hello from the engine", file=engine.sink)
        with urllib.request.urlopen(f"{base}/api/events?t=tok", timeout=5) as r:
            got = b""
            while b"event: state" not in got:
                got += r.readline()
        assert b"hello from the engine" in got
    finally:
        server.shutdown()


def test_connect_shows_connecting_then_error(engine, monkeypatch):
    import threading
    gate = threading.Event()

    class FailingBot:
        def __init__(self, cfg):
            self.cfg = cfg

        async def connect(self):
            await asyncio.to_thread(gate.wait, 5)
            raise RuntimeError("Login did not reach the trade page")

    monkeypatch.setattr(qx, "Bot", FailingBot)
    with pytest.raises(ValueError):
        engine.connect({"name": "p", "email": "", "password": ""})  # nothing to log in with
    engine.connect({"name": "p", "email": "a@b.c", "password": "x", "remember": False})
    asyncio.run(asyncio.sleep(0.2))
    assert engine.snapshot()["status"] == "connecting"
    gate.set()
    for _ in range(100):
        if engine.status == "error":
            break
        asyncio.run(asyncio.sleep(0.02))
    assert engine.snapshot()["status"] == "error" and "trade page" in engine.snapshot()["error"]


def test_schedule_state_follows_tasks_and_stop(engine, monkeypatch):
    from types import SimpleNamespace
    from signals import parse_signals
    sigs = parse_signals("M1 EURUSD 10:00 CALL\nM1 GBPUSD 10:01 PUT", timezone.utc,
                         datetime(2026, 11, 8, 9, 0, tzinfo=timezone.utc))

    async def fake_start_list(bot, text, tz):
        async def quick():
            pass
        return [(sigs[0], qx.spawn(quick(), "a")), (sigs[1], qx.spawn(asyncio.sleep(60), "b"))]

    class FakeBot:
        pending_lock, taken, cancelled = None, {1.0}, False

        balance, clock, clock_ok = 0.0, "", None

        async def cancel_pending(self):
            self.cancelled = True

        def my_trades(self):
            return []

    monkeypatch.setattr(qx, "start_list", fake_start_list)
    b = FakeBot()
    engine.run(asyncio.sleep(0))
    b.pending_lock = engine.run(_lock())
    engine.bot, engine.status, engine.cfg = b, "online", {"utc_offset": 0}
    assert engine.start_list("x") == {"scheduled": 2}
    engine.run(asyncio.sleep(0.05))
    assert [x["state"] for x in engine.snapshot()["schedule"]] == ["done", "waiting"] and engine.waiting() == 1
    assert engine.stop() == {"cancelled": 1}
    engine.run(asyncio.sleep(0.05))
    assert [x["state"] for x in engine.snapshot()["schedule"]] == ["done", "cancelled"]
    assert b.cancelled and not b.taken


async def _lock():
    return asyncio.Lock()
