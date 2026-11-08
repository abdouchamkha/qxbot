import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L
/// returned by `L.of(context)`.
///
/// Applications need to include `L.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L.localizationsDelegates,
///   supportedLocales: L.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L.supportedLocales
/// property.
abstract class L {
  L(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L of(BuildContext context) {
    return Localizations.of<L>(context, L)!;
  }

  static const LocalizationsDelegate<L> delegate = _LDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'QXBot'**
  String get appTitle;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabSignals.
  ///
  /// In en, this message translates to:
  /// **'Signals'**
  String get tabSignals;

  /// No description provided for @tabLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get tabLive;

  /// No description provided for @tabStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get tabStats;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @demo.
  ///
  /// In en, this message translates to:
  /// **'DEMO'**
  String get demo;

  /// No description provided for @real.
  ///
  /// In en, this message translates to:
  /// **'REAL'**
  String get real;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'CALL'**
  String get call;

  /// No description provided for @put.
  ///
  /// In en, this message translates to:
  /// **'PUT'**
  String get put;

  /// No description provided for @win.
  ///
  /// In en, this message translates to:
  /// **'WIN'**
  String get win;

  /// No description provided for @loss.
  ///
  /// In en, this message translates to:
  /// **'LOSS'**
  String get loss;

  /// No description provided for @draw.
  ///
  /// In en, this message translates to:
  /// **'DRAW'**
  String get draw;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to Quotex'**
  String get loginTitle;

  /// No description provided for @loginHelp.
  ///
  /// In en, this message translates to:
  /// **'Log in with your Quotex email and password (and the email code if asked). The app continues by itself once you are in.'**
  String get loginHelp;

  /// No description provided for @reload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reload;

  /// No description provided for @pasteToken.
  ///
  /// In en, this message translates to:
  /// **'Paste token'**
  String get pasteToken;

  /// No description provided for @sessionToken.
  ///
  /// In en, this message translates to:
  /// **'Session token'**
  String get sessionToken;

  /// No description provided for @use.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get use;

  /// No description provided for @connection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get connection;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connecting;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// No description provided for @connectFailedStatus.
  ///
  /// In en, this message translates to:
  /// **'Login expired or no connection'**
  String get connectFailedStatus;

  /// No description provided for @reconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get reconnect;

  /// No description provided for @clockCorrected.
  ///
  /// In en, this message translates to:
  /// **'Clock vs Quotex: {offset} s (corrected)'**
  String clockCorrected(String offset);

  /// No description provided for @clockNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Clock vs Quotex: not verified (phone clock in use)'**
  String get clockNotVerified;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @todaySummary.
  ///
  /// In en, this message translates to:
  /// **'Today {net} · {wins}W {losses}L {draws}D'**
  String todaySummary(String net, String wins, String losses, String draws);

  /// No description provided for @demoAccountSwitch.
  ///
  /// In en, this message translates to:
  /// **'Demo account (practice money)'**
  String get demoAccountSwitch;

  /// No description provided for @realTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch to REAL money?'**
  String get realTitle;

  /// No description provided for @realBody.
  ///
  /// In en, this message translates to:
  /// **'Trades will use your real Quotex balance. Losses are real.'**
  String get realBody;

  /// No description provided for @useReal.
  ///
  /// In en, this message translates to:
  /// **'Use real account'**
  String get useReal;

  /// No description provided for @bot.
  ///
  /// In en, this message translates to:
  /// **'Bot'**
  String get bot;

  /// No description provided for @runningWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Running · no signals waiting} =1{Running · 1 signal waiting} other{Running · {count} signals waiting}}'**
  String runningWaiting(int count);

  /// No description provided for @stopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get stopped;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @pasteSignals.
  ///
  /// In en, this message translates to:
  /// **'Paste signals'**
  String get pasteSignals;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @signalsHint.
  ///
  /// In en, this message translates to:
  /// **'Paste the Telegram signal list here\ne.g. M1 EURUSD-OTC 14:30 CALL'**
  String get signalsHint;

  /// No description provided for @pasteFromClipboard.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get pasteFromClipboard;

  /// No description provided for @listTimezone.
  ///
  /// In en, this message translates to:
  /// **'List timezone: {tz} (from Settings; a \"UTC+6\" written in the list wins)'**
  String listTimezone(String tz);

  /// No description provided for @notConnectedNames.
  ///
  /// In en, this message translates to:
  /// **'Not connected: pair names not checked'**
  String get notConnectedNames;

  /// No description provided for @signalsFound.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No signals found} =1{1 signal found} other{{count} signals found}}'**
  String signalsFound(int count);

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 min} other{{n} min}}'**
  String minutes(int n);

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'{n} s'**
  String seconds(int n);

  /// No description provided for @pairNotFound.
  ///
  /// In en, this message translates to:
  /// **'Pair not found on Quotex: this line is skipped'**
  String get pairNotFound;

  /// No description provided for @connectFirst.
  ///
  /// In en, this message translates to:
  /// **'Connect first'**
  String get connectFirst;

  /// No description provided for @startTrading.
  ///
  /// In en, this message translates to:
  /// **'Start trading ({count})'**
  String startTrading(int count);

  /// No description provided for @scheduled.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No signals scheduled} =1{1 signal scheduled} other{{count} signals scheduled}}'**
  String scheduled(int count);

  /// No description provided for @stopBot.
  ///
  /// In en, this message translates to:
  /// **'Stop bot'**
  String get stopBot;

  /// No description provided for @waiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting ({count})'**
  String waiting(int count);

  /// No description provided for @log.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get log;

  /// No description provided for @logEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet'**
  String get logEmpty;

  /// No description provided for @thisSession.
  ///
  /// In en, this message translates to:
  /// **'This session'**
  String get thisSession;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All time ({account})'**
  String allTime(String account);

  /// No description provided for @netProfit.
  ///
  /// In en, this message translates to:
  /// **'Net profit'**
  String get netProfit;

  /// No description provided for @winRate.
  ///
  /// In en, this message translates to:
  /// **'Win rate'**
  String get winRate;

  /// No description provided for @trades.
  ///
  /// In en, this message translates to:
  /// **'Trades'**
  String get trades;

  /// No description provided for @wld.
  ///
  /// In en, this message translates to:
  /// **'W / L / D'**
  String get wld;

  /// No description provided for @signalsWon.
  ///
  /// In en, this message translates to:
  /// **'Signals won'**
  String get signalsWon;

  /// No description provided for @wonAfterGale.
  ///
  /// In en, this message translates to:
  /// **'Won after martingale'**
  String get wonAfterGale;

  /// No description provided for @maxDrawdown.
  ///
  /// In en, this message translates to:
  /// **'Max drawdown'**
  String get maxDrawdown;

  /// No description provided for @worstStreak.
  ///
  /// In en, this message translates to:
  /// **'Worst streak'**
  String get worstStreak;

  /// No description provided for @lossesCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{no losses} =1{1 loss} other{{n} losses}}'**
  String lossesCount(int n);

  /// No description provided for @recentTrades.
  ///
  /// In en, this message translates to:
  /// **'Recent trades'**
  String get recentTrades;

  /// No description provided for @noTrades.
  ///
  /// In en, this message translates to:
  /// **'No trades yet'**
  String get noTrades;

  /// No description provided for @entryPending.
  ///
  /// In en, this message translates to:
  /// **'pending'**
  String get entryPending;

  /// No description provided for @entryDirect.
  ///
  /// In en, this message translates to:
  /// **'direct'**
  String get entryDirect;

  /// No description provided for @galeTag.
  ///
  /// In en, this message translates to:
  /// **'G{level}'**
  String galeTag(String level);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Phone language'**
  String get languageSystem;

  /// No description provided for @stopToChange.
  ///
  /// In en, this message translates to:
  /// **'Stop the bot to change settings'**
  String get stopToChange;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Trade amount (\$)'**
  String get amountLabel;

  /// No description provided for @amountHelp.
  ///
  /// In en, this message translates to:
  /// **'Stake for each signal'**
  String get amountHelp;

  /// No description provided for @tzLabel.
  ///
  /// In en, this message translates to:
  /// **'Signal list timezone (UTC hours)'**
  String get tzLabel;

  /// No description provided for @tzHelp.
  ///
  /// In en, this message translates to:
  /// **'e.g. -3 for UTC-3, 1 for Algeria, 5.5 for UTC+5:30'**
  String get tzHelp;

  /// No description provided for @galesLabel.
  ///
  /// In en, this message translates to:
  /// **'Martingale levels'**
  String get galesLabel;

  /// No description provided for @offHelp.
  ///
  /// In en, this message translates to:
  /// **'0 = off'**
  String get offHelp;

  /// No description provided for @multLabel.
  ///
  /// In en, this message translates to:
  /// **'Martingale multiplier'**
  String get multLabel;

  /// No description provided for @multHelp.
  ///
  /// In en, this message translates to:
  /// **'Next stake = stake × this'**
  String get multHelp;

  /// No description provided for @minPayoutLabel.
  ///
  /// In en, this message translates to:
  /// **'Minimum payout (%)'**
  String get minPayoutLabel;

  /// No description provided for @minPayoutHelp.
  ///
  /// In en, this message translates to:
  /// **'Skip a signal when the payout is lower'**
  String get minPayoutHelp;

  /// No description provided for @stopLossLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily stop-loss (\$)'**
  String get stopLossLabel;

  /// No description provided for @takeProfitLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily take-profit (\$)'**
  String get takeProfitLabel;

  /// No description provided for @pendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending orders for OTC'**
  String get pendingTitle;

  /// No description provided for @pendingSub.
  ///
  /// In en, this message translates to:
  /// **'Quotex opens the trade itself at the exact minute'**
  String get pendingSub;

  /// No description provided for @overlapTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow overlapping signals'**
  String get overlapTitle;

  /// No description provided for @overlapSub.
  ///
  /// In en, this message translates to:
  /// **'Off: one signal per minute, a list signal beats a martingale'**
  String get overlapSub;

  /// No description provided for @autoTiming.
  ///
  /// In en, this message translates to:
  /// **'Automatic entry timing'**
  String get autoTiming;

  /// No description provided for @autoTimingSub.
  ///
  /// In en, this message translates to:
  /// **'Send direct orders half a ping before the minute'**
  String get autoTimingSub;

  /// No description provided for @preEntryLabel.
  ///
  /// In en, this message translates to:
  /// **'Pre-entry (ms)'**
  String get preEntryLabel;

  /// No description provided for @preEntryHelp.
  ///
  /// In en, this message translates to:
  /// **'Send this many ms before the minute'**
  String get preEntryHelp;

  /// No description provided for @notifTrading.
  ///
  /// In en, this message translates to:
  /// **'QXBot is trading'**
  String get notifTrading;

  /// No description provided for @notifToday.
  ///
  /// In en, this message translates to:
  /// **'QXBot · today {net} ({wins}W {losses}L)'**
  String notifToday(String net, String wins, String losses);

  /// No description provided for @channelName.
  ///
  /// In en, this message translates to:
  /// **'QXBot trading'**
  String get channelName;

  /// No description provided for @channelDesc.
  ///
  /// In en, this message translates to:
  /// **'Bot running and trade results'**
  String get channelDesc;

  /// No description provided for @evConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected to Quotex ({account} account)'**
  String evConnected(String account);

  /// No description provided for @evConnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Connect failed: {error}'**
  String evConnectFailed(String error);

  /// No description provided for @evStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get evStopped;

  /// No description provided for @evAllDone.
  ///
  /// In en, this message translates to:
  /// **'All signals done'**
  String get evAllDone;

  /// No description provided for @evSkipped.
  ///
  /// In en, this message translates to:
  /// **'{time} {pair} {dir} skipped: {reason}'**
  String evSkipped(String time, String pair, String dir, String reason);

  /// No description provided for @rOverlap.
  ///
  /// In en, this message translates to:
  /// **'another signal has this minute (overlap off)'**
  String get rOverlap;

  /// No description provided for @rStopLoss.
  ///
  /// In en, this message translates to:
  /// **'daily stop-loss reached (today {net})'**
  String rStopLoss(String net);

  /// No description provided for @rTakeProfit.
  ///
  /// In en, this message translates to:
  /// **'daily take-profit reached (today {net})'**
  String rTakeProfit(String net);

  /// No description provided for @rBalance.
  ///
  /// In en, this message translates to:
  /// **'balance {balance} can\'t cover {amount}'**
  String rBalance(String balance, String amount);

  /// No description provided for @rNotConnected.
  ///
  /// In en, this message translates to:
  /// **'not connected'**
  String get rNotConnected;

  /// No description provided for @rPairNotFound.
  ///
  /// In en, this message translates to:
  /// **'pair not found on Quotex'**
  String get rPairNotFound;

  /// No description provided for @rPairClosed.
  ///
  /// In en, this message translates to:
  /// **'Quotex has this pair closed right now'**
  String get rPairClosed;

  /// No description provided for @rPayout.
  ///
  /// In en, this message translates to:
  /// **'payout {payout}% < {min}%'**
  String rPayout(String payout, String min);

  /// No description provided for @rStopped.
  ///
  /// In en, this message translates to:
  /// **'stopped'**
  String get rStopped;

  /// No description provided for @evConnectionLost.
  ///
  /// In en, this message translates to:
  /// **'Connection lost, logging in again...'**
  String get evConnectionLost;

  /// No description provided for @evReconnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Reconnect failed: {error}'**
  String evReconnectFailed(String error);

  /// No description provided for @evOrderNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'{pair} order not confirmed (pair closed or amount invalid?)'**
  String evOrderNotConfirmed(String pair);

  /// No description provided for @evOrderRejected.
  ///
  /// In en, this message translates to:
  /// **'{pair} {dir} rejected by Quotex: {error}'**
  String evOrderRejected(String pair, String dir, String error);

  /// No description provided for @evOrderOpened.
  ///
  /// In en, this message translates to:
  /// **'{pair} {dir} {amount} opened {delay} ms vs {at} (sent {sent} ms, ping {ping} ms) open {price}'**
  String evOrderOpened(String pair, String dir, String amount, String delay,
      String at, String sent, String ping, String price);

  /// No description provided for @evPendingSet.
  ///
  /// In en, this message translates to:
  /// **'{pair} {dir} {amount} pending order set for {at} (Quotex opens it)'**
  String evPendingSet(String pair, String dir, String amount, String at);

  /// No description provided for @evPendingNoTicket.
  ///
  /// In en, this message translates to:
  /// **'{pair} pending reply without a ticket: skipped (no risk of a double entry)'**
  String evPendingNoTicket(String pair);

  /// No description provided for @evPendingCancelled.
  ///
  /// In en, this message translates to:
  /// **'{pair} pending order cancelled: {reason}'**
  String evPendingCancelled(String pair, String reason);

  /// No description provided for @evPendingOpened.
  ///
  /// In en, this message translates to:
  /// **'{pair} {dir} {amount} opened {delay} ms vs {at} by Quotex (pending) open {price}'**
  String evPendingOpened(String pair, String dir, String amount, String delay,
      String at, String price);

  /// No description provided for @evPendingNoAnswer.
  ///
  /// In en, this message translates to:
  /// **'{pair} pending order not confirmed: skipped (no risk of a double entry)'**
  String evPendingNoAnswer(String pair);

  /// No description provided for @evPendingFailed.
  ///
  /// In en, this message translates to:
  /// **'{pair} pending order failed ({error}): entering directly'**
  String evPendingFailed(String pair, String error);

  /// No description provided for @evGaleReady.
  ///
  /// In en, this message translates to:
  /// **'{pair} losing with 5 s left, martingale {level} ready'**
  String evGaleReady(String pair, String level);

  /// No description provided for @evGaleCancelled.
  ///
  /// In en, this message translates to:
  /// **'Martingale on {pair} cancelled: a list signal has {at} (overlap off)'**
  String evGaleCancelled(String pair, String at);

  /// No description provided for @evGaleStart.
  ///
  /// In en, this message translates to:
  /// **'Martingale {level} on {pair}: {amount}'**
  String evGaleStart(String level, String pair, String amount);

  /// No description provided for @evResultNotReceived.
  ///
  /// In en, this message translates to:
  /// **'{pair} result not received (check Quotex history)'**
  String evResultNotReceived(String pair);

  /// No description provided for @evResult.
  ///
  /// In en, this message translates to:
  /// **'{pair} {dir}{gale}: {result} {profit}'**
  String evResult(
      String pair, String dir, String gale, String result, String profit);

  /// No description provided for @evError.
  ///
  /// In en, this message translates to:
  /// **'{pair} error: {error}'**
  String evError(String pair, String error);

  /// No description provided for @evClockWarning.
  ///
  /// In en, this message translates to:
  /// **'Phone clock is {offset} s off Quotex: timing is corrected automatically'**
  String evClockWarning(String offset);
}

class _LDelegate extends LocalizationsDelegate<L> {
  const _LDelegate();

  @override
  Future<L> load(Locale locale) {
    return SynchronousFuture<L>(lookupL(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_LDelegate old) => false;
}

L lookupL(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return LAr();
    case 'en':
      return LEn();
  }

  throw FlutterError(
      'L.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
