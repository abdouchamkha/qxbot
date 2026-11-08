// Home, results, settings, details and the first-run guide render in English and Arabic; Arabic is right-to-left
// with LTR numbers, pairs and times.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qxbot_app/app_state.dart';
import 'package:qxbot_app/core/engine.dart';
import 'package:qxbot_app/core/quotex.dart';
import 'package:qxbot_app/format.dart';
import 'package:qxbot_app/l10n/app_localizations.dart';
import 'package:qxbot_app/main.dart';
import 'package:qxbot_app/ui/home.dart';
import 'package:qxbot_app/ui/onboarding.dart';
import 'package:qxbot_app/ui/results.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "HH:MM" [d] from now in the default list timezone (UTC-3), so the signal is always in the future.
String listTime(Duration d) {
  final t = DateTime.now().toUtc().subtract(const Duration(hours: 3)).add(d);
  return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

final soon = listTime(const Duration(minutes: 30));
final list = 'M1 EURUSD-OTC $soon CALL\nABC/XYZ $soon PUT';

Future<AppState> makeApp(String lang, {bool running = true}) async {
  SharedPreferences.setMockInitialValues({'lastList': list, 'lang': lang});
  final app = AppState()
    ..prefs = await SharedPreferences.getInstance()
    ..lang = lang
    ..token = 'x';
  app.trades.add(Trade(DateTime.now(), true, 's', 'EURUSD_otc', 'call', 1, 2.2, 'direct', 120, 1.1, 'win', 1.9));
  app.trades.add(Trade(DateTime.now(), true, 't', 'GBPJPY', 'put', 0, 1, 'pending', 60, 1.1, 'loss', -1));
  app.log(const EngineEvent('result', {'time': '10:00', 'pair': 'EURUSD_otc', 'dir': 'call', 'level': 1, 'result': 'win', 'profit': 1.9}));
  app.log(const EngineEvent('skipped', {
    'time': '10:05', 'pair': 'GBPJPY', 'dir': 'put', 'reason': EngineEvent('payout', {'payout': 77, 'min': 80.0}),
  }));
  if (running) {
    final q = QuotexClient('x', demo: true);
    app
      ..q = q
      ..engine = Engine(q, app.cfg, app.trades, app.log)
      ..running = true;
    app.engine!.scheduled.addAll(app.parse(list));
  }
  return app;
}

Future<void> visitTabs(WidgetTester tester, L l) async {
  for (final tab in [l.tabResults, l.tabSettings, l.tabHome]) {
    await tester.tap(find.text(tab).last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: tab);
  }
}

void main() {
  testWidgets('English: status card, results, settings essentials first, details', (tester) async {
    final app = await makeApp('en');
    await tester.pumpWidget(qxMaterialApp(app, Shell(app)));
    await tester.pumpAndSettle();
    final l = lookupL(const Locale('en'));
    expect(find.text('Next trade'), findsOneWidget);
    expect(find.text(pairLabel('EURUSD_otc')), findsWidgets);
    expect(find.text('at ${ltr(soon)}'), findsOneWidget);
    expect(find.textContaining(RegExp(r'^in ')), findsOneWidget); // countdown
    expect(find.text(l.stop), findsOneWidget); // running: big Stop
    expect(find.text(signedMoney(0.9)), findsOneWidget); // today's profit
    await visitTabs(tester, l);

    await tester.tap(find.text(l.tabResults).last);
    await tester.pumpAndSettle();
    expect(find.text(l.galeTag(ltr(1))), findsNothing); // the step is in the card's detail line
    expect(find.textContaining(l.galeTag(ltr(1))), findsOneWidget);
    expect(find.text('WIN'), findsOneWidget);
    expect(find.text('LOSS'), findsOneWidget);

    await tester.tap(find.text(l.tabSettings).last);
    await tester.pumpAndSettle();
    expect(find.text(l.essentials), findsOneWidget);
    expect(find.text(l.pendingTitle), findsNothing); // under Advanced, collapsed
    expect(find.text(l.stopToChange), findsOneWidget); // running: locked

    await tester.tap(find.byTooltip(l.details));
    await tester.pumpAndSettle();
    expect(find.byType(DetailsPage), findsOneWidget);
    expect(find.textContaining('payout ${ltr(77)}% < ${ltr(80)}%'), findsOneWidget);
  });

  testWidgets('Stop asks first', (tester) async {
    final app = await makeApp('en');
    await tester.pumpWidget(qxMaterialApp(app, Shell(app)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stop'));
    await tester.pumpAndSettle();
    expect(find.text('Stop the bot?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(app.running, isTrue);
  });

  testWidgets('Paste from clipboard shows the preview with Start', (tester) async {
    final app = await makeApp('en', running: false);
    app.engine = Engine(QuotexClient('x', demo: true), app.cfg, app.trades, app.log);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform, (call) async => call.method == 'Clipboard.getData' ? {'text': list} : null);
    await tester.pumpWidget(qxMaterialApp(app, Shell(app)));
    await tester.pumpAndSettle();
    expect(find.text('Copy a signal list in Telegram, then tap the button below.'), findsOneWidget);
    await tester.tap(find.text('Paste list from clipboard'));
    await tester.pumpAndSettle();
    expect(find.byType(PreviewSheet), findsOneWidget);
    expect(find.text('1 signal found'), findsOneWidget);
    expect(find.textContaining('Pair not found'), findsOneWidget); // the ABC/XYZ line
    expect(find.text('Start trading (1)'), findsOneWidget);
    expect(find.textContaining('per trade · DEMO account'), findsOneWidget);
  });

  testWidgets('Arabic: right-to-left, translated, numbers isolated LTR', (tester) async {
    final app = await makeApp('ar');
    await tester.pumpWidget(qxMaterialApp(app, Shell(app)));
    await tester.pumpAndSettle();
    final l = lookupL(const Locale('ar'));

    final ctx = tester.element(find.byType(Shell));
    expect(Directionality.of(ctx), TextDirection.rtl);
    expect(Theme.of(ctx).textTheme.bodyMedium!.fontFamily, 'Cairo');
    expect(find.text('الصفقة التالية'), findsOneWidget);
    expect(find.text('شراء'), findsWidgets); // CALL
    expect(find.text('الساعة ${ltr(soon)}'), findsOneWidget);
    expect(find.textContaining(RegExp('^بعد ')), findsOneWidget); // countdown
    expect(find.text('تجريبي'), findsOneWidget); // DEMO chip
    expect(find.text(ltr('EURUSD (OTC)')), findsWidgets); // pair isolated LTR

    // RTL layout: the first navigation destination (Home) sits on the right
    final home = tester.getCenter(find.text(l.tabHome).last), settings = tester.getCenter(find.text(l.tabSettings).last);
    expect(home.dx, greaterThan(settings.dx));
    await visitTabs(tester, l);

    await tester.tap(find.text(l.tabResults).last);
    await tester.pumpAndSettle();
    expect(find.text('ربح'), findsOneWidget); // WIN card
    expect(find.text(signedMoney(1.9)), findsOneWidget);
    expect(find.textContaining('مضاعفة ${ltr(1)}'), findsOneWidget); // martingale step

    await tester.tap(find.text(l.tabSettings).last);
    await tester.pumpAndSettle();
    expect(find.text('الأساسيات'), findsOneWidget);
    final tz = tester.widget<Text>(find.text('UTC-3'));
    expect(Directionality.of(tester.element(find.byWidget(tz))), TextDirection.ltr);

    app.setLang('en');
    await tester.pumpAndSettle();
    expect(Directionality.of(tester.element(find.byType(Shell))), TextDirection.ltr);
    expect(find.text('Essentials'), findsOneWidget);
  });

  for (final lang in ['en', 'ar']) {
    testWidgets('first-run guide ($lang): account -> amount -> background -> done', (tester) async {
      final app = await makeApp(lang, running: false);
      app.onboarded = false;
      await tester.pumpWidget(qxMaterialApp(
          app, ListenableBuilder(listenable: app, builder: (_, child) => app.onboarded ? Shell(app) : Onboarding(app))));
      await tester.pumpAndSettle();
      final l = lookupL(Locale(lang));
      expect(find.text(l.obAccountTitle), findsOneWidget);
      expect(find.text(l.obStep(ltr(2), ltr(4))), findsOneWidget);
      expect(find.text(l.demoCardTitle), findsOneWidget);
      if (lang == 'ar') expect(Directionality.of(tester.element(find.byType(Onboarding))), TextDirection.rtl);
      await tester.tap(find.text(l.next));
      await tester.pumpAndSettle();
      expect(find.text(l.obAmountTitle), findsOneWidget);
      await tester.tap(find.text('\$5'));
      await tester.pumpAndSettle();
      expect(app.cfg.amount, 5);
      expect(find.textContaining(dollars(11)), findsOneWidget); // martingale step of 5 x 2.2
      await tester.tap(find.text(l.next));
      await tester.pumpAndSettle();
      expect(find.text(l.bgTitle), findsOneWidget);
      expect(find.textContaining(l.bgPending), findsOneWidget);
      await tester.tap(find.text(l.continueBtn));
      await tester.pumpAndSettle();
      expect(find.text(l.obDoneTitle), findsOneWidget);
      await tester.tap(find.text(l.goHome));
      await tester.pumpAndSettle();
      expect(app.onboarded, isTrue);
      expect(app.prefs.getBool('onboarded'), isTrue);
      expect(find.byType(Shell), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  test('upgrade from 1.1.0: saved settings or a login skip the first-run guide', () async {
    SharedPreferences.setMockInitialValues({'settings': '{"amount":3}'});
    expect(isOnboarded(await SharedPreferences.getInstance(), null), isTrue);
    SharedPreferences.setMockInitialValues({});
    expect(isOnboarded(await SharedPreferences.getInstance(), 'token'), isTrue);
    expect(isOnboarded(await SharedPreferences.getInstance(), null), isFalse); // fresh install
    SharedPreferences.setMockInitialValues({'settings': '{}', 'onboarded': false});
    expect(isOnboarded(await SharedPreferences.getInstance(), 'token'), isFalse);
  });

  test('every engine event key has a text in both languages', () {
    for (final code in ['en', 'ar']) {
      final l = lookupL(Locale(code));
      for (final e in [
        const EngineEvent('connected', {'demo': true}), const EngineEvent('connectFailed', {'error': 'x'}),
        const EngineEvent('started', {'count': 3}), const EngineEvent('stopped'), const EngineEvent('allDone'),
        for (final r in [
          const EngineEvent('overlap'), const EngineEvent('stopLoss', {'net': -5.0}),
          const EngineEvent('takeProfit', {'net': 5.0}), const EngineEvent('balance', {'balance': 0.5, 'amount': 1.0}),
          const EngineEvent('notConnected'), const EngineEvent('pairNotFound'), const EngineEvent('pairClosed'),
          const EngineEvent('payout', {'payout': 70, 'min': 80.0}), const EngineEvent('stopped'),
          const EngineEvent('late', {'seconds': 42}),
        ])
          EngineEvent('skipped', {'time': '10:00', 'pair': 'EURUSD', 'dir': 'put', 'reason': r}),
        const EngineEvent('connectionLost'), const EngineEvent('reconnectFailed', {'error': 'x'}),
        const EngineEvent('orderNotConfirmed', {'pair': 'EURUSD'}),
        const EngineEvent('orderRejected', {'pair': 'EURUSD', 'dir': 'call', 'error': 'open_time'}),
        const EngineEvent('orderOpened', {
          'pair': 'EURUSD', 'dir': 'call', 'amount': 1.0, 'delay': -120, 'at': 1700000000, 'sent': -250, 'ping': 480,
          'price': 1.1,
        }),
        const EngineEvent('pendingSet', {'pair': 'EURUSD_otc', 'dir': 'put', 'amount': 1.0, 'at': 1700000000}),
        const EngineEvent('pendingNoTicket', {'pair': 'EURUSD_otc'}),
        const EngineEvent('pendingCancelled', {'pair': 'EURUSD_otc', 'reason': EngineEvent('stopped')}),
        const EngineEvent('pendingOpened',
            {'pair': 'EURUSD_otc', 'dir': 'put', 'amount': 1.0, 'delay': 64, 'at': 1700000000, 'price': 1.1}),
        const EngineEvent('pendingNoAnswer', {'pair': 'EURUSD_otc'}),
        const EngineEvent('pendingFailed', {'pair': 'EURUSD_otc', 'error': 'code 9'}),
        const EngineEvent('galeReady', {'pair': 'EURUSD', 'level': 1}),
        const EngineEvent('galeCancelledOverlap', {'pair': 'EURUSD', 'at': 1700000060}),
        const EngineEvent('galeStart', {'pair': 'EURUSD', 'level': 1, 'amount': 2.2}),
        const EngineEvent('resultNotReceived', {'pair': 'EURUSD'}),
        const EngineEvent('result', {'pair': 'EURUSD', 'dir': 'put', 'level': 0, 'result': 'loss', 'profit': -1.0}),
        const EngineEvent('error', {'pair': 'EURUSD', 'error': 'x'}),
        const EngineEvent('clockWarning', {'offset': 1.4}),
        const EngineEvent('wokeUp', {'seconds': 95}),
        const EngineEvent('serviceFailed', {'error': 'x'}),
      ]) {
        final text = formatEvent(l, e);
        expect(text, isNot('$e'), reason: '$code ${e.key} has no text');
        final reason = e.args['reason'];
        if (code == 'ar' && reason is EngineEvent) expect(formatReason(l, reason), isNot('$reason'), reason: '$code ${reason.key}');
        if (code == 'ar') {
          expect(text, isNot(contains(e.key)), reason: 'ar ${e.key} is not translated');
          expect(RegExp('[؀-ۿ]').hasMatch(text), isTrue, reason: 'ar ${e.key}: $text');
        }
      }
    }
  });

  test('connection errors in plain words', () {
    final l = lookupL(const Locale('en'));
    expect(humanError(l, 'authorization failed: {}'), l.loginExpired);
    expect(humanError(l, "SocketException: Failed host lookup: 'ws2.quotex.com'"), l.noInternet);
    expect(humanError(l, 'TimeoutException after 0:00:15'), l.connectProblem);
    expect(countdown(const Duration(minutes: 3, seconds: 12)), ltr('03:12'));
    expect(countdown(const Duration(hours: 1, minutes: 2, seconds: 3)), ltr('1:02:03'));
    expect(countdown(const Duration(seconds: -5)), ltr('00:00'));
  });
}
