"""Signal-list parser: reads most Telegram signal formats.

Handles fancy Unicode fonts, any field order, one-line signals ("M1 EURUSD-OTC 14:30 CALL")
and multi-line blocks ("📊 EUR/USD (OTC)" / "⏰ 14:30" / "⌛ 5 min" / "🟢 BUY"), arrows and
emoji as directions, English/Portuguese/Arabic words, list-wide headers ("Expiry M5",
"Timezone UTC-3", "OTC signals"). Pairs are matched against Quotex's own symbol list when
it is given (forex, crypto, indices, commodities, by symbol or by name like "Bitcoin").
"""

import re
import unicodedata
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone


@dataclass
class Signal:
    duration: int  # seconds
    asset: str  # Quotex symbol, e.g. NZDJPY_otc
    at: datetime  # aware entry time
    direction: str  # call | put


CURRENCIES = set(
    "USD EUR GBP JPY AUD NZD CAD CHF CNY CNH HKD SGD SEK NOK DKK PLN TRY ZAR MXN BRL ARS INR IDR PKR BDT "
    "NGN EGP PHP THB MYR VND KRW COP CLP DZD MAD TND SAR AED QAR KES UAH RUB CZK HUF ILS XAU XAG".split()
)
CALL_WORDS = r"CALL|BUY|UP|HIGHER|ABOVE|COMPRA|ACIMA|ALTA|SUBIDA|شراء|صعود|اعلى|أعلى"
PUT_WORDS = r"PUT|SELL|DOWN|LOWER|BELOW|VENDA|ABAIXO|BAIXA|QUEDA|بيع|هبوط|ادنى|أدنى|نزول"
CALL_MARKS = "⬆↑🔼⏫📈🟢🟩⤴"
PUT_MARKS = "⬇↓🔽⏬📉🔴🟥⤵"

TIME_RE = re.compile(r"(?<![\d.:/])([01]?\d|2[0-3])\s?[:hH]\s?([0-5]\d)(?![\d/])")
TIME_DOT_RE = re.compile(r"(?<![\d.:/])([01]?\d|2[0-3])\.([0-5]\d)(?![\d./])")  # 14.30, but not prices or dates
DURATION_RES = [
    (re.compile(r"\bM\s?(\d{1,3})\b"), 60),  # M1, M5
    (re.compile(r"\bH(\d)\b"), 3600),
    (re.compile(r"\b(\d{1,3})\s?(?:M|MIN|MINS|MINUTE|MINUTES|MINUTO|MINUTOS)\b|(\d{1,3})\s?(?:دقيقة|دقائق|دقيقه)"), 60),
    (re.compile(r"\b(\d{1,3})\s?(?:S|SEC|SECS|SECOND|SECONDS|SEGUNDOS)\b"), 1),
    (re.compile(r"\b(\d)\s?(?:H|HR|HOUR|HOURS|HORA|HORAS)\b"), 3600),
]
TZ_RE = re.compile(r"\b(?:UTC|GMT)\s?([+\-−])\s?(\d{1,2})(?:[:.]?(\d{2}))?")
OTC_RE = re.compile(r"OTC")


def symbol_index(names: list[tuple[str, str]]) -> dict[str, dict[bool, str]]:
    """Quotex (symbol, label) rows -> {key: {is_otc: symbol}}; keys are the symbol base and the label."""
    index: dict[str, dict[bool, str]] = {}
    for symbol, label in names:
        otc = symbol.lower().endswith("_otc")
        base = symbol[:-4] if otc else symbol
        for key in {base.upper().lstrip("#"), re.sub(r"\(OTC\)|[^A-Z0-9]", "", label.upper())}:
            if len(key) >= 3:
                index.setdefault(key, {})[otc] = symbol
    return index


def _clean(line: str) -> str:
    line = unicodedata.normalize("NFKC", line).upper()
    # EUR/USD, EUR-USD, EUR_USD, EUR / USD -> EURUSD (not "-OTC")
    return re.sub(r"\b([A-Z]{3})\s?[/\\\-_|.]\s?(?!OTC(?![A-Z]))([A-Z]{3})(?![A-Z])", r"\1\2", line)


def _pair(line: str, index: dict | None) -> str | None:
    for token in re.findall(r"#?[A-Z][A-Z0-9&]{2,14}", line):
        token = token.lstrip("#")
        for key in (token, token.removesuffix("OTC")):
            if index is not None:
                if key in index:
                    return key
            elif len(key) == 6 and key[:3] in CURRENCIES and key[3:] in CURRENCIES:
                return key
    return None


def _direction(line: str) -> str | None:
    words = re.search(rf"(?<![A-Z])(?:({CALL_WORDS})|({PUT_WORDS}))(?![A-Z])", line)
    marks = [("call" if ch in CALL_MARKS else "put") for ch in line if ch in CALL_MARKS + PUT_MARKS]
    if words:
        return "call" if words.group(1) else "put"
    return marks[0] if marks else None


def _duration(line: str) -> int | None:
    for regex, unit in DURATION_RES:
        m = regex.search(line)
        if m:
            value = int(next(g for g in m.groups() if g)) * unit
            if 5 <= value <= 4 * 3600:
                return value
    return None


def _time(line: str) -> tuple[int, int] | None:
    m = TIME_RE.search(line) or TIME_DOT_RE.search(line)
    return (int(m.group(1)), int(m.group(2))) if m else None


def _fields(raw: str, index: dict | None) -> dict:
    line = _clean(raw)
    no_time = TIME_RE.sub(" ", line)  # so "14:30" is not read as a duration
    found = {"pair": _pair(no_time, index), "time": _time(line), "direction": _direction(line),
             "duration": _duration(TZ_RE.sub(" ", no_time)), "otc": bool(OTC_RE.search(line))}
    return {k: v for k, v in found.items() if v}


def list_timezone(text: str) -> timezone | None:
    m = TZ_RE.search(unicodedata.normalize("NFKC", text).upper())
    if not m:
        return None
    sign = -1 if m.group(1) in "-−" else 1
    return timezone(sign * timedelta(hours=int(m.group(2)), minutes=int(m.group(3) or 0)))


def parse_signals(text: str, tz: timezone, now: datetime, names: list[tuple[str, str]] | None = None,
                  default_duration: int = 60, unknown: list[str] | None = None) -> list[Signal]:
    """Signals in time order. A timezone written in the list (UTC-3, GMT+1) overrides `tz`.
    Past times within 12h are dropped (already happened today); older ones roll to tomorrow.
    Lines with a time and a direction but no pair Quotex knows are added to `unknown`."""
    tz = list_timezone(text) or tz
    index = symbol_index(names) if names else None
    out: list[Signal] = []
    header = {"duration": default_duration, "otc": False}
    block: dict = {}

    def emit(f: dict) -> None:
        hh, mm = f["time"]
        at = now.astimezone(tz).replace(hour=hh, minute=mm, second=0, microsecond=0)
        if at <= now:
            if now - at < timedelta(hours=12):
                return
            at += timedelta(days=1)
        otc = f.get("otc", False) or header["otc"]
        asset = f["pair"] + ("_otc" if otc else "")
        if index is not None:
            variants = index[f["pair"]]
            asset = variants.get(otc) or variants.get(not otc)  # e.g. a pair Quotex only has as OTC
        out.append(Signal(f.get("duration", header["duration"]), asset, at, f["direction"]))

    def complete(f: dict) -> bool:
        return {"pair", "time", "direction"} <= f.keys()

    def flush() -> None:
        nonlocal block
        if complete(block):
            emit(block)
        block = {}

    for raw in text.splitlines() + [""]:
        f = _fields(raw, index)
        keys = f.keys() - {"otc"}
        if unknown is not None and {"time", "direction"} <= keys and "pair" not in f:
            unknown.append(raw.strip())
        if complete(f):  # whole signal on one line
            flush()
            emit(f)
        elif not keys:  # blank/noise line, or an "OTC" line
            if f.get("otc"):
                (block if block else header)["otc"] = True
            elif complete(block):
                flush()
        elif keys == {"duration"} and not block:  # "Expiry: M5" header
            header["duration"] = f["duration"]
            header["otc"] = header["otc"] or f.get("otc", False)
        else:
            if keys & block.keys() & {"pair", "time", "direction"}:  # a field repeats: next signal
                flush()
            block.update(f)
    return sorted(out, key=lambda s: s.at)
