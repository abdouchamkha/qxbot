import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'core/engine.dart';
import 'core/parser.dart';
import 'core/quotex.dart';
import 'format.dart';
import 'l10n/app_localizations.dart';

/// The foreground service only keeps the app process alive (and shows results);
/// the engine itself runs in the main isolate.
@pragma('vm:entry-point')
void startCallback() => FlutterForegroundTask.setTaskHandler(_KeepAlive());

class _KeepAlive extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}
  @override
  void onRepeatEvent(DateTime timestamp) {}
  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}

Future<void> _guard(Future<void> Function() f) async {
  try {
    await f();
  } catch (_) {} // the service is a nice-to-have: trading must not depend on it
}

/// A log line: when it happened (phone time) and what (formatted in the UI language when shown).
class LogEntry {
  final DateTime time;
  final EngineEvent event;
  LogEntry(this.time, this.event);
}

enum Conn { disconnected, connecting, connected, failed }

/// App state: token, settings, language, trade history, connection and engine.
class AppState extends ChangeNotifier {
  static const _secure = FlutterSecureStorage();
  late SharedPreferences prefs;
  String? token;
  Settings cfg = Settings();
  final trades = <Trade>[];
  final logs = <LogEntry>[];
  QuotexClient? q;
  Engine? engine;
  Conn status = Conn.disconnected;
  bool running = false;
  Timer? _timer;

  /// '' = follow the phone, or 'en' / 'ar'.
  String lang = '';
  Locale? get localeOverride => lang.isEmpty ? null : Locale(lang);

  /// Strings for code without a BuildContext (notifications).
  L get strings {
    final code = lang.isNotEmpty ? lang : PlatformDispatcher.instance.locale.languageCode;
    return lookupL(Locale(L.supportedLocales.any((l) => l.languageCode == code) ? code : 'en'));
  }

  Future<void> load() async {
    prefs = await SharedPreferences.getInstance();
    token = await _secure.read(key: 'token');
    lang = prefs.getString('lang') ?? '';
    final s = prefs.getString('settings');
    if (s != null) cfg = Settings.fromJson(jsonDecode(s));
    for (final t in jsonDecode(prefs.getString('trades') ?? '[]') as List) {
      trades.add(Trade.fromJson(t));
    }
    _initService();
    var ticks = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      // keep the session up between signals too (the engine also reconnects before each signal)
      if (++ticks % 30 == 0 && token != null && status != Conn.connecting && !connected) connect();
      if (running && (engine?.scheduled.isEmpty ?? true)) {
        log(const EngineEvent('allDone'));
        stop();
      }
      notifyListeners();
    });
    if (token != null) connect();
    notifyListeners();
  }

  void _initService() => FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
            channelId: 'qxbot', channelName: strings.channelName, channelDescription: strings.channelDesc,
            onlyAlertOnce: false),
        iosNotificationOptions: const IOSNotificationOptions(),
        foregroundTaskOptions: ForegroundTaskOptions(
            eventAction: ForegroundTaskEventAction.nothing(), allowWakeLock: true, allowWifiLock: true),
      );

  void setLang(String code) {
    lang = code;
    prefs.setString('lang', code);
    notifyListeners();
  }

  void log(EngineEvent e) {
    logs.add(LogEntry(DateTime.now(), e));
    if (logs.length > 500) logs.removeAt(0);
    if (running && e.key == 'result') {
      final l = strings, today = summarize(this.today);
      _guard(() => FlutterForegroundTask.updateService(
          notificationTitle: l.notifToday(signedMoney(today.net), '${today.wins}', '${today.losses}'),
          notificationText: formatEvent(l, e)));
    }
    notifyListeners();
  }

  Future<void> setToken(String? t) async {
    token = t;
    t == null ? await _secure.delete(key: 'token') : await _secure.write(key: 'token', value: t);
    if (t == null) {
      stop();
      await q?.close();
      q = null;
      status = Conn.disconnected;
    } else {
      await connect();
    }
    notifyListeners();
  }

  Future<void> connect() async {
    if (token == null) return;
    status = Conn.connecting;
    notifyListeners();
    final reuse = q != null && q!.demo == cfg.demo && q!.token == token; // keep the running engine's client
    if (!reuse) {
      if (running) stop();
      await q?.close();
    }
    // a new client keeps the clock learnt so far: the phone's clock error doesn't change with the account
    final c = q = reuse ? q! : QuotexClient(token!, demo: cfg.demo, clock: q?.clock);
    try {
      await c.connect();
      await c.next((n, d) => n == 'instruments/list', const Duration(seconds: 10));
      if (!reuse || engine == null) engine = Engine(c, cfg, trades, log, onTrade: (_) => saveTrades());
      if (!running) c.follow(_clockPair(c)); // price ticks teach the clock before the first signal
      status = Conn.connected;
      log(EngineEvent('connected', {'demo': cfg.demo}));
    } catch (e) {
      status = Conn.failed;
      log(EngineEvent('connectFailed', {'error': '$e'}));
    }
    notifyListeners();
  }

  String _clockPair(QuotexClient c) {
    final open = c.instruments.where((r) => r[14] == true).map((r) => '${r[1]}').toList();
    return open.contains('EURUSD_otc') ? 'EURUSD_otc' : open.firstWhere((s) => s.endsWith('_otc'), orElse: () => 'EURUSD_otc');
  }

  bool get connected => q?.alive ?? false;

  void saveSettings() => prefs.setString('settings', jsonEncode(cfg.toJson()));
  void saveTrades() => prefs.setString('trades', jsonEncode([for (final t in trades) t.toJson()]));

  Future<void> switchAccount(bool demo) async {
    cfg.demo = demo;
    saveSettings();
    await connect();
  }

  /// Quotex time when known, else the phone's.
  DateTime get serverNow =>
      q == null ? DateTime.now() : DateTime.fromMicrosecondsSinceEpoch((q!.clock.now() * 1e6).round());

  List<Signal> parse(String text, {List<String>? unknown}) =>
      parseSignals(text, Duration(minutes: cfg.utcOffsetMin), serverNow, names: q?.names, unknown: unknown);

  int start(String text) {
    final e = engine;
    if (e == null) return 0;
    final kept = e.start(parse(text));
    running = kept.isNotEmpty;
    if (running) {
      WakelockPlus.enable();
      final l = strings;
      _guard(() async {
        await FlutterForegroundTask.requestNotificationPermission();
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
        _initService(); // channel name in the current language
        await FlutterForegroundTask.startService(
            serviceId: 7, notificationTitle: l.notifTrading, notificationText: l.scheduled(kept.length),
            callback: startCallback);
      });
      log(EngineEvent('started', {'count': kept.length}));
    }
    notifyListeners();
    return kept.length;
  }

  void stop() {
    engine?.stop();
    if (running) log(const EngineEvent('stopped'));
    running = false;
    _guard(() => WakelockPlus.disable());
    _guard(() => FlutterForegroundTask.stopService());
    notifyListeners();
  }

  List<Trade> get mine => trades.where((t) => t.demo == cfg.demo).toList();
  List<Trade> get today {
    final n = DateTime.now();
    return mine.where((t) => t.time.year == n.year && t.time.month == n.month && t.time.day == n.day).toList();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
