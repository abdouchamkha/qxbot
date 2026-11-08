// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class LEn extends L {
  LEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'QXBot';

  @override
  String get tabHome => 'Home';

  @override
  String get tabSignals => 'Signals';

  @override
  String get tabLive => 'Live';

  @override
  String get tabStats => 'Stats';

  @override
  String get tabSettings => 'Settings';

  @override
  String get demo => 'DEMO';

  @override
  String get real => 'REAL';

  @override
  String get call => 'CALL';

  @override
  String get put => 'PUT';

  @override
  String get win => 'WIN';

  @override
  String get loss => 'LOSS';

  @override
  String get draw => 'DRAW';

  @override
  String get cancel => 'Cancel';

  @override
  String get loginTitle => 'Log in to Quotex';

  @override
  String get loginHelp =>
      'Log in with your Quotex email and password (and the email code if asked). The app continues by itself once you are in.';

  @override
  String get reload => 'Reload';

  @override
  String get pasteToken => 'Paste token';

  @override
  String get sessionToken => 'Session token';

  @override
  String get use => 'Use';

  @override
  String get connection => 'Connection';

  @override
  String get connected => 'Connected';

  @override
  String get connecting => 'Connecting...';

  @override
  String get disconnected => 'Disconnected';

  @override
  String get connectFailedStatus => 'Login expired or no connection';

  @override
  String get reconnect => 'Reconnect';

  @override
  String clockCorrected(String offset) {
    return 'Clock vs Quotex: $offset s (corrected)';
  }

  @override
  String get clockNotVerified =>
      'Clock vs Quotex: not verified (phone clock in use)';

  @override
  String get balance => 'Balance';

  @override
  String todaySummary(String net, String wins, String losses, String draws) {
    return 'Today $net · ${wins}W ${losses}L ${draws}D';
  }

  @override
  String get demoAccountSwitch => 'Demo account (practice money)';

  @override
  String get realTitle => 'Switch to REAL money?';

  @override
  String get realBody =>
      'Trades will use your real Quotex balance. Losses are real.';

  @override
  String get useReal => 'Use real account';

  @override
  String get bot => 'Bot';

  @override
  String runningWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Running · $count signals waiting',
      one: 'Running · 1 signal waiting',
      zero: 'Running · no signals waiting',
    );
    return '$_temp0';
  }

  @override
  String get stopped => 'Stopped';

  @override
  String get stop => 'Stop';

  @override
  String get pasteSignals => 'Paste signals';

  @override
  String get logout => 'Log out';

  @override
  String get signalsHint =>
      'Paste the Telegram signal list here\ne.g. M1 EURUSD-OTC 14:30 CALL';

  @override
  String get pasteFromClipboard => 'Paste';

  @override
  String listTimezone(String tz) {
    return 'List timezone: $tz (from Settings; a \"UTC+6\" written in the list wins)';
  }

  @override
  String get notConnectedNames => 'Not connected: pair names not checked';

  @override
  String signalsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count signals found',
      one: '1 signal found',
      zero: 'No signals found',
    );
    return '$_temp0';
  }

  @override
  String minutes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n min',
      one: '1 min',
    );
    return '$_temp0';
  }

  @override
  String seconds(int n) {
    return '$n s';
  }

  @override
  String get pairNotFound => 'Pair not found on Quotex: this line is skipped';

  @override
  String get connectFirst => 'Connect first';

  @override
  String startTrading(int count) {
    return 'Start trading ($count)';
  }

  @override
  String scheduled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count signals scheduled',
      one: '1 signal scheduled',
      zero: 'No signals scheduled',
    );
    return '$_temp0';
  }

  @override
  String get stopBot => 'Stop bot';

  @override
  String waiting(int count) {
    return 'Waiting ($count)';
  }

  @override
  String get log => 'Log';

  @override
  String get logEmpty => 'Nothing yet';

  @override
  String get thisSession => 'This session';

  @override
  String get today => 'Today';

  @override
  String allTime(String account) {
    return 'All time ($account)';
  }

  @override
  String get netProfit => 'Net profit';

  @override
  String get winRate => 'Win rate';

  @override
  String get trades => 'Trades';

  @override
  String get wld => 'W / L / D';

  @override
  String get signalsWon => 'Signals won';

  @override
  String get wonAfterGale => 'Won after martingale';

  @override
  String get maxDrawdown => 'Max drawdown';

  @override
  String get worstStreak => 'Worst streak';

  @override
  String lossesCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n losses',
      one: '1 loss',
      zero: 'no losses',
    );
    return '$_temp0';
  }

  @override
  String get recentTrades => 'Recent trades';

  @override
  String get noTrades => 'No trades yet';

  @override
  String get entryPending => 'pending';

  @override
  String get entryDirect => 'direct';

  @override
  String galeTag(String level) {
    return 'G$level';
  }

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Phone language';

  @override
  String get stopToChange => 'Stop the bot to change settings';

  @override
  String get amountLabel => 'Trade amount (\$)';

  @override
  String get amountHelp => 'Stake for each signal';

  @override
  String get tzLabel => 'Signal list timezone (UTC hours)';

  @override
  String get tzHelp => 'e.g. -3 for UTC-3, 1 for Algeria, 5.5 for UTC+5:30';

  @override
  String get galesLabel => 'Martingale levels';

  @override
  String get offHelp => '0 = off';

  @override
  String get multLabel => 'Martingale multiplier';

  @override
  String get multHelp => 'Next stake = stake × this';

  @override
  String get minPayoutLabel => 'Minimum payout (%)';

  @override
  String get minPayoutHelp => 'Skip a signal when the payout is lower';

  @override
  String get stopLossLabel => 'Daily stop-loss (\$)';

  @override
  String get takeProfitLabel => 'Daily take-profit (\$)';

  @override
  String get pendingTitle => 'Pending orders for OTC';

  @override
  String get pendingSub => 'Quotex opens the trade itself at the exact minute';

  @override
  String get overlapTitle => 'Allow overlapping signals';

  @override
  String get overlapSub =>
      'Off: one signal per minute, a list signal beats a martingale';

  @override
  String get autoTiming => 'Automatic entry timing';

  @override
  String get autoTimingSub =>
      'Send direct orders half a ping before the minute';

  @override
  String get preEntryLabel => 'Pre-entry (ms)';

  @override
  String get preEntryHelp => 'Send this many ms before the minute';

  @override
  String get notifTrading => 'QXBot is trading';

  @override
  String notifToday(String net, String wins, String losses) {
    return 'QXBot · today $net (${wins}W ${losses}L)';
  }

  @override
  String get channelName => 'QXBot trading';

  @override
  String get channelDesc => 'Bot running and trade results';

  @override
  String evConnected(String account) {
    return 'Connected to Quotex ($account account)';
  }

  @override
  String evConnectFailed(String error) {
    return 'Connect failed: $error';
  }

  @override
  String get evStopped => 'Stopped';

  @override
  String get evAllDone => 'All signals done';

  @override
  String evSkipped(String time, String pair, String dir, String reason) {
    return '$time $pair $dir skipped: $reason';
  }

  @override
  String get rOverlap => 'another signal has this minute (overlap off)';

  @override
  String rStopLoss(String net) {
    return 'daily stop-loss reached (today $net)';
  }

  @override
  String rTakeProfit(String net) {
    return 'daily take-profit reached (today $net)';
  }

  @override
  String rBalance(String balance, String amount) {
    return 'balance $balance can\'t cover $amount';
  }

  @override
  String get rNotConnected => 'not connected';

  @override
  String get rPairNotFound => 'pair not found on Quotex';

  @override
  String get rPairClosed => 'Quotex has this pair closed right now';

  @override
  String rPayout(String payout, String min) {
    return 'payout $payout% < $min%';
  }

  @override
  String get rStopped => 'stopped';

  @override
  String get evConnectionLost => 'Connection lost, logging in again...';

  @override
  String evReconnectFailed(String error) {
    return 'Reconnect failed: $error';
  }

  @override
  String evOrderNotConfirmed(String pair) {
    return '$pair order not confirmed (pair closed or amount invalid?)';
  }

  @override
  String evOrderRejected(String pair, String dir, String error) {
    return '$pair $dir rejected by Quotex: $error';
  }

  @override
  String evOrderOpened(String pair, String dir, String amount, String delay,
      String at, String sent, String ping, String price) {
    return '$pair $dir $amount opened $delay ms vs $at (sent $sent ms, ping $ping ms) open $price';
  }

  @override
  String evPendingSet(String pair, String dir, String amount, String at) {
    return '$pair $dir $amount pending order set for $at (Quotex opens it)';
  }

  @override
  String evPendingNoTicket(String pair) {
    return '$pair pending reply without a ticket: skipped (no risk of a double entry)';
  }

  @override
  String evPendingCancelled(String pair, String reason) {
    return '$pair pending order cancelled: $reason';
  }

  @override
  String evPendingOpened(String pair, String dir, String amount, String delay,
      String at, String price) {
    return '$pair $dir $amount opened $delay ms vs $at by Quotex (pending) open $price';
  }

  @override
  String evPendingNoAnswer(String pair) {
    return '$pair pending order not confirmed: skipped (no risk of a double entry)';
  }

  @override
  String evPendingFailed(String pair, String error) {
    return '$pair pending order failed ($error): entering directly';
  }

  @override
  String evGaleReady(String pair, String level) {
    return '$pair losing with 5 s left, martingale $level ready';
  }

  @override
  String evGaleCancelled(String pair, String at) {
    return 'Martingale on $pair cancelled: a list signal has $at (overlap off)';
  }

  @override
  String evGaleStart(String level, String pair, String amount) {
    return 'Martingale $level on $pair: $amount';
  }

  @override
  String evResultNotReceived(String pair) {
    return '$pair result not received (check Quotex history)';
  }

  @override
  String evResult(
      String pair, String dir, String gale, String result, String profit) {
    return '$pair $dir$gale: $result $profit';
  }

  @override
  String evError(String pair, String error) {
    return '$pair error: $error';
  }

  @override
  String evClockWarning(String offset) {
    return 'Phone clock is $offset s off Quotex: timing is corrected automatically';
  }
}
