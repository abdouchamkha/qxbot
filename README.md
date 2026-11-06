# qxbot

Paste a signal list (`M1 NZDJPY-OTC 00:03 PUT`) and it places each trade on Quotex at the exact candle time.

## Setup
```bash
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
.venv/bin/patchright install chromium   # Linux only; Windows uses the installed Edge/Chrome/Brave
.venv/bin/python bot.py
```
On start it asks for: email, account (PRACTICE/REAL), amount, list timezone (UTC offset), martingale levels and multiplier, safe-entry pips, pre-entry ms, overlap, minimum payout, proxy, and whether to hide the browser. Answers are saved as named profiles in `config.json` (password too, if you say yes). Next run: press Enter on the profile name, then Enter on "Change settings?" and it starts. A new profile name = a new account.

## Windows build (no Python needed)
`C:\Users\dz\qxbot-build\QXBot-windows.zip`: embedded Python 3.12 + deps + `start.bat`. To rebuild after changing `bot.py`, copy it into `dist\QXBot\` and re-zip.

## Notes
- Login uses a real Chromium browser via Patchright (Windows: Edge, then Chrome, then Brave). Run it once with the browser visible: if Quotex sends a PIN, type it in the terminal. After that the login is kept in `login_profile/`.
- The websocket uses the Quotex app User-Agent `Quotex/1.0` (Cloudflare 403s browser UAs there) and the same proxy as the browser. Never change the proxy without deleting `login_profile/` and `session.json`.
- Timing: Quotex opens an order on the latest price tick it holds (ticks are 0.25-0.5s apart), so sending "early by the ping" can land in the previous candle. The bot waits for the first tick stamped >= HH:MM:00 for that pair and fires instantly, so every order opens in the signal's candle (tested: +2 to +1054ms). Keep the PC clock NTP-synced (on WSL: `sudo hwclock -s` after sleep).
- Safe entry (optional, `safe_pips` > 0): after the candle opens, wait up to half the candle (M1 30s, M5 2:30) for the price to move that many pips against the signal (1 pip = 10 of the pair's smallest price steps, from Quotex: 0.0001 on 5-decimal pairs, 0.01 on JPY, 0.001 on silver), then enter with the same expiry. If it never gets there, the signal is skipped. Gales always enter at the candle open.
- Martingale: with 5s left, the chart is moved back to the pair and the next candle prepared; the final gale decision is made 0.3s before expiry (a late reversal can still win).
- Pre-entry (`pre_entry_ms` > 0): send the order that many ms before :00 so it arrives at about :00 (start with half the `ping` the bot prints, e.g. 250). Tested: opens -375..+72ms instead of +400..+1300ms. If it arrives before the candle's first tick, Quotex opens it on the previous candle's last tick (open time shows :59, price = previous close); the expiry is still the candle close. Pairs whose price updates less often than the ping (exotics like XAGUSD) automatically wait for the candle's first price instead, so they never open on a seconds-old price. 0 = always wait for the first tick (always in the new candle, but a ping late).
- Every order uses a fixed expiry at the candle close (`time` = candle end), so a late or safe entry still ends exactly at HH:MM:00 of the candle close.
- Minimum payout (`min_payout`, default 80): 15s before a signal the bot refreshes Quotex's payouts and skips the pair if its M1 (or M5) payout is lower.
- Overlap (`overlap` = n): only the first list signal per minute is traded, and a martingale that would land on a minute that has a list signal is cancelled. `y` = trade everything.
- Quotex ignores an order unless the account's chart is on that pair, so orders for the same minute are sent one after another (a few hundred ms apart).
- Analytics: every result is appended to `trades.csv` (one row per trade, per profile and account). After each result a session line is printed. Type `stats` at the paste prompt for session/today/all-time win rate, net profit, ROI, signals won after martingale, max drawdown, losing streak, wins per gale step, entry delay and per-pair results.
- Pairs: OTC (`NZDJPY-OTC`, Quotex's own market, open most of the time) and real-market pairs (`EURUSD`, follow forex hours, closed at weekends). 15s before each signal the bot checks Quotex's pair list and skips a pair that doesn't exist (typo, wrong -OTC) or is closed right now.
- Robustness: the connection is checked before every signal and every 30s (socket state + recent messages; pyquotex's `check_connect()` can't see a dead socket). If it's dead, pyquotex gets 10s to reconnect, then the bot logs in again. Errors inside a trade are printed, never silent.
- Clock check on connect: warns if this PC's clock is off vs Quotex (all timing depends on it).
- `open_time` rejection = the pair is closed right now (Quotex closes some OTC pairs while the real market is open).
- `login_profile/`, `session.json`, `config.json` and `trades.csv` hold your session. Keep them private.
