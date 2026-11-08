/// Settings: essentials first (account, amount, martingale, list timezone, daily limits), the rest under Advanced.
library;

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/engine.dart';
import '../l10n/app_localizations.dart';
import 'background.dart';
import 'common.dart';

/// Asks before switching to real money. Returns when done.
Future<void> switchAccount(BuildContext context, AppState app, bool demo) async {
  final l = L.of(context);
  if (!demo && !await confirm(context, l.realTitle, l.realBody, l.useReal, danger: true)) return;
  await app.switchAccount(demo);
}

/// Timezones offered for the list (minutes); a saved value outside the list is added.
List<int> tzChoices(int current) =>
    ({for (var h = -12; h <= 14; h++) h * 60, 210, 270, 330, 345, 390, 570, current}.toList()..sort());

String tzLabel(int minutes) {
  final sign = minutes < 0 ? '-' : '+', m = minutes.abs();
  return 'UTC$sign${m ~/ 60}${m % 60 == 0 ? '' : ':${(m % 60).toString().padLeft(2, '0')}'}';
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
          initialValue: plainNumber(value),
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          textDirection: TextDirection.ltr, // numbers read left-to-right; label and help follow the app
          decoration: InputDecoration(labelText: label, helperText: help, helperMaxLines: 3),
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
    final l = L.of(context), app = widget.app, locked = app.running;
    final bgOk = app.bg?.ok;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
      if (locked)
        Panel(
          color: amber.withValues(alpha: 0.14),
          child: Row(children: [
            const Icon(Icons.lock_outline, color: amber),
            gap12,
            Expanded(child: Text(l.stopToChange, style: const TextStyle(color: textHi))),
          ]),
        ),
      AbsorbPointer(
        absorbing: locked,
        child: Opacity(
          opacity: locked ? 0.5 : 1,
          child: Column(children: [
            Panel(
              title: l.essentials,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(l.account, style: const TextStyle(color: textMid)),
                gap8,
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(value: true, label: Text(l.demo)),
                    ButtonSegment(value: false, label: Text(l.real)),
                  ],
                  selected: {c.demo},
                  onSelectionChanged: (s) async {
                    await switchAccount(context, app, s.first);
                    setState(() {});
                  },
                ),
                gap24,
                AmountField(app),
                gap16,
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.martingale, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(l.martingaleSub),
                  value: c.gales > 0,
                  onChanged: (v) => {c.gales = v ? 1 : 0, _save()},
                ),
                if (c.gales > 0) ...[
                  _num(l.multLabel, l.multHelp, c.galeMultiplier, (v) => c.galeMultiplier = v),
                  gap8,
                  Text(l.levels, style: const TextStyle(color: textMid)),
                  gap8,
                  SegmentedButton<int>(
                    segments: [for (final n in [1, 2, 3]) ButtonSegment(value: n, label: ltrText('$n'))],
                    selected: {c.gales.clamp(1, 3)},
                    onSelectionChanged: (s) => {c.gales = s.first, _save()},
                  ),
                ],
                gap24,
                DropdownButtonFormField<int>(
                  initialValue: c.utcOffsetMin,
                  decoration: InputDecoration(labelText: l.tzLabel, helperText: l.tzHint, helperMaxLines: 4),
                  items: [
                    for (final m in tzChoices(c.utcOffsetMin))
                      DropdownMenuItem(value: m, child: ltrText(tzLabel(m))),
                  ],
                  onChanged: (v) => {c.utcOffsetMin = v ?? c.utcOffsetMin, _save()},
                ),
              ]),
            ),
            Panel(
              title: l.dailyLimits,
              child: Column(children: [
                _num(l.stopLossLabel, l.offHelp, c.stopLoss, (v) => c.stopLoss = v),
                _num(l.takeProfitLabel, l.offHelp, c.takeProfit, (v) => c.takeProfit = v),
              ]),
            ),
          ]),
        ),
      ),
      Panel(
        padding: EdgeInsets.zero,
        child: ListTile(
          minVerticalPadding: 16,
          leading: Icon(bgOk == false ? Icons.battery_alert : Icons.battery_charging_full, color: bgOk == false ? amber : green),
          title: Text(l.backgroundSetup, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(bgOk == false ? l.bgWarnBody : l.backgroundSetupSub),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BackgroundSetupPage(app))),
        ),
      ),
      Panel(
        title: l.language,
        child: SegmentedButton<String>(
          segments: [
            ButtonSegment(value: '', label: Text(l.languageSystem)),
            const ButtonSegment(value: 'en', label: Text('English')),
            const ButtonSegment(value: 'ar', label: Text('العربية')),
          ],
          selected: {app.lang},
          onSelectionChanged: (s) => app.setLang(s.first),
        ),
      ),
      AbsorbPointer(
        absorbing: locked,
        child: Panel(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(l.advanced, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(l.advancedSub, style: const TextStyle(color: textMid, fontSize: 13)),
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.pendingTitle),
                  subtitle: Text(l.pendingSub),
                  value: c.pending,
                  onChanged: (v) => {c.pending = v, _save()},
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.autoTiming),
                  subtitle: Text(l.autoTimingSub),
                  value: c.preEntryMs == null,
                  onChanged: (v) => {c.preEntryMs = v ? null : 250, _save()},
                ),
                if (c.preEntryMs != null)
                  _num(l.preEntryLabel, l.preEntryHelp, c.preEntryMs!, (v) => c.preEntryMs = v.round()),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.overlapTitle),
                  subtitle: Text(l.overlapSub),
                  value: c.overlap,
                  onChanged: (v) => {c.overlap = v, _save()},
                ),
                _num(l.minPayoutLabel, l.minPayoutHelp, c.minPayout, (v) => c.minPayout = v),
                gap8,
              ],
            ),
          ),
        ),
      ),
      gap8,
      TextButton.icon(
        style: TextButton.styleFrom(foregroundColor: textMid, minimumSize: const Size.fromHeight(48)),
        onPressed: locked
            ? null
            : () async {
                if (await confirm(context, l.logoutTitle, '', l.logout)) app.setToken(null);
              },
        icon: const Icon(Icons.logout),
        label: Text(l.logout),
      ),
      Center(child: ltrText('QXBot 1.2.0', style: const TextStyle(color: textLo, fontSize: 12))),
    ]);
  }
}
