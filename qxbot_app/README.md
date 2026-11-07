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
- `lib/main.dart`: the UI (Material 3, dark).
- `tool/cli.dart`: command-line check of the core against the real demo account.

## Verified (2026-11-07, Quotex demo, from `tool/cli.dart` on the PC)
- Connect with token only, authorization, demo balance, 92 pairs / payouts, parser against the live pair list.
- Pending order by time created 70s ahead, opened by Quotex at +607ms / +64ms; results received (LOSS -1.00 each), balance updated.
- Direct order: see the commit message / supervisor report for the result of the second run.
- 22 unit tests pass (`flutter test`).

## Not verified
- The app itself on a phone (no device/emulator here): the WebView login + token extraction, the
  foreground service and notifications are built but untested. If login gets stuck, use the key icon
  to paste a token.
- Martingale on a live account (logic ported and unit-tested for the decisions, not exercised live).
- Phone clock accuracy: entries use the phone clock. Keep "automatic time" on in Android settings.

## Decisions
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
