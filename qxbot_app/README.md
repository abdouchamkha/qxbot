# QXBot Android app (Flutter)

Phone version of the desktop bot (`../bot.py` + `../signals.py`): log in to Quotex, paste a Telegram
signal list, and the app places each trade at the exact candle time, with martingale, filters, daily
limits and stats.

## Install
Copy `QXBot.apk` to the phone, open it, allow "install unknown apps". Android 7+ (minSdk from Flutter).

1. **Login**: log in to Quotex inside the app (email, password, email code if asked). The app reads the
   session token from the trade page and keeps it in the phone's secure storage. (Key icon = paste a token by hand.)
2. **Home**: connection, balance, today's profit, demo/real switch (real asks for confirmation), Stop.
3. **Signals**: paste the list; the preview shows every signal found and the lines whose pair Quotex
   doesn't have. Start.
4. **Live**: waiting signals and the log (orders, delays, results).
5. **Stats**: session / today / all time: trades, W/L/D, win %, signals won (after martingale), net,
   max drawdown, worst losing streak, recent trades.
6. **Settings**: amount, list timezone, martingale levels + multiplier, min payout, daily stop-loss /
   take-profit, pending orders, overlap, pre-entry (auto or ms). Saved on the phone.

Keep the phone on the charger with the app open or in the background: while trading the screen-lock
wakelock is on and a foreground service ("QXBot is trading") keeps the app alive; results show in that
notification. Allow notifications and "no battery restrictions" when asked.

## Build
```
export JAVA_HOME=~/sdk/jdk ANDROID_HOME=~/sdk/android PATH=~/sdk/flutter/bin:~/sdk/jdk/bin:$PATH
cd qxbot_app
flutter test                    # parser + engine tests (pure Dart core)
flutter build apk --release     # build/app/outputs/flutter-apk/app-release.apk (debug signing)
dart run tool/cli.dart TOKEN_FILE info    # demo check: balance + pairs
dart run tool/cli.dart TOKEN_FILE trade   # demo check: one $1 direct + one $1 pending order (isDemo=1 only)
```

## Layout
- `lib/core/parser.dart`: 1:1 port of `signals.py` (tests: `test/parser_test.dart`, every case of `test_signals.py` + the parse tests of `test_bot.py`).
- `lib/core/quotex.dart`: Quotex WebSocket client (Socket.IO v2 over `dart:io`, `User-Agent: Quotex/1.0`, token only).
- `lib/core/engine.dart`: port of `bot.py` `Bot` (pending/direct entry, pre-entry timing, chart switch, martingale, overlap, payout/closed/balance/daily-limit checks, stats). Tests: `test/engine_test.dart`.
- `lib/core/clock.dart`: Quotex server clock estimated from tick timestamps (tests: `test/clock_test.dart`).
- `lib/main.dart`: the UI (Material 3, dark); `lib/app_state.dart`: state, connection, notifications;
  `lib/format.dart`: engine events -> text in the user's language, LTR isolates for numbers/pairs/times.
- `lib/l10n/app_en.arb`, `app_ar.arb`: all user-facing text (gen-l10n, class `L`). They are generated from
  `tool/make_arb.py` (one table, both languages, keys always in sync): edit the table, run
  `python3 tool/make_arb.py`, then `flutter gen-l10n` (or any `flutter run/build/test`).
- `tool/cli.dart`: command-line check of the core against the real demo account
  (`clock` mode: follows a pair's ticks, prints the clock estimate next to an NTP reference, no trade).

## Languages (v1.1)
English and Arabic (العربية), right-to-left. Default = the phone's language; Settings > Language switches
(System / English / العربية) and is remembered. The engine (`lib/core`) never builds text: it reports
`EngineEvent(key, args)` and the UI formats them, so the Live log and the result notifications follow the
language. Prices, pair symbols, times, amounts and +/- profits are wrapped in Unicode isolates (LRI/PDI) or
an LTR `Directionality`, so they read left-to-right inside Arabic sentences; number inputs are LTR and
accept Arabic-Indic digits. Arabic uses the bundled Cairo font (`assets/fonts`, SIL OFL).
Terms: CALL شراء, PUT بيع, martingale مضاعفة, pending order صفقة معلقة, payout نسبة الربح,
stop-loss حد الخسارة اليومي, take-profit هدف الربح اليومي.

## Quotex clock (v1.1)
Every timing decision (sleeps to T-70 / T-15 / T-0.5, pre-entry send, the martingale decision, waiting
for the first tick of a candle) uses Quotex's time, not the phone's: `serverNow = phoneNow - offset`.
Each price tick carries Quotex's timestamp; `phoneReceive - tickTs = one-way latency + offset`. The
minimum over the last 60 s / 200 ticks (the fastest tick) minus the one-way latency gives the offset,
smoothed with an EMA; > 30 s off is ignored. One-way latency = half the Engine.IO ping/pong round trip
(pure network), else half the order round trip, else 0.2 s. Order confirmations' open time feed the same
bound. After login the app follows one OTC pair's ticks so the clock is known before the first signal.
Home shows "Clock vs Quotex: +0.71 s (corrected)", or "not verified" (phone clock in use) until ticks
arrive; the log warns once when the phone is more than 1 s off.
Measured on this PC (WSL, `tool/cli.dart clock`, next to an SNTP query to time.google.com): right after
the PC clock was stepped, Quotex estimate +0.071 s vs NTP +0.109 s; before it, +1.666 s vs +1.784 s.
Limit: the window minimum lags a clock that *drifts* fast (this WSL clock gains ~80 ms per second between
resyncs); phone clocks drift by microseconds per second, which the 60 s window absorbs.

## Verified v1.0 (2026-11-07, Quotex demo, `tool/cli.dart` on the PC, 6 trades of $1)
- Connect with the token only (no cookies), authorization, demo balance, 92 pairs with payouts, parser
  matched against the live pair list.
- Pending orders by time (created 70s ahead): opened by Quotex at +607ms, +64ms, +296ms; results received
  (LOSS -1.00, LOSS -1.00, WIN +0.77).
- Direct order: `orders/open` confirmed (sent -248ms, ping 489ms), result WIN +0.86. Quotex stamped the open
  -2302ms before :00 (it opens on the last price it holds); the desktop bot sees -0.2..-0.7s. Not investigated
  further because the desktop bot was trading on the same demo account at the same time.
- Bug found and fixed on demo: Quotex also sends `f_pending/opened` WITHOUT an error for pending orders it then
  opens normally (seen at :00.4, `s_pending/opened` at :04.7). The first version took that as a failure and also
  entered directly (double entry). Now only `f_pending/opened` with an `error` code counts as a failure.
  The desktop bot's raw hook in `bot.py` treats any `f_pending/opened` as a failure too: worth checking.
- `s_pending/create` replies of other apps on the same account arrive too: replies are matched by pair.
- `flutter test`: 23 tests (parser port of every `test_signals.py` case + `test_bot.py` parse tests, engine
  decisions, a widget smoke test of all tabs).

## Not verified
- v1.0 was installed and works on the owner's phone (2026-11-08). v1.1 (Arabic, Quotex clock) is
  tested by widget tests and the CLI only, not on a phone: check the Arabic screens and the clock line.
- Martingale on a live account (logic ported and unit-tested for the decisions, not exercised live).
- v1.1 timing with a real order: no live trade was placed for v1.1 because the desktop bot was trading
  on the same demo account; the order code is unchanged apart from its time source.

## Decisions
- v1.1: the parser also reads Arabic-Indic digits (١٤:٣٠, ۱۴:۳۵), as `signals.py` does through Python's `\d`.
- Default list timezone UTC-3 (same as the desktop bot); a timezone written in the list overrides it.
- Default martingale 1 level x2.2 (as the brief), pending on, min payout 80%, overlap off, pre-entry auto.
- Trade history is stored in the app (shared_preferences JSON), not in Quotex's history; stop-loss /
  take-profit count only trades made by this app today, per account (demo/real).
- The engine runs in the main Dart isolate; the foreground service (`flutter_foreground_task`, type
  `dataSync`) only keeps the process alive and shows results. Android 15 limits dataSync services to
  about 6h per day.
- Safe-entry (`safe_pips`) and backtest of past signals from the desktop bot are not ported.
- If a pending order gets no answer the signal is skipped (no risk of a double entry), as on desktop.
- Switching demo/real is blocked while the bot is running.
- Stop ends every scheduled signal (also ones waiting for a gale); the bot stops by itself when all are done.
- The log shows raw `pending` events from Quotex (shortcut for diagnosing pending orders; remove once settled).
