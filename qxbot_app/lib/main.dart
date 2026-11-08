import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' show Bidi;
import 'package:webview_flutter/webview_flutter.dart';

import 'app_state.dart';
import 'core/engine.dart';
import 'core/parser.dart';
import 'format.dart';
import 'l10n/app_localizations.dart';

const green = Color(0xFF16C784), red = Color(0xFFEA3943), bg = Color(0xFF0B0E14), card = Color(0xFF151A23);
const amber = Color(0xFFF0B90B);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();
  runApp(const QxApp());
}

ThemeData qxTheme({required bool arabic}) => ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: green, brightness: Brightness.dark, surface: bg),
      scaffoldBackgroundColor: bg,
      fontFamily: arabic ? 'Cairo' : null, // bundled: renders Arabic and Latin well
      cardTheme: CardThemeData(color: card, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: card, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
    );

/// The MaterialApp with localization, language choice and theme; [home] decides the page (tests pass their own).
Widget qxMaterialApp(AppState app, Widget home) => ListenableBuilder(
      listenable: app,
      builder: (context, _) => MaterialApp(
        onGenerateTitle: (c) => L.of(c).appTitle,
        debugShowCheckedModeBanner: false,
        locale: app.localeOverride, // null = the phone's language
        supportedLocales: L.supportedLocales,
        localizationsDelegates: const [
          L.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: qxTheme(arabic: false),
        builder: (context, child) => Localizations.localeOf(context).languageCode == 'ar'
            ? Theme(data: qxTheme(arabic: true), child: child!)
            : child!,
        home: home,
      ),
    );

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
  Widget build(BuildContext context) => !loaded
      ? const MaterialApp(home: Scaffold(backgroundColor: bg, body: Center(child: CircularProgressIndicator())))
      : qxMaterialApp(app, ListenableBuilder(
          listenable: app, builder: (context, _) => app.token == null ? LoginPage(app) : Shell(app)));
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
    final l = L.of(context);
    final c = TextEditingController();
    final t = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.sessionToken),
        content: TextField(
            controller: c, textDirection: TextDirection.ltr, decoration: InputDecoration(hintText: l.pasteToken)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: Text(l.use)),
        ],
      ),
    );
    if (t != null && t.isNotEmpty) widget.app.setToken(t);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.loginTitle),
        actions: [
          IconButton(tooltip: l.reload, icon: const Icon(Icons.refresh), onPressed: () => web.reload()),
          IconButton(tooltip: l.pasteToken, icon: const Icon(Icons.key), onPressed: _pasteToken),
        ],
      ),
      body: Column(children: [
        Container(width: double.infinity, color: card, padding: const EdgeInsets.all(12), child: Text(l.loginHelp)),
        // the Quotex page itself stays left-to-right
        Expanded(child: Directionality(textDirection: TextDirection.ltr, child: WebViewWidget(controller: web))),
      ]),
    );
  }
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
    final app = widget.app, l = L.of(context);
    final pages = [
      HomePage(app, () => setState(() => tab = 1)),
      SignalsPage(app, () => setState(() => tab = 2)),
      LivePage(app),
      StatsPage(app),
      SettingsPage(app),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.appTitle, style: const TextStyle(fontWeight: FontWeight.w800)), actions: [
        Padding(padding: const EdgeInsetsDirectional.only(end: 16), child: _AccountChip(app)),
      ]),
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: l.tabHome),
          NavigationDestination(icon: const Icon(Icons.list_alt), label: l.tabSignals),
          NavigationDestination(icon: const Icon(Icons.bolt), label: l.tabLive),
          NavigationDestination(icon: const Icon(Icons.bar_chart), label: l.tabStats),
          NavigationDestination(icon: const Icon(Icons.tune), label: l.tabSettings),
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
        label: Text(app.cfg.demo ? L.of(context).demo : L.of(context).real, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: app.cfg.demo ? Colors.blueGrey.shade800 : Colors.orange.shade900,
        side: BorderSide.none,
      );
}

Widget section(String title, List<Widget> children) => Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title.toUpperCase(), style: const TextStyle(fontSize: 12, letterSpacing: 1.2, color: Colors.white54)),
          const SizedBox(height: 10),
          ...children,
        ]),
      ),
    );

/// Numbers, prices, times and symbols on their own: always left-to-right.
Widget ltrText(String s, {TextStyle? style}) =>
    Directionality(textDirection: TextDirection.ltr, child: Text(s, style: style));

// ---------------------------------------------------------------- home

class HomePage extends StatelessWidget {
  final AppState app;
  final VoidCallback goSignals;
  const HomePage(this.app, this.goSignals, {super.key});

  Future<void> _toggleAccount(BuildContext context, bool demo) async {
    if (!demo) {
      final l = L.of(context);
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.realTitle),
          content: Text(l.realBody),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
            FilledButton(
                style: FilledButton.styleFrom(backgroundColor: red),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l.useReal)),
          ],
        ),
      );
      if (ok != true) return;
    }
    await app.switchAccount(demo);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final today = summarize(app.today);
    final on = app.connected;
    final offset = app.q?.clock.offset;
    final statusText = on
        ? l.connected
        : switch (app.status) {
            Conn.connecting => l.connecting,
            Conn.failed => l.connectFailedStatus,
            _ => l.disconnected,
          };
    return ListView(children: [
      section(l.connection, [
        Row(children: [
          Icon(Icons.circle, size: 12, color: on ? green : red),
          const SizedBox(width: 8),
          Expanded(child: Text(statusText, style: const TextStyle(fontSize: 16))),
          TextButton.icon(onPressed: app.connect, icon: const Icon(Icons.refresh), label: Text(l.reconnect)),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          Icon(offset == null ? Icons.schedule : Icons.verified, size: 16,
              color: offset == null ? Colors.white38 : offset.abs() > 1 ? amber : green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(offset == null ? l.clockNotVerified : l.clockCorrected(signedSeconds(offset)),
                style: const TextStyle(color: Colors.white70)),
          ),
        ]),
      ]),
      section(l.balance, [
        ltrText(app.q?.balance == null ? '--' : '\$${app.q!.balance!.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(l.todaySummary(signedMoney(today.net), ltr(today.wins), ltr(today.losses), ltr(today.draws)),
            style: TextStyle(fontSize: 16, color: today.net >= 0 ? green : red)),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l.demoAccountSwitch),
          value: app.cfg.demo,
          onChanged: app.running ? null : (v) => _toggleAccount(context, v),
        ),
      ]),
      section(l.bot, [
        Row(children: [
          Icon(app.running ? Icons.play_circle : Icons.pause_circle, color: app.running ? green : Colors.white38, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Text(app.running ? l.runningWaiting(app.engine?.scheduled.length ?? 0) : l.stopped,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: app.running
              ? FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: red),
                  onPressed: app.stop,
                  icon: const Icon(Icons.stop),
                  label: Text(l.stop))
              : FilledButton.icon(onPressed: goSignals, icon: const Icon(Icons.paste), label: Text(l.pasteSignals)),
        ),
      ]),
      Center(
        child: TextButton(
            onPressed: () => app.setToken(null), child: Text(l.logout, style: const TextStyle(color: Colors.white38))),
      ),
    ]);
  }
}

// ---------------------------------------------------------------- signals

Widget dirChip(BuildContext context, String dir) {
  final l = L.of(context), c = dir == 'call' ? green : red;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: c.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      // up/down arrows mean price direction: the same in both writing directions
      Icon(dir == 'call' ? Icons.arrow_upward : Icons.arrow_downward, size: 16, color: c),
      const SizedBox(width: 4),
      Text(dirLabel(l, dir), style: TextStyle(color: c, fontWeight: FontWeight.bold)),
    ]),
  );
}

String durationLabel(L l, int seconds) => seconds >= 60 ? l.minutes(seconds ~/ 60) : l.seconds(seconds);

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
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app, l = L.of(context);
    final h = app.cfg.utcOffsetMin / 60;
    final tz = ltr('UTC${h >= 0 ? '+' : ''}${h.toString().replaceAll('.0', '')}');
    return ListView(padding: const EdgeInsets.all(16), children: [
      TextField(
        controller: text,
        minLines: 6,
        maxLines: 12,
        // a list's direction follows its text (most lists are Latin even in an Arabic app)
        textDirection: Bidi.detectRtlDirectionality(text.text) ? TextDirection.rtl : TextDirection.ltr,
        decoration: InputDecoration(
          hintText: l.signalsHint,
          suffixIcon: IconButton(
            tooltip: l.pasteFromClipboard,
            icon: const Icon(Icons.content_paste),
            onPressed: () async => text.text = (await Clipboard.getData('text/plain'))?.text ?? '',
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(l.listTimezone(tz), style: const TextStyle(color: Colors.white54)),
      if (app.q == null) Text(l.notConnectedNames, style: const TextStyle(color: amber)),
      const SizedBox(height: 12),
      Text(l.signalsFound(preview.length), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      for (final s in preview)
        Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: ltrText(s.hhmm, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            title: Text(pairLabel(s.asset)),
            subtitle: Text(durationLabel(l, s.duration)),
            trailing: dirChip(context, s.direction),
          ),
        ),
      for (final u in unknown)
        Card(
          color: Colors.orange.withValues(alpha: 0.15),
          child: ListTile(
              leading: const Icon(Icons.help_outline, color: Colors.orange), title: Text(u), subtitle: Text(l.pairNotFound)),
        ),
      const SizedBox(height: 16),
      FilledButton.icon(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        onPressed: preview.isEmpty || app.engine == null
            ? null
            : () {
                app.prefs.setString('lastList', text.text);
                final n = app.start(text.text);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.scheduled(n))));
                widget.goLive();
              },
        icon: const Icon(Icons.play_arrow),
        label: Text(app.engine == null ? l.connectFirst : l.startTrading(preview.length)),
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
    final l = L.of(context);
    final waiting = app.engine?.scheduled ?? [];
    return ListView(padding: const EdgeInsets.all(16), children: [
      if (app.running)
        FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: red),
            onPressed: app.stop,
            icon: const Icon(Icons.stop),
            label: Text(l.stopBot)),
      const SizedBox(height: 8),
      Text(l.waiting(waiting.length), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      for (final s in waiting)
        ListTile(
            dense: true,
            leading: ltrText(s.hhmm, style: const TextStyle(fontSize: 16)),
            title: Text(pairLabel(s.asset)),
            trailing: dirChip(context, s.direction)),
      const Divider(),
      Text(l.log, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      if (app.logs.isEmpty) Text(l.logEmpty, style: const TextStyle(color: Colors.white54)),
      for (final e in app.logs.reversed)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Text('${ltr(clock(e.time))}  ${formatEvent(l, e.event)}',
              style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: switch (eventTone(e.event)) { 1 => green, -1 => red, 2 => amber, _ => Colors.white70 })),
        ),
    ]);
  }
}

// ---------------------------------------------------------------- stats

class StatsPage extends StatelessWidget {
  final AppState app;
  const StatsPage(this.app, {super.key});

  Widget _block(L l, String title, List<Trade> rows) {
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
        tile(l.netProfit, signedMoney(s.net), s.net >= 0 ? green : red),
        tile(l.winRate, ltr('${s.winRate.toStringAsFixed(0)}%')),
        tile(l.trades, ltr(s.trades)),
        tile(l.wld, ltr('${s.wins} / ${s.losses} / ${s.draws}')),
        tile(l.signalsWon, ltr('${s.signalsWon}/${s.signalsWon + s.signalsLost}')),
        tile(l.wonAfterGale, ltr(s.signalsWonGale)),
        tile(l.maxDrawdown, ltr(s.maxDrawdown.toStringAsFixed(2)), red),
        tile(l.worstStreak, l.lossesCount(s.lossStreak)),
      ]),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final mine = app.mine;
    final session = mine.where((t) => app.engine != null && t.time.isAfter(app.engine!.started)).toList();
    return ListView(children: [
      _block(l, l.thisSession, session),
      _block(l, l.today, app.today),
      _block(l, l.allTime(app.cfg.demo ? l.demo : l.real), mine),
      section(l.recentTrades, [
        if (mine.isEmpty) Text(l.noTrades, style: const TextStyle(color: Colors.white54)),
        for (final t in mine.reversed.take(50))
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: dirChip(context, t.direction),
            title: Text('${pairLabel(t.asset)}${t.level > 0 ? '  ${l.galeTag(ltr(t.level))}' : ''}'),
            subtitle: Text('${ltr(t.time.toString().substring(5, 16))} · ${dollars(t.amount)} · '
                '${entryLabel(l, t.entry)} · ${ltr('${t.delayMs} ms')}'),
            trailing: Text(signedMoney(t.profit),
                style: TextStyle(fontWeight: FontWeight.bold, color: t.profit > 0 ? green : t.profit < 0 ? red : null)),
          ),
      ]),
    ]);
  }
}

// ---------------------------------------------------------------- settings

/// Parses a typed number, also with Arabic-Indic digits and Arabic separators.
double? parseNumber(String v) {
  final ascii = v
      .trim()
      .replaceAllMapped(RegExp('[\u0660-\u0669\u06F0-\u06F9]'), (m) => '${m[0]!.codeUnitAt(0) & 0xF}')
      .replaceAll(RegExp('[,\u066B]'), '.')
      .replaceAll('\u2212', '-')
      .replaceAll(RegExp('[\u200E\u200F]'), '');
  return double.tryParse(ascii);
}

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
          textDirection: TextDirection.ltr, // numbers read left-to-right; label and help follow the app
          decoration: InputDecoration(labelText: label, helperText: help),
          onChanged: (v) {
            final d = parseNumber(v);
            if (d != null) {
              set(d);
              _save();
            }
          },
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = L.of(context), app = widget.app;
    final locked = app.running;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(l.language, style: const TextStyle(fontSize: 12, color: Colors.white54)),
      const SizedBox(height: 6),
      SegmentedButton<String>(
        segments: [
          ButtonSegment(value: '', label: Text(l.languageSystem)),
          const ButtonSegment(value: 'en', label: Text('English')),
          const ButtonSegment(value: 'ar', label: Text('العربية')),
        ],
        selected: {app.lang},
        onSelectionChanged: (s) => app.setLang(s.first),
      ),
      const SizedBox(height: 16),
      if (locked) Text(l.stopToChange, style: const TextStyle(color: Colors.orange)),
      AbsorbPointer(
        absorbing: locked,
        child: Column(children: [
          _num(l.amountLabel, l.amountHelp, c.amount, (v) => c.amount = v),
          _num(l.tzLabel, l.tzHelp, c.utcOffsetMin / 60, (v) => c.utcOffsetMin = (v * 60).round()),
          _num(l.galesLabel, l.offHelp, c.gales, (v) => c.gales = v.round().clamp(0, 5)),
          _num(l.multLabel, l.multHelp, c.galeMultiplier, (v) => c.galeMultiplier = v),
          _num(l.minPayoutLabel, l.minPayoutHelp, c.minPayout, (v) => c.minPayout = v),
          _num(l.stopLossLabel, l.offHelp, c.stopLoss, (v) => c.stopLoss = v),
          _num(l.takeProfitLabel, l.offHelp, c.takeProfit, (v) => c.takeProfit = v),
          SwitchListTile(
            title: Text(l.pendingTitle),
            subtitle: Text(l.pendingSub),
            value: c.pending,
            onChanged: (v) => {c.pending = v, _save()},
          ),
          SwitchListTile(
            title: Text(l.overlapTitle),
            subtitle: Text(l.overlapSub),
            value: c.overlap,
            onChanged: (v) => {c.overlap = v, _save()},
          ),
          SwitchListTile(
            title: Text(l.autoTiming),
            subtitle: Text(l.autoTimingSub),
            value: c.preEntryMs == null,
            onChanged: (v) => {c.preEntryMs = v ? null : 250, _save()},
          ),
          if (c.preEntryMs != null)
            _num(l.preEntryLabel, l.preEntryHelp, c.preEntryMs!, (v) => c.preEntryMs = v.round()),
        ]),
      ),
    ]);
  }
}
