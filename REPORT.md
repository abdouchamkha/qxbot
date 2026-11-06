# qxbot report (2026-11-06)

## 1. What the Quotex platform offers (found by reading its web app and testing on demo)

| Feature | How | Used by the bot |
|---|---|---|
| Order at fixed expiry | ws `orders/open` `{asset, amount, time: expiry_ts, action, optionType: 3}` | yes (direct entries, gales) |
| **Pending order by time** | ws `pending/create` `{openType: 0, asset, openTime: "YYYY-MM-DDTHH:MM:SS.000Z", timeframe, command: "call"/"put", amount}` | **yes**: OTC list signals |
| Pending order by price | same with `openType: 1/2` and `openPrice` instead of `openTime` (Quotex opens when the price reaches it) | no (server-side "safe entry"; backtest says safe entry loses winners) |
| Cancel a pending order | ws `pending/cancel {ticket}` | yes (daily limit hit before it opens) |
| Close a trade early ("Sell now") | ws `orders/cancel {ticket}` | no |
| Pairs: open/closed, payout M1/M5, decimals | ws `instruments/get` -> list rows (`[1]` symbol, `[2]` label, `[4]` decimals, `[14]` open, `[18]`/`[19]` payout M1/M5) | yes (payout filter, closed/unknown pair skip, pip size) |
| Tick history (every price, ms timestamps) | ws `history/load {asset, index, time, offset, period}` | used for the safe-entry backtest |
| Trade history (source of truth) | HTTPS `GET /api/v1/cabinets/trades/history/type/{demo,live}?page=&dateFrom=&dateTo=` with the browser cookies | yes (`history` command) |
| Balance, account switch, tournaments | ws `balance/list`, `account/change`, tournaments in payloads | balance only |
| Market sentiment, Quotex's own signals | ws `sentiment` event, `signal/subscribe` | no (ideas below) |

Rules learned:
- Quotex **ignores an order unless the account's chart is on that pair** (`instruments/update` + `settings_apply`). Same-minute direct orders must be sent one after another.
- Pending by time: **OTC only**, **>= 60s lead** (62s ok, 58s `open_time_min`), executed by Quotex at the minute.
- Orders open on the latest price tick Quotex holds; there is no price at exactly :00. Exotic OTC pairs update only every 1-2.5s.
- Some OTC pairs close while the real market is open (`open_time` error / open flag false).
- Payouts change during the day (Litecoin OTC dropped to 60%).
- pyquotex's `check_connect()` only checks the login state, not a dead socket.

## 2. Built today
- Pending-order entries for OTC, direct fallback.
- Smart parser (`signals.py`): blocks, fonts, arrows/emoji, EN/PT/AR words, Quotex symbol names, timezone in list.
- Daily stop-loss / take-profit, balance check, auto pre-entry from measured ping.
- `history` command from Quotex's trade-history API.
- Paste reader that accepts blank lines; PIN prompt shares the input.

## 3. Soak test results
(filled in below)
