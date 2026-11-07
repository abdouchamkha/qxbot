/// Quotex WebSocket client (Socket.IO v2 / Engine.IO 3 over dart:io). See HANDOFF-android.md for the protocol.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

typedef EventHandler = void Function(String name, dynamic data);

class QuotexClient {
  final String token;
  final bool demo;
  final String host;
  QuotexClient(this.token, {required this.demo, this.host = 'ws2.quotex.com'});

  WebSocket? _ws;
  Timer? _ping, _tick;
  String? _placeholder; // name of the event whose payload comes in the next binary frame
  Completer<void>? _auth;
  final _handlers = <EventHandler>[];

  /// Instrument rows: [1] symbol, [2] label, [4] decimals, [14] open, [18] payout M1, [19] payout M5.
  List<List<dynamic>> instruments = [];
  final ticks = <String, List<(double, double)>>{}; // symbol -> [(server ts, price)], last 50
  double? demoBalance, liveBalance;
  DateTime lastMessage = DateTime.fromMillisecondsSinceEpoch(0);
  String? chart; // pair the account's chart is on

  double? get balance => demo ? demoBalance : liveBalance;
  bool get alive => _ws?.readyState == WebSocket.open && DateTime.now().difference(lastMessage).inSeconds < 20;

  void on(EventHandler h) => _handlers.add(h);

  Future<void> connect() async {
    await close();
    final auth = _auth = Completer();
    final ws = _ws = await WebSocket.connect('wss://$host/socket.io/?EIO=3&transport=websocket',
        headers: {'User-Agent': 'Quotex/1.0', 'Origin': 'https://quotex.com'}).timeout(const Duration(seconds: 15));
    ws.listen((f) => identical(ws, _ws) ? _onFrame(f) : null, // ignore a replaced socket's last frames
        onDone: () => auth.isCompleted ? null : auth.completeError('socket closed'), onError: (_) {}, cancelOnError: false);
    _ping = Timer.periodic(const Duration(seconds: 25), (_) => _send('2'));
    _tick = Timer.periodic(const Duration(seconds: 5), (_) => emit('tick'));
    await auth.future.timeout(const Duration(seconds: 15));
    emit('instruments/get');
    emit('balance/list');
    chart = null;
  }

  Future<void> close() async {
    _ping?.cancel();
    _tick?.cancel();
    await _ws?.close();
    _ws = null;
  }

  void _send(String s) {
    if (_ws?.readyState == WebSocket.open) _ws!.add(s);
  }

  /// Send `42["name",payload]`.
  void emit(String name, [Object? payload]) =>
      _send('42${jsonEncode(payload == null ? [name] : [name, payload])}');

  void _onFrame(dynamic frame) {
    lastMessage = DateTime.now();
    if (frame is String) {
      if (frame == '40') {
        emit('authorization', {'session': token, 'isDemo': demo ? 1 : 0, 'tournamentId': 0});
      } else if (frame == '2') {
        _send('3');
      } else if (frame.startsWith('451-')) {
        final msg = jsonDecode(frame.substring(4)) as List;
        _placeholder = msg[0] as String;
      } else if (frame.startsWith('42')) {
        final msg = jsonDecode(frame.substring(2)) as List;
        _dispatch(msg[0] as String, msg.length > 1 ? msg[1] : null);
      }
      return;
    }
    final bytes = frame as List<int>;
    var i = 0;
    while (i < bytes.length && bytes[i] != 0x5b && bytes[i] != 0x7b) {
      i++; // strip the 0x04 binary marker
    }
    dynamic data;
    try {
      data = jsonDecode(utf8.decode(bytes.sublist(i), allowMalformed: true));
    } catch (_) {
      return;
    }
    final name = _placeholder ?? '';
    _placeholder = null;
    _dispatch(name, data);
  }

  void _dispatch(String name, dynamic data) {
    if (name == 's_authorization') _auth?.isCompleted == false ? _auth!.complete() : null;
    if (name == 'f_authorization' && _auth?.isCompleted == false) _auth!.completeError('authorization failed: $data');
    if (name == 'instruments/list' && data is List) instruments = data.whereType<List>().toList();
    if (data is Map && data.containsKey('demoBalance')) {
      demoBalance = (data['demoBalance'] as num?)?.toDouble();
      liveBalance = (data['liveBalance'] as num?)?.toDouble();
    }
    if (data is Map && data['accountBalance'] is num) {
      final b = (data['accountBalance'] as num).toDouble();
      demo ? demoBalance = b : liveBalance = b;
    }
    if (data is List && data.isNotEmpty && data.first is List) {
      for (final row in data) {
        if (row is List && row.length >= 3 && row[0] is String && row[1] is num && row[2] is num) {
          final list = ticks.putIfAbsent(row[0] as String, () => []);
          list.add(((row[1] as num).toDouble(), (row[2] as num).toDouble()));
          if (list.length > 50) list.removeAt(0);
        }
      }
    }
    for (final h in List.of(_handlers)) {
      h(name, data);
    }
  }

  List<dynamic>? instrument(String symbol) => instruments.where((r) => r.length > 19 && r[1] == symbol).firstOrNull;

  /// (symbol, label) rows for the parser.
  List<(String, String)> get names => [for (final r in instruments) if (r.length > 2) ('${r[1]}', '${r[2]}')];

  double? price(String asset) => ticks[asset]?.lastOrNull?.$2;
  double tickTime(String asset) => ticks[asset]?.lastOrNull?.$1 ?? 0;

  /// Put the account's chart on [asset] (Quotex ignores direct orders for another pair).
  void show(String asset, int duration, int endTime) {
    emit('instruments/update', {'asset': asset, 'period': duration});
    emit('depth/follow', asset);
    emit('settings/apply', {
      'chartId': 'graph',
      'settings': {
        'chartId': 'graph', 'chartType': 2, 'currentExpirationTime': endTime, 'isFastOption': true,
        'isFastAmountOption': false, 'isIndicatorsMinimized': false, 'isIndicatorsShowing': true,
        'isShortBetElement': false, 'chartPeriod': 4, 'currentAsset': {'symbol': asset}, 'dealValue': 5,
        'dealPercentValue': 1, 'isVisible': true, 'timePeriod': duration, 'gridOpacity': 8, 'isAutoScrolling': 1,
        'isOneClickTrade': true, 'upColor': '#0FAF59', 'downColor': '#FF6251',
      },
      'endTime': endTime,
    });
    chart = asset;
  }

  /// Wait for the first event matching [test] (or time out -> null).
  Future<(String, dynamic)?> next(bool Function(String name, dynamic data) test, Duration timeout) {
    final c = Completer<(String, dynamic)?>();
    late EventHandler h;
    h = (n, d) {
      if (!c.isCompleted && test(n, d)) c.complete((n, d));
    };
    _handlers.add(h);
    return c.future.timeout(timeout, onTimeout: () => null).whenComplete(() => _handlers.remove(h));
  }
}
