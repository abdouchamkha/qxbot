from datetime import datetime, timedelta, timezone

from bot import is_losing, parse_signals, past_signals  # parse_signals re-exported from signals.py

TZ = timezone(timedelta(hours=-3))
LIST = """M1 NZDJPY-OTC 00:00 PUT  ✅
M1 NZDJPY-OTC 00:03 PUT    ✅
M1 NZDCAD-OTC 00:23 PUT  ✅
M5 EURUSD 00:45 CALL ✅"""


def test_parse_next_day_list():
    now = datetime(2026, 11, 4, 23, 50, tzinfo=TZ)
    s = parse_signals(LIST, TZ, now)
    assert [x.asset for x in s] == ["NZDJPY_otc", "NZDJPY_otc", "NZDCAD_otc", "EURUSD"]
    assert s[0].at == datetime(2026, 11, 5, 0, 0, tzinfo=TZ)
    assert s[0].direction == "put" and s[0].duration == 60 and s[3].duration == 300


def test_parse_skips_already_passed():
    now = datetime(2026, 11, 5, 0, 10, tzinfo=TZ)
    s = parse_signals(LIST, TZ, now)
    assert [x.at.minute for x in s] == [23, 45]


def test_timezone_conversion():
    now = datetime(2026, 11, 5, 2, 0, tzinfo=timezone.utc)  # 23:00 at UTC-3
    s = parse_signals("M1 EURUSD 23:30 CALL", TZ, now)
    assert s[0].at.astimezone(timezone.utc) == datetime(2026, 11, 5, 2, 30, tzinfo=timezone.utc)


def test_is_losing():
    assert is_losing("call", 1.0, 0.9) and not is_losing("call", 1.0, 1.0)
    assert is_losing("put", 1.0, 1.1) and not is_losing("put", 1.0, 1.0)


def test_read_config_migrates_old_file(tmp_path, monkeypatch):
    import json, bot
    monkeypatch.setattr(bot, "CONFIG_FILE", tmp_path / "config.json")
    assert bot.read_config() == {"last": "default", "profiles": {}}
    bot.CONFIG_FILE.write_text(json.dumps({"email": "a@b.c"}))
    assert bot.read_config()["profiles"]["default"]["email"] == "a@b.c"


def test_safe_price():
    from bot import safe_price
    assert safe_price("call", 1.0998, 1.0999) and not safe_price("call", 1.1, 1.0999)
    assert safe_price("put", 1.1001, 1.1) and not safe_price("put", 1.0999, 1.1)
    assert not safe_price("call", None, 1.0)


def test_summarize_martingale_signals():
    from bot import summarize
    row = lambda sig, lv, res, profit: {"signal": sig, "level": lv, "result": res, "profit": profit, "amount": 1}
    rows = [row("A", 0, "loss", -1), row("A", 1, "win", 0.8), row("B", 0, "loss", -1),
            row("C", 0, "draw", 0), row("D", 0, "win", 0.9)]
    m = summarize(rows)
    assert (m["wins"], m["losses"], m["draws"]) == (2, 2, 1)
    assert (m["signals_won"], m["signals_lost"]) == (2, 1)
    assert round(m["net"], 2) == -0.3 and round(m["max_drawdown"], 2) == 1.2 and m["loss_streak"] == 1


def test_overlap_off_keeps_first_signal_and_blocks_gales():
    from bot import Bot
    now = datetime(2026, 11, 5, 10, 0, tzinfo=TZ)
    sigs = parse_signals("M1 NZDJPY-OTC 10:05 PUT\nM1 AUDCAD-OTC 10:05 CALL\nM1 USDJPY-OTC 10:06 CALL", TZ, now)
    bot = Bot({"overlap": "n"})
    kept = bot.schedule(sigs)
    assert [s.asset for s in kept] == ["NZDJPY_otc", "USDJPY_otc"]
    assert bot.gale_blocked(kept[1].at.timestamp())  # 10:06 belongs to a list signal
    assert not bot.gale_blocked(kept[1].at.timestamp() + 60)
    assert len(Bot({"overlap": "y"}).schedule(sigs)) == 3


def test_parse_fancy_font_comma_format():
    now = datetime(2026, 11, 6, 18, 0, tzinfo=TZ)
    s = parse_signals("𝙰𝚄𝙳𝙽𝚉𝙳-𝙾𝚃𝙲,𝟷𝟾:𝟻𝟻 𝙼𝟷 𝙲𝙰𝙻𝙻\n𝙽𝚉𝙳𝙲𝙰𝙳-𝙾𝚃𝙲,𝟷𝟿:𝟹𝟺 𝙼𝟻 𝙿𝚄𝚃", TZ, now)
    assert [(x.asset, x.at.hour, x.at.minute, x.duration, x.direction) for x in s] == [
        ("AUDNZD_otc", 18, 55, 60, "call"), ("NZDCAD_otc", 19, 34, 300, "put")]


def test_median_gap():
    from bot import median_gap
    assert median_gap([{"time": t} for t in (0, 0.25, 0.5, 0.75, 5)]) == 0.25
    assert median_gap([{"time": 0}, {"time": 1}]) == float("inf")


def test_pip_from_decimals():
    from bot import pip
    assert pip("NZDCAD_otc", 5) == 0.0001 and pip("USDJPY_otc", 3) == 0.01 and abs(pip("XAGUSD_otc", 4) - 0.001) < 1e-12
    assert pip("USDJPY_otc") == 0.01


def test_daily_limits_and_balance(monkeypatch):
    import bot as botmod
    from bot import Bot
    today = datetime.now().date().isoformat()
    rows = [{"time": f"{today}T10:00:00", "profile": "p", "account": "PRACTICE", "profit": "-4.0"},
            {"time": "2020-01-01T10:00:00", "profile": "p", "account": "PRACTICE", "profit": "-50"}]
    monkeypatch.setattr(botmod, "read_trades", lambda: rows)
    b = Bot({"profile": "p", "account": "PRACTICE", "stop_loss": 5.0, "take_profit": 0.0, "pre_entry_ms": "auto"})
    b.balance = 100
    s = parse_signals("M1 EURUSD 23:59 CALL", TZ, datetime.now(TZ) - timedelta(days=1))[0]
    assert b.today_net() == -4.0 and b.can_trade(s, 1)
    assert not b.can_trade(s, 1, open_loss=1)  # losing gale step would reach -5
    b.balance = 0.5
    assert not b.can_trade(s, 1) and b.limit_reason() is None
    assert b.pre_ms() == 250  # auto, no ping measured yet
    b.pings.extend([0.4, 0.5, 0.6])
    assert b.pre_ms() == 250 and Bot({"pre_entry_ms": 120}).pre_ms() == 120


def test_backtest_result_with_gale():
    from bot import backtest_result
    s = parse_signals("M1 EURUSD 10:00 CALL", TZ, datetime(2026, 11, 5, 9, 0, tzinfo=TZ))[0]
    t = int(s.at.timestamp())
    c = lambda o, cl: {"open": o, "close": cl}
    assert backtest_result(s, {t: c(1, 2)}, 1) == "WIN"
    assert backtest_result(s, {t: c(2, 1), t + 60: c(1, 2)}, 1) == "WIN G1"
    assert backtest_result(s, {t: c(2, 1), t + 60: c(2, 1)}, 1) == "LOSS"
    assert backtest_result(s, {t: c(2, 1)}, 0) == "LOSS"
    assert backtest_result(s, {t: c(1, 1)}, 1) == "DRAW"
    assert backtest_result(s, {}, 1) == "no data"


def test_parse_collects_passed_signals():
    passed = []
    s = parse_signals(LIST, TZ, datetime(2026, 11, 5, 0, 10, tzinfo=TZ), passed=passed)
    assert [x.at.minute for x in s] == [23, 45]
    assert [(x.at.minute, x.direction) for x in passed] == [(0, "put"), (3, "put")]


def test_past_signals_puts_every_time_in_last_24h_and_can_override_list_tz():
    now = datetime(2026, 11, 8, 18, 0, tzinfo=timezone.utc)
    text = "TIMEZONE: UTC +06:00\nM1 USDBRL 00:04 PUT\nM1 USDBRL 23:50 CALL"
    s = past_signals(text, TZ, now)  # list tz +6: 00:04 = Nov 7 18:04 UTC, 23:50 = Nov 8 17:50 UTC
    assert [x.at.astimezone(timezone.utc) for x in s] == [datetime(2026, 11, 7, 18, 4, tzinfo=timezone.utc),
                                                          datetime(2026, 11, 8, 17, 50, tzinfo=timezone.utc)]
    s = past_signals(text, timezone(timedelta(hours=-3)), now, force_tz=True)  # 23:50-3 = 02:50 UTC, 00:04-3 = 03:04 UTC
    assert [x.at.astimezone(timezone.utc).hour for x in s] == [2, 3]
    assert all(now - timedelta(days=1) < x.at <= now for x in s)
