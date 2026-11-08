import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter/widgets.dart' show AppLifecycleListener, Locale;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'core/ai.dart';
import 'core/backtest.dart';
import 'core/engine.dart';
import 'core/parser.dart';
import 'core/quotex.dart';
import 'format.dart';
import 'l10n/app_localizations.dart';

/// The foreground service keeps the app process alive (and shows results); the engine itself runs in the
/// main isolate, whose Flutter engine outlives the activity (see MainActivity.kt).
@pragma('vm:entry-point')
void startCallback() => FlutterForegroundTask.setTaskHandler(_KeepAlive());

class _KeepAlive extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Restarted by Android after the process was killed: the trading engine (and its list) is gone, so a
    // "trading" notification would lie. Stop; the user restarts from the app.
    if (starter == TaskStarter.system) await FlutterForegroundTask.stopService();
  }
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

/// What keeps the bot running in the background, as far as the app can check.
class BgStatus {
  final bool notifications, battery;
  const BgStatus(this.notifications, this.battery);
  bool get ok => notifications && battery;
}

const _system = MethodChannel('qxbot/system');

/// First-run guide done? Users upgrading from 1.1.0 (saved settings or a login, no flag yet) count as done.
bool isOnboarded(SharedPreferences prefs, String? token) =>
    prefs.getBool('onboarded') ?? (prefs.containsKey('settings') || token != null);

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
  String? connectError; // raw error of the last failed connect (the UI shows it in plain words)

  /// First-run guide finished (1.1.0 users with settings or a login count as done).
  bool onboarded = true;
  bool bgSetupSeen = true;
  BgStatus? bg; // null until checked (or not on Android)
  String brand = '';

  /// '' = follow the phone, or 'en' / 'ar'.
  String lang = '';
  Locale? get localeOverride => lang.isEmpty ? null : Locale(lang);

  // ------------------------------------------------------------ AI (Gemini) and backtest

  /// Built in at build time (`--dart-define-from-file=.env`); a key typed in Settings wins.
  static const builtInAiKey = String.fromEnvironment('GEMINI_API_KEY');
  String userAiKey = '';
  String get aiKey => userAiKey.isNotEmpty ? userAiKey : builtInAiKey;
  bool get aiReady => cfg.ai && aiKey.isNotEmpty;

  /// Last coach answer: {at, lang, data}, kept across restarts.
  Map<String, dynamic>? lastCoach;

  Future<void> setUserAiKey(String k) async {
    userAiKey = k.trim();
    userAiKey.isEmpty ? await _secure.delete(key: 'gemini_key') : await _secure.write(key: 'gemini_key', value: userAiKey);
    notifyListeners();
  }

  List<(String, String)> get pairNames => q?.names ?? const [];

  /// AI list reader: the raw text, the Quotex pair list and the list timezone only. User-triggered.
  Future<AiParse> aiReadList(String text) async {
    if (pairNames.isEmpty) throw const AiException('noPairs');
    final tz = Duration(minutes: cfg.utcOffsetMin);
    final json = await Gemini(aiKey).json(listPrompt(text, pairNames, tz), listSchema);
    return validateAiSignals(json, pairNames, tz, serverNow);
  }

  /// AI coach on aggregated stats of this account's trades (and a backtest summary when given). User-triggered.
  Future<Map<String, Object>> aiCoach(String langCode, {Map<String, Object?>? backtest}) async {
    final skips = logs.where((e) => e.event.key == 'skipped' && (e.event.args['reason'] as EngineEvent?)?.key == 'payout').length;
    final stats = coachStats(mine, payoutSkips: skips, backtest: backtest, settings: {
      'amount': cfg.amount, 'martingale_steps': cfg.gales, 'martingale_multiplier': cfg.galeMultiplier,
      'min_payout_pct': cfg.minPayout, 'daily_stop_loss': cfg.stopLoss, 'daily_take_profit': cfg.takeProfit,
    });
    final data = cleanCoach(await Gemini(aiKey).json(coachPrompt(stats, langCode), coachSchema));
    lastCoach = {'at': DateTime.now().toIso8601String(), 'lang': langCode, 'backtest': backtest != null, 'data': data};
    prefs.setString('aiCoach', jsonEncode(lastCoach));
    notifyListeners();
    return data;
  }

  /// Scores past signals on Quotex 1-minute candles (read-only, under the engine's chart lock), with at least one
  /// martingale step so the summary can show the rate with and without it.
  Future<List<(Signal, BtResult)>> backtest(List<Signal> sigs) async {
    final c = q;
    if (c == null || !connected) throw StateError('not connected');
    final gales = cfg.gales < 1 ? 1 : cfg.gales;
    final rows = <(Signal, BtResult)>[];
    for (final asset in {for (final s in sigs) s.asset}) {
      final mine = sigs.where((s) => s.asset == asset).toList();
      final first = mine.map((s) => s.at.millisecondsSinceEpoch ~/ 1000).reduce((a, b) => a < b ? a : b);
      Future<Map<int, Candle>> load() => c.candles(asset, first - 60);
      final candles = engine == null ? await load() : await engine!.chart.run(load);
      rows.addAll([for (final s in mine) (s, backtestResult(s, candles, gales))]);
    }
    return rows..sort((a, b) => a.$1.at.compareTo(b.$1.at));
  }

  BtSummary summarizeBt(List<(Signal, BtResult)> rows) => summarizeBacktest(rows,
      gales: cfg.gales, amount: cfg.amount, mult: cfg.galeMultiplier,
      payout: (a) => (q?.instrument(a)?[18] as num?)?.toDouble());

  /// Strings for code without a BuildContext (notifications).
  L get strings {
    final code = lang.isNotEmpty ? lang : PlatformDispatcher.instance.locale.languageCode;
    return lookupL(Locale(L.supportedLocales.any((l) => l.languageCode == code) ? code : 'en'));
  }

  Future<void> load() async {
    prefs = await SharedPreferences.getInstance();
    token = await _secure.read(key: 'token');
    userAiKey = await _secure.read(key: 'gemini_key') ?? '';
    final cached = prefs.getString('aiCoach');
    if (cached != null) lastCoach = jsonDecode(cached) as Map<String, dynamic>;
    lang = prefs.getString('lang') ?? '';
    onboarded = isOnboarded(prefs, token);
    bgSetupSeen = prefs.getBool('bgSetupSeen') ?? false;
    final s = prefs.getString('settings');
    if (s != null) cfg = Settings.fromJson(jsonDecode(s));
    for (final t in jsonDecode(prefs.getString('trades') ?? '[]') as List) {
      trades.add(Trade.fromJson(t));
    }
    _initService();
    var ticks = 0;
    var last = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now(), gap = now.difference(last).inSeconds;
      last = now;
      // A 1 s timer that fires much later means the phone slept (Doze stops the CPU when the wakelock is
      // not honoured). End the missed signals at once and get the connection back.
      if (gap >= 5 && running) {
        log(EngineEvent('wokeUp', {'seconds': gap}));
        engine?.resync();
        if (!connected && status != Conn.connecting) connect();
      }
      // keep the session up between signals too (the engine also reconnects before each signal)
      if (++ticks % (running ? 5 : 30) == 0 && token != null && status != Conn.connecting && !connected) connect();
      if (running && (engine?.scheduled.isEmpty ?? true)) {
        log(const EngineEvent('allDone'));
        stop();
      }
      notifyListeners();
    });
    if (token != null) connect();
    checkBackground();
    _life = AppLifecycleListener(onResume: onResume);
    notifyListeners();
  }

  AppLifecycleListener? _life;

  void finishOnboarding() {
    onboarded = true;
    prefs.setBool('onboarded', true);
    notifyListeners();
  }

  void markBgSetupSeen() {
    bgSetupSeen = true;
    prefs.setBool('bgSetupSeen', true);
  }

  /// Back in the app: reconnect at once if the socket died meanwhile, and re-read the background state.
  void onResume() {
    if (token != null && status != Conn.connecting && !connected) connect();
    checkBackground();
  }

  Future<void> checkBackground() async {
    try {
      final n = await FlutterForegroundTask.checkNotificationPermission() == NotificationPermission.granted;
      bg = BgStatus(n, await FlutterForegroundTask.isIgnoringBatteryOptimizations);
      brand = await _system.invokeMethod<String>('brand') ?? '';
    } catch (_) {} // not Android (tests): nothing to check
    notifyListeners();
  }

  Future<void> requestNotifications() async {
    await _guard(() => FlutterForegroundTask.requestNotificationPermission());
    await checkBackground();
  }

  /// System dialog "Let app always run in background?" (Doze exemption: network and wakelock keep working).
  Future<void> requestBattery() async {
    await _guard(() async {
      if (!await FlutterForegroundTask.requestIgnoreBatteryOptimization()) {
        await FlutterForegroundTask.openIgnoreBatteryOptimizationSettings();
      }
    });
    await checkBackground();
  }

  /// Opens the first OEM screen ("package/class") that exists on this phone, else the app's info page.
  Future<void> openSystemScreen(List<String> components) => _guard(() => _system.invokeMethod('open', components));

  void _initService() => FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
            channelId: 'qxbot', channelName: strings.channelName, channelDescription: strings.channelDesc,
            onlyAlertOnce: false),
        iosNotificationOptions: const IOSNotificationOptions(),
        foregroundTaskOptions: ForegroundTaskOptions(
            // partial wakelock + wifi lock while trading; no auto-restart: a restarted service has no engine
            eventAction: ForegroundTaskEventAction.nothing(), allowWakeLock: true, allowWifiLock: true,
            allowAutoRestart: false),
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
      connectError = null;
      log(EngineEvent('connected', {'demo': cfg.demo}));
      if (running) engine?.resync(); // signals whose minute passed while offline are skipped, not entered late
    } catch (e) {
      status = Conn.failed;
      connectError = '$e';
      log(EngineEvent('connectFailed', {'error': '$e'}));
    }
    notifyListeners();
  }

  String _clockPair(QuotexClient c) {
    final open = c.instruments.where((r) => r[14] == true).map((r) => '${r[1]}').toList();
    return open.contains('EURUSD_otc') ? 'EURUSD_otc' : open.firstWhere((s) => s.endsWith('_otc'), orElse: () => 'EURUSD_otc');
  }

  bool get connected => q?.alive ?? false;

  void saveSettings() {
    prefs.setString('settings', jsonEncode(cfg.toJson()));
    notifyListeners();
  }
  void saveTrades() => prefs.setString('trades', jsonEncode([for (final t in trades) t.toJson()]));

  Future<void> switchAccount(bool demo) async {
    cfg.demo = demo;
    saveSettings();
    await connect();
  }

  /// Quotex time when known, else the phone's.
  DateTime get serverNow =>
      q == null ? DateTime.now() : DateTime.fromMicrosecondsSinceEpoch((q!.clock.now() * 1e6).round());

  List<Signal> parse(String text, {List<String>? unknown, List<Signal>? passed}) => parseSignals(
      text, Duration(minutes: cfg.utcOffsetMin), serverNow, names: q?.names, unknown: unknown, passed: passed);

  int start(String text) => startSignals(parse(text));

  int startSignals(List<Signal> signals) {
    final e = engine;
    if (e == null) return 0;
    final kept = e.start(signals);
    running = kept.isNotEmpty;
    if (running) {
      _guard(() => WakelockPlus.enable());
      final l = strings;
      _guard(() async {
        await FlutterForegroundTask.requestNotificationPermission();
        _initService(); // channel name in the current language
        final r = await FlutterForegroundTask.startService(
            serviceId: 7, notificationTitle: l.notifTrading, notificationText: l.scheduled(kept.length),
            // Android 14+: specialUse (no daily limit); older Android: the manifest types
            serviceTypes: [ForegroundServiceTypes.specialUse], callback: startCallback);
        if (r is ServiceRequestFailure) log(EngineEvent('serviceFailed', {'error': '${r.error}'}));
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

  /// The next signal still to be entered (by entry time), or null.
  Signal? get nextSignal {
    final e = engine;
    if (e == null) return null;
    final waiting = e.scheduled.where((s) => !e.entered.contains(s)).toList()..sort((a, b) => a.at.compareTo(b.at));
    return waiting.firstOrNull;
  }

  List<Trade> get mine => trades.where((t) => t.demo == cfg.demo).toList();
  List<Trade> get today {
    final n = DateTime.now();
    return mine.where((t) => t.time.year == n.year && t.time.month == n.month && t.time.day == n.day).toList();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _life?.dispose();
    super.dispose();
  }
}
