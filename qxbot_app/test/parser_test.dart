// Port of test_signals.py and the parse tests of test_bot.py.
import 'package:qxbot_app/core/parser.dart';
import 'package:flutter_test/flutter_test.dart';

const tz = Duration(hours: -3);
DateTime at3(int y, int mo, int d, int h, int mi) => DateTime.utc(y, mo, d, h, mi).subtract(tz); // a UTC-3 wall time
final now = at3(2026, 11, 6, 10, 0);
const names = [
  ('EURUSD', 'EUR/USD'), ('EURUSD_otc', 'EUR/USD (OTC)'), ('GBPJPY', 'GBP/JPY'), ('BRLUSD_otc', 'USD/BRL (OTC)'),
  ('BTCUSD_otc', 'Bitcoin (OTC)'), ('XAUUSD', 'Gold'), ('XAUUSD_otc', 'Gold (OTC)'), ('AUDCAD_otc', 'AUD/CAD (OTC)'),
  ('GBPUSD', 'GBP/USD'),
];

List<(String, String, int, String)> parsed(String text, [List<(String, String)>? n]) =>
    [for (final s in parseSignals(text, tz, now, names: n)) (s.asset, s.hhmm, s.duration, s.direction)];

const list = '''M1 NZDJPY-OTC 00:00 PUT  ✅
M1 NZDJPY-OTC 00:03 PUT    ✅
M1 NZDCAD-OTC 00:23 PUT  ✅
M5 EURUSD 00:45 CALL ✅''';

void main() {
  test('classic lines with noise', () {
    expect(parsed('🔥 VIP SIGNALS 🔥\nM1 NZDJPY-OTC 10:03 PUT  ✅\nM5 EURUSD 10:45 CALL ✅✅'),
        [('NZDJPY_otc', '10:03', 60, 'put'), ('EURUSD', '10:45', 300, 'call')]);
  });

  test('fancy font comma format', () {
    expect(parsed('𝙰𝚄𝙳𝙽𝚉𝙳-𝙾𝚃𝙲,𝟷𝟾:𝟻𝟻 𝙼𝟷 𝙲𝙰𝙻𝙻'), [('AUDNZD_otc', '18:55', 60, 'call')]);
  });

  test('multiline blocks', () {
    const text = '📊 EUR/USD (OTC)\n⏰ 14:30\n⌛ 5 min\n🟢 BUY\n\n📊 GBP/JPY\n⏰ 14:40\n⌛ 1 minute\n🔴 SELL';
    expect(parsed(text, names), [('EURUSD_otc', '14:30', 300, 'call'), ('GBPJPY', '14:40', 60, 'put')]);
  });

  test('header expiry, separators and words', () {
    const text = 'Expiração: M5\n14:30 - GBP/JPY - VENDA\n14.35 ; EUR-USD ; COMPRA\n14h40 AUD_CAD OTC ⬆️';
    expect(parsed(text), [('GBPJPY', '14:30', 300, 'put'), ('EURUSD', '14:35', 300, 'call'), ('AUDCAD_otc', '14:40', 300, 'call')]);
  });

  test('timezone written in list overrides setting', () {
    final s = parseSignals('Timezone: UTC+1\nM1 EURUSD 15:00 CALL', tz, now);
    expect(s[0].offset, const Duration(hours: 1));
    expect(s[0].local.hour, 15);
  });

  test('prices and dates are not times', () {
    expect(parsed('📅 06.11.2026\nEURUSD entry 1.12935 at 14:30 CALL'), [('EURUSD', '14:30', 60, 'call')]);
  });

  test('names from quotex list and otc fallback', () {
    expect(parsed('Bitcoin OTC 15:00 call 1 min\nGOLD 15:05 PUT M5\nUSD/BRL 15:10 PUT', names),
        [('BTCUSD_otc', '15:00', 60, 'call'), ('XAUUSD', '15:05', 300, 'put'), ('BRLUSD_otc', '15:10', 60, 'put')]);
  });

  test('arabic and glued otc', () {
    expect(parsed('EUR/USD 14:30 شراء 5 دقائق\nEURUSDOTC 14:35 بيع'),
        [('EURUSD', '14:30', 300, 'call'), ('EURUSD_otc', '14:35', 60, 'put')]);
  });

  test('seconds and otc header', () {
    expect(parsed('OTC SIGNALS\nEURUSD 14:30:00 CALL 30s\nGBPUSD 14:31 DOWN'),
        [('EURUSD_otc', '14:30', 30, 'call'), ('GBPUSD_otc', '14:31', 60, 'put')]);
  });

  test('garbage gives nothing', () {
    expect(parsed('Hello! Join our VIP channel 🚀 profit 85% today, win rate 90%'), isEmpty);
  });

  test('unknown pair is reported', () {
    final unknown = <String>[];
    expect(parseSignals('ABC/XYZ OTC 14:30 CALL\nEURUSD 14:31 PUT', tz, now, names: names, unknown: unknown)[0].asset, 'EURUSD');
    expect(unknown, ['ABC/XYZ OTC 14:30 CALL']);
  });

  test('slash pair with underscore otc and dash', () {
    const text = 'توقيت المنصة 06:00+ ❤️\nمدة الصفقة 1 دقيقة ❤️\n\n'
        '❒ 𝚄𝚂𝙳/𝙱𝙳𝚃_𝙾𝚃𝙲 𝙼𝟷 — 𝙿𝚄𝚃 𝟷𝟶:𝟹𝟺✅.\n❒ 𝚄𝚂𝙳/𝙼𝚇𝙽_𝙾𝚃𝙲 𝙼𝟷 — 𝙱𝚄𝚈 𝟷𝟷:𝟺𝟷';
    final n = [...names, ('USDBDT_otc', 'USD/BDT (OTC)'), ('USDMXN_otc', 'USD/MXN (OTC)')];
    expect(parsed(text, n), [('USDBDT_otc', '10:34', 60, 'put'), ('USDMXN_otc', '11:41', 60, 'call')]);
  });

  // test_bot.py
  test('next day list', () {
    final s = parseSignals(list, tz, at3(2026, 11, 4, 23, 50));
    expect(s.map((x) => x.asset), ['NZDJPY_otc', 'NZDJPY_otc', 'NZDCAD_otc', 'EURUSD']);
    expect(s[0].at, at3(2026, 11, 5, 0, 0));
    expect([s[0].direction, s[0].duration, s[3].duration], ['put', 60, 300]);
  });

  test('skips already passed, collects them', () {
    final passed = <Signal>[];
    final s = parseSignals(list, tz, at3(2026, 11, 5, 0, 10), passed: passed);
    expect(s.map((x) => x.local.minute), [23, 45]);
    expect(passed.map((x) => (x.local.minute, x.direction)), [(0, 'put'), (3, 'put')]);
    expect(parseSignals(list, tz, at3(2026, 11, 5, 0, 10)).length, 2);
  });

  test('timezone conversion', () {
    final s = parseSignals('M1 EURUSD 23:30 CALL', tz, DateTime.utc(2026, 11, 5, 2, 0));
    expect(s[0].at, DateTime.utc(2026, 11, 5, 2, 30));
  });

  test('fancy font two lines', () {
    final s = parseSignals('𝙰𝚄𝙳𝙽𝚉𝙳-𝙾𝚃𝙲,𝟷𝟾:𝟻𝟻 𝙼𝟷 𝙲𝙰𝙻𝙻\n𝙽𝚉𝙳𝙲𝙰𝙳-𝙾𝚃𝙲,𝟷𝟿:𝟹𝟺 𝙼𝟻 𝙿𝚄𝚃', tz, at3(2026, 11, 6, 18, 0));
    expect(s.map((x) => (x.asset, x.hhmm, x.duration, x.direction)),
        [('AUDNZD_otc', '18:55', 60, 'call'), ('NZDCAD_otc', '19:34', 300, 'put')]);
  });

  test('UTC+6 header with colon', () {
    expect(listTimezone('(UTC +6:00)'), const Duration(hours: 6));
    expect(listTimezone('GMT−3'), const Duration(hours: -3));
  });

  // Arabic lists
  test('arabic header with timezone, arabic block labels', () {
    const text = 'إشارات اليوم 🔥 التوقيت UTC+1\n'
        'مدة الصفقة: 5 دقائق\n\n'
        '📊 الزوج: EUR/USD OTC\n⏰ الوقت: 14:30\n🟢 الاتجاه: شراء\n\n'
        '📊 الزوج: GBP/JPY\n⏰ الوقت: 14:40\n🔴 الاتجاه: بيع';
    final s = parseSignals(text, tz, now, names: names);
    expect(s.map((x) => (x.asset, x.hhmm, x.duration, x.direction)),
        [('EURUSD_otc', '14:30', 300, 'call'), ('GBPJPY', '14:40', 300, 'put')]);
    expect(s[0].offset, const Duration(hours: 1));
  });

  test('arabic one-line signals with arabic-indic digits', () {
    expect(parsed('EURUSD-OTC ١٤:٣٠ صعود ١ دقيقة\nGBPJPY ۱۴:۳۵ هبوط', names),
        [('EURUSD_otc', '14:30', 60, 'call'), ('GBPJPY', '14:35', 60, 'put')]);
  });

  test('arabic GMT header and unknown pair report', () {
    final unknown = <String>[];
    final s = parseSignals('توقيت (GMT -3:00)\nAUD/CAD OTC 11:05 أعلى\nXYZ/ABC 11:10 أدنى', const Duration(hours: 5), now,
        names: names, unknown: unknown);
    expect(s.single.asset, 'AUDCAD_otc');
    expect(s.single.offset, const Duration(hours: -3));
    expect(s.single.direction, 'call');
    expect(unknown, ['XYZ/ABC 11:10 أدنى']);
  });
}
