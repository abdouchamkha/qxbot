/// Home: one status card, one big action (paste a list / stop), what's next and the latest results.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show Bidi;

import '../app_state.dart';
import '../core/engine.dart';
import '../core/parser.dart';
import '../format.dart';
import '../l10n/app_localizations.dart';
import 'background.dart';
import 'common.dart';
import 'results.dart';

class HomePage extends StatelessWidget {
  final AppState app;
  final VoidCallback showResults;
  const HomePage(this.app, this.showResults, {super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context), e = app.engine;
    final upcoming = [...?e?.scheduled]..sort((a, b) => a.at.compareTo(b.at));
    final latest = app.mine.reversed.take(3).toList();
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
      if (app.bg != null && !app.bg!.ok) _BackgroundBanner(app),
      StatusCard(app),
      gap8,
      if (app.running)
        FilledButton.icon(
          style: FilledButton.styleFrom(
              backgroundColor: red, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(64)),
          onPressed: () => stopWithConfirm(context, app),
          icon: const Icon(Icons.stop_circle_outlined, size: 28),
          label: Text(l.stop, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        )
      else ...[
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(64)),
          onPressed: () => pasteAndPreview(context, app),
          icon: const Icon(Icons.content_paste_go, size: 28),
          label: Text(l.pasteBig, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ),
        gap8,
        TextButton.icon(
          style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48), foregroundColor: textMid),
          onPressed: () => openEditor(context, app),
          icon: const Icon(Icons.edit_note),
          label: Text(l.typeList),
        ),
      ],
      gap16,
      if (app.running && upcoming.isNotEmpty) ...[
        Text(l.upcoming, style: caption),
        gap8,
        for (final s in upcoming.take(5))
          SignalTile(s, note: e!.entered.contains(s) ? l.inTrade : durationLabel(l, s.duration)),
        gap8,
      ],
      Row(children: [
        Expanded(child: Text(l.latestResults, style: caption)),
        if (latest.isNotEmpty) TextButton(onPressed: showResults, child: Text(l.seeAll)),
      ]),
      gap8,
      if (latest.isEmpty)
        _Empty(Icons.insights_outlined, l.noResultsYet)
      else
        for (final t in latest) ResultCard(t),
    ]);
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Empty(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Panel(
        child: Row(children: [
          Icon(icon, color: textLo, size: 28),
          gap12,
          Expanded(child: Text(text, style: const TextStyle(color: textMid, fontSize: 15))),
        ]),
      );
}

class _BackgroundBanner extends StatelessWidget {
  final AppState app;
  const _BackgroundBanner(this.app);
  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Panel(
      color: amber.withValues(alpha: 0.14),
      child: Row(children: [
        const Icon(Icons.battery_alert, color: amber),
        gap12,
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.bgWarnTitle, style: const TextStyle(fontWeight: FontWeight.w700, color: textHi)),
            Text(l.bgWarnBody, style: const TextStyle(color: textMid, fontSize: 14)),
          ]),
        ),
        TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BackgroundSetupPage(app))),
            child: Text(l.fix, style: const TextStyle(color: amber, fontWeight: FontWeight.w700))),
      ]),
    );
  }
}

/// Connection, balance, next trade with a countdown, and today's profit in one card.
class StatusCard extends StatelessWidget {
  final AppState app;
  const StatusCard(this.app, {super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context), today = summarize(app.today), on = app.connected;
    final failed = !on && app.status == Conn.failed;
    final statusText = on
        ? l.connected
        : switch (app.status) { Conn.connecting => l.connecting, Conn.failed => humanError(l, app.connectError), _ => l.disconnected };
    final expired = failed && humanError(l, app.connectError) == l.loginExpired;
    final next = app.nextSignal;
    return Panel(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: on ? green : failed ? red : amber)),
          gap8,
          Expanded(child: Text(statusText, style: TextStyle(fontSize: 15, color: failed ? red : textMid, fontWeight: FontWeight.w600))),
          AccountChip(app.cfg.demo),
        ]),
        if (failed)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
                onPressed: () => expired ? app.setToken(null) : app.connect(), child: Text(expired ? l.logInAgain : l.retry)),
          ),
        gap12,
        Text(l.balance, style: caption),
        ltrText(app.q?.balance == null ? '--' : '\$${app.q!.balance!.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: textHi)),
        const Divider(height: 32, color: line),
        Text(l.nextTrade, style: caption),
        gap4,
        if (next != null) ...[
          Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Text(pairLabel(next.asset), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textHi)),
            dirChip(context, next.direction, small: true),
            Text(l.atTime(ltr(next.hhmm)), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textHi)),
          ]),
          gap4,
          Builder(builder: (context) {
            final left = next.at.difference(app.serverNow);
            return Text(left.inSeconds > 0 ? l.inCountdown(countdown(left)) : l.nowEntering,
                style: const TextStyle(fontSize: 16, color: amber, fontWeight: FontWeight.w700));
          }),
        ] else
          Text(app.running ? l.noNextTrade : l.botStoppedHint, style: const TextStyle(fontSize: 15, color: textMid)),
        const Divider(height: 32, color: line),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.todayProfit, style: caption),
              Text(signedMoney(today.net),
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: today.net > 0 ? green : today.net < 0 ? red : textHi)),
            ]),
          ),
          Text(l.winsLosses(ltr(today.wins), ltr(today.losses)), style: const TextStyle(color: textMid, fontSize: 14)),
        ]),
      ]),
    );
  }
}

Future<void> stopWithConfirm(BuildContext context, AppState app) async {
  final l = L.of(context);
  if (await confirm(context, l.stopTitle, l.stopBody, l.stop, danger: true)) app.stop();
}

/// Starts [text] after a confirmation when the account is real. Returns true when trading started.
Future<bool> startWithConfirm(BuildContext context, AppState app, String text, int count) async {
  final l = L.of(context);
  if (!app.cfg.demo &&
      !await confirm(context, l.realStartTitle, l.realStartBody(ltr(count), dollars(app.cfg.amount)), l.startReal, danger: true)) {
    return false;
  }
  app.prefs.setString('lastList', text);
  final n = app.start(text);
  if (context.mounted) snack(context, l.scheduled(n));
  return n > 0;
}

/// One tap: read the clipboard, parse it, show the preview with a Start button.
Future<void> pasteAndPreview(BuildContext context, AppState app) async {
  final l = L.of(context);
  var text = '';
  try {
    text = (await Clipboard.getData('text/plain'))?.text ?? '';
  } catch (_) {}
  if (!context.mounted) return;
  if (text.trim().isEmpty) return snack(context, l.clipboardEmpty);
  final unknown = <String>[];
  final sigs = app.parse(text, unknown: unknown);
  if (sigs.isEmpty) {
    snack(context, l.noSignalsInText);
    return openEditor(context, app, text);
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: card,
    showDragHandle: true,
    builder: (_) => PreviewSheet(app, text, sigs, unknown),
  );
}

void openEditor(BuildContext context, AppState app, [String? text]) =>
    Navigator.push(context, MaterialPageRoute(builder: (_) => ListEditorPage(app, text)));

/// Settings that apply to the list, in one line each.
List<String> runSummary(L l, Settings c) => [
      l.previewSummary(dollars(c.amount), c.demo ? l.demo : l.real),
      c.gales > 0 ? l.martingaleOn(ltr(plainNumber(c.galeMultiplier)), ltr(c.gales)) : l.martingaleOffShort,
    ];

class PreviewSheet extends StatelessWidget {
  final AppState app;
  final String text;
  final List<Signal> sigs;
  final List<String> unknown;
  const PreviewSheet(this.app, this.text, this.sigs, this.unknown, {super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(l.signalsFound(sigs.length), style: titleStyle),
            gap4,
            for (final s in runSummary(l, app.cfg)) Text(s, style: const TextStyle(color: textMid, fontSize: 14)),
            gap12,
            Flexible(
              child: ListView(shrinkWrap: true, children: [
                for (final s in sigs) SignalTile(s),
                for (final u in unknown) _UnknownLine(u),
              ]),
            ),
            gap12,
            Row(children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size(96, 56)),
                onPressed: () {
                  Navigator.pop(context);
                  openEditor(context, app, text);
                },
                child: Text(l.edit),
              ),
              gap12,
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                  onPressed: app.engine == null
                      ? null
                      : () async {
                          if (await startWithConfirm(context, app, text, sigs.length) && context.mounted) Navigator.pop(context);
                        },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(app.engine == null ? l.connectFirst : l.startTrading(sigs.length),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _UnknownLine extends StatelessWidget {
  final String line;
  const _UnknownLine(this.line);
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: amber.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Icon(Icons.help_outline, color: amber),
          gap12,
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(line, style: const TextStyle(color: textHi)),
              Text(L.of(context).pairNotFound, style: const TextStyle(color: textMid, fontSize: 13)),
            ]),
          ),
        ]),
      );
}

/// Type or edit a list by hand, with the live preview.
class ListEditorPage extends StatefulWidget {
  final AppState app;
  final String? initial;
  const ListEditorPage(this.app, this.initial, {super.key});
  @override
  State<ListEditorPage> createState() => _ListEditorPageState();
}

class _ListEditorPageState extends State<ListEditorPage> {
  final text = TextEditingController();
  List<Signal> preview = [];
  List<String> unknown = [];

  void _parse() {
    final u = <String>[];
    setState(() {
      preview = widget.app.parse(text.text, unknown: u);
      unknown = u;
    });
  }

  @override
  void initState() {
    super.initState();
    text.text = widget.initial ?? widget.app.prefs.getString('lastList') ?? '';
    text.addListener(_parse);
    _parse();
  }

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app, l = L.of(context);
    final h = app.cfg.utcOffsetMin / 60;
    final tz = ltr('UTC${h >= 0 ? '+' : ''}${plainNumber(h)}');
    return Scaffold(
      appBar: AppBar(title: Text(l.typeList)),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          TextField(
            controller: text,
            minLines: 6,
            maxLines: 12,
            // a list's direction follows its text (most lists are Latin even in an Arabic app)
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
          gap8,
          Text(l.listTimezone(tz), style: const TextStyle(color: textLo, fontSize: 13)),
          if (app.q == null) Text(l.notConnectedNames, style: const TextStyle(color: amber)),
          gap16,
          Text(l.signalsFound(preview.length), style: titleStyle),
          gap8,
          for (final s in preview) SignalTile(s),
          for (final u in unknown) _UnknownLine(u),
          gap16,
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            onPressed: preview.isEmpty || app.engine == null || app.running
                ? null
                : () async {
                    if (await startWithConfirm(context, app, text.text, preview.length) && context.mounted) {
                      Navigator.pop(context);
                    }
                  },
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(app.engine == null ? l.connectFirst : l.startTrading(preview.length)),
          ),
        ]),
      ),
    );
  }
}
