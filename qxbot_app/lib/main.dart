import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'core/engine.dart';
import 'core/parser.dart';
import 'core/quotex.dart';

const green = Color(0xFF16C784), red = Color(0xFFEA3943), bg = Color(0xFF0B0E14), card = Color(0xFF151A23);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();
  runApp(const QxApp());
}

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

/// App state: token, settings, trade history, connection and engine.
class AppState extends ChangeNotifier {
  static const _secure = FlutterSecureStorage();
  late SharedPreferences prefs;
  String? token;
  Settings cfg = Settings();
  final trades = <Trade>[];
  final logs = <String>[];
  QuotexClient? q;
  Engine? engine;
  String status = 'Disconnected';
  bool running = false;
  Timer? _timer;

  Future<void> load() async {
    prefs = await SharedPreferences.getInstance();
    token = await _secure.read(key: 'token');
    final s = prefs.getString('settings');
    if (s != null) cfg = Settings.fromJson(jsonDecode(s));
    for (final t in jsonDecode(prefs.getString('trades') ?? '[]') as List) {
      trades.add(Trade.fromJson(t));
    }
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'qxbot', channelName: 'QXBot trading', channelDescription: 'Bot running and trade results',
          onlyAlertOnce: false),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.nothing(), allowWakeLock: true, allowWifiLock: true),
    );
    var ticks = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      // keep the session up between signals too (the engine also reconnects before each signal)
      if (++ticks % 30 == 0 && token != null && status != 'Connecting...' && !connected) connect();
      if (running && (engine?.scheduled.isEmpty ?? true)) {
        log('All signals done');
        stop();
      }
      notifyListeners();
    });
    if (token != null) connect();
    notifyListeners();
  }

  void log(String m) {
    final n = DateTime.now();
    logs.add('${_two(n.hour)}:${_two(n.minute)}:${_two(n.second)}  $m');
    if (logs.length > 500) logs.removeAt(0);
    if (running && (m.contains(': WIN') || m.contains(': LOSS') || m.contains(': DRAW'))) {
      final today = summarize(this.today);
      _guard(() => FlutterForegroundTask.updateService(
          notificationTitle: 'QXBot · today ${money(today.net)} (${today.wins}W ${today.losses}L)', notificationText: m));
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
      status = 'Disconnected';
    } else {
      await connect();
    }
    notifyListeners();
  }

  Future<void> connect() async {
    if (token == null) return;
    status = 'Connecting...';
    notifyListeners();
    final reuse = q != null && q!.demo == cfg.demo && q!.token == token; // keep the running engine's client
    if (!reuse) {
      if (running) stop();
      await q?.close();
    }
    final c = q = reuse ? q! : QuotexClient(token!, demo: cfg.demo);
    try {
      await c.connect();
      await c.next((n, d) => n == 'instruments/list', const Duration(seconds: 10));
      if (!reuse || engine == null) engine = Engine(c, cfg, trades, log, onTrade: (_) => saveTrades());
      status = 'Connected';
      log('Connected to Quotex (${cfg.demo ? 'DEMO' : 'REAL'} account)');
    } catch (e) {
      status = 'Login expired or no connection';
      log('Connect failed: $e');
    }
    notifyListeners();
  }

  bool get connected => q?.alive ?? false;

  void saveSettings() => prefs.setString('settings', jsonEncode(cfg.toJson()));
  void saveTrades() => prefs.setString('trades', jsonEncode([for (final t in trades) t.toJson()]));

  Future<void> switchAccount(bool demo) async {
    cfg.demo = demo;
    saveSettings();
    await connect();
  }

  List<Signal> parse(String text, {List<String>? unknown}) => parseSignals(
      text, Duration(minutes: cfg.utcOffsetMin), DateTime.now(),
      names: q?.names, unknown: unknown);

  int start(String text) {
    final e = engine;
    if (e == null) return 0;
    final kept = e.start(parse(text));
    running = kept.isNotEmpty;
    if (running) {
      WakelockPlus.enable();
      _guard(() async {
        await FlutterForegroundTask.requestNotificationPermission();
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
        await FlutterForegroundTask.startService(
            serviceId: 7, notificationTitle: 'QXBot is trading', notificationText: '${kept.length} signals scheduled',
            callback: startCallback);
      });
      log('Started: ${kept.length} signals scheduled');
    }
    notifyListeners();
    return kept.length;
  }

  void stop() {
    engine?.stop();
    if (running) log('Stopped');
    running = false;
    WakelockPlus.disable();
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

String _two(int v) => v.toString().padLeft(2, '0');
String money(double v) => '${v >= 0 ? '+' : ''}${v.toStringAsFixed(2)}';

class QxApp extends StatefulWidget {
  const QxApp({super.key});
  @override
  State<QxApp> createState() => _QxAppState();
}

class _QxAppState extends State<QxApp> {
  final app = AppState();
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    app.load().then((_) => setState(() => loaded = true));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: green, brightness: Brightness.dark, surface: bg);
    return MaterialApp(
      title: 'QXBot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        scaffoldBackgroundColor: bg,
        cardTheme: CardThemeData(color: card, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: card, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      ),
      home: !loaded
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : ListenableBuilder(
              listenable: app,
              builder: (context, _) => app.token == null ? LoginPage(app) : Shell(app),
            ),
    );
  }
}

// ---------------------------------------------------------------- login

class LoginPage extends StatefulWidget {
  final AppState app;
  const LoginPage(this.app, {super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final WebViewController web;
  bool grabbing = false;

  @override
  void initState() {
    super.initState();
    web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(onPageFinished: _onPage))
      ..loadRequest(Uri.parse('https://quotex.com/en/demo-trade')); // redirects to sign-in when logged out
  }

  Future<void> _onPage(String url) async {
    if (!url.contains('/trade') || grabbing) return;
    grabbing = true;
    // Logged in: the trade page's inline script JSON holds the session token (may appear a bit after load).
    for (var i = 0; i < 30 && mounted; i++) {
      final r = await web.runJavaScriptReturningResult(
          r'(function(){var m=document.documentElement.innerHTML.match(/"token":"([^"]+)"/);return m?m[1]:"";})()');
      var t = r.toString();
      if (t.startsWith('"')) t = jsonDecode(t) as String;
      if (t.isNotEmpty) return widget.app.setToken(t);
      await Future.delayed(const Duration(seconds: 1));
    }
    grabbing = false;
  }

  Future<void> _pasteToken() async {
    final c = TextEditingController();
    final t = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Session token'),
        content: TextField(controller: c, decoration: const InputDecoration(hintText: 'Paste token')),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Use'))],
      ),
    );
    if (t != null && t.isNotEmpty) widget.app.setToken(t);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Log in to Quotex'),
          actions: [
            IconButton(tooltip: 'Reload', icon: const Icon(Icons.refresh), onPressed: () => web.reload()),
            IconButton(tooltip: 'Paste token', icon: const Icon(Icons.key), onPressed: _pasteToken),
          ],
        ),
        body: Column(children: [
          Container(
            width: double.infinity,
            color: card,
            padding: const EdgeInsets.all(12),
            child: const Text('Log in with your Quotex email and password (and the email code if asked). '
                'The app continues by itself once you are in.'),
          ),
          Expanded(child: WebViewWidget(controller: web)),
        ]),
      );
}

// ---------------------------------------------------------------- shell

class Shell extends StatefulWidget {
  final AppState app;
  const Shell(this.app, {super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final pages = [HomePage(app, () => setState(() => tab = 1)), SignalsPage(app, () => setState(() => tab = 2)),
      LivePage(app), StatsPage(app), SettingsPage(app)];
    return Scaffold(
      appBar: AppBar(title: const Text('QXBot', style: TextStyle(fontWeight: FontWeight.w800)), actions: [
        Padding(padding: const EdgeInsets.only(right: 16), child: _AccountChip(app)),
      ]),
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Signals'),
          NavigationDestination(icon: Icon(Icons.bolt), label: 'Live'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Stats'),
          NavigationDestination(icon: Icon(Icons.tune), label: 'Settings'),
        ],
      ),
    );
  }
}

class _AccountChip extends StatelessWidget {
  final AppState app;
  const _AccountChip(this.app);
  @override
  Widget build(BuildContext context) => Chip(
        label: Text(app.cfg.demo ? 'DEMO' : 'REAL', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: app.cfg.demo ? Colors.blueGrey.shade800 : Colors.orange.shade900,
        side: BorderSide.none,
      );
}

Widget section(String title, List<Widget> children) => Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title.toUpperCase(), style: const TextStyle(fontSize: 12, letterSpacing: 1.2, color: Colors.white54)),
          const SizedBox(height: 10),
          ...children,
        ]),
      ),
    );

// ---------------------------------------------------------------- home

class HomePage extends StatelessWidget {
  final AppState app;
  final VoidCallback goSignals;
  const HomePage(this.app, this.goSignals, {super.key});

  Future<void> _toggleAccount(BuildContext context, bool demo) async {
    if (!demo) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Switch to REAL money?'),
          content: const Text('Trades will use your real Quotex balance. Losses are real.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(style: FilledButton.styleFrom(backgroundColor: red), onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Use real account')),
          ],
        ),
      );
      if (ok != true) return;
    }
    await app.switchAccount(demo);
  }

  @override
  Widget build(BuildContext context) {
    final today = summarize(app.today);
    final on = app.connected;
    return ListView(children: [
      section('Connection', [
        Row(children: [
          Icon(Icons.circle, size: 12, color: on ? green : red),
          const SizedBox(width: 8),
          Expanded(child: Text(on ? 'Connected' : app.status, style: const TextStyle(fontSize: 16))),
          TextButton.icon(onPressed: app.connect, icon: const Icon(Icons.refresh), label: const Text('Reconnect')),
        ]),
      ]),
      section('Balance', [
        Text(app.q?.balance == null ? '--' : '\$${app.q!.balance!.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('Today ${money(today.net)}  ·  ${today.wins}W ${today.losses}L ${today.draws}D',
            style: TextStyle(fontSize: 16, color: today.net >= 0 ? green : red)),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Demo account (practice money)'),
          value: app.cfg.demo,
          onChanged: app.running ? null : (v) => _toggleAccount(context, v),
        ),
      ]),
      section('Bot', [
        Row(children: [
          Icon(app.running ? Icons.play_circle : Icons.pause_circle, color: app.running ? green : Colors.white38, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Text(app.running ? 'Running · ${app.engine?.scheduled.length ?? 0} signals waiting' : 'Stopped',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: app.running
              ? FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: red), onPressed: app.stop,
                  icon: const Icon(Icons.stop), label: const Text('Stop'))
              : FilledButton.icon(onPressed: goSignals, icon: const Icon(Icons.paste), label: const Text('Paste signals')),
        ),
      ]),
      Center(
        child: TextButton(onPressed: () => app.setToken(null), child: const Text('Log out', style: TextStyle(color: Colors.white38))),
      ),
    ]);
  }
}

// ---------------------------------------------------------------- signals

Widget dirChip(String dir) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: (dir == 'call' ? green : red).withValues(alpha: 0.18), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(dir == 'call' ? Icons.arrow_upward : Icons.arrow_downward, size: 16, color: dir == 'call' ? green : red),
        Text(dir == 'call' ? ' CALL' : ' PUT', style: TextStyle(color: dir == 'call' ? green : red, fontWeight: FontWeight.bold)),
      ]),
    );

class SignalsPage extends StatefulWidget {
  final AppState app;
  final VoidCallback goLive;
  const SignalsPage(this.app, this.goLive, {super.key});
  @override
  State<SignalsPage> createState() => _SignalsPageState();
}

class _SignalsPageState extends State<SignalsPage> {
  final text = TextEditingController();
  List<Signal> preview = [];
  List<String> unknown = [];

  void _parse() {
    final u = <String>[];
    setState(() {
      preview = widget.app.parse(text.text, unknown: u);
      unknown = u;
    });
  }

  @override
  void initState() {
    super.initState();
    text.text = widget.app.prefs.getString('lastList') ?? '';
    text.addListener(_parse);
    _parse();
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final h = app.cfg.utcOffsetMin / 60;
    return ListView(padding: const EdgeInsets.all(16), children: [
      TextField(
        controller: text,
        minLines: 6,
        maxLines: 12,
        decoration: InputDecoration(
          hintText: 'Paste the Telegram signal list here\ne.g. M1 EURUSD-OTC 14:30 CALL',
          suffixIcon: IconButton(
            icon: const Icon(Icons.content_paste),
            onPressed: () async => text.text = (await Clipboard.getData('text/plain'))?.text ?? '',
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text('List timezone: UTC${h >= 0 ? '+' : ''}${h.toString().replaceAll('.0', '')} (Settings; a "UTC+6" in the list wins)'
          '${app.q == null ? ' · not connected: pair names not checked' : ''}',
          style: const TextStyle(color: Colors.white54)),
      const SizedBox(height: 12),
      Text('${preview.length} signals found', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      for (final s in preview)
        Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: Text(s.hhmm, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            title: Text(s.asset.replaceAll('_otc', ' (OTC)')),
            subtitle: Text('${s.duration >= 60 ? '${s.duration ~/ 60} min' : '${s.duration}s'}'),
            trailing: dirChip(s.direction),
          ),
        ),
      for (final u in unknown)
        Card(
          color: Colors.orange.withValues(alpha: 0.15),
          child: ListTile(leading: const Icon(Icons.help_outline, color: Colors.orange), title: Text(u),
              subtitle: const Text('Pair not found on Quotex: this line is skipped')),
        ),
      const SizedBox(height: 16),
      FilledButton.icon(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        onPressed: preview.isEmpty || app.engine == null
            ? null
            : () {
                app.prefs.setString('lastList', text.text);
                final n = app.start(text.text);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$n signals scheduled')));
                widget.goLive();
              },
        icon: const Icon(Icons.play_arrow),
        label: Text(app.engine == null ? 'Connect first' : 'Start trading ${preview.length} signals'),
      ),
    ]);
  }
}

// ---------------------------------------------------------------- live

class LivePage extends StatelessWidget {
  final AppState app;
  const LivePage(this.app, {super.key});
  @override
  Widget build(BuildContext context) {
    final waiting = app.engine?.scheduled ?? [];
    return ListView(padding: const EdgeInsets.all(16), children: [
      if (app.running)
        FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: red), onPressed: app.stop,
            icon: const Icon(Icons.stop), label: const Text('Stop bot')),
      const SizedBox(height: 8),
      Text('Waiting (${waiting.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      for (final s in waiting)
        ListTile(dense: true, leading: Text(s.hhmm, style: const TextStyle(fontSize: 16)), title: Text(s.asset), trailing: dirChip(s.direction)),
      const Divider(),
      const Text('Log', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      for (final l in app.logs.reversed)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Text(l,
              style: TextStyle(
                  fontFamily: 'monospace', fontSize: 13,
                  color: l.contains('WIN') ? green : l.contains('LOSS') || l.contains('REJECTED') || l.contains('failed') ? red : Colors.white70)),
        ),
    ]);
  }
}

// ---------------------------------------------------------------- stats

class StatsPage extends StatelessWidget {
  final AppState app;
  const StatsPage(this.app, {super.key});

  Widget _block(String title, List<Trade> rows) {
    final s = summarize(rows);
    Widget tile(String k, String v, [Color? c]) => SizedBox(
          width: 150,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(k, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              Text(v, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: c)),
            ]),
          ),
        );
    return section(title, [
      Wrap(children: [
        tile('Net profit', money(s.net), s.net >= 0 ? green : red),
        tile('Win rate', '${s.winRate.toStringAsFixed(0)}%'),
        tile('Trades', '${s.trades}'),
        tile('W / L / D', '${s.wins} / ${s.losses} / ${s.draws}'),
        tile('Signals won', '${s.signalsWon}/${s.signalsWon + s.signalsLost}'),
        tile('Won after gale', '${s.signalsWonGale}'),
        tile('Max drawdown', s.maxDrawdown.toStringAsFixed(2), red),
        tile('Worst streak', '${s.lossStreak} losses'),
      ]),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final mine = app.mine;
    final session = mine.where((t) => app.engine != null && t.time.isAfter(app.engine!.started)).toList();
    return ListView(children: [
      _block('This session', session),
      _block('Today', app.today),
      _block('All time (${app.cfg.demo ? 'demo' : 'real'})', mine),
      section('Recent trades', [
        if (mine.isEmpty) const Text('No trades yet', style: TextStyle(color: Colors.white54)),
        for (final t in mine.reversed.take(50))
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: dirChip(t.direction),
            title: Text('${t.asset}${t.level > 0 ? '  G${t.level}' : ''}'),
            subtitle: Text('${t.time.toString().substring(5, 16)} · \$${t.amount} · ${t.entry} ${t.delayMs}ms'),
            trailing: Text(money(t.profit),
                style: TextStyle(fontWeight: FontWeight.bold, color: t.profit > 0 ? green : t.profit < 0 ? red : null)),
          ),
      ]),
    ]);
  }
}

// ---------------------------------------------------------------- settings

class SettingsPage extends StatefulWidget {
  final AppState app;
  const SettingsPage(this.app, {super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Settings get c => widget.app.cfg;

  void _save() {
    widget.app.saveSettings();
    setState(() {});
  }

  Widget _num(String label, String help, num value, void Function(double) set) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextFormField(
          initialValue: value is int || value == value.roundToDouble() ? '${value.toInt()}' : '$value',
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          decoration: InputDecoration(labelText: label, helperText: help),
          onChanged: (v) {
            final d = double.tryParse(v.replaceAll(',', '.'));
            if (d != null) {
              set(d);
              _save();
            }
          },
        ),
      );

  @override
  Widget build(BuildContext context) {
    final locked = widget.app.running;
    return AbsorbPointer(
      absorbing: locked,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        if (locked) const Text('Stop the bot to change settings', style: TextStyle(color: Colors.orange)),
        _num('Trade amount (\$)', 'Stake for each signal', c.amount, (v) => c.amount = v),
        _num('Signal list timezone (UTC hours)', 'e.g. -3 for UTC-3, 5.5 for UTC+5:30', c.utcOffsetMin / 60,
            (v) => c.utcOffsetMin = (v * 60).round()),
        _num('Martingale levels', '0 = off', c.gales, (v) => c.gales = v.round().clamp(0, 5)),
        _num('Martingale multiplier', 'Next stake = stake x this', c.galeMultiplier, (v) => c.galeMultiplier = v),
        _num('Minimum payout (%)', 'Skip a signal when the payout is lower', c.minPayout, (v) => c.minPayout = v),
        _num('Daily stop-loss (\$)', '0 = off', c.stopLoss, (v) => c.stopLoss = v),
        _num('Daily take-profit (\$)', '0 = off', c.takeProfit, (v) => c.takeProfit = v),
        SwitchListTile(
          title: const Text('Pending orders for OTC'),
          subtitle: const Text('Quotex opens the trade itself at the exact minute'),
          value: c.pending,
          onChanged: (v) => {c.pending = v, _save()},
        ),
        SwitchListTile(
          title: const Text('Allow overlapping signals'),
          subtitle: const Text('Off: one signal per minute, a signal beats a martingale'),
          value: c.overlap,
          onChanged: (v) => {c.overlap = v, _save()},
        ),
        SwitchListTile(
          title: const Text('Automatic entry timing'),
          subtitle: const Text('Send direct orders half a ping before the minute'),
          value: c.preEntryMs == null,
          onChanged: (v) => {c.preEntryMs = v ? null : 250, _save()},
        ),
        if (c.preEntryMs != null)
          _num('Pre-entry (ms)', 'Send this many ms before the minute', c.preEntryMs!, (v) => c.preEntryMs = v.round()),
      ]),
    );
  }
}
