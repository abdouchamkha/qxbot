/// Backtest screen: a list's signals of the last 24 h scored on Quotex 1-minute candles (read-only).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show Bidi;

import '../app_state.dart';
import '../core/backtest.dart';
import '../core/parser.dart';
import '../format.dart';
import '../l10n/app_localizations.dart';
import 'ai.dart';
import 'common.dart';
import 'settings.dart' show tzChoices, tzLabel;

/// One timezone's run.
class BtRun {
  final int tzMin;
  final List<(Signal, BtResult)> rows;
  final BtSummary sum;
  BtRun(this.tzMin, this.rows, this.sum);
}

String btLabel(L l, BtResult r) => switch (r.kind) {
      'win' => r.level > 0 ? '${l.win} ${l.galeTag(ltr(r.level))}' : l.win,
      'draw' => r.level > 0 ? '${l.draw} ${l.galeTag(ltr(r.level))}' : l.draw,
      'loss' => l.loss,
      _ => l.noData,
    };

class BacktestPage extends StatefulWidget {
  final AppState app;
  final String? text;
  const BacktestPage(this.app, {super.key, this.text});
  @override
  State<BacktestPage> createState() => _BacktestPageState();
}

class _BacktestPageState extends State<BacktestPage> {
  final text = TextEditingController();
  late int tzMin;
  bool several = false, busy = false;
  String? error;
  List<BtRun> runs = [];

  @override
  void initState() {
    super.initState();
    text.text = widget.text ?? '';
    text.addListener(_defaultTz);
    _defaultTz();
    // Opened from a pasted list ("Backtest only"): run at once.
    if (text.text.trim().isNotEmpty) WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  int? _lastDefault;

  /// Default timezone: the one written in the list, else the setting (a choice made by hand stays until it changes).
  void _defaultTz() {
    final d = listTimezone(text.text)?.inMinutes ?? widget.app.cfg.utcOffsetMin;
    if (d != _lastDefault) setState(() => tzMin = _lastDefault = d);
  }

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final app = widget.app, l = L.of(context);
    setState(() {
      busy = true;
      error = null;
      runs = [];
    });
    final listTz = listTimezone(text.text)?.inMinutes;
    final out = <BtRun>[];
    try {
      for (final m in several ? {tzMin, -180, 60, 360} : {tzMin}) {
        final sigs = pastSignals(text.text, Duration(minutes: m), app.serverNow,
            names: app.pairNames.isEmpty ? null : app.pairNames, forceTz: m != listTz);
        if (sigs.isEmpty) continue;
        final rows = await app.backtest(sigs);
        out.add(BtRun(m, rows, app.summarizeBt(rows)));
      }
      if (out.isEmpty) error = l.noPastSignals;
    } on StateError {
      error = l.connectFirst;
    } catch (e) {
      error = '${l.connectProblem} ($e)';
    }
    if (mounted)
      setState(() {
        busy = false;
        runs = out;
      });
  }

  Map<String, Object?> _forAi(BtRun r) => {
        'timezone': tzLabel(r.tzMin),
        'signals': r.rows.length,
        'wins': r.sum.wins,
        'losses': r.sum.losses,
        'draws': r.sum.draws,
        'no_data': r.sum.nodata,
        'win_rate_with_martingale_pct': r.sum.winRate.round(),
        'win_rate_first_entry_pct': r.sum.winRateNoGale.round(),
        'net': double.parse(r.sum.net.toStringAsFixed(2)),
        'per_pair': {
          for (final a in {for (final (s, _) in r.rows) s.asset})
            a: [
              for (final (s, res) in r.rows)
                if (s.asset == a) '$res'
            ],
        },
        'per_hour_utc': {
          for (final h in {for (final (s, _) in r.rows) s.at.hour})
            '${h}h': [
              for (final (s, res) in r.rows)
                if (s.at.hour == h) '$res'
            ],
        },
      };

  @override
  Widget build(BuildContext context) {
    final l = L.of(context), app = widget.app;
    final best = runs.length > 1 ? (runs.toList()..sort((a, b) => b.sum.winRate.compareTo(a.sum.winRate))).first : null;
    return Scaffold(
      appBar: AppBar(title: Text(l.backtestTitle)),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text(l.backtestIntro, style: const TextStyle(color: textMid, fontSize: 15, height: 1.4)),
          gap12,
          TextField(
            controller: text,
            minLines: 4,
            maxLines: 8,
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
          gap12,
          DropdownButtonFormField<int>(
            key: ValueKey(tzMin),
            initialValue: tzMin,
            decoration: InputDecoration(labelText: l.tzLabel),
            items: [for (final m in tzChoices(tzMin)) DropdownMenuItem(value: m, child: ltrText(tzLabel(m)))],
            onChanged: (v) => setState(() => tzMin = v ?? tzMin),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.tryTimezones),
            subtitle: Text(l.tryTimezonesSub),
            value: several,
            onChanged: (v) => setState(() => several = v),
          ),
          gap8,
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            onPressed: busy || text.text.trim().isEmpty ? null : _run,
            icon: busy
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: onGreen))
                : const Icon(Icons.history),
            label: Text(busy ? l.backtesting : l.runBacktest,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ),
          gap16,
          if (error != null) Text(error!, style: const TextStyle(color: amber, fontSize: 15)),
          for (final r in runs) BtRunView(r, app.cfg.amount, best: identical(r, best)),
          if (runs.isNotEmpty && app.aiReady)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: () => showCoach(context, app, backtest: {
                'runs': [for (final r in runs) _forAi(r)]
              }),
              icon: const Icon(Icons.auto_awesome, color: blue),
              label: Text(l.aiAnalysis),
            ),
        ]),
      ),
    );
  }
}

class BtRunView extends StatelessWidget {
  final BtRun run;
  final double amount;
  final bool best;
  const BtRunView(this.run, this.amount, {super.key, this.best = false});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context), s = run.sum;
    String pct(double v) => ltr('${v.toStringAsFixed(0)}%');
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(l.timesReadAs(ltr(tzLabel(run.tzMin))), style: caption)),
          if (best)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: green.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(8)),
              child: Text(l.bestTz, style: const TextStyle(color: green, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
        ]),
        gap8,
        Text(l.btWinRate(pct(s.winRate), pct(s.winRateNoGale)), style: titleStyle),
        gap4,
        Text(l.btCounts(ltr(s.wins), ltr(s.losses), ltr(s.draws), ltr(s.nodata)),
            style: const TextStyle(color: textMid)),
        Text(l.btNet(signedMoney(s.net), dollars(amount)),
            style: TextStyle(color: s.net >= 0 ? green : red, fontWeight: FontWeight.w700)),
        const Divider(height: 24, color: line),
        for (final (sig, r) in run.rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              ltrText(sig.hhmm, style: const TextStyle(fontWeight: FontWeight.w700, color: textHi)),
              gap12,
              Expanded(child: Text(pairLabel(sig.asset), style: const TextStyle(color: textHi))),
              dirChip(context, sig.direction, small: true),
              gap8,
              SizedBox(
                width: 96,
                child: Text(btLabel(l, r),
                    textAlign: TextAlign.end,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: switch (r.kind) { 'win' => green, 'loss' => red, _ => textMid })),
              ),
            ]),
          ),
      ]),
    );
  }
}
