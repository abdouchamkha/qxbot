/// AI pieces of the UI: plain-word errors and the coach (analysis) sheet.
library;

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/ai.dart';
import '../format.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';

String aiError(L l, Object e) => switch (e is AiException ? e.kind : '') {
      'noKey' => l.aiNoKey,
      'badKey' => l.aiBadKey,
      'quota' => l.aiQuota,
      'offline' => l.noInternet,
      'timeout' => l.aiTimeout,
      'noPairs' => l.aiNoPairs,
      _ => l.aiFailed,
    };

/// Opens the coach: shows the cached analysis at once, "Refresh" asks Gemini again (user-triggered only).
Future<void> showCoach(BuildContext context, AppState app, {Map<String, Object?>? backtest}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: card,
      showDragHandle: true,
      builder: (_) => CoachSheet(app, backtest: backtest),
    );

class CoachSheet extends StatefulWidget {
  final AppState app;
  final Map<String, Object?>? backtest;
  const CoachSheet(this.app, {super.key, this.backtest});
  @override
  State<CoachSheet> createState() => _CoachSheetState();
}

class _CoachSheetState extends State<CoachSheet> {
  bool busy = false;
  String? error;

  Future<void> _run() async {
    final lang = Localizations.localeOf(context).languageCode, l = L.of(context);
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.app.aiCoach(lang, backtest: widget.backtest);
    } catch (e) {
      error = aiError(l, e);
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  void initState() {
    super.initState();
    final c = widget.app.lastCoach;
    // a cached answer for the same kind of data is shown as is; otherwise ask once
    if (c == null || (c['backtest'] == true) != (widget.backtest != null))
      WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context), c = widget.app.lastCoach;
    final data = c != null && (c['backtest'] == true) == (widget.backtest != null) ? c['data'] as Map : null;
    List<String> list(Object? v) => [for (final x in (v as List? ?? [])) '$x'];
    Widget block(String title, List<String> items, Color color) => items.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15)),
              gap4,
              for (final i in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $i', style: const TextStyle(color: textHi, fontSize: 15, height: 1.4)),
                ),
            ]),
          );
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: [
          Row(children: [
            const Icon(Icons.auto_awesome, color: blue),
            gap8,
            Expanded(child: Text(l.aiAnalysis, style: titleStyle)),
            if (!busy) TextButton(onPressed: _run, child: Text(l.refresh)),
          ]),
          gap12,
          if (busy)
            Row(children: [
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              gap12,
              Expanded(child: Text(l.aiAnalyzing, style: const TextStyle(color: textMid))),
            ]),
          if (error != null) Text(error!, style: const TextStyle(color: amber, fontSize: 15)),
          if (data != null && !busy) ...[
            Text(l.aiFrom(ltr(clock(DateTime.parse(c!['at'] as String).toLocal()).substring(0, 5))),
                style: const TextStyle(color: textLo, fontSize: 12)),
            gap8,
            Text('${data['summary']}', style: const TextStyle(color: textHi, fontSize: 16, height: 1.45)),
            gap16,
            block(l.aiWorks, list(data['works']), green),
            block(l.aiLoses, list(data['loses']), red),
            if ('${data['martingale']}'.isNotEmpty) block(l.aiMartingale, ['${data['martingale']}'], amber),
            block(l.aiSuggestions, list(data['suggestions']), blue),
          ],
          gap8,
          Text(l.aiNotAdvice, style: const TextStyle(color: textLo, fontSize: 12)),
        ]),
      ),
    );
  }
}
