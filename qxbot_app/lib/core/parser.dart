/// Signal-list parser: a 1:1 port of signals.py (desktop bot).
///
/// Handles fancy Unicode fonts, any field order, one-line signals ("M1 EURUSD-OTC 14:30 CALL")
/// and multi-line blocks, arrows and emoji as directions, English/Portuguese/Arabic words,
/// list-wide headers ("Expiry M5", "Timezone UTC-3", "OTC signals"). Pairs are matched against
/// Quotex's own symbol list when given.
library;

import 'package:unorm_dart/unorm_dart.dart' as unorm;

class Signal {
  final int duration; // seconds
  final String asset; // Quotex symbol, e.g. NZDJPY_otc
  final DateTime at; // UTC entry time
  final Duration offset; // the list's timezone, for display
  final String direction; // call | put
  Signal(this.duration, this.asset, this.at, this.offset, this.direction);

  /// Entry time as written in the list's timezone.
  DateTime get local => at.add(offset);
  String get hhmm => '${_2(local.hour)}:${_2(local.minute)}';
  @override
  String toString() => '$hhmm $asset ${direction.toUpperCase()} ${duration}s';
}

String _2(int v) => v.toString().padLeft(2, '0');

final currencies = ('USD EUR GBP JPY AUD NZD CAD CHF CNY CNH HKD SGD SEK NOK DKK PLN TRY ZAR MXN BRL ARS INR IDR PKR BDT '
        'NGN EGP PHP THB MYR VND KRW COP CLP DZD MAD TND SAR AED QAR KES UAH RUB CZK HUF ILS XAU XAG')
    .split(' ')
    .toSet();
const _callWords = r'CALL|BUY|UP|HIGHER|ABOVE|COMPRA|ACIMA|ALTA|SUBIDA|شراء|صعود|اعلى|أعلى';
const _putWords = r'PUT|SELL|DOWN|LOWER|BELOW|VENDA|ABAIXO|BAIXA|QUEDA|بيع|هبوط|ادنى|أدنى|نزول';
const _callMarks = '⬆↑🔼⏫📈🟢🟩⤴';
const _putMarks = '⬇↓🔽⏬📉🔴🟥⤵';

final _timeRe = RegExp(r'(?<![\d.:/])([01]?\d|2[0-3])\s?[:hH]\s?([0-5]\d)(?![\d/])');
final _timeDotRe = RegExp(r'(?<![\d.:/])([01]?\d|2[0-3])\.([0-5]\d)(?![\d./])'); // 14.30, not prices/dates
final _durationRes = <(RegExp, int)>[
  (RegExp(r'\bM\s?(\d{1,3})\b'), 60),
  (RegExp(r'\bH(\d)\b'), 3600),
  (RegExp(r'\b(\d{1,3})\s?(?:M|MIN|MINS|MINUTE|MINUTES|MINUTO|MINUTOS)\b|(\d{1,3})\s?(?:دقيقة|دقائق|دقيقه)'), 60),
  (RegExp(r'\b(\d{1,3})\s?(?:S|SEC|SECS|SECOND|SECONDS|SEGUNDOS)\b'), 1),
  (RegExp(r'\b(\d)\s?(?:H|HR|HOUR|HOURS|HORA|HORAS)\b'), 3600),
];
final _tzRe = RegExp(r'\b(?:UTC|GMT)\s?([+\-−])\s?(\d{1,2})(?:[:.]?(\d{2}))?');
final _dirRe = RegExp('(?<![A-Z])(?:($_callWords)|($_putWords))(?![A-Z])');
final _pairSepRe = RegExp(r'\b([A-Z]{3})\s?[/\\\-_|.]\s?(?!OTC(?![A-Z]))([A-Z]{3})(?![A-Z])');
final _tokenRe = RegExp(r'#?[A-Z][A-Z0-9&]{2,14}');

typedef SymbolIndex = Map<String, Map<bool, String>>;

/// Quotex (symbol, label) rows -> {key: {isOtc: symbol}}; keys are the symbol base and the label.
SymbolIndex symbolIndex(List<(String, String)> names) {
  final index = <String, Map<bool, String>>{};
  for (final (symbol, label) in names) {
    final otc = symbol.toLowerCase().endsWith('_otc');
    final base = otc ? symbol.substring(0, symbol.length - 4) : symbol;
    for (final key in {
      _lstripHash(base.toUpperCase()),
      label.toUpperCase().replaceAll(RegExp(r'\(OTC\)|[^A-Z0-9]'), ''),
    }) {
      if (key.length >= 3) index.putIfAbsent(key, () => {})[otc] = symbol;
    }
  }
  return index;
}

String _lstripHash(String s) => s.replaceFirst(RegExp(r'^#+'), '');

/// NFKC + Arabic-Indic digits (٠-٩, ۰-۹) as ASCII: Python's `\d`/int() in signals.py accept them, Dart's don't.
String _normalize(String text) => unorm.nfkc(text).replaceAllMapped(RegExp('[\u0660-\u0669\u06F0-\u06F9]'),
    (m) => '${m[0]!.codeUnitAt(0) & 0xF}');

String _clean(String line) =>
    _normalize(line).toUpperCase().replaceAllMapped(_pairSepRe, (m) => '${m[1]}${m[2]}');

String? _pair(String line, SymbolIndex? index) {
  for (final m in _tokenRe.allMatches(line)) {
    final token = _lstripHash(m[0]!);
    for (final key in [token, token.endsWith('OTC') ? token.substring(0, token.length - 3) : token]) {
      if (index != null) {
        if (index.containsKey(key)) return key;
      } else if (key.length == 6 && currencies.contains(key.substring(0, 3)) && currencies.contains(key.substring(3))) {
        return key;
      }
    }
  }
  return null;
}

String? _direction(String line) {
  final words = _dirRe.firstMatch(line);
  if (words != null) return words[1] != null ? 'call' : 'put';
  for (final r in line.runes) {
    final ch = String.fromCharCode(r);
    if (_callMarks.contains(ch)) return 'call';
    if (_putMarks.contains(ch)) return 'put';
  }
  return null;
}

int? _duration(String line) {
  for (final (re, unit) in _durationRes) {
    final m = re.firstMatch(line);
    if (m != null) {
      final g = [for (var i = 1; i <= m.groupCount; i++) m[i]].firstWhere((g) => g != null && g.isNotEmpty);
      final value = int.parse(g!) * unit;
      if (value >= 5 && value <= 4 * 3600) return value;
    }
  }
  return null;
}

(int, int)? _time(String line) {
  final m = _timeRe.firstMatch(line) ?? _timeDotRe.firstMatch(line);
  return m == null ? null : (int.parse(m[1]!), int.parse(m[2]!));
}

Map<String, Object> _fields(String raw, SymbolIndex? index) {
  final line = _clean(raw);
  final noTime = line.replaceAll(_timeRe, ' '); // so "14:30" is not read as a duration
  final found = <String, Object?>{
    'pair': _pair(noTime, index),
    'time': _time(line),
    'direction': _direction(line),
    'duration': _duration(noTime.replaceAll(_tzRe, ' ')),
    'otc': line.contains('OTC') ? true : null,
  };
  return {
    for (final e in found.entries)
      if (e.value != null) e.key: e.value!
  };
}

/// Timezone written in the list (UTC-3, GMT+1, (UTC +6:00)), or null.
Duration? listTimezone(String text) {
  final m = _tzRe.firstMatch(_normalize(text).toUpperCase());
  if (m == null) return null;
  final sign = (m[1] == '-' || m[1] == '−') ? -1 : 1;
  return Duration(hours: int.parse(m[2]!), minutes: int.parse(m[3] ?? '0')) * sign;
}

const _core = {'pair', 'time', 'direction'};

/// Signals in time order. A timezone written in the list overrides [tz].
/// Past times within 12h are left out and added to [passed]; older ones roll to tomorrow.
/// Lines with a time and a direction but no known pair are added to [unknown].
List<Signal> parseSignals(String text, Duration tz, DateTime now,
    {List<(String, String)>? names, int defaultDuration = 60, List<String>? unknown, List<Signal>? passed}) {
  final offset = listTimezone(text) ?? tz;
  final index = names != null && names.isNotEmpty ? symbolIndex(names) : null;
  final out = <Signal>[];
  final header = <String, Object>{'duration': defaultDuration, 'otc': false};
  var block = <String, Object>{};
  final nowUtc = now.toUtc();

  void emit(Map<String, Object> f) {
    final (hh, mm) = f['time'] as (int, int);
    final day = nowUtc.add(offset);
    var at = DateTime.utc(day.year, day.month, day.day, hh, mm).subtract(offset);
    final otc = (f['otc'] as bool? ?? false) || (header['otc'] as bool);
    var asset = '${f['pair']}${otc ? '_otc' : ''}';
    if (index != null) {
      final variants = index[f['pair']]!;
      asset = variants[otc] ?? variants[!otc]!; // e.g. a pair Quotex only has as OTC
    }
    var target = out;
    if (!at.isAfter(nowUtc)) {
      if (nowUtc.difference(at) < const Duration(hours: 12)) {
        if (passed == null) return;
        target = passed;
      } else {
        at = at.add(const Duration(days: 1));
      }
    }
    target.add(Signal((f['duration'] ?? header['duration']) as int, asset, at, offset, f['direction'] as String));
  }

  bool complete(Map<String, Object> f) => f.keys.toSet().containsAll(_core);

  void flush() {
    if (complete(block)) emit(block);
    block = {};
  }

  for (final raw in [...text.split(RegExp(r'\r?\n')), '']) {
    final f = _fields(raw, index);
    final keys = f.keys.toSet()..remove('otc');
    if (unknown != null && keys.containsAll({'time', 'direction'}) && !f.containsKey('pair')) {
      unknown.add(raw.trim());
    }
    if (complete(f)) {
      flush();
      emit(f);
    } else if (keys.isEmpty) {
      if (f['otc'] == true) {
        (block.isNotEmpty ? block : header)['otc'] = true;
      } else if (complete(block)) {
        flush();
      }
    } else if (keys.length == 1 && keys.first == 'duration' && block.isEmpty) {
      header['duration'] = f['duration']!;
      header['otc'] = (header['otc'] as bool) || (f['otc'] as bool? ?? false);
    } else {
      if (keys.intersection(block.keys.toSet()).intersection(_core).isNotEmpty) flush();
      block.addAll(f);
    }
  }
  if (passed != null) _byTime(passed);
  return _byTime(out);
}

/// Stable sort by time (Dart's List.sort is not stable; same-minute order matters for overlap).
List<Signal> _byTime(List<Signal> list) {
  final idx = {for (var i = 0; i < list.length; i++) list[i]: i};
  return list..sort((a, b) => a.at.compareTo(b.at) != 0 ? a.at.compareTo(b.at) : idx[a]!.compareTo(idx[b]!));
}
