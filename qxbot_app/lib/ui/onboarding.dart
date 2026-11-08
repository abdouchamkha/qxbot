/// First start: log in -> demo or real -> amount per trade -> background setup -> done.
library;

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../format.dart';
import '../l10n/app_localizations.dart';
import '../main.dart' show LoginPage;
import 'background.dart';
import 'common.dart';
import 'settings.dart' show switchAccount;

class Onboarding extends StatefulWidget {
  final AppState app;
  const Onboarding(this.app, {super.key});
  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  static const total = 4; // login, account, amount, background
  int step = 2;

  void _finish() {
    widget.app.markBgSetupSeen();
    widget.app.finishOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app, l = L.of(context);
    if (app.token == null) return LoginPage(app, header: '${l.welcome} · ${l.obStep(ltr(1), ltr(total))}');
    final (title, body) = switch (step) {
      2 => (l.obAccountTitle, _account(context)),
      3 => (l.obAmountTitle, _amount(context)),
      4 => (l.bgTitle, BackgroundSetupBody(app)),
      _ => (l.obDoneTitle, _done(context)),
    };
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (step <= total) ...[
              Text(l.obStep(ltr(step), ltr(total)), style: caption),
              gap8,
              LinearProgressIndicator(value: step / total, color: green, backgroundColor: card2, minHeight: 6,
                  borderRadius: BorderRadius.circular(3)),
              gap24,
            ],
            Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: textHi)),
            gap16,
            Expanded(child: SingleChildScrollView(child: body)),
            gap12,
            Row(children: [
              if (step > 2 && step <= total)
                TextButton(
                    style: TextButton.styleFrom(minimumSize: const Size(80, 56)),
                    onPressed: () => setState(() => step--),
                    child: Text(l.back)),
              gap8,
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                  onPressed: step == 3 && app.cfg.amount < 1
                      ? null
                      : () => step > total ? _finish() : setState(() => step++),
                  child: Text(step > total ? l.goHome : step == total ? l.continueBtn : l.next,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _account(BuildContext context) {
    final l = L.of(context), app = widget.app;
    Widget option(bool demo, IconData icon, String title, String sub) {
      final selected = app.cfg.demo == demo, c = demo ? blue : const Color(0xFFFF8A3D);
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await switchAccount(context, app, demo);
            setState(() {});
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? c : line, width: selected ? 2 : 1),
            ),
            child: Row(children: [
              Icon(icon, color: c, size: 32),
              gap16,
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textHi)),
                  gap4,
                  Text(sub, style: const TextStyle(color: textMid)),
                ]),
              ),
              Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? c : textLo),
            ]),
          ),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(l.obAccountBody, style: const TextStyle(fontSize: 16, height: 1.45, color: textMid)),
      gap24,
      option(true, Icons.school_outlined, l.demoCardTitle, l.demoCardSub),
      option(false, Icons.account_balance_wallet_outlined, l.realCardTitle, l.realCardSub),
    ]);
  }

  Widget _amount(BuildContext context) {
    final l = L.of(context), c = widget.app.cfg;
    return ListenableBuilder(
      listenable: widget.app,
      builder: (context, _) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l.obAmountBody(dollars(c.amount * c.galeMultiplier)), style: const TextStyle(fontSize: 16, height: 1.45, color: textMid)),
        gap24,
        AmountField(widget.app),
      ]),
    );
  }

  Widget _done(BuildContext context) {
    final l = L.of(context);
    return Column(children: [
      gap24,
      const Icon(Icons.check_circle_rounded, color: green, size: 88),
      gap24,
      Text(l.obDoneBody, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, height: 1.5, color: textMid)),
    ]);
  }
}
