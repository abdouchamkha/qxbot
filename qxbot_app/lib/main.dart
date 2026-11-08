import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'app_state.dart';
import 'l10n/app_localizations.dart';
import 'ui/background.dart';
import 'ui/common.dart';
import 'ui/home.dart';
import 'ui/onboarding.dart';
import 'ui/results.dart';
import 'ui/settings.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();
  runApp(const QxApp());
}

ThemeData qxTheme({required bool arabic}) {
  final scheme = ColorScheme.fromSeed(seedColor: green, brightness: Brightness.dark, surface: bg)
      .copyWith(primary: green, onPrimary: onGreen, error: red, surface: bg, onSurface: textHi);
  final base = ThemeData(colorScheme: scheme, fontFamily: arabic ? 'Cairo' : null); // Cairo: Arabic + Latin
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
  return base.copyWith(
    scaffoldBackgroundColor: bg,
    appBarTheme: const AppBarTheme(backgroundColor: bg, surfaceTintColor: Colors.transparent, centerTitle: false),
    cardTheme: CardThemeData(color: card, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    dialogTheme: const DialogThemeData(backgroundColor: card2),
    navigationBarTheme: const NavigationBarThemeData(backgroundColor: card, indicatorColor: Color(0xFF1F4D3B), height: 68),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size(64, 48), shape: shape)),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48), shape: shape, side: const BorderSide(color: line))),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(minimumSize: const Size(48, 48))),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card2,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      helperStyle: const TextStyle(color: textLo),
    ),
    snackBarTheme: const SnackBarThemeData(backgroundColor: card2, contentTextStyle: TextStyle(color: textHi, fontSize: 15)),
  );
}

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
          listenable: app,
          builder: (context, _) => !app.onboarded ? Onboarding(app) : app.token == null ? LoginPage(app) : Shell(app)));
}

// ---------------------------------------------------------------- login

class LoginPage extends StatefulWidget {
  final AppState app;
  final String? header; // first-run step line
  const LoginPage(this.app, {super.key, this.header});
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
        Container(
            width: double.infinity,
            color: card,
            padding: const EdgeInsets.all(16),
            child: Text(widget.header == null ? l.loginHelp : '${widget.header}\n${l.loginHelp}',
                style: const TextStyle(fontSize: 15, height: 1.4, color: textMid))),
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
  void initState() {
    super.initState();
    // 1.1.0 users skip the first-run guide but see the background setup once.
    if (!widget.app.bgSetupSeen) {
      widget.app.markBgSetupSeen();
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => Navigator.push(context, MaterialPageRoute(builder: (_) => BackgroundSetupPage(widget.app))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app, l = L.of(context);
    final pages = [HomePage(app, () => setState(() => tab = 1)), ResultsPage(app), SettingsPage(app)];
    // Back on another tab returns Home first; on Home it leaves the app (trading keeps running).
    return PopScope(
      canPop: tab == 0,
      onPopInvokedWithResult: (didPop, _) => didPop ? null : setState(() => tab = 0),
      child: Scaffold(
        appBar: AppBar(title: Text(l.appTitle, style: const TextStyle(fontWeight: FontWeight.w800)), actions: [
          IconButton(
            tooltip: l.details,
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPage(app))),
          ),
          gap8,
        ]),
        body: SafeArea(child: pages[tab]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (i) => setState(() => tab = i),
          destinations: [
            NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: l.tabHome),
            NavigationDestination(
                icon: const Icon(Icons.insights_outlined), selectedIcon: const Icon(Icons.insights), label: l.tabResults),
            NavigationDestination(icon: const Icon(Icons.tune), label: l.tabSettings),
          ],
        ),
      ),
    );
  }
}
