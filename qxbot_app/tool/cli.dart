// Demo-account check of the core against real Quotex. PRACTICE only (isDemo is hard-wired to 1 here).
//   dart run tool/cli.dart <token-file> info            balance + open pairs
//   dart run tool/cli.dart <token-file> trade [PAIR]    one $1 direct order + one $1 pending order, then results
import 'dart:io';

import 'package:qxbot_app/core/engine.dart';
import 'package:qxbot_app/core/parser.dart';
import 'package:qxbot_app/core/quotex.dart';

void say(String m) => print('[${DateTime.now().toIso8601String().substring(11, 23)}] $m');

Future<void> main(List<String> args) async {
  final token = File(args[0]).readAsStringSync().trim();
  final q = QuotexClient(token, demo: true);
  await q.connect();
  await q.next((n, d) => n == 'instruments/list', const Duration(seconds: 10));
  await Future.delayed(const Duration(seconds: 2));
  say('connected. demo balance ${q.demoBalance}, live balance ${q.liveBalance == null ? 'n/a' : '(hidden)'}');
  final open = q.instruments.where((r) => r[14] == true).toList();
  say('${q.instruments.length} pairs, ${open.length} open; e.g. ${open.take(5).map((r) => '${r[1]} ${r[18]}%').join(', ')}');
  final parsed = parseSignals('EUR/USD OTC 10:00 CALL\nBitcoin OTC 10:01 PUT', Duration.zero,
      DateTime.utc(2026, 1, 1, 9), names: q.names);
  say('parser with live pair list: $parsed');
  if (args.length > 1 && args[1] == 'trade') {
    final pair = args.length > 2 ? args[2] : 'EURUSD_otc';
    final cfg = Settings()
      ..demo = true
      ..gales = 0
      ..minPayout = 0;
    final e = Engine(q, cfg, [], say);
    final now = nowS();
    var direct = ((now + 25) ~/ 60 + 1) * 60; // next minute at least 25s away
    final pending = direct + 120; // > 70s ahead: Quotex pending order
    Signal sig(int t, String dir) =>
        Signal(60, pair, DateTime.fromMillisecondsSinceEpoch(t * 1000, isUtc: true), Duration.zero, dir);
    e.start([sig(direct, 'call'), sig(pending, 'put')]);
    say('scheduled direct CALL at ${DateTime.fromMillisecondsSinceEpoch(direct * 1000)} and pending PUT at '
        '${DateTime.fromMillisecondsSinceEpoch(pending * 1000)} on $pair');
    while (e.history.length < 2 && nowS() < pending + 120) {
      await Future.delayed(const Duration(seconds: 1));
    }
    final s = summarize(e.history);
    say('stats: ${s.trades} trades ${s.wins}W ${s.losses}L ${s.draws}D net ${s.net.toStringAsFixed(2)} '
        'balance ${q.demoBalance}');
  }
  await q.close();
  exit(0);
}
