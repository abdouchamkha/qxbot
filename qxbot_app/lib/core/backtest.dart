/// Backtest of past signals against Quotex 1-minute candles: a port of bot.py `backtest_result` / `past_signals`.
library;

import 'dart:math';

import 'engine.dart' show isLosing;
import 'parser.dart';

/// A 1-minute candle (open time in unix seconds).
typedef Candle = ({int time, double open, double close});

/// Outcome of one signal: win / draw at [level] (0 = first entry, 1 = G1...), loss (every level lost), or nodata.
class BtResult {
  final String kind; // win | loss | draw | nodata
  final int level;
  const BtResult(this.kind, [this.level = 0]);

  /// The same signal traded with only [gales] martingale steps (scored with at least that many).
  BtResult withGales(int gales) =>
      (kind == 'win' || kind == 'draw') && level > gales ? const BtResult('loss') : this;

  /// bot.py's labels: WIN, WIN G1, DRAW, LOSS, no data.
  @override
  String toString() => kind == 'nodata' ? 'no data' : '${kind.toUpperCase()}${level > 0 ? ' G$level' : ''}';
  @override
  bool operator ==(Object o) => o is BtResult && o.kind == kind && o.level == level;
  @override
  int get hashCode => Object.hash(kind, level);
}

/// A level loses on the candle(s) of its expiry; a loss goes to the next gale, like live trading.
/// shortcut: candle open/close, not the exact tick a live order would get; fine for a past-list check.
BtResult backtestResult(Signal s, Map<int, Candle> candles, int gales) {
  var t = s.at.millisecondsSinceEpoch ~/ 1000;
  for (var level = 0; level <= gales; level++) {
    final first = candles[t], last = candles[t + s.duration - 60];
    if (first == null || last == null) return const BtResult('nodata');
    if (last.close == first.open) return BtResult('draw', level);
    if (!isLosing(s.direction, first.open, last.close)) return BtResult('win', level);
    t += s.duration;
  }
  return const BtResult('loss');
}

final _tzRe = RegExp(r'\b(?:UTC|GMT)\s?([+\-−])\s?(\d{1,2})(?:[:.]?(\d{2}))?', caseSensitive: false);

/// Every signal of a list at its latest time before [now] (within 24 h), for a backtest.
/// [forceTz]: use [tz] even if the list names its own timezone (to try other timezones).
List<Signal> pastSignals(String text, Duration tz, DateTime now, {List<(String, String)>? names, bool forceTz = false}) {
  if (forceTz) text = text.replaceAll(_tzRe, ' ');
  final passed = <Signal>[];
  final future = parseSignals(text, tz, now, names: names, passed: passed);
  return [
    ...passed,
    for (final s in future) Signal(s.duration, s.asset, s.at.subtract(const Duration(days: 1)), s.offset, s.direction),
  ]..sort((a, b) => a.at.compareTo(b.at));
}

/// Totals of a backtest for [gales] martingale steps, [amount] per first entry, gale [mult], and the
/// payout % of each pair ([payout]; null = unknown -> [defaultPayout]).
class BtSummary {
  int wins = 0, losses = 0, draws = 0, nodata = 0, winsFirst = 0, lossesFirst = 0;
  double net = 0;
  double get winRate => wins + losses == 0 ? 0 : 100 * wins / (wins + losses);
  double get winRateNoGale => winsFirst + lossesFirst == 0 ? 0 : 100 * winsFirst / (winsFirst + lossesFirst);
}

BtSummary summarizeBacktest(List<(Signal, BtResult)> rows,
    {required int gales, required double amount, required double mult, double? Function(String asset)? payout,
    double defaultPayout = 80}) {
  final s = BtSummary();
  double stake(int level) => amount * pow(mult, level);
  double spent(int levels) => [for (var i = 0; i < levels; i++) stake(i)].fold(0.0, (a, b) => a + b);
  for (final (sig, raw) in rows) {
    if (raw.kind == 'nodata') {
      s.nodata++;
      continue;
    }
    // without martingale: the first candle alone decides
    final first = raw.withGales(0);
    if (first.kind == 'win') s.winsFirst++;
    if (first.kind == 'loss') s.lossesFirst++;
    final r = raw.withGales(gales);
    final p = (payout?.call(sig.asset) ?? defaultPayout) / 100;
    switch (r.kind) {
      case 'win':
        s.wins++;
        s.net += stake(r.level) * p - spent(r.level);
      case 'draw':
        s.draws++;
        s.net -= spent(r.level);
      default:
        s.losses++;
        s.net -= spent(gales + 1);
    }
  }
  return s;
}
