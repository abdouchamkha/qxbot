/// Google Gemini (Flash-Lite) over REST: AI list reader and performance coach. Pure Dart (dart:io).
/// Only the pasted list, the pair names and aggregated stats are sent: never the session token, email or ids.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'engine.dart';
import 'parser.dart';

/// Cheapest Flash-Lite that reads lists well (checked 2026-11-08: gemini-2.5-flash-lite is gone (404),
/// gemini-flash-lite-latest now points to 3.5).
const geminiModel = 'gemini-3.1-flash-lite';

class AiException implements Exception {
  /// noKey | badKey | quota | offline | timeout | server | bad
  final String kind;
  final String detail;
  const AiException(this.kind, [this.detail = '']);
  @override
  String toString() => 'AiException($kind${detail.isEmpty ? '' : ': $detail'})';
}

class Gemini {
  final String key;
  final String model;
  final Duration timeout;
  Gemini(this.key, {this.model = geminiModel, this.timeout = const Duration(seconds: 30)});

  /// One structured call: [prompt] in, JSON matching [schema] out.
  Future<Object?> json(String prompt, Map<String, Object?> schema) async {
    if (key.trim().isEmpty) throw const AiException('noKey');
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final req = await client
          .postUrl(Uri.https('generativelanguage.googleapis.com', '/v1beta/models/$model:generateContent'))
          .timeout(timeout);
      req.headers
        ..set('x-goog-api-key', key.trim())
        ..contentType = ContentType.json;
      req.write(jsonEncode({
        'contents': [
          {'parts': [{'text': prompt}]}
        ],
        'generationConfig': {'responseMimeType': 'application/json', 'responseSchema': schema, 'temperature': 0.2},
      }));
      final res = await req.close().timeout(timeout);
      final body = await res.transform(utf8.decoder).join().timeout(timeout);
      if (res.statusCode == 429) throw const AiException('quota');
      if (res.statusCode == 400 && body.contains('API_KEY') || res.statusCode == 401 || res.statusCode == 403) {
        throw const AiException('badKey');
      }
      if (res.statusCode != 200) throw AiException('server', 'HTTP ${res.statusCode}');
      final text = (((jsonDecode(body) as Map)['candidates'] as List).first as Map)['content']['parts'][0]['text'];
      return jsonDecode(text as String);
    } on AiException {
      rethrow;
    } on TimeoutException {
      throw const AiException('timeout');
    } on SocketException catch (e) {
      throw AiException('offline', e.message);
    } on HandshakeException catch (e) {
      throw AiException('offline', e.message);
    } catch (e) {
      throw AiException('bad', '$e');
    } finally {
      client.close(force: true);
    }
  }
}

// ---------------------------------------------------------------- list reader

String _tzText(Duration tz) {
  final m = tz.inMinutes, a = m.abs();
  return 'UTC${m < 0 ? '-' : '+'}${a ~/ 60}${a % 60 == 0 ? '' : ':${(a % 60).toString().padLeft(2, '0')}'}';
}

/// The prompt: rules, the Quotex pair list (symbol = label) and the raw text. Nothing about the account.
String listPrompt(String text, List<(String, String)> names, Duration tz) => '''
You read Telegram trading signal lists for the Quotex broker. Extract every trade signal in the text below.
For each signal return:
- symbol: EXACTLY one symbol from the Quotex pair list (OTC pairs end with _otc; if the text says OTC use the _otc symbol, else the plain one if it exists).
- time: the entry time as HH:MM (24h), as written (do not convert timezones).
- direction: "call" for buy/up/CALL/COMPRA/شراء/green, "put" for sell/down/PUT/VENDA/بيع/red.
- duration_seconds: the expiry (M1 = 60, M5 = 300, 5min = 300, 30s = 30); 60 if not written.
Also return timezone: the list's timezone if the text writes one (like "UTC-3" or "GMT+1"), else an empty string.
Skip anything that is not a signal (results, ads, emojis only). Never invent a signal or a pair.
Default timezone of the user's lists: ${_tzText(tz)}.

Quotex pair list:
${[for (final (s, l) in names) '$s = $l'].join('\n')}

Text:
"""
$text
"""''';

const listSchema = {
  'type': 'OBJECT',
  'properties': {
    'timezone': {'type': 'STRING'},
    'signals': {
      'type': 'ARRAY',
      'items': {
        'type': 'OBJECT',
        'properties': {
          'symbol': {'type': 'STRING'},
          'time': {'type': 'STRING'},
          'direction': {'type': 'STRING', 'enum': ['call', 'put']},
          'duration_seconds': {'type': 'INTEGER'},
        },
        'required': ['symbol', 'time', 'direction', 'duration_seconds'],
      },
    },
  },
  'required': ['signals', 'timezone'],
};

final _timeRe = RegExp(r'^([01]?\d|2[0-3])[:hH.]([0-5]\d)$');
final _aiTzRe = RegExp(r'^(?:UTC|GMT)\s?([+\-−])\s?(\d{1,2})(?::?(\d{2}))?$', caseSensitive: false);

/// AI signals checked against the real pair list and sane values: [signals] upcoming, [passed] already
/// passed (within 12 h, for a backtest), [rejected] items that failed validation (shown to the user).
class AiParse {
  final signals = <Signal>[], passed = <Signal>[], rejected = <String>[];
}

/// Validates the model's answer. Never trusted as-is: unknown symbols, bad times, directions or durations are
/// rejected; a timezone the model reports must be well-formed and within UTC-12..+14.
AiParse validateAiSignals(Object? json, List<(String, String)> names, Duration defaultTz, DateTime now) {
  final out = AiParse();
  final symbols = {for (final (s, _) in names) s.toLowerCase(): s};
  var tz = defaultTz;
  if (json is! Map || json['signals'] is! List) {
    out.rejected.add('$json');
    return out;
  }
  final m = _aiTzRe.firstMatch('${json['timezone'] ?? ''}'.trim());
  if (m != null) {
    final mins = (int.parse(m[2]!) * 60 + int.parse(m[3] ?? '0')) * (m[1] == '+' ? 1 : -1);
    if (mins >= -12 * 60 && mins <= 14 * 60) tz = Duration(minutes: mins);
  }
  final nowUtc = now.toUtc(), day = nowUtc.add(tz);
  for (final item in json['signals'] as List) {
    if (item is! Map) {
      out.rejected.add('$item');
      continue;
    }
    final symbol = symbols['${item['symbol']}'.toLowerCase()];
    final t = _timeRe.firstMatch('${item['time']}'.trim());
    final dir = item['direction'];
    final dur = item['duration_seconds'] ?? 60;
    if (symbol == null || t == null || (dir != 'call' && dir != 'put') || dur is! int || dur < 5 || dur > 14400 || dur % 5 != 0) {
      out.rejected.add('${item['symbol']} ${item['time']} ${item['direction']}');
      continue;
    }
    // same day / rollover rules as the parser
    var at = DateTime.utc(day.year, day.month, day.day, int.parse(t[1]!), int.parse(t[2]!)).subtract(tz);
    var target = out.signals;
    if (!at.isAfter(nowUtc)) {
      if (nowUtc.difference(at) < const Duration(hours: 12)) {
        target = out.passed;
      } else {
        at = at.add(const Duration(days: 1));
      }
    }
    final s = Signal(dur, symbol, at, tz, dir as String);
    if (!target.any((x) => x.at == s.at && x.asset == s.asset && x.direction == s.direction)) target.add(s);
  }
  out.signals.sort((a, b) => a.at.compareTo(b.at));
  out.passed.sort((a, b) => a.at.compareTo(b.at));
  return out;
}

// ---------------------------------------------------------------- coach

Map<String, Object?> _rate(Iterable<Trade> rows) {
  final s = summarize(rows.toList());
  return {'trades': s.trades, 'wins': s.wins, 'losses': s.losses, 'draws': s.draws,
    'win_rate_pct': s.winRate.round(), 'net': double.parse(s.net.toStringAsFixed(2))};
}

/// Aggregated stats only (no ids, no account, no token): totals, per pair, per hour, per martingale step,
/// drawdown, payout skips, and an optional backtest summary.
Map<String, Object?> coachStats(List<Trade> trades,
    {int payoutSkips = 0, Map<String, Object?>? backtest, Map<String, Object?>? settings}) {
  final s = summarize(trades);
  final byPair = <String, List<Trade>>{}, byHour = <int, List<Trade>>{}, byLevel = <int, List<Trade>>{};
  for (final t in trades) {
    byPair.putIfAbsent(t.asset, () => []).add(t);
    byHour.putIfAbsent(t.time.hour, () => []).add(t);
    byLevel.putIfAbsent(t.level, () => []).add(t);
  }
  return {
    'totals': {
      ..._rate(trades), 'signals_won': s.signalsWon, 'signals_lost': s.signalsLost,
      'signals_won_after_martingale': s.signalsWonGale, 'max_drawdown': double.parse(s.maxDrawdown.toStringAsFixed(2)),
      'worst_losing_streak': s.lossStreak, 'staked': double.parse(s.staked.toStringAsFixed(2)),
    },
    'per_pair': {for (final e in byPair.entries) e.key: _rate(e.value)},
    'per_hour_local': {for (final e in (byHour.entries.toList()..sort((a, b) => a.key - b.key))) '${e.key}h': _rate(e.value)},
    'per_martingale_step': {for (final e in byLevel.entries) 'step_${e.key}': _rate(e.value)},
    'signals_skipped_low_payout': payoutSkips,
    if (settings != null) 'settings': settings,
    if (backtest != null) 'backtest': backtest,
  };
}

String coachPrompt(Map<String, Object?> stats, String lang) => '''
You are a trading performance coach for a user of an auto-trading bot on Quotex (binary options, 1-minute signals
from Telegram lists, optional martingale). Look at these aggregated statistics and answer in ${lang == 'ar' ? 'Arabic' : 'English'},
in plain, short, friendly language for a non-technical user:
- summary: 2-3 sentences on how it went.
- works: what works (pairs, hours) - short bullet phrases.
- loses: which pairs or hours lose - short bullet phrases.
- martingale: whether martingale helps or hurts, from the per-step numbers.
- suggestions: 2-4 practical setting changes (e.g. raise minimum payout to X%, skip pair Y, avoid hour Z, lower the multiplier, set a daily stop-loss).
Be honest when there is too little data (under ~20 trades). Numbers are in the account currency. Do not promise profits.

Statistics (JSON):
${jsonEncode(stats)}''';

const coachSchema = {
  'type': 'OBJECT',
  'properties': {
    'summary': {'type': 'STRING'},
    'works': {'type': 'ARRAY', 'items': {'type': 'STRING'}},
    'loses': {'type': 'ARRAY', 'items': {'type': 'STRING'}},
    'martingale': {'type': 'STRING'},
    'suggestions': {'type': 'ARRAY', 'items': {'type': 'STRING'}},
  },
  'required': ['summary', 'works', 'loses', 'martingale', 'suggestions'],
};

/// The coach answer, made safe to show (strings only, bounded sizes).
Map<String, Object> cleanCoach(Object? json) {
  if (json is! Map || json['summary'] is! String) throw const AiException('bad', 'no summary');
  List<String> list(Object? v) => v is List ? [for (final x in v.take(6)) if (x is String && x.trim().isNotEmpty) x.trim()] : [];
  String text(Object? v) => v is String ? v.trim().substring(0, min(v.trim().length, 800)) : '';
  return {
    'summary': text(json['summary']), 'works': list(json['works']), 'loses': list(json['loses']),
    'martingale': text(json['martingale']), 'suggestions': list(json['suggestions']),
  };
}
