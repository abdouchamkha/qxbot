// Smoke test: every tab renders without layout errors (no network, no token).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qxbot_app/core/engine.dart';
import 'package:qxbot_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('all tabs render', (tester) async {
    SharedPreferences.setMockInitialValues({'lastList': 'M1 EURUSD-OTC 23:59 CALL\nABC/XYZ 23:58 PUT'});
    final app = AppState()..prefs = await SharedPreferences.getInstance();
    app.trades.add(Trade(DateTime.now(), true, 's', 'EURUSD_otc', 'call', 1, 2.2, 'direct', 120, 1.1, 'win', 1.9));
    app.log('EURUSD_otc CALL G1: WIN +1.90');
    await tester.pumpWidget(MaterialApp(theme: ThemeData.dark(), home: Shell(app)));
    for (final tab in ['Signals', 'Live', 'Stats', 'Settings', 'Home']) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: tab);
    }
    await tester.tap(find.text('Signals').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('1 signals found'), findsOneWidget);
    expect(find.textContaining('Pair not found'), findsOneWidget); // ABC/XYZ line is reported
  });
}
