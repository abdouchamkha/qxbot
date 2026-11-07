# Handoff: QXBot Android app (Flutter/Dart)

Written 2026-11-07 23:15 WAT by the supervising session. Owner is asleep; do not ask questions, decide and note decisions in `qxbot_app/README.md`.

## Goal
A Flutter Android app (later iOS from the same code) that does what the desktop bot `bot.py` + `signals.py` does: log in to Quotex, take a pasted Telegram signal list, and place each trade at the exact candle time on the owner's account, with martingale, filters, limits and stats. Good-looking, simple, dark "trading" UI (Material 3).

## HARD DEADLINE
The PC powers off at ~01:12 WAT (2026-11-08). Everything must be **committed and pushed** (`git push origin main`, SSH works) by **00:50 WAT**. Commit + push after every milestone, not only at the end. An unpushed APK/code is lost.

## Where things are
- Repo: `/home/dz/trade/qxbot` (GitHub `abdouchamkha/qxbot`, branch `main`). Put the app in `qxbot_app/`. Do not modify `bot.py`/`signals.py` behaviour.
- Reference implementation: `bot.py` (engine), `signals.py` (parser), `test_signals.py` (parser cases to port), `REPORT.md` (platform findings), pyquotex source `.venv/lib/python3.12/site-packages/pyquotex/api.py` (message handling, `settings_apply` ~line 603).
- Toolchain (being installed by the supervisor; wait for `~/sdk/READY`, failure = `~/sdk/FAILED`, log `~/sdk/install.log`):
  `export JAVA_HOME=~/sdk/jdk ANDROID_HOME=~/sdk/android PATH=~/sdk/flutter/bin:~/sdk/jdk/bin:$PATH`.
  Dart SDK alone (ready now): `~/sdk/dart-sdk/bin/dart`; Flutter ships its own dart.
- Private, never commit/print: `config.json`, `session.json`, `login_profile/`, `trades*.csv`, any token. Scratch files go in `/tmp/claude-1000/-home-dz-trade-qxbot/75903a06-db13-468f-9ff8-8c197ef86946/scratchpad/`.

## Quotex protocol (verified on demo; trust this over guesses)
- WebSocket `wss://ws2.quotex.com/socket.io/?EIO=3&transport=websocket`, header `User-Agent: Quotex/1.0`, `Origin: https://quotex.com`. **Verified from Dart `dart:io` WebSocket: works, cookies not needed, only the token.** Browser UAs get 403 from Cloudflare.
- Socket.IO v2 / Engine.IO 3 framing: server sends `0{...pingInterval:25000}` then `40`. Client keepalive: send `2` (ping) every 25s (server answers `3`) and pyquotex also sends `42["tick"]` every 5s. Events: `42["name",payload]`. Server replies with binary attachments: a text frame `451-["s_orders/open",{"_placeholder":true,"num":0}]` followed by ONE binary frame holding the JSON payload (first byte may be `0x04`, strip any leading non-`[`/`{` byte). `s_` prefix = success, `f_` = failure.
- Authorize right after `40`: `42["authorization",{"session":TOKEN,"isDemo":1,"tournamentId":0}]` (isDemo 0 = real). Reply `42["s_authorization"]`. Then send `42["instruments/get"]`, `42["balance/list"]` (balance arrives as `{"liveBalance":..,"demoBalance":..}`).
- Pair list (`instruments/list` payload): array of rows; `[1]` symbol (`EURUSD_otc`, `EURUSD`, `BTCUSD_otc`, `USCrude_otc`...), `[2]` label (`EUR/USD (OTC)`, `Bitcoin (OTC)`, `Gold`), `[4]` price decimals, `[14]` open now (bool), `[18]` payout % M1, `[19]` payout % M5. Payouts change during the day: re-send `instruments/get` ~15s before using them.
- Price ticks: frames whose JSON is `[["EURUSD_otc", 1793983560.123, 1.11469, 0]]` (symbol, server ts, price, _). Only the pair the chart is on streams.
- **Chart switch (required before a direct order; Quotex silently ignores orders for another pair):** `42["instruments/update",{"asset":A,"period":60}]`, `42["depth/follow","A"]`, `42["settings/apply",{...}]` (copy the payload from pyquotex `settings_apply` with `isFastOption:true`, `endTime`=expiry, `currentExpirationTime`=expiry, `currentAsset.symbol`=A, `timePeriod`=duration). Same-minute direct orders must be sequential (lock).
- **Direct order:** `42["orders/open",{"asset":A,"amount":1,"time":EXPIRY_UNIX,"action":"call"|"put","isDemo":1,"tournamentId":0,"requestId":UNIQUE_INT,"optionType":3}]`. EXPIRY = candle start + duration (fixed expiry at the candle close). Reply `s_orders/open` payload: `{id, openTimestamp, openMs, openPrice, closeTimestamp, accountBalance, requestId, ...}` or `{"error":"open_time"}` (pair closed). requestId must be unique (counter), Quotex dedupes.
- Timing for direct orders: send `pre_entry` ms before :00 (auto = half the measured order round trip, ~250ms) for pairs whose ticks arrive faster than the ping; for slow pairs wait for the first tick stamped >= :00 then send.
- **Pending order by time (OTC only, created >= 60s ahead; 62s ok, 58s -> `open_time_min`):** `42["pending/create",{"openType":0,"asset":A,"openTime":"2026-11-06T16:48:00.000Z","timeframe":60,"command":"call"|"put","amount":1}]` -> `s_pending/create` `{"pending":{"ticket":...}}` or `f_pending/create` `{"error":...}`. Quotex itself opens it at the minute (measured +23..+988ms): arrives as `s_orders/open` with `id == ticket`, `requestId 0`. Failure at open time: `f_pending/opened` `{ticket, error: 9}` -> then enter directly at once. Cancel: `42["pending/cancel",{"ticket":T}]`. Create it 70s before the signal.
- Results: closed trades arrive as `s_orders/close` (payload with `deals:[{id, profit, ...}]`) and/or a message with `deals:[...]`; profit > 0 win, < 0 loss, 0 draw. Verify with a real demo trade.
- Token for login: after logging in through a WebView (Quotex's real page passes Cloudflare), load `https://quotex.com/en/demo-trade` and regex the page HTML for `"token":"([^"]+)"`. PIN (email code) is typed by the user in the WebView itself.

## Engine rules to port (see bot.py `run_signal`)
- Per signal: at T-70s (pending) / T-15s (direct): ensure connected (reconnect if no message for 20s), refresh instruments, skip if pair unknown, closed, payout < min_payout, daily stop-loss/take-profit hit, or balance < amount.
- Entry: OTC + `pending` setting + > 70s ahead -> pending order (cancel 3s before if a daily limit was hit meanwhile); else direct.
- Martingale (`gales` levels, `gale_multiplier`): 5s before expiry put the chart on the pair; decide just before expiry (pre_entry + 0.3s) using live price vs openPrice (equal = draw, not loss); gale = direct order on the next candle. Overlap off: one list signal per minute, a gale is cancelled if a list signal owns its minute. A gale counts the losing trade toward the stop-loss.
- Settings (defaults): account PRACTICE, amount 1, utc_offset (list timezone; a `UTC+6` in the list overrides), gales 1, gale_multiplier 2.2, pending on, pre_entry auto, overlap off, min_payout 80, stop_loss 0, take_profit 0 (0 = off).
- Stats: per trade log (time, pair, dir, level, amount, entry kind, delay ms, result, profit); session/today: trades, W/L/D, win%, signals won after martingale, net, max drawdown, worst losing streak.

## Parser (port `signals.py` 1:1, port every case of `test_signals.py` + `test_bot.py` parse tests to `dart test`)
NFKC (Dart: `unorm_dart` package) for fancy fonts, `USD/BDT_OTC`, blocks, arrows, EN/PT/AR words, `UTC+6`/`(UTC +6:00)` header, matching against Quotex symbol list, unknown-pair lines reported.

## Deliverables, in priority order (stop adding features at 00:30, then build/commit/push)
1. `qxbot_app/` Flutter project; engine + protocol + parser as pure Dart under `lib/core/` (no Flutter imports) with `dart test` tests for the parser and engine decisions.
2. Verify the core against real Quotex **demo** from a CLI (`qxbot_app/tool/cli.dart`): connect with a token, read balance + pairs, place ONE $1 demo direct order and ONE pending order, receive results. Get a token without the app by running the desktop login: `cd /home/dz/trade/qxbot && .venv/bin/python -c "import asyncio,bot,json; c=bot.DEFAULTS|bot.read_config()['profiles']['default']; t,_=asyncio.run(bot.browser_session(c)); print(t)"` and pass it via a 0600 file in the scratchpad (delete after). PRACTICE ONLY, at most 6 trades of $1. Never isDemo 0.
3. UI: Login (WebView, extracts token, stores it with flutter_secure_storage) -> Home (connection status, demo/real switch with confirmation for real, balance, today P/L, running/stopped) -> Signals (paste box, parsed preview incl. unknown lines, Start) -> Live (scheduled + log + results) -> Stats -> Settings (all settings above, persisted).
4. Keep running: `wakelock_plus` while trading at minimum; Android foreground service (`flutter_foreground_task`) + result notifications if time allows.
5. `flutter build apk --release` (debug signing is fine), copy to `/mnt/c/Users/dz/qxbot-build/QXBot.apk`. Do not commit the APK.
6. `qxbot_app/README.md`: how to build/install, what was verified, what was not, decisions made.

Report back to the supervisor (final message): what works and was verified (with evidence), what was not, commit hashes, APK path.
