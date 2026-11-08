// Every tab renders in English and Arabic; Arabic is right-to-left with LTR numbers, pairs and times.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qxbot_app/app_state.dart';
import 'package:qxbot_app/core/engine.dart';
import 'package:qxbot_app/format.dart';
import 'package:qxbot_app/l10n/app_localizations.dart';
import 'package:qxbot_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppState> makeApp(String lang) async {
  SharedPreferences.setMockInitialValues({'lastList': 'M1 EURUSD-OTC 23:59 CALL\nABC/XYZ 23:58 PUT', 'lang': lang});
  final app = AppState()
    ..prefs = await SharedPreferences.getInstance()
    ..lang = lang;
  app.trades.add(Trade(DateTime.now(), true, 's', 'EURUSD_otc', 'call', 1, 2.2, 'direct', 120, 1.1, 'win', 1.9));
  app.log(const EngineEvent('result', {'time': '10:00', 'pair': 'EURUSD_otc', 'dir': 'call', 'level': 1, 'result': 'win', 'profit': 1.9}));
  app.log(const EngineEvent('skipped', {
    'time': '10:05', 'pair': 'GBPJPY', 'dir': 'put', 'reason': EngineEvent('payout', {'payout': 77, 'min': 80.0}),
  }));
  return app;
}

Future<void> visitTabs(WidgetTester tester, L l) async {
  for (final tab in [l.tabSignals, l.tabLive, l.tabStats, l.tabSettings, l.tabHome]) {
    await tester.tap(find.text(tab).last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: tab);
  }
}

void main() {
  testWidgets('all tabs render in English', (tester) async {
    final app = await makeApp('en');
    await tester.pumpWidget(qxMaterialApp(app, Shell(app)));
    await tester.pumpAndSettle();
    final l = lookupL(const Locale('en'));
    await visitTabs(tester, l);
    await tester.tap(find.text(l.tabSignals).last);
    await tester.pumpAndSettle();
    expect(find.text('1 signal found'), findsOneWidget);
    expect(find.textContaining('Pair not found'), findsOneWidget); // the ABC/XYZ line
  });

  testWidgets('Arabic: right-to-left, translated, numbers isolated LTR', (tester) async {
    final app = await makeApp('ar');
    await tester.pumpWidget(qxMaterialApp(app, Shell(app)));
    await tester.pumpAndSettle();
    final l = lookupL(const Locale('ar'));

    // the whole app is RTL and uses the bundled Arabic font
    final ctx = tester.element(find.byType(Shell));
    expect(Directionality.of(ctx), TextDirection.rtl);
    expect(Theme.of(ctx).textTheme.bodyMedium!.fontFamily, 'Cairo');
    expect(find.text('الرئيسية'), findsWidgets); // Home tab
    expect(find.text('تجريبي'), findsOneWidget); // DEMO chip

    // RTL layout: the first navigation destination (Home) sits on the right
    final home = tester.getCenter(find.text(l.tabHome).last), settings = tester.getCenter(find.text(l.tabSettings).last);
    expect(home.dx, greaterThan(settings.dx));

    await visitTabs(tester, l);

    await tester.tap(find.text(l.tabSignals).last);
    await tester.pumpAndSettle();
    expect(find.text('تم العثور على إشارة واحدة'), findsOneWidget);
    expect(find.text('شراء'), findsWidgets); // CALL
    expect(find.text('دقيقة واحدة'), findsOneWidget); // 1 min
    expect(find.text(ltr('EURUSD (OTC)')), findsOneWidget); // pair isolated LTR
    final time = tester.widget<Text>(find.text('23:59'));
    expect(Directionality.of(tester.element(find.byWidget(time))), TextDirection.ltr);

    await tester.tap(find.text(l.tabLive).last);
    await tester.pumpAndSettle();
    expect(find.textContaining('ربح ${signedMoney(1.9)}'), findsOneWidget); // WIN +1.90 with LTR money
    expect(find.textContaining('نسبة الربح ${ltr(77)}% أقل من ${ltr(80)}%'), findsOneWidget);

    // switching the language back follows at once
    app.setLang('en');
    await tester.pumpAndSettle();
    expect(Directionality.of(tester.element(find.byType(Shell))), TextDirection.ltr);
    expect(find.text('Log'), findsOneWidget);
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
      ]) {
        final text = formatEvent(l, e);
        expect(text, isNot('$e'), reason: '$code ${e.key} has no text');
        final reason = e.args['reason'];
        if (code == 'ar' && reason is EngineEvent) expect(formatReason(l, reason), isNot('$reason'), reason: '$code ${reason.key}');
        if (code == 'ar') {
          expect(text, isNot(contains(e.key)), reason: 'ar ${e.key} is not translated');
          expect(RegExp('[\u0600-\u06FF]').hasMatch(text), isTrue, reason: 'ar ${e.key}: $text');
        }
      }
    }
  });
}
