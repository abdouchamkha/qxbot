from datetime import datetime, timedelta, timezone

from signals import parse_signals

TZ = timezone(timedelta(hours=-3))
NOW = datetime(2026, 11, 6, 10, 0, tzinfo=TZ)
NAMES = [("EURUSD", "EUR/USD"), ("EURUSD_otc", "EUR/USD (OTC)"), ("GBPJPY", "GBP/JPY"),
         ("BRLUSD_otc", "USD/BRL (OTC)"), ("BTCUSD_otc", "Bitcoin (OTC)"), ("XAUUSD", "Gold"),
         ("XAUUSD_otc", "Gold (OTC)"), ("AUDCAD_otc", "AUD/CAD (OTC)"), ("GBPUSD", "GBP/USD")]


def parsed(text, names=None, tz=TZ):
    return [(s.asset, s.at.strftime("%H:%M"), s.duration, s.direction)
            for s in parse_signals(text, tz, NOW, names)]


def test_classic_lines_with_noise():
    text = """🔥 VIP SIGNALS 🔥
M1 NZDJPY-OTC 10:03 PUT  ✅
M5 EURUSD 10:45 CALL ✅✅"""
    assert parsed(text) == [("NZDJPY_otc", "10:03", 60, "put"), ("EURUSD", "10:45", 300, "call")]


def test_fancy_font_comma_format():
    assert parsed("𝙰𝚄𝙳𝙽𝚉𝙳-𝙾𝚃𝙲,𝟷𝟾:𝟻𝟻 𝙼𝟷 𝙲𝙰𝙻𝙻") == [("AUDNZD_otc", "18:55", 60, "call")]


def test_multiline_blocks():
    text = """📊 EUR/USD (OTC)
⏰ 14:30
⌛ 5 min
🟢 BUY

📊 GBP/JPY
⏰ 14:40
⌛ 1 minute
🔴 SELL"""
    assert parsed(text, NAMES) == [("EURUSD_otc", "14:30", 300, "call"), ("GBPJPY", "14:40", 60, "put")]


def test_header_expiry_separators_and_words():
    text = """Expiração: M5
14:30 - GBP/JPY - VENDA
14.35 ; EUR-USD ; COMPRA
14h40 AUD_CAD OTC ⬆️"""
    assert parsed(text) == [("GBPJPY", "14:30", 300, "put"), ("EURUSD", "14:35", 300, "call"),
                            ("AUDCAD_otc", "14:40", 300, "call")]


def test_timezone_written_in_list_overrides_setting():
    s = parse_signals("Timezone: UTC+1\nM1 EURUSD 15:00 CALL", TZ, NOW)
    assert s[0].at.utcoffset() == timedelta(hours=1) and s[0].at.hour == 15


def test_prices_and_dates_are_not_times():
    text = """📅 06.11.2026
EURUSD entry 1.12935 at 14:30 CALL"""
    assert parsed(text) == [("EURUSD", "14:30", 60, "call")]


def test_names_from_quotex_list_and_otc_fallback():
    text = """Bitcoin OTC 15:00 call 1 min
GOLD 15:05 PUT M5
USD/BRL 15:10 PUT"""
    assert parsed(text, NAMES) == [("BTCUSD_otc", "15:00", 60, "call"), ("XAUUSD", "15:05", 300, "put"),
                                   ("BRLUSD_otc", "15:10", 60, "put")]  # USD/BRL exists only as OTC


def test_arabic_and_glued_otc():
    assert parsed("EUR/USD 14:30 شراء 5 دقائق\nEURUSDOTC 14:35 بيع") == [
        ("EURUSD", "14:30", 300, "call"), ("EURUSD_otc", "14:35", 60, "put")]


def test_seconds_and_otc_header():
    text = """OTC SIGNALS
EURUSD 14:30:00 CALL 30s
GBPUSD 14:31 DOWN"""
    assert parsed(text) == [("EURUSD_otc", "14:30", 30, "call"), ("GBPUSD_otc", "14:31", 60, "put")]


def test_garbage_gives_nothing():
    assert parsed("Hello! Join our VIP channel 🚀 profit 85% today, win rate 90%") == []


def test_unknown_pair_is_reported():
    unknown = []
    assert parse_signals("ABC/XYZ OTC 14:30 CALL\nEURUSD 14:31 PUT", TZ, NOW, NAMES, unknown=unknown)[0].asset == "EURUSD"
    assert unknown == ["ABC/XYZ OTC 14:30 CALL"]


def test_slash_pair_with_underscore_otc_and_dash():
    text = """توقيت المنصة 06:00+ ❤️
مدة الصفقة 1 دقيقة ❤️

❒ 𝚄𝚂𝙳/𝙱𝙳𝚃_𝙾𝚃𝙲 𝙼𝟷 — 𝙿𝚄𝚃 𝟷𝟶:𝟹𝟺✅.
❒ 𝚄𝚂𝙳/𝙼𝚇𝙽_𝙾𝚃𝙲 𝙼𝟷 — 𝙱𝚄𝚈 𝟷𝟷:𝟺𝟷"""
    names = NAMES + [("USDBDT_otc", "USD/BDT (OTC)"), ("USDMXN_otc", "USD/MXN (OTC)")]
    assert parsed(text, names) == [("USDBDT_otc", "10:34", 60, "put"), ("USDMXN_otc", "11:41", 60, "call")]
