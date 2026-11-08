// Demo-account check of the core against real Quotex. PRACTICE only (isDemo is hard-wired to 1 here).
//   dart run tool/cli.dart <token-file> info            balance + open pairs
//   dart run tool/cli.dart <token-file> trade [PAIR]    one $1 direct order + one $1 pending order, then results
//   dart run tool/cli.dart <token-file> pending [PAIR]  one $1 pending order only
//   dart run tool/cli.dart <token-file> clock [PAIR]    follow a pair's ticks for 20s and print the clock estimate (no trade)
import 'dart:io';

import 'package:qxbot_app/core/engine.dart';
import 'package:qxbot_app/core/parser.dart';
import 'package:qxbot_app/core/quotex.dart';

/// Phone clock minus time.google.com (SNTP), seconds; null if unreachable. Reference for the clock check.
Future<double?> ntpOffset() async {
  try {
    final addr = (await InternetAddress.lookup('time.google.com')).first;
    final sock = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    final req = List<int>.filled(48, 0)..[0] = 0x1b;
    final t0 = DateTime.now().microsecondsSinceEpoch / 1e6;
    sock.send(req, addr, 123);
    final d = await sock.where((e) => e == RawSocketEvent.read).map((_) => sock.receive()).firstWhere((d) => d != null)
        .timeout(const Duration(seconds: 3));
    final t3 = DateTime.now().microsecondsSinceEpoch / 1e6;
    sock.close();
    final b = d!.data;
    int u32(int i) => (b[i] << 24) | (b[i + 1] << 16) | (b[i + 2] << 8) | b[i + 3];
    final server = u32(40) - 2208988800 + u32(44) / 4294967296;
    return (t0 + t3) / 2 - server;
  } catch (_) {
    return null;
  }
}

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
  if (args.length > 1 && args[1] == 'clock') {
    q.follow(args.length > 2 ? args[2] : 'EURUSD_otc');
    for (var i = 0; i < 10; i++) {
      await Future.delayed(const Duration(seconds: 2));
      final o = q.clock.offset;
      final ntp = await ntpOffset();
      say('clock: ${o == null ? 'not verified (no ticks)' : 'phone vs Quotex ${o >= 0 ? '+' : ''}${o.toStringAsFixed(3)} s'}'
          ' (one-way latency ${q.clock.latency.toStringAsFixed(3)} s, ${q.ticks.values.fold(0, (a, l) => a + l.length)} ticks)'
          '${ntp == null ? '' : ' | phone vs NTP ${ntp >= 0 ? '+' : ''}${ntp.toStringAsFixed(3)} s'}');
    }
  }
  if (args.length > 1 && (args[1] == 'trade' || args[1] == 'pending')) {
    final onlyPending = args[1] == 'pending';
    final pair = args.length > 2 ? args[2] : 'EURUSD_otc';
    final cfg = Settings()
      ..demo = true
      ..gales = 0
      ..minPayout = 0;
    final e = Engine(q, cfg, [], (ev) => say('$ev'));
    final now = q.clock.now();
    var direct = ((now + 20) ~/ 60 + 1) * 60; // 20..80s away
    if (direct - now > 68) direct -= 60; // keep it a direct order (pending needs > 70s)
    if (direct - now < 18) direct += 60;
    final pending = direct + 120; // > 70s ahead: Quotex pending order
    Signal sig(int t, String dir) =>
        Signal(60, pair, DateTime.fromMillisecondsSinceEpoch(t * 1000, isUtc: true), Duration.zero, dir);
    e.start([if (!onlyPending) sig(direct, 'call'), sig(pending, 'put')]);
    say('scheduled direct CALL at ${DateTime.fromMillisecondsSinceEpoch(direct * 1000)} and pending PUT at '
        '${DateTime.fromMillisecondsSinceEpoch(pending * 1000)} on $pair');
    while (e.history.length < (onlyPending ? 1 : 2) && q.clock.now() < pending + 120) {
      await Future.delayed(const Duration(seconds: 1));
    }
    final s = summarize(e.history);
    say('stats: ${s.trades} trades ${s.wins}W ${s.losses}L ${s.draws}D net ${s.net.toStringAsFixed(2)} '
        'balance ${q.demoBalance}');
  }
  await q.close();
  exit(0);
}
