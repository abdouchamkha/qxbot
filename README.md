# qxbot

Paste a Telegram signal list in almost any format and it places each trade on Quotex at the exact candle time.

## Setup
```bash
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
.venv/bin/patchright install chromium   # Linux only; Windows uses the installed Edge/Chrome/Brave
.venv/bin/python bot.py
```
On start it asks for the settings below and saves them as named profiles in `config.json` (password too, if you say yes). Next run: Enter on the profile name, Enter on "Change settings?" and it starts.

| Setting | Default | Meaning |
|---|---|---|
| account | PRACTICE | PRACTICE (demo) or REAL |
| amount | 1 | $ per trade |
| utc_offset | -3 | timezone of the signal lists (a `UTC-3`/`GMT+1` written in the list overrides it) |
| gales / gale_multiplier | 0 / 2.2 | martingale levels and multiplier |
| pending | y | OTC entries as Quotex pending orders: Quotex opens them itself at :00 (see Timing) |
| pre_entry_ms | auto | direct entries: send this early so the order reaches Quotex at :00; auto = half the measured ping |
| overlap | n | n = one trade per minute (first list signal), a list signal cancels a gale on the same minute |
| min_payout | 80 | skip pairs paying less (%), checked 15-70s before the trade |
| safe_pips | 0 | optional: wait up to half the candle for the price to move this far against the signal (backtest: worse, keep 0) |
| stop_loss / take_profit | 0 / 0 | daily limits in $ (0 = off): no new trades or gales today once reached |

Type `backtest` (or `backtest -3 +6 5.5` to try timezones), then paste a list: every signal is scored at its last occurrence in the past 24h. Signals in a pasted list whose time already passed (within 12h) are also backtested on Quotex's 1-minute candles (open vs close, with the gale) and printed as WIN / WIN G1 / LOSS / DRAW.

Commands at the paste prompt: `stats` (session/today/all-time analytics from `trades.csv`), `history` (today's results from Quotex's own records, includes manual trades).

## Signal formats
`signals.py` reads one-line and multi-line signals, any field order, fancy Unicode fonts, and matches pairs against Quotex's own symbol list (forex, crypto, indices, commodities, by symbol or name like `Bitcoin`, `Gold`). Examples that all work (see `test_signals.py`):
```
M1 NZDJPY-OTC 00:03 PUT ✅
𝙰𝚄𝙳𝙽𝚉𝙳-𝙾𝚃𝙲,𝟷𝟾:𝟻𝟻 𝙼𝟷 𝙲𝙰𝙻𝙻
14:30 - GBP/JPY - VENDA        14h40 AUD_CAD OTC ⬆️        EUR/USD 14:30 شراء 5 دقائق
📊 EUR/USD (OTC)
⏰ 14:30
⌛ 5 min
🟢 BUY
```
Directions: CALL/PUT, BUY/SELL, UP/DOWN, HIGHER/LOWER, COMPRA/VENDA, شراء/بيع, arrows and 🟢/🔴. Expiry: M1, 5 min, 30s, H1, `Expiry: M5` header (default M1). OTC from `-OTC`, `(OTC)`, `OTC` or an "OTC signals" header; a pair Quotex only has as OTC is traded as OTC. Pastes may contain blank lines (the paste ends 0.6s after the last line).

## Timing (how entries hit :00)
- **Pending orders (OTC, signal > 70s ahead)**: the bot creates a Quotex pending order by time 70s before; Quotex itself opens it at HH:MM:00 (measured +115..+180ms, no network delay, many pairs in the same second). Quotex requires >= 60s lead and allows it on OTC only. If Quotex fails it at open time, the bot enters directly at once.
- **Direct orders** (real-market pairs, gales, late signals): the account's chart is switched to the pair (Quotex ignores orders for other pairs), then the order is sent `pre_entry` ms early. Fast pairs: arrives ~:00 (measured -375..+72ms). Pairs whose price updates slower than the ping wait for the candle's first price instead (never opens on a seconds-old price).
- Every order has a fixed expiry at the candle close, so a late entry still ends at HH:MM:00.
- Clock check on connect: warns if this PC's clock is off vs Quotex (all timing depends on it).

## Safety
- Daily stop-loss / take-profit (a gale counts the losing trade it follows); pending orders are cancelled 3s before if a limit was hit meanwhile.
- Balance check before every trade and gale (balance from Quotex's order replies).
- 15-70s before each signal: connection check (re-login if dead), pair exists and is open, payout >= minimum.
- Errors inside a trade are printed, never silent; reconnects never run twice at once.

## Desktop app (Windows GUI)
`desktop/`: the same engine (`bot.Bot`) behind a local web UI on 127.0.0.1, shown in a native window (pywebview on Edge WebView2; the default browser if WebView2 is missing). Login with PIN box, live signal preview, Start/Stop, countdown to the next trade, result cards, details log, stats, Quotex history, backtest, settings and profiles from `config.json`, English/Arabic. Every `print` of the engine reaches the GUI log and `qxbot.log`. Run it from source with `.venv/bin/python -m desktop` (`--browser` for no native window); terminal mode is still `bot.py`.

Rebuild the Windows zip from WSL: `desktop/build_windows.sh` (copies the code into `dist\QXBot\`, installs the pywebview wheels into the embedded Python, compiles `QXBot.exe` with the C# compiler built into Windows, and zips without private files).

### For testers / للمختبرين
**English.** Download `QXBot-windows.zip`, right-click > Extract All, open the `QXBot` folder, double-click **QXBot.exe** (if Windows shows "Windows protected your PC": More info > Run anyway). Sign in with your Quotex email and password and choose Demo; a browser window logs in by itself and closes. If Quotex emails a PIN, type it in the box QXBot shows. Paste a signal list on the Signals page, check the preview, click Start trading. Home shows the balance, today's profit, the next trade with a countdown and a big Stop button; Results shows every trade. Keep QXBot open while trading.

**العربية.** نزّل `QXBot-windows.zip`، زر الفأرة الأيمن > استخراج الكل، افتح مجلد `QXBot` واضغط مرتين على **QXBot.exe** (إذا ظهر "Windows protected your PC": More info ثم Run anyway). سجّل الدخول ببريد وكلمة سر Quotex واختر الحساب التجريبي؛ تفتح نافذة متصفح وتسجّل الدخول وحدها ثم تُغلق. إذا أرسل Quotex رمز PIN إلى بريدك، اكتبه في المربع الذي يظهر في QXBot. الصق قائمة الإشارات في صفحة الإشارات، راجع المعاينة، ثم اضغط ابدأ التداول. الرئيسية تعرض الرصيد وربح اليوم والصفقة القادمة مع عدّاد وزر إيقاف كبير؛ صفحة النتائج تعرض كل صفقة. اترك QXBot مفتوحاً أثناء التداول.

## Windows build (no Python needed)
`C:\Users\dz\qxbot-build\QXBot-windows.zip`: embedded Python 3.12 + deps, `QXBot.exe` (GUI) and `QXBot-terminal.bat` (terminal mode). Rebuild with `desktop/build_windows.sh`.

## Notes
- Login uses a real Chromium browser via Patchright (Windows: Edge, then Chrome, then Brave). If Quotex sends a PIN, type it in the terminal (or the GUI's PIN box). The login is kept in `login_profile/`.
- The websocket uses the Quotex app User-Agent `Quotex/1.0` (Cloudflare 403s browser UAs there) and the same proxy as the browser. Never change the proxy without deleting `login_profile/`.
- `open_time` rejection = the pair is closed right now (Quotex closes some OTC pairs while the real market is open).
- `login_profile/`, `session.json`, `config.json` and `trades.csv` hold your session and history. Keep them private.
- `REPORT.md`: what the platform offers and test results.
