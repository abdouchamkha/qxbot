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

  @override
  String get tabResults => 'Results';

  @override
  String get details => 'Details';

  @override
  String get detailsTitle => 'Details (technical log)';

  @override
  String get nextTrade => 'Next trade';

  @override
  String atTime(String time) {
    return 'at $time';
  }

  @override
  String inCountdown(String time) {
    return 'in $time';
  }

  @override
  String get nowEntering => 'entering now';

  @override
  String get noNextTrade => 'No trade waiting';

  @override
  String get botStoppedHint =>
      'Copy a signal list in Telegram, then tap the button below.';

  @override
  String get todayProfit => 'Today\'s profit';

  @override
  String winsLosses(String wins, String losses) {
    return '$wins won · $losses lost';
  }

  @override
  String get pasteBig => 'Paste list from clipboard';

  @override
  String get typeList => 'Type or edit the list';

  @override
  String get clipboardEmpty =>
      'The clipboard is empty. Copy the signal list in Telegram first.';

  @override
  String get noSignalsInText =>
      'No signals found in the copied text. Copy the whole list (e.g. M1 EURUSD 14:30 CALL).';

  @override
  String previewSummary(String amount, String account) {
    return '$amount per trade · $account account';
  }

  @override
  String martingaleOn(String mult, String levels) {
    return 'Martingale ×$mult, up to $levels steps';
  }

  @override
  String get martingaleOffShort => 'Martingale off';

  @override
  String get edit => 'Edit';

  @override
  String get realStartTitle => 'Trade with REAL money?';

  @override
  String realStartBody(String trades, String amount) {
    return '$trades trades of $amount on your REAL account (more if martingale is used). Losses are real.';
  }

  @override
  String get startReal => 'Start with real money';

  @override
  String get stopTitle => 'Stop the bot?';

  @override
  String get stopBody =>
      'Waiting trades are cancelled. Trades already open on Quotex finish normally.';

  @override
  String get keepRunning => 'Keep running';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get inTrade => 'in trade';

  @override
  String get latestResults => 'Latest results';

  @override
  String get seeAll => 'See all';

  @override
  String get noResultsYet =>
      'No results yet. They appear here after each trade.';

  @override
  String get firstEntry => 'First entry';

  @override
  String get statistics => 'Statistics';

  @override
  String get bgWarnTitle => 'Background not set up';

  @override
  String get bgWarnBody => 'Trading may stop when the screen is off.';

  @override
  String get fix => 'Fix';

  @override
  String get loginExpired =>
      'Your Quotex login has expired. Please log in again.';

  @override
  String get noInternet =>
      'No internet connection. Check Wi-Fi or mobile data.';

  @override
  String get connectProblem => 'Can\'t reach Quotex right now. Trying again...';

  @override
  String get logInAgain => 'Log in again';

  @override
  String get retry => 'Retry';

  @override
  String get account => 'Account';

  @override
  String get logoutTitle => 'Log out of Quotex?';

  @override
  String get essentials => 'Essentials';

  @override
  String get martingale => 'Martingale';

  @override
  String get martingaleSub =>
      'After a loss, trade the next candle with a bigger amount';

  @override
  String get levels => 'Steps';

  @override
  String get tzHint =>
      'The time zone the channel writes its times in (look for \"UTC-3\" at the top of the list). If the list says it, the list wins.';

  @override
  String get dailyLimits => 'Daily limits';

  @override
  String get advanced => 'Advanced';

  @override
  String get advancedSub => 'Pending orders, entry timing, overlap, payout';

  @override
  String get backgroundSetup => 'Background setup';

  @override
  String get backgroundSetupSub => 'Keep trading with the screen off';

  @override
  String get other => 'Other';

  @override
  String get bgTitle => 'Keep QXBot running';

  @override
  String get bgIntro =>
      'Android stops apps in the background to save battery. Do these steps once so QXBot keeps trading with the screen off.';

  @override
  String get bgNotif => 'Notifications';

  @override
  String get bgNotifSub => 'Shows that the bot is running, and each result';

  @override
  String get bgBattery => 'Battery: no restrictions';

  @override
  String get bgBatterySub =>
      'Tap Allow, then choose \"Allow\" / \"Don\'t optimize\" / \"Unrestricted\"';

  @override
  String bgBrand(String brand) {
    return 'Phone settings ($brand)';
  }

  @override
  String get bgBrandGeneric => 'Phone settings';

  @override
  String get allow => 'Allow';

  @override
  String get allowed => 'Allowed';

  @override
  String get openSettings => 'Open';

  @override
  String get bgXiaomi =>
      'Autostart: turn QXBot ON. Then App info > Battery saver: \"No restrictions\". In recent apps, pull QXBot down to lock it.';

  @override
  String get bgHuawei =>
      'App launch: turn off \"Manage automatically\" for QXBot, then allow Auto-launch, Secondary launch and Run in background.';

  @override
  String get bgOppo =>
      'Auto launch: turn QXBot ON. Battery > App battery management > QXBot: allow background activity.';

  @override
  String get bgVivo =>
      'Background startup and \"High background power consumption\": allow QXBot.';

  @override
  String get bgSamsung =>
      'Battery > Background usage limits > Never sleeping apps: add QXBot (and remove it from Sleeping apps).';

  @override
  String get bgOther =>
      'App info > Battery: \"Unrestricted\". If your phone has an \"Autostart\" or \"Background activity\" setting, allow QXBot.';

  @override
  String get bgTips =>
      'Tips: keep the phone charging during long lists, and don\'t close QXBot from recent apps.';

  @override
  String get bgPending =>
      'Good to know: pending orders (OTC pairs, placed 1 minute ahead) are already on Quotex and open even if the phone sleeps. Martingale and direct trades need the app awake.';

  @override
  String get continueBtn => 'Continue';

  @override
  String get later => 'Later';

  @override
  String get done => 'Done';

  @override
  String get welcome => 'Welcome to QXBot';

  @override
  String obStep(String step, String total) {
    return 'Step $step of $total';
  }

  @override
  String get obAccountTitle => 'Which account?';

  @override
  String get obAccountBody =>
      'Start with demo to try the bot with practice money. You can switch any time in Settings.';

  @override
  String get demoCardTitle => 'Demo (practice money)';

  @override
  String get demoCardSub => 'Recommended to start. No risk.';

  @override
  String get realCardTitle => 'Real money';

  @override
  String get realCardSub => 'Trades use your real balance.';

  @override
  String get obAmountTitle => 'Amount per trade';

  @override
  String obAmountBody(String amount) {
    return 'How much each trade uses. With martingale on, a lost trade is followed by one of $amount.';
  }

  @override
  String get obDoneTitle => 'All set!';

  @override
  String get obDoneBody =>
      'Copy a signal list in Telegram, open QXBot and tap \"Paste list from clipboard\".';

  @override
  String get goHome => 'Start using QXBot';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get invalidAmount => 'Enter an amount of at least 1';

  @override
  String evWokeUp(String seconds) {
    return 'The phone was asleep for $seconds s: checking the connection and the list';
  }

  @override
  String evServiceFailed(String error) {
    return 'Background mode could not start ($error). Keep the app open.';
  }

  @override
  String rLate(String seconds) {
    return 'its minute started $seconds s ago (phone was asleep); a late entry is worse than none';
  }
}
