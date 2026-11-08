// Live check of the AI features (Gemini). The key comes from the GEMINI_API_KEY environment variable
// (e.g. `set -a; . ./.env; set +a`) and is never printed.
//   dart run tool/ai.dart TOKEN_FILE   list reader with the live Quotex pair list, then the coach on sample stats
import 'dart:io';

import 'package:qxbot_app/core/ai.dart';
import 'package:qxbot_app/core/engine.dart';
import 'package:qxbot_app/core/quotex.dart';

Future<void> main(List<String> args) async {
  final g = Gemini(Platform.environment['GEMINI_API_KEY'] ?? '');
  final q = QuotexClient(File(args[0]).readAsStringSync().trim(), demo: true);
  await q.connect();
  await q.next((n, d) => n == 'instruments/list', const Duration(seconds: 10));
  await q.close();
  const text = '''🔥 VIP SIGNALS 🔥 (horário de Brasília)
📊 EUR/USD (OTC) ⏰ 23h35 🔴 VENDA ⌛ M1
💹 Dólar Americano / Iene Japonês OTC → 23:40 ⬆️ COMPRA 5 minutos
GBP-JPY-otc 23.50 put
✅✅✅ WIN na G1 ontem!
XYZ/ABC 23:55 CALL''';
  final sw = Stopwatch()..start();
  final json = await g.json(listPrompt(text, q.names, const Duration(hours: -3)), listSchema);
  final ms = sw.elapsedMilliseconds;
  final r = validateAiSignals(json, q.names, const Duration(hours: -3), DateTime.now());
  print('[$geminiModel] list reader: ${ms} ms');
  print('  raw: $json');
  print('  valid upcoming: ${r.signals}');
  print('  valid passed: ${r.passed}');
  print('  rejected: ${r.rejected}');

  final now = DateTime.now();
  Trade t(String a, int h, int lvl, String res, double p) =>
      Trade(DateTime(now.year, now.month, now.day, h), true, '$a$h', a, 'call', lvl, lvl == 0 ? 1 : 2.2, 'direct', 0, 1.0, res, p);
  final trades = [
    for (var i = 0; i < 6; i++) t('EURUSD_otc', 14, 0, 'win', 0.85),
    t('EURUSD_otc', 15, 0, 'loss', -1), t('EURUSD_otc', 15, 1, 'win', 1.87),
    for (var i = 0; i < 4; i++) ...[t('USDINR_otc', 20, 0, 'loss', -1), t('USDINR_otc', 20, 1, 'loss', -2.2)],
    t('USDINR_otc', 21, 0, 'win', 0.7),
  ];
  for (final lang in ['en', 'ar']) {
    sw.reset();
    final c = cleanCoach(await g.json(coachPrompt(coachStats(trades, payoutSkips: 3), lang), coachSchema));
    print('[$geminiModel] coach ($lang): ${sw.elapsedMilliseconds} ms\n  $c');
  }
}
