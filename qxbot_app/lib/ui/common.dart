/// Design tokens and small widgets shared by the screens.
library;

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/parser.dart';
import '../format.dart';
import '../l10n/app_localizations.dart';

// Dark trading palette. Text colours keep >= 4.5:1 contrast on [card] and [bg].
const bg = Color(0xFF0B0E14), card = Color(0xFF151A23), card2 = Color(0xFF1D2430), line = Color(0xFF2A3240);
const green = Color(0xFF16C784), red = Color(0xFFEA3943), amber = Color(0xFFF0B90B), blue = Color(0xFF4C8DFF);
const textHi = Color(0xFFF2F4F8), textMid = Color(0xFFB0B8C4), textLo = Color(0xFF8B94A3);
const onGreen = Color(0xFF04150D); // dark text on green buttons (white on green fails contrast)

// Spacing scale: 4 / 8 / 12 / 16 / 24 / 32.
const gap4 = SizedBox(width: 4, height: 4), gap8 = SizedBox(width: 8, height: 8), gap12 = SizedBox(width: 12, height: 12);
const gap16 = SizedBox(width: 16, height: 16), gap24 = SizedBox(width: 24, height: 24);

const caption = TextStyle(fontSize: 13, color: textLo, fontWeight: FontWeight.w600, letterSpacing: 0.3);
const titleStyle = TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textHi);

/// A rounded surface with an optional small heading.
class Panel extends StatelessWidget {
  final String? title;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  const Panel({super.key, this.title, required this.child, this.padding = const EdgeInsets.all(16), this.color = card});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias, // list tiles and ink inside stay within the corners
          child: Padding(
            padding: padding,
            child: SizedBox(
              width: double.infinity,
              child: title == null
                  ? child
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title!, style: caption), gap12, child]),
            ),
          ),
        ),
      );
}

/// Numbers, prices, times and symbols on their own: always left-to-right.
Widget ltrText(String s, {TextStyle? style}) =>
    Directionality(textDirection: TextDirection.ltr, child: Text(s, style: style));

Widget dirChip(BuildContext context, String dir, {bool small = false}) {
  final l = L.of(context), c = dir == 'call' ? green : red;
  return Container(
    padding: EdgeInsets.symmetric(horizontal: small ? 8 : 10, vertical: small ? 2 : 4),
    decoration: BoxDecoration(color: c.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      // up/down arrows mean price direction: the same in both writing directions
      Icon(dir == 'call' ? Icons.arrow_upward : Icons.arrow_downward, size: small ? 14 : 16, color: c),
      const SizedBox(width: 4),
      Text(dirLabel(l, dir), style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: small ? 13 : 14)),
    ]),
  );
}

String durationLabel(L l, int seconds) => seconds >= 60 ? l.minutes(seconds ~/ 60) : l.seconds(seconds);

/// One signal of a list: time, pair, duration, direction.
class SignalTile extends StatelessWidget {
  final Signal s;
  final String? note;
  const SignalTile(this.s, {super.key, this.note});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: card2, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          ltrText(s.hhmm, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textHi)),
          gap16,
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(pairLabel(s.asset), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textHi)),
              Text(note ?? durationLabel(L.of(context), s.duration), style: const TextStyle(fontSize: 13, color: textMid)),
            ]),
          ),
          dirChip(context, s.direction),
        ]),
      );
}

/// The account badge: blue DEMO, orange REAL.
class AccountChip extends StatelessWidget {
  final bool demo;
  const AccountChip(this.demo, {super.key});
  @override
  Widget build(BuildContext context) {
    final c = demo ? blue : const Color(0xFFFF8A3D);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(20)),
      child: Text(demo ? L.of(context).demo : L.of(context).real,
          style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5)),
    );
  }
}

/// Yes/no dialog; [danger] colours the confirm button red (real money, stopping).
Future<bool> confirm(BuildContext context, String title, String body, String ok, {bool danger = false}) async {
  final l = L.of(context);
  return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(body, style: const TextStyle(fontSize: 16, height: 1.4)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
            FilledButton(
                style: danger ? FilledButton.styleFrom(backgroundColor: red, foregroundColor: Colors.white) : null,
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(ok)),
          ],
        ),
      ) ??
      false;
}

void snack(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));

/// Parses a typed number, also with Arabic-Indic digits and Arabic separators.
double? parseNumber(String v) {
  final ascii = v
      .trim()
      .replaceAllMapped(RegExp('[٠-٩۰-۹]'), (m) => '${m[0]!.codeUnitAt(0) & 0xF}')
      .replaceAll(RegExp('[,٫]'), '.')
      .replaceAll('−', '-')
      .replaceAll(RegExp('[‎‏]'), '');
  return double.tryParse(ascii);
}

String plainNumber(num v) => v == v.roundToDouble() ? '${v.toInt()}' : '$v';

/// Amount per trade: a number field plus quick picks.
class AmountField extends StatefulWidget {
  final AppState app;
  const AmountField(this.app, {super.key});
  @override
  State<AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<AmountField> {
  late final ctl = TextEditingController(text: plainNumber(widget.app.cfg.amount));

  void _set(double v) {
    widget.app.cfg.amount = v;
    widget.app.saveSettings();
    setState(() {});
  }

  @override
  void dispose() {
    ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context), a = widget.app.cfg.amount;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(
        controller: ctl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textDirection: TextDirection.ltr,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          labelText: l.amountLabel,
          prefixText: '\$ ',
          errorText: (parseNumber(ctl.text) ?? 0) < 1 ? l.invalidAmount : null,
        ),
        onChanged: (v) {
          final d = parseNumber(v);
          if (d != null && d >= 1) _set(d);
          setState(() {});
        },
      ),
      gap12,
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final v in [1.0, 2.0, 5.0, 10.0, 25.0])
          ChoiceChip(
            label: ltrText('\$${plainNumber(v)}'),
            selected: a == v,
            onSelected: (_) {
              ctl.text = plainNumber(v);
              _set(v);
            },
          ),
      ]),
    ]);
  }
}
