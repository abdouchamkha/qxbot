// Backtest scoring (port of bot.py backtest_result / past_signals) and AI answer validation / prompt contents.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:qxbot_app/core/ai.dart';
import 'package:qxbot_app/core/backtest.dart';
import 'package:qxbot_app/core/engine.dart';
import 'package:qxbot_app/core/parser.dart';

const tz = Duration(hours: -3);
final now = DateTime.utc(2026, 11, 8, 20, 0); // 17:00 at UTC-3

Signal sig(String dir, {int dur = 60}) => Signal(dur, 'EURUSD_otc', DateTime.utc(2026, 11, 8, 18, 0), tz, dir);
int t0 = DateTime.utc(2026, 11, 8, 18, 0).millisecondsSinceEpoch ~/ 1000;

/// Candles from [t0], one per minute: (open, close).
Map<int, Candle> candles(List<(double, double)> oc) =>
    {for (var i = 0; i < oc.length; i++) t0 + 60 * i: (time: t0 + 60 * i, open: oc[i].$1, close: oc[i].$2)};

void main() {
  group('backtest', () {
    test('win, draw, gale win, loss, no data (as bot.py)', () {
      expect(backtestResult(sig('call'), candles([(1.0, 1.1)]), 1), const BtResult('win'));
      expect('${backtestResult(sig('put'), candles([(1.0, 1.1), (1.1, 1.0)]), 1)}', 'WIN G1');
      expect('${backtestResult(sig('put'), candles([(1.0, 1.0)]), 1)}', 'DRAW');
      expect('${backtestResult(sig('call'), candles([(1.0, 0.9), (0.9, 0.8)]), 1)}', 'LOSS');
      expect('${backtestResult(sig('call'), candles([(1.0, 0.9)]), 0)}', 'LOSS');
      expect('${backtestResult(sig('call'), candles([(1.0, 0.9)]), 1)}', 'no data'); // G1 candle missing
      expect('${backtestResult(sig('call'), {}, 1)}', 'no data');
      // M2: the first level opens on the first candle and closes on the second
      expect('${backtestResult(sig('call', dur: 120), candles([(1.0, 0.9), (0.9, 1.05)]), 0)}', 'WIN');
    });

    test('summary: win rate with and without martingale, net for amount / multiplier / payout', () {
      final rows = [
        (sig('call'), const BtResult('win')),
        (sig('call'), const BtResult('win', 1)),
        (sig('call'), const BtResult('loss')),
        (sig('call'), const BtResult('draw')),
        (sig('call'), const BtResult('nodata')),
      ];
      final s = summarizeBacktest(rows, gales: 1, amount: 1, mult: 2, payout: (_) => 80);
      expect([s.wins, s.losses, s.draws, s.nodata, s.winsFirst, s.lossesFirst], [2, 1, 1, 1, 1, 2]);
      expect(s.winRate.round(), 67);
      expect(s.winRateNoGale.round(), 33);
      // +0.80, G1: 2*0.8 - 1 = +0.60, loss: -(1+2) = -3, draw 0
      expect(s.net, closeTo(-1.6, 1e-9));
      final noGale = summarizeBacktest(rows, gales: 0, amount: 1, mult: 2, payout: (_) => 80);
      expect([noGale.wins, noGale.losses], [1, 2]);
      expect(noGale.net, closeTo(0.8 - 1 - 1, 1e-9));
    });

    test('past signals: passed ones today, upcoming ones moved to yesterday, forced timezone', () {
      const list = 'UTC+1\nM1 EURUSD 16:00 CALL\nM1 EURUSD 18:00 PUT';
      final p = pastSignals(list, tz, now); // the list's UTC+1: 16:00 = 15:00 UTC passed, 18:00 = 17:00 UTC passed
      expect(p.map((s) => s.at.toIso8601String()), ['2026-11-08T15:00:00.000Z', '2026-11-08T17:00:00.000Z']);
      final forced = pastSignals(list, tz, now, forceTz: true); // read as UTC-3: 16:00 passed, 18:00 = yesterday
      expect(forced.map((s) => s.at.toIso8601String()), ['2026-11-07T21:00:00.000Z', '2026-11-08T19:00:00.000Z']);
    });
  });

  group('AI', () {
    const names = [('EURUSD_otc', 'EUR/USD (OTC)'), ('USDJPY', 'USD/JPY'), ('BTCUSD_otc', 'Bitcoin (OTC)')];

    test('valid items become signals; bad pairs, times, directions and durations are rejected', () {
      final r = validateAiSignals({
        'timezone': 'UTC-3',
        'signals': [
          {'symbol': 'EURUSD_otc', 'time': '17:30', 'direction': 'call', 'duration_seconds': 60},
          {'symbol': 'usdjpy', 'time': '18:05', 'direction': 'put', 'duration_seconds': 300},
          {'symbol': 'EURUSD_otc', 'time': '16:10', 'direction': 'put', 'duration_seconds': 60}, // passed
          {'symbol': 'XYZABC', 'time': '17:40', 'direction': 'call', 'duration_seconds': 60}, // not on Quotex
          {'symbol': 'EURUSD_otc', 'time': '25:10', 'direction': 'call', 'duration_seconds': 60},
          {'symbol': 'EURUSD_otc', 'time': '17:45', 'direction': 'up', 'duration_seconds': 60},
          {'symbol': 'EURUSD_otc', 'time': '17:50', 'direction': 'call', 'duration_seconds': 7},
          {'symbol': 'EURUSD_otc', 'time': '17:55', 'direction': 'call', 'duration_seconds': 99999},
          'garbage',
        ],
      }, names, const Duration(hours: 1), now);
      expect(r.signals.map((s) => '$s'), ['17:30 EURUSD_otc CALL 60s', '18:05 USDJPY PUT 300s']);
      expect(r.signals.first.at, DateTime.utc(2026, 11, 8, 20, 30)); // the answer's UTC-3 beats the default UTC+1
      expect(r.passed.map((s) => '$s'), ['16:10 EURUSD_otc PUT 60s']);
      expect(r.rejected.length, 6);
    });

    test('bad timezone falls back to the default; non-object answers are rejected', () {
      final r = validateAiSignals({
        'timezone': 'UTC+99',
        'signals': [{'symbol': 'BTCUSD_otc', 'time': '20:30', 'direction': 'put', 'duration_seconds': 60}],
      }, names, Duration.zero, now);
      expect(r.signals.single.at, DateTime.utc(2026, 11, 8, 20, 30));
      expect(validateAiSignals([1, 2], names, tz, now).signals, isEmpty);
      expect(validateAiSignals(null, names, tz, now).rejected, isNotEmpty);
    });

    test('prompts carry the list and aggregated stats only: no token, email or trade ids', () {
      final p = listPrompt('EUR/USD 14:30 CALL', names, tz);
      expect(p, contains('EURUSD_otc = EUR/USD (OTC)'));
      expect(p, contains('UTC-3'));
      expect(p, contains('EUR/USD 14:30 CALL'));
      final trades = [
        Trade(DateTime(2026, 11, 8, 14), true, '2026-11-08T17:00:00.000Z EURUSD_otc call', 'EURUSD_otc', 'call', 0, 1,
            'direct', 120, 1.1, 'win', 0.85),
        Trade(DateTime(2026, 11, 8, 15), false, 'sig-b', 'USDJPY', 'put', 1, 2.2, 'pending', 60, 1.1, 'loss', -2.2),
      ];
      final stats = coachStats(trades, payoutSkips: 2);
      final c = coachPrompt(stats, 'ar');
      expect(c, contains('Arabic'));
      expect(c, contains('"EURUSD_otc"'));
      final json = jsonEncode(stats);
      for (final secret in ['sig-b', '2026-11-08T17', 'token', 'session', 'email', '@', 'demo', 'uid']) {
        expect(json.toLowerCase(), isNot(contains(secret)), reason: secret);
      }
      expect((stats['per_martingale_step'] as Map).keys, containsAll(['step_0', 'step_1']));
      expect((stats['totals'] as Map)['trades'], 2);
    });

    test('coach answer is cleaned before display', () {
      final c = cleanCoach({'summary': ' ok ', 'works': ['a', 3, ''], 'loses': 'x', 'martingale': 'm', 'suggestions': ['s']});
      expect(c, {'summary': 'ok', 'works': ['a'], 'loses': <String>[], 'martingale': 'm', 'suggestions': ['s']});
      expect(() => cleanCoach({'works': []}), throwsA(isA<AiException>()));
      expect(() => Gemini('').json('x', listSchema), throwsA(isA<AiException>().having((e) => e.kind, 'kind', 'noKey')));
    });
  });
}
