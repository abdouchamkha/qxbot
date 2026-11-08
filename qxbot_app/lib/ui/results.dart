/// Results as cards (win green, loss red, martingale step visible), statistics, and the raw Details log.
library;

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/engine.dart';
import '../format.dart';
import '../l10n/app_localizations.dart';
import 'ai.dart';
import 'common.dart';

class ResultCard extends StatelessWidget {
  final Trade t;
  const ResultCard(this.t, {super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final c = t.result == 'win' ? green : t.result == 'loss' ? red : textMid;
    final icon = t.result == 'win' ? Icons.check_rounded : t.result == 'loss' ? Icons.close_rounded : Icons.remove_rounded;
    final time = '${t.time.hour.toString().padLeft(2, '0')}:${t.time.minute.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: c.withValues(alpha: 0.16), shape: BoxShape.circle),
          child: Icon(icon, color: c),
        ),
        gap12,
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text(pairLabel(t.asset), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textHi)),
              dirChip(context, t.direction, small: true),
            ]),
            gap4,
            Text('${ltr(time)} · ${dollars(t.amount)} · ${t.level > 0 ? l.galeTag(ltr(t.level)) : l.firstEntry}',
                style: TextStyle(fontSize: 13, color: t.level > 0 ? amber : textMid)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(resultLabel(l, t.result), style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 13)),
          Text(signedMoney(t.profit), style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 18)),
        ]),
      ]),
    );
  }
}

class ResultsPage extends StatelessWidget {
  final AppState app;
  const ResultsPage(this.app, {super.key});

  Widget _stats(L l, String title, List<Trade> rows) {
    final s = summarize(rows);
    Widget tile(String k, String v, [Color? c]) => SizedBox(
          width: 150,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(k, style: const TextStyle(color: textLo, fontSize: 12)),
              Text(v, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c ?? textHi)),
            ]),
          ),
        );
    return Panel(
      title: title,
      color: card2,
      child: Wrap(children: [
        tile(l.netProfit, signedMoney(s.net), s.net >= 0 ? green : red),
        tile(l.winRate, ltr('${s.winRate.toStringAsFixed(0)}%')),
        tile(l.trades, ltr(s.trades)),
        tile(l.wld, ltr('${s.wins} / ${s.losses} / ${s.draws}')),
        tile(l.signalsWon, ltr('${s.signalsWon}/${s.signalsWon + s.signalsLost}')),
        tile(l.wonAfterGale, ltr(s.signalsWonGale)),
        tile(l.maxDrawdown, ltr(s.maxDrawdown.toStringAsFixed(2)), red),
        tile(l.worstStreak, l.lossesCount(s.lossStreak)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context), mine = app.mine, today = summarize(app.today);
    final session = mine.where((t) => app.engine != null && t.time.isAfter(app.engine!.started)).toList();
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
      Panel(
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.todayProfit, style: caption),
              Text(signedMoney(today.net),
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: today.net >= 0 ? green : red)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(l.winsLosses(ltr(today.wins), ltr(today.losses)), style: const TextStyle(color: textMid)),
            Text('${l.winRate} ${ltr('${today.winRate.toStringAsFixed(0)}%')}', style: const TextStyle(color: textMid)),
          ]),
        ]),
      ),
      if (app.aiReady && mine.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: () => showCoach(context, app),
            icon: const Icon(Icons.auto_awesome, color: blue),
            label: Text(l.aiAnalysis),
          ),
        ),
      if (mine.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(children: [
            const Icon(Icons.insights_outlined, size: 48, color: textLo),
            gap12,
            Text(l.noResultsYet, textAlign: TextAlign.center, style: const TextStyle(color: textMid, fontSize: 15)),
          ]),
        ),
      for (final t in mine.reversed.take(100)) ResultCard(t),
      if (mine.isNotEmpty)
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(l.statistics, style: titleStyle),
            children: [
              _stats(l, l.thisSession, session),
              _stats(l, l.today, app.today),
              _stats(l, l.allTime(app.cfg.demo ? l.demo : l.real), mine),
            ],
          ),
        ),
    ]);
  }
}

/// The raw engine log (orders, delays, skips) for diagnosis.
class DetailsPage extends StatelessWidget {
  final AppState app;
  const DetailsPage(this.app, {super.key});
  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.detailsTitle)),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: app,
          builder: (context, _) {
            final offset = app.q?.clock.offset;
            return ListView(padding: const EdgeInsets.all(16), children: [
              Text(offset == null ? l.clockNotVerified : l.clockCorrected(signedSeconds(offset)),
                  style: const TextStyle(color: textMid)),
              gap12,
              Text(l.log, style: titleStyle),
              gap8,
              if (app.logs.isEmpty) Text(l.logEmpty, style: const TextStyle(color: textMid)),
              for (final e in app.logs.reversed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text('${ltr(clock(e.time))}  ${formatEvent(l, e.event)}',
                      style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: switch (eventTone(e.event)) { 1 => green, -1 => red, 2 => amber, _ => textMid })),
                ),
            ]);
          },
        ),
      ),
    );
  }
}
