// Engine decisions, ported from test_bot.py.
import 'package:flutter_test/flutter_test.dart';
import 'package:qxbot_app/core/engine.dart';
import 'package:qxbot_app/core/parser.dart';
import 'package:qxbot_app/core/quotex.dart';

const tz = Duration(hours: -3);
DateTime at3(int y, int mo, int d, int h, int mi) => DateTime.utc(y, mo, d, h, mi).subtract(tz);

/// Records what the engine sends instead of sending it.
class FakeQuotex extends QuotexClient {
  final sent = <String>[];
  FakeQuotex() : super('x', demo: true);
  @override
  void emit(String name, [Object? payload]) => sent.add(name);
}

Trade trade(String signal, String result, double profit, {int level = 0, double amount = 1, DateTime? time}) =>
    Trade(time ?? DateTime(2026, 1, 1), true, signal, 'EURUSD', 'call', level, amount, 'direct', 0, 1.0, result, profit);

void main() {
  test('isLosing: equal price is a draw', () {
    expect(isLosing('call', 1.0, 0.9), isTrue);
    expect(isLosing('call', 1.0, 1.0), isFalse);
    expect(isLosing('put', 1.0, 1.1), isTrue);
    expect(isLosing('put', 1.0, 1.0), isFalse);
  });

  test('summarize with martingale signals', () {
    final s = summarize([
      trade('a', 'loss', -1), trade('a', 'win', 0.9, level: 1, amount: 2.2),
      trade('b', 'loss', -1), trade('c', 'draw', 0),
    ]);
    expect([s.trades, s.wins, s.losses, s.draws, s.signalsWon, s.signalsLost, s.signalsWonGale, s.lossStreak],
        [4, 1, 2, 1, 1, 1, 1, 1]);
    expect(s.net.toStringAsFixed(2), '-1.10');
    expect(s.maxDrawdown.toStringAsFixed(2), '1.10');
  });

  test('median gap', () {
    expect(medianGap([0, 0.25, 0.5, 0.75, 5]), 0.25);
    expect(medianGap([0, 1]), double.infinity);
  });

  test('overlap off keeps first signal and blocks gales', () {
    final sigs = parseSignals('M1 NZDJPY-OTC 10:05 PUT\nM1 AUDCAD-OTC 10:05 CALL\nM1 USDJPY-OTC 10:06 CALL', tz,
        at3(2026, 11, 5, 10, 0));
    final e = Engine(QuotexClient('x', demo: true), Settings(), [], (_) {});
    final kept = e.schedule(sigs);
    expect(kept.map((s) => s.asset), ['NZDJPY_otc', 'USDJPY_otc']);
    final t = kept[1].at.millisecondsSinceEpoch ~/ 1000;
    expect(e.galeBlocked(t), isTrue);
    expect(e.galeBlocked(t + 60), isFalse);
    expect(Engine(QuotexClient('x', demo: true), Settings()..overlap = true, [], (_) {}).schedule(sigs).length, 3);
  });

  test('daily limits, balance and pre-entry', () {
    final q = QuotexClient('x', demo: true)..demoBalance = 100;
    final e = Engine(q, Settings()..stopLoss = 5, [trade('a', 'loss', -4, time: DateTime.now()), trade('b', 'loss', -50)], (_) {});
    final s = parseSignals('M1 EURUSD 23:59 CALL', tz, DateTime.now().subtract(const Duration(days: 1)))[0];
    expect(e.todayNet(), -4.0);
    expect(e.canTrade(s, 1), isTrue);
    expect(e.canTrade(s, 1, openLoss: 1), isFalse); // a losing gale step would reach -5
    q.demoBalance = 0.5;
    expect(e.canTrade(s, 1), isFalse);
    expect(e.limitReason(), isNull);
    expect(e.preMs(), 250); // auto, no ping measured yet
    e.pings.addAll([0.4, 0.5, 0.6]);
    expect(e.preMs(), 250);
    expect(Engine(q, Settings()..preEntryMs = 120, [], (_) {}).preMs(), 120);
  });

  test('late wake-up: a trade whose minute already started is skipped, never sent', () async {
    final q = FakeQuotex(), events = <EngineEvent>[];
    final s = parseSignals('M1 EURUSD 10:05 CALL', tz, at3(2026, 11, 5, 10, 0))[0];
    final at = s.at.millisecondsSinceEpoch / 1000;
    var t = at + 30; // Doze froze the timers through 10:05
    final e = Engine(q, Settings(), [], events.add, now: () => t);
    e.start([s]);
    await pumpEventQueue();
    expect(events.single.key, 'skipped');
    final reason = events.single.args['reason'] as EngineEvent;
    expect([reason.key, reason.args['seconds']], ['late', 30]);
    expect(q.sent, isEmpty);
    expect(e.scheduled, isEmpty);
    expect(t, at + 30);
  });

  test('resync after a reconnect: ends missed signals, keeps entered and future ones', () {
    final q = FakeQuotex()..chart = 'EURUSD', events = <EngineEvent>[];
    final sigs = parseSignals('M1 EURUSD 10:05 CALL\nM1 GBPUSD 10:06 PUT\nM1 USDJPY 10:09 CALL', tz,
        at3(2026, 11, 5, 10, 0));
    final t = sigs[2].at.millisecondsSinceEpoch / 1000 - 60; // 10:08: 10:05 and 10:06 are past
    final e = Engine(q, Settings(), [], events.add, now: () => t);
    e.scheduled.addAll(sigs);
    e.entered.add(sigs[1]); // 10:06 has an order (its result or martingale is still running)
    expect(e.resync(), 2);
    expect(e.scheduled, [sigs[1], sigs[2]]);
    expect(events.map((x) => '${x.args['pair']} ${(x.args['reason'] as EngineEvent).key}'), ['EURUSD late']);
    expect(q.chart, isNull); // the new socket's chart is unknown: show the pair again before ordering
    expect(Engine(q, Settings(), [], events.add, now: () => t - 120).resync(), 0); // nothing scheduled
  });

  test('settings saved by 1.1.0 load unchanged', () {
    final old = {
      'demo': false, 'amount': 2.5, 'utcOffsetMin': 60, 'gales': 2, 'galeMultiplier': 2.0, 'pending': false,
      'preEntryMs': 300, 'overlap': true, 'minPayout': 85, 'stopLoss': 10, 'takeProfit': 5,
    };
    final c = Settings.fromJson(old);
    expect(c.toJson(), {...old, 'minPayout': 85.0, 'stopLoss': 10.0, 'takeProfit': 5.0, 'ai': true}); // new keys: defaults
    expect(Settings.fromJson({}).toJson(), Settings().toJson()); // missing keys = defaults
  });
}
