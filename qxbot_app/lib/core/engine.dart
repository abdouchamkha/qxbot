/// Trading engine: a port of bot.py `Bot` (run_signal, place, place_pending, martingale, limits, stats).
library;

import 'dart:async';
import 'dart:math';

import 'parser.dart';
import 'quotex.dart';

class Settings {
  bool demo = true; // PRACTICE
  double amount = 1;
  int utcOffsetMin = -180; // the signal list's timezone; a "UTC+6" in the list overrides it
  int gales = 1;
  double galeMultiplier = 2.2;
  bool pending = true;
  int? preEntryMs; // null = auto (half the measured order round trip)
  bool overlap = false;
  double minPayout = 80;
  double stopLoss = 0, takeProfit = 0; // 0 = off

  Map<String, dynamic> toJson() => {
        'demo': demo, 'amount': amount, 'utcOffsetMin': utcOffsetMin, 'gales': gales,
        'galeMultiplier': galeMultiplier, 'pending': pending, 'preEntryMs': preEntryMs, 'overlap': overlap,
        'minPayout': minPayout, 'stopLoss': stopLoss, 'takeProfit': takeProfit,
      };

  static Settings fromJson(Map<String, dynamic> j) => Settings()
    ..demo = j['demo'] ?? true
    ..amount = (j['amount'] ?? 1).toDouble()
    ..utcOffsetMin = j['utcOffsetMin'] ?? -180
    ..gales = j['gales'] ?? 1
    ..galeMultiplier = (j['galeMultiplier'] ?? 2.2).toDouble()
    ..pending = j['pending'] ?? true
    ..preEntryMs = j['preEntryMs']
    ..overlap = j['overlap'] ?? false
    ..minPayout = (j['minPayout'] ?? 80).toDouble()
    ..stopLoss = (j['stopLoss'] ?? 0).toDouble()
    ..takeProfit = (j['takeProfit'] ?? 0).toDouble();
}

class Trade {
  final DateTime time;
  final bool demo;
  final String signal, asset, direction, entry, result;
  final int level, delayMs;
  final double amount, profit;
  final double? openPrice;
  Trade(this.time, this.demo, this.signal, this.asset, this.direction, this.level, this.amount, this.entry, this.delayMs,
      this.openPrice, this.result, this.profit);

  Map<String, dynamic> toJson() => {
        't': time.toIso8601String(), 'demo': demo, 'signal': signal, 'asset': asset, 'dir': direction, 'level': level,
        'amount': amount, 'entry': entry, 'delay': delayMs, 'open': openPrice, 'result': result, 'profit': profit,
      };
  static Trade fromJson(Map<String, dynamic> j) => Trade(DateTime.parse(j['t']), j['demo'], j['signal'], j['asset'],
      j['dir'], j['level'], (j['amount'] as num).toDouble(), j['entry'], j['delay'], (j['open'] as num?)?.toDouble(),
      j['result'], (j['profit'] as num).toDouble());
}

class Stats {
  int trades = 0, wins = 0, losses = 0, draws = 0, signalsWon = 0, signalsLost = 0, signalsWonGale = 0, lossStreak = 0;
  double net = 0, staked = 0, maxDrawdown = 0;
  double get winRate => wins + losses == 0 ? 0 : 100 * wins / (wins + losses);
}

/// bot.py summarize(): a signal's last step decides it.
Stats summarize(List<Trade> rows) {
  final s = Stats()..trades = rows.length;
  final last = <String, Trade>{};
  double equity = 0, peak = 0;
  var streak = 0;
  for (final r in rows) {
    if (r.result == 'win') s.wins++;
    if (r.result == 'loss') s.losses++;
    s.net += r.profit;
    s.staked += r.amount;
    equity += r.profit;
    peak = max(peak, equity);
    s.maxDrawdown = max(s.maxDrawdown, peak - equity);
    streak = r.result == 'loss' ? streak + 1 : 0;
    s.lossStreak = max(s.lossStreak, streak);
    last[r.signal] = r;
  }
  s.draws = s.trades - s.wins - s.losses;
  for (final r in last.values) {
    if (r.result == 'win') {
      s.signalsWon++;
      if (r.level > 0) s.signalsWonGale++;
    }
    if (r.result == 'loss') s.signalsLost++;
  }
  return s;
}

/// Equal price is a refund (draw) on Quotex, so not a loss.
bool isLosing(String direction, double openPrice, double price) =>
    direction == 'call' ? price < openPrice : price > openPrice;

/// Typical seconds between price updates over the last 10 ticks (infinity if unknown).
double medianGap(List<double> times) {
  final t = times.length > 11 ? times.sublist(times.length - 11) : times;
  final gaps = [for (var i = 1; i < t.length; i++) t[i] - t[i - 1]]..sort();
  return gaps.length >= 3 ? gaps[gaps.length ~/ 2] : double.infinity;
}

/// Serialises async sections (Quotex has one chart per account).
class Lock {
  Future<void> _last = Future.value();
  Future<T> run<T>(Future<T> Function() f) {
    final prev = _last;
    final done = Completer<void>();
    _last = done.future;
    return prev.then((_) => f()).whenComplete(done.complete);
  }
}

double nowS() => DateTime.now().millisecondsSinceEpoch / 1000;

class Engine {
  final QuotexClient q;
  final Settings cfg;
  final List<Trade> history; // all trades (persisted by the caller via onTrade)
  final void Function(String) log;
  final void Function(Trade)? onTrade;
  Engine(this.q, this.cfg, this.history, this.log, {this.onTrade}) {
    q.on(_onEvent);
  }

  final taken = <int>{};
  final pings = <double>[];
  final chart = Lock(), pendingLock = Lock(), reconnecting = Lock();
  var _requestId = DateTime.now().millisecondsSinceEpoch;
  final _orders = <String, Completer<Map>>{}; // requestId or asset -> open reply
  final _pendingOpened = <String, Completer<Map>>{}; // ticket -> open result
  final _results = <String, Completer<double>>{}; // deal id -> profit
  final _earlyResults = <String, double>{};
  Completer<Map>? _pendingReply;
  String? _pendingAsset;
  bool stopped = false;
  final scheduled = <Signal>[];
  final started = DateTime.now();

  double get ping {
    if (pings.isEmpty) return 0.5;
    final s = [...pings]..sort();
    return s[s.length ~/ 2];
  }

  int preMs() => cfg.preEntryMs ?? min(600, max(50, (ping * 500).round()));
  double lead() => max(0.5, preMs() / 1000 + 0.3);

  Future<void> sleepUntil(double t) async {
    final ms = ((t - nowS()) * 1000).round();
    if (ms > 0) await Future.delayed(Duration(milliseconds: ms));
  }

  void _onEvent(String name, dynamic data) {
    if (name.contains('pending')) log('  quotex $name ${_short(data)}'); // shortcut: raw log until pending replies are fully mapped
    if (name == 's_pending/create' || name == 'f_pending/create') {
      // Another app on the same account gets these too: only take a reply for our pair.
      final asset = data is Map && data['pending'] is Map ? (data['pending'] as Map)['asset'] : null;
      if (_pendingReply?.isCompleted == false && (asset == null || asset == _pendingAsset)) {
        _pendingReply!.complete(data is Map ? data : {'error': '$data'});
      }
    }
    // Quotex also sends f_pending/opened WITHOUT an error for orders it then opens normally (seen on demo
    // 2026-11-07: f_ at :00.4, s_pending/opened at :04.7, order opened): only an error code is a failure.
    if (name == 'f_pending/opened' && data is Map && data['ticket'] != null && data['error'] != null) {
      _pendingOpened.remove('${data['ticket']}')?.complete({'error': 'pending failed (code ${data['error']})'});
    }
    if ((name == 's_orders/open' || name == 'f_orders/open') && data is Map) {
      final c = _pendingOpened.remove('${data['id']}') ??
          _orders.remove('${data['requestId']}') ??
          _orders.remove('${data['asset'] ?? ''}');
      if (c != null && !c.isCompleted) c.complete(name.startsWith('f_') && !data.containsKey('error') ? {'error': '$data'} : data);
    }
    // Closed trades: s_orders/close (list or {deals: [...]}), or any message with deals.
    final items = <dynamic>[
      if (name.contains('close') && data is List) ...data,
      if (data is Map && data['deals'] is List) ...data['deals'] as List,
    ];
    for (final d in items) {
      if (d is Map && d['id'] != null && d['profit'] is num && (name.contains('close') || d['closePrice'] != null)) {
        final id = '${d['id']}', profit = (d['profit'] as num).toDouble();
        final c = _results.remove(id);
        c != null ? c.complete(profit) : _earlyResults[id] = profit;
      }
    }
  }

  // ------------------------------------------------------------ limits

  double todayNet() {
    final n = DateTime.now();
    return history
        .where((t) => t.demo == cfg.demo && t.time.year == n.year && t.time.month == n.month && t.time.day == n.day)
        .fold(0.0, (a, t) => a + t.profit);
  }

  String? limitReason([double openLoss = 0]) {
    final net = todayNet() - openLoss;
    if (cfg.stopLoss > 0 && net <= -cfg.stopLoss) return 'daily stop-loss reached (today ${_money(net)})';
    if (cfg.takeProfit > 0 && net >= cfg.takeProfit) return 'daily take-profit reached (today ${_money(net)})';
    return null;
  }

  bool canTrade(Signal s, double amount, {double openLoss = 0}) {
    var reason = limitReason(openLoss);
    if (reason == null && amount > (q.balance ?? 0)) {
      reason = "balance ${(q.balance ?? 0).toStringAsFixed(2)} can't cover ${amount.toStringAsFixed(2)}";
    }
    if (reason != null) log('${s.hhmm} ${s.asset} ${s.direction.toUpperCase()} skipped: $reason');
    return reason == null;
  }

  /// Without overlap, keep only the first list signal per candle start.
  List<Signal> schedule(List<Signal> signals) {
    final kept = <Signal>[];
    for (final s in signals) {
      final at = s.at.millisecondsSinceEpoch ~/ 1000;
      if (!cfg.overlap && taken.contains(at)) {
        log('${s.hhmm} ${s.asset} ${s.direction.toUpperCase()} skipped: another signal has this minute (overlap off)');
        continue;
      }
      taken.add(at);
      kept.add(s);
    }
    return kept;
  }

  bool galeBlocked(int at) => !cfg.overlap && taken.contains(at);

  /// Schedule and run a list (returns at once; trades run in the background).
  List<Signal> start(List<Signal> signals) {
    stopped = false;
    final kept = schedule(signals);
    scheduled.addAll(kept);
    for (final s in kept) {
      runSignal(s).catchError((e) => log('${s.asset} error: $e')).whenComplete(() => scheduled.remove(s));
    }
    return kept;
  }

  void stop() {
    stopped = true;
    scheduled.clear();
    taken.clear();
  }

  Future<bool> ensureConnected() => reconnecting.run(() async {
        for (var i = 0; i < 10; i++) {
          if (q.alive) return true;
          await Future.delayed(const Duration(seconds: 1));
        }
        log('Connection lost, logging in again...');
        try {
          await q.connect();
          return true;
        } catch (e) {
          log('Reconnect failed: $e');
          return false;
        }
      });

  Future<List<dynamic>?> instrument(String asset) async {
    q.emit('instruments/get');
    await Future.delayed(const Duration(seconds: 2));
    return q.instrument(asset);
  }

  // ------------------------------------------------------------ orders

  bool _losing(Signal s, Map data) {
    final p = q.price(s.asset), o = (data['openPrice'] as num?)?.toDouble();
    return p != null && o != null && isLosing(s.direction, o, p);
  }

  /// Direct order for the candle starting at [at] (unix s).
  Future<Map?> place(Signal s, int at, double amount) async {
    final requestId = '${++_requestId}'; // unique, Quotex dedupes
    final payload = {
      'asset': s.asset, 'amount': amount, 'time': at + s.duration, 'action': s.direction,
      'isDemo': cfg.demo ? 1 : 0, 'tournamentId': 0, 'requestId': int.parse(requestId), 'optionType': 3,
    };
    await sleepUntil(at - lead());
    if (stopped) return null;
    final c = Completer<Map>();
    late double sent;
    await chart.run(() async {
      await _waitEntry(s, at);
      _orders[requestId] = _orders[s.asset] = c;
      q.emit('orders/open', payload);
      sent = nowS();
    });
    Map data;
    try {
      data = await c.future.timeout(const Duration(seconds: 10));
      pings.add(nowS() - sent);
      if (pings.length > 20) pings.removeAt(0);
    } on TimeoutException {
      log('${s.asset} order not confirmed (pair closed or amount invalid?)');
      return null;
    } finally {
      _orders.remove(requestId);
      _orders.remove(s.asset);
    }
    if (data.containsKey('error')) {
      log('${s.asset} ${s.direction.toUpperCase()} REJECTED by Quotex: ${data['error']}');
      return null;
    }
    data = Map.of(data);
    data['delay_ms'] = _delay(data, at);
    log('${s.asset} ${s.direction.toUpperCase()} \$$amount opened ${_signed(data['delay_ms'])}ms vs ${_clock(at)} '
        '(sent ${_signed(((sent - at) * 1000).round())}ms, ping ${((pings.lastOrNull ?? 0) * 1000).round()}ms) '
        'open=${data['openPrice']}');
    return data;
  }

  int _delay(Map data, int at) =>
      (((data['openTimestamp'] as num) + ((data['openMs'] as num?) ?? 0) / 1000 - at) * 1000).round();

  /// Hold the chart lock. Fast pair: send pre_entry ms before :00. Slow pair: wait for a tick stamped >= :00.
  Future<void> _waitEntry(Signal s, int at) async {
    if (q.chart != s.asset) q.show(s.asset, s.duration, at + s.duration);
    if (preMs() > 0) {
      await sleepUntil(at - preMs() / 1000);
      final times = [for (final t in q.ticks[s.asset] ?? <(double, double)>[]) t.$1];
      if (medianGap(times) < ping) return;
    }
    while (q.tickTime(s.asset) < at && nowS() < at + 1.5) {
      await Future.delayed(const Duration(milliseconds: 2));
    }
  }

  /// Quotex pending order by time (OTC only, >= 60s ahead). Returns the opened order,
  /// {"error": ...} if refused/failed, or null if no answer.
  Future<Map?> placePending(Signal s, int at, double amount) async {
    final payload = {
      'openType': 0, 'asset': s.asset, 'timeframe': s.duration, 'command': s.direction, 'amount': amount,
      'openTime': '${DateTime.fromMillisecondsSinceEpoch(at * 1000, isUtc: true).toIso8601String().substring(0, 19)}.000Z',
    };
    final reply = await pendingLock.run(() async {
      _pendingReply = Completer();
      _pendingAsset = s.asset;
      final sent = nowS();
      q.emit('pending/create', payload);
      try {
        final r = await _pendingReply!.future.timeout(const Duration(seconds: 10));
        pings.add(nowS() - sent);
        return r;
      } on TimeoutException {
        return {'error': 'no reply to pending/create'};
      }
    });
    if (reply.containsKey('error')) return reply;
    final t = (reply['pending'] as Map?)?['ticket'];
    if (t == null) {
      log('${s.asset} pending reply without ticket: skipped (no risk of a double entry)');
      return null;
    }
    final ticket = '$t';
    final c = _pendingOpened[ticket] = Completer();
    log('${s.asset} ${s.direction.toUpperCase()} \$$amount pending order set for ${_clock(at)} (Quotex opens it)');
    await sleepUntil(at - 3.0);
    final reason = stopped ? 'stopped' : limitReason();
    if (reason != null) {
      q.emit('pending/cancel', {'ticket': ticket});
      log('${s.asset} pending order cancelled: $reason');
      _pendingOpened.remove(ticket);
      return {'error': 'cancelled', 'cancelled': true};
    }
    Map data;
    try {
      data = await c.future.timeout(Duration(milliseconds: ((at + 15 - nowS()) * 1000).round()));
    } on TimeoutException {
      return null;
    } finally {
      _pendingOpened.remove(ticket);
    }
    if (data.containsKey('error')) return data;
    data = Map.of(data);
    data['delay_ms'] = _delay(data, at);
    log('${s.asset} ${s.direction.toUpperCase()} \$$amount opened ${_signed(data['delay_ms'])}ms vs ${_clock(at)} '
        'by Quotex (pending) open=${data['openPrice']}');
    return data;
  }

  Future<void> runSignal(Signal s) async {
    var at = s.at.millisecondsSinceEpoch ~/ 1000;
    var amount = cfg.amount;
    final signal = '${s.at.toIso8601String()} ${s.asset} ${s.direction}';
    final usePending = cfg.pending && s.asset.endsWith('_otc') && at - nowS() > 70;
    await sleepUntil(at - (usePending ? 70.0 : 15.0));
    if (stopped) return;
    if (!await ensureConnected()) return log('${s.hhmm} ${s.asset} skipped: not connected');
    final info = await instrument(s.asset);
    if (info == null) return log('${s.hhmm} ${s.asset} skipped: pair not found on Quotex');
    if (info[14] != true) return log('${s.hhmm} ${s.asset} skipped: Quotex has this pair closed right now');
    final payout = info[s.duration < 300 ? 18 : 19];
    if (payout is num && payout < cfg.minPayout) {
      return log('${s.hhmm} ${s.asset} ${s.direction.toUpperCase()} skipped: payout $payout% < ${cfg.minPayout}%');
    }
    if (!canTrade(s, amount)) return;
    Map? data;
    var kind = 'pending';
    if (usePending) {
      data = await placePending(s, at, amount);
      if (data?['cancelled'] == true) return;
      if (data == null || data.containsKey('error')) {
        log('${s.asset} pending order ${data == null ? 'not confirmed: checking' : '${data['error']}: entering directly'}');
        if (data == null) return; // no answer: don't risk a double entry
        data = null;
      }
    }
    if (data == null) await chart.run(() async => q.show(s.asset, s.duration, at + s.duration));
    for (var level = 0; level <= cfg.gales; level++) {
      if (data == null) {
        data = await place(s, at, amount);
        kind = 'direct';
      }
      if (data == null) return;
      _report(s, data, level, amount, signal, kind);
      if (level == cfg.gales) return;
      final end = at + s.duration;
      await sleepUntil(end - 5.0);
      if (!galeBlocked(end)) {
        await chart.run(() async => q.show(s.asset, s.duration, end + s.duration));
        if (_losing(s, data)) log('${s.asset} losing with 5s left, gale ${level + 1} ready');
      }
      await sleepUntil(end - lead()); // final call just before expiry: a late reversal can still save it
      if (stopped || !_losing(s, data)) return;
      if (galeBlocked(end)) return log('gale on ${s.asset} cancelled: a list signal has ${_clock(end)} (overlap off)');
      final nextAmount = (amount * cfg.galeMultiplier * 100).round() / 100;
      if (!canTrade(s, nextAmount, openLoss: amount)) return;
      at = end;
      amount = nextAmount;
      data = null;
      log('gale ${level + 1} on ${s.asset}: \$$amount');
    }
  }

  /// Wait for the deal's close and record it.
  Future<void> _report(Signal s, Map data, int level, double amount, String signal, String entry) async {
    final id = '${data['id']}';
    final c = _results[id] = Completer();
    if (_earlyResults.containsKey(id)) c.complete(_earlyResults.remove(id));
    final closeAt = ((data['closeTimestamp'] as num?) ?? nowS() + s.duration).toDouble();
    double profit;
    try {
      profit = await c.future.timeout(Duration(milliseconds: ((closeAt + 30 - nowS()) * 1000).round()));
    } on TimeoutException {
      _results.remove(id);
      return log('${s.asset} result not received (check Quotex history)');
    }
    final result = profit > 0 ? 'win' : profit < 0 ? 'loss' : 'draw';
    final t = Trade(DateTime.fromMillisecondsSinceEpoch(((data['openTimestamp'] as num) * 1000).round()), cfg.demo,
        signal, s.asset, s.direction, level, amount, entry, data['delay_ms'] as int,
        (data['openPrice'] as num?)?.toDouble(), result, profit);
    history.add(t);
    onTrade?.call(t);
    q.emit('balance/list'); // closes don't carry the new balance
    log('${s.asset} ${s.direction.toUpperCase()}${level > 0 ? ' G$level' : ''}: ${result.toUpperCase()} ${_money(profit)}');
  }
}

String _short(dynamic d) {
  final t = '$d';
  return t.length > 300 ? '${t.substring(0, 300)}...' : t;
}

String _money(double v) => '${v >= 0 ? '+' : ''}${v.toStringAsFixed(2)}';
String _signed(dynamic v) => '${v >= 0 ? '+' : ''}$v';
String _clock(int unix) {
  final d = DateTime.fromMillisecondsSinceEpoch(unix * 1000);
  return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
}
