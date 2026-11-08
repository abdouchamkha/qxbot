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

  /// No description provided for @tabResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get tabResults;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @detailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Details (technical log)'**
  String get detailsTitle;

  /// No description provided for @nextTrade.
  ///
  /// In en, this message translates to:
  /// **'Next trade'**
  String get nextTrade;

  /// No description provided for @atTime.
  ///
  /// In en, this message translates to:
  /// **'at {time}'**
  String atTime(String time);

  /// No description provided for @inCountdown.
  ///
  /// In en, this message translates to:
  /// **'in {time}'**
  String inCountdown(String time);

  /// No description provided for @nowEntering.
  ///
  /// In en, this message translates to:
  /// **'entering now'**
  String get nowEntering;

  /// No description provided for @noNextTrade.
  ///
  /// In en, this message translates to:
  /// **'No trade waiting'**
  String get noNextTrade;

  /// No description provided for @botStoppedHint.
  ///
  /// In en, this message translates to:
  /// **'Copy a signal list in Telegram, then tap the button below.'**
  String get botStoppedHint;

  /// No description provided for @todayProfit.
  ///
  /// In en, this message translates to:
  /// **'Today\'s profit'**
  String get todayProfit;

  /// No description provided for @winsLosses.
  ///
  /// In en, this message translates to:
  /// **'{wins} won · {losses} lost'**
  String winsLosses(String wins, String losses);

  /// No description provided for @pasteBig.
  ///
  /// In en, this message translates to:
  /// **'Paste list from clipboard'**
  String get pasteBig;

  /// No description provided for @typeList.
  ///
  /// In en, this message translates to:
  /// **'Type or edit the list'**
  String get typeList;

  /// No description provided for @clipboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'The clipboard is empty. Copy the signal list in Telegram first.'**
  String get clipboardEmpty;

  /// No description provided for @noSignalsInText.
  ///
  /// In en, this message translates to:
  /// **'No signals found in the copied text. Copy the whole list (e.g. M1 EURUSD 14:30 CALL).'**
  String get noSignalsInText;

  /// No description provided for @previewSummary.
  ///
  /// In en, this message translates to:
  /// **'{amount} per trade · {account} account'**
  String previewSummary(String amount, String account);

  /// No description provided for @martingaleOn.
  ///
  /// In en, this message translates to:
  /// **'Martingale ×{mult}, up to {levels} steps'**
  String martingaleOn(String mult, String levels);

  /// No description provided for @martingaleOffShort.
  ///
  /// In en, this message translates to:
  /// **'Martingale off'**
  String get martingaleOffShort;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @realStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Trade with REAL money?'**
  String get realStartTitle;

  /// No description provided for @realStartBody.
  ///
  /// In en, this message translates to:
  /// **'{trades} trades of {amount} on your REAL account (more if martingale is used). Losses are real.'**
  String realStartBody(String trades, String amount);

  /// No description provided for @startReal.
  ///
  /// In en, this message translates to:
  /// **'Start with real money'**
  String get startReal;

  /// No description provided for @stopTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop the bot?'**
  String get stopTitle;

  /// No description provided for @stopBody.
  ///
  /// In en, this message translates to:
  /// **'Waiting trades are cancelled. Trades already open on Quotex finish normally.'**
  String get stopBody;

  /// No description provided for @keepRunning.
  ///
  /// In en, this message translates to:
  /// **'Keep running'**
  String get keepRunning;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @inTrade.
  ///
  /// In en, this message translates to:
  /// **'in trade'**
  String get inTrade;

  /// No description provided for @latestResults.
  ///
  /// In en, this message translates to:
  /// **'Latest results'**
  String get latestResults;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @noResultsYet.
  ///
  /// In en, this message translates to:
  /// **'No results yet. They appear here after each trade.'**
  String get noResultsYet;

  /// No description provided for @firstEntry.
  ///
  /// In en, this message translates to:
  /// **'First entry'**
  String get firstEntry;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @bgWarnTitle.
  ///
  /// In en, this message translates to:
  /// **'Background not set up'**
  String get bgWarnTitle;

  /// No description provided for @bgWarnBody.
  ///
  /// In en, this message translates to:
  /// **'Trading may stop when the screen is off.'**
  String get bgWarnBody;

  /// No description provided for @fix.
  ///
  /// In en, this message translates to:
  /// **'Fix'**
  String get fix;

  /// No description provided for @loginExpired.
  ///
  /// In en, this message translates to:
  /// **'Your Quotex login has expired. Please log in again.'**
  String get loginExpired;

  /// No description provided for @noInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check Wi-Fi or mobile data.'**
  String get noInternet;

  /// No description provided for @connectProblem.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach Quotex right now. Trying again...'**
  String get connectProblem;

  /// No description provided for @logInAgain.
  ///
  /// In en, this message translates to:
  /// **'Log in again'**
  String get logInAgain;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @logoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out of Quotex?'**
  String get logoutTitle;

  /// No description provided for @essentials.
  ///
  /// In en, this message translates to:
  /// **'Essentials'**
  String get essentials;

  /// No description provided for @martingale.
  ///
  /// In en, this message translates to:
  /// **'Martingale'**
  String get martingale;

  /// No description provided for @martingaleSub.
  ///
  /// In en, this message translates to:
  /// **'After a loss, trade the next candle with a bigger amount'**
  String get martingaleSub;

  /// No description provided for @levels.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get levels;

  /// No description provided for @tzHint.
  ///
  /// In en, this message translates to:
  /// **'The time zone the channel writes its times in (look for \"UTC-3\" at the top of the list). If the list says it, the list wins.'**
  String get tzHint;

  /// No description provided for @dailyLimits.
  ///
  /// In en, this message translates to:
  /// **'Daily limits'**
  String get dailyLimits;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// No description provided for @advancedSub.
  ///
  /// In en, this message translates to:
  /// **'Pending orders, entry timing, overlap, payout'**
  String get advancedSub;

  /// No description provided for @backgroundSetup.
  ///
  /// In en, this message translates to:
  /// **'Background setup'**
  String get backgroundSetup;

  /// No description provided for @backgroundSetupSub.
  ///
  /// In en, this message translates to:
  /// **'Keep trading with the screen off'**
  String get backgroundSetupSub;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @bgTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep QXBot running'**
  String get bgTitle;

  /// No description provided for @bgIntro.
  ///
  /// In en, this message translates to:
  /// **'Android stops apps in the background to save battery. Do these steps once so QXBot keeps trading with the screen off.'**
  String get bgIntro;

  /// No description provided for @bgNotif.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get bgNotif;

  /// No description provided for @bgNotifSub.
  ///
  /// In en, this message translates to:
  /// **'Shows that the bot is running, and each result'**
  String get bgNotifSub;

  /// No description provided for @bgBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery: no restrictions'**
  String get bgBattery;

  /// No description provided for @bgBatterySub.
  ///
  /// In en, this message translates to:
  /// **'Tap Allow, then choose \"Allow\" / \"Don\'t optimize\" / \"Unrestricted\"'**
  String get bgBatterySub;

  /// No description provided for @bgBrand.
  ///
  /// In en, this message translates to:
  /// **'Phone settings ({brand})'**
  String bgBrand(String brand);

  /// No description provided for @bgBrandGeneric.
  ///
  /// In en, this message translates to:
  /// **'Phone settings'**
  String get bgBrandGeneric;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @allowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get allowed;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openSettings;

  /// No description provided for @bgXiaomi.
  ///
  /// In en, this message translates to:
  /// **'Autostart: turn QXBot ON. Then App info > Battery saver: \"No restrictions\". In recent apps, pull QXBot down to lock it.'**
  String get bgXiaomi;

  /// No description provided for @bgHuawei.
  ///
  /// In en, this message translates to:
  /// **'App launch: turn off \"Manage automatically\" for QXBot, then allow Auto-launch, Secondary launch and Run in background.'**
  String get bgHuawei;

  /// No description provided for @bgOppo.
  ///
  /// In en, this message translates to:
  /// **'Auto launch: turn QXBot ON. Battery > App battery management > QXBot: allow background activity.'**
  String get bgOppo;

  /// No description provided for @bgVivo.
  ///
  /// In en, this message translates to:
  /// **'Background startup and \"High background power consumption\": allow QXBot.'**
  String get bgVivo;

  /// No description provided for @bgSamsung.
  ///
  /// In en, this message translates to:
  /// **'Battery > Background usage limits > Never sleeping apps: add QXBot (and remove it from Sleeping apps).'**
  String get bgSamsung;

  /// No description provided for @bgOther.
  ///
  /// In en, this message translates to:
  /// **'App info > Battery: \"Unrestricted\". If your phone has an \"Autostart\" or \"Background activity\" setting, allow QXBot.'**
  String get bgOther;

  /// No description provided for @bgTips.
  ///
  /// In en, this message translates to:
  /// **'Tips: keep the phone charging during long lists, and don\'t close QXBot from recent apps.'**
  String get bgTips;

  /// No description provided for @bgPending.
  ///
  /// In en, this message translates to:
  /// **'Good to know: pending orders (OTC pairs, placed 1 minute ahead) are already on Quotex and open even if the phone sleeps. Martingale and direct trades need the app awake.'**
  String get bgPending;

  /// No description provided for @continueBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueBtn;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to QXBot'**
  String get welcome;

  /// No description provided for @obStep.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String obStep(String step, String total);

  /// No description provided for @obAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Which account?'**
  String get obAccountTitle;

  /// No description provided for @obAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Start with demo to try the bot with practice money. You can switch any time in Settings.'**
  String get obAccountBody;

  /// No description provided for @demoCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Demo (practice money)'**
  String get demoCardTitle;

  /// No description provided for @demoCardSub.
  ///
  /// In en, this message translates to:
  /// **'Recommended to start. No risk.'**
  String get demoCardSub;

  /// No description provided for @realCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Real money'**
  String get realCardTitle;

  /// No description provided for @realCardSub.
  ///
  /// In en, this message translates to:
  /// **'Trades use your real balance.'**
  String get realCardSub;

  /// No description provided for @obAmountTitle.
  ///
  /// In en, this message translates to:
  /// **'Amount per trade'**
  String get obAmountTitle;

  /// No description provided for @obAmountBody.
  ///
  /// In en, this message translates to:
  /// **'How much each trade uses. With martingale on, a lost trade is followed by one of {amount}.'**
  String obAmountBody(String amount);

  /// No description provided for @obDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'All set!'**
  String get obDoneTitle;

  /// No description provided for @obDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Copy a signal list in Telegram, open QXBot and tap \"Paste list from clipboard\".'**
  String get obDoneBody;

  /// No description provided for @goHome.
  ///
  /// In en, this message translates to:
  /// **'Start using QXBot'**
  String get goHome;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount of at least 1'**
  String get invalidAmount;

  /// No description provided for @evWokeUp.
  ///
  /// In en, this message translates to:
  /// **'The phone was asleep for {seconds} s: checking the connection and the list'**
  String evWokeUp(String seconds);

  /// No description provided for @evServiceFailed.
  ///
  /// In en, this message translates to:
  /// **'Background mode could not start ({error}). Keep the app open.'**
  String evServiceFailed(String error);

  /// No description provided for @rLate.
  ///
  /// In en, this message translates to:
  /// **'its minute started {seconds} s ago (phone was asleep); a late entry is worse than none'**
  String rLate(String seconds);

  /// No description provided for @backtest.
  ///
  /// In en, this message translates to:
  /// **'Backtest'**
  String get backtest;

  /// No description provided for @backtestTitle.
  ///
  /// In en, this message translates to:
  /// **'Backtest a list'**
  String get backtestTitle;

  /// No description provided for @backtestIntro.
  ///
  /// In en, this message translates to:
  /// **'Checks how the list\'s signals would have done in the last 24 h, on Quotex 1-minute candles. No trade is placed.'**
  String get backtestIntro;

  /// No description provided for @tryTimezones.
  ///
  /// In en, this message translates to:
  /// **'Try several timezones (UTC-3, UTC+1, UTC+6)'**
  String get tryTimezones;

  /// No description provided for @tryTimezonesSub.
  ///
  /// In en, this message translates to:
  /// **'Finds the timezone the channel really uses'**
  String get tryTimezonesSub;

  /// No description provided for @runBacktest.
  ///
  /// In en, this message translates to:
  /// **'Run backtest'**
  String get runBacktest;

  /// No description provided for @backtesting.
  ///
  /// In en, this message translates to:
  /// **'Loading candles...'**
  String get backtesting;

  /// No description provided for @noPastSignals.
  ///
  /// In en, this message translates to:
  /// **'No signals found in this list.'**
  String get noPastSignals;

  /// No description provided for @timesReadAs.
  ///
  /// In en, this message translates to:
  /// **'Times read as {tz}'**
  String timesReadAs(String tz);

  /// No description provided for @bestTz.
  ///
  /// In en, this message translates to:
  /// **'best'**
  String get bestTz;

  /// No description provided for @btWinRate.
  ///
  /// In en, this message translates to:
  /// **'Win rate {withGale} with martingale · {noGale} without'**
  String btWinRate(String withGale, String noGale);

  /// No description provided for @btCounts.
  ///
  /// In en, this message translates to:
  /// **'{wins} won · {losses} lost · {draws} draw · {nodata} no data'**
  String btCounts(String wins, String losses, String draws, String nodata);

  /// No description provided for @btNet.
  ///
  /// In en, this message translates to:
  /// **'Net {net} at {amount} per trade (your settings, current payouts)'**
  String btNet(String net, String amount);

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'no data'**
  String get noData;

  /// No description provided for @passedSignals.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 signal already passed: backtest it} other{{count} signals already passed: backtest them}}'**
  String passedSignals(int count);

  /// No description provided for @backtestOnly.
  ///
  /// In en, this message translates to:
  /// **'Backtest only (no trades)'**
  String get backtestOnly;

  /// No description provided for @readWithAi.
  ///
  /// In en, this message translates to:
  /// **'Read with AI'**
  String get readWithAi;

  /// No description provided for @aiReading.
  ///
  /// In en, this message translates to:
  /// **'AI is reading the list...'**
  String get aiReading;

  /// No description provided for @aiReadNote.
  ///
  /// In en, this message translates to:
  /// **'Read by AI: check every line before you start.'**
  String get aiReadNote;

  /// No description provided for @aiRejected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 line ignored (pair or time not valid)} other{{count} lines ignored (pair or time not valid)}}'**
  String aiRejected(int count);

  /// No description provided for @aiNothing.
  ///
  /// In en, this message translates to:
  /// **'The AI found no signals in this text.'**
  String get aiNothing;

  /// No description provided for @noSignalsShort.
  ///
  /// In en, this message translates to:
  /// **'No signals understood in this text.'**
  String get noSignalsShort;

  /// No description provided for @aiAnalysis.
  ///
  /// In en, this message translates to:
  /// **'AI analysis'**
  String get aiAnalysis;

  /// No description provided for @aiAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'AI is looking at your results...'**
  String get aiAnalyzing;

  /// No description provided for @aiWorks.
  ///
  /// In en, this message translates to:
  /// **'What works'**
  String get aiWorks;

  /// No description provided for @aiLoses.
  ///
  /// In en, this message translates to:
  /// **'What loses'**
  String get aiLoses;

  /// No description provided for @aiMartingale.
  ///
  /// In en, this message translates to:
  /// **'Martingale'**
  String get aiMartingale;

  /// No description provided for @aiSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get aiSuggestions;

  /// No description provided for @aiNotAdvice.
  ///
  /// In en, this message translates to:
  /// **'AI summary of your own numbers, not financial advice.'**
  String get aiNotAdvice;

  /// No description provided for @aiFrom.
  ///
  /// In en, this message translates to:
  /// **'From {time}'**
  String aiFrom(String time);

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @aiNoKey.
  ///
  /// In en, this message translates to:
  /// **'No AI key. Add one in Settings > AI.'**
  String get aiNoKey;

  /// No description provided for @aiBadKey.
  ///
  /// In en, this message translates to:
  /// **'The AI key was refused. Check it in Settings > AI.'**
  String get aiBadKey;

  /// No description provided for @aiQuota.
  ///
  /// In en, this message translates to:
  /// **'AI limit reached for now (free quota). Try again later.'**
  String get aiQuota;

  /// No description provided for @aiTimeout.
  ///
  /// In en, this message translates to:
  /// **'The AI took too long. Try again.'**
  String get aiTimeout;

  /// No description provided for @aiFailed.
  ///
  /// In en, this message translates to:
  /// **'The AI could not answer. Try again.'**
  String get aiFailed;

  /// No description provided for @aiNoPairs.
  ///
  /// In en, this message translates to:
  /// **'Connect to Quotex first (the AI needs the pair list).'**
  String get aiNoPairs;

  /// No description provided for @aiSection.
  ///
  /// In en, this message translates to:
  /// **'AI (Gemini)'**
  String get aiSection;

  /// No description provided for @aiSwitch.
  ///
  /// In en, this message translates to:
  /// **'AI help'**
  String get aiSwitch;

  /// No description provided for @aiSwitchSub.
  ///
  /// In en, this message translates to:
  /// **'Read hard lists and explain your results. Only the list text and totals are sent to Google, never your login.'**
  String get aiSwitchSub;

  /// No description provided for @aiKeyBuiltIn.
  ///
  /// In en, this message translates to:
  /// **'Using the built-in key'**
  String get aiKeyBuiltIn;

  /// No description provided for @aiKeyOwn.
  ///
  /// In en, this message translates to:
  /// **'Using your own key'**
  String get aiKeyOwn;

  /// No description provided for @aiKeyNone.
  ///
  /// In en, this message translates to:
  /// **'No key: AI is off'**
  String get aiKeyNone;

  /// No description provided for @aiKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Your Gemini API key (optional)'**
  String get aiKeyLabel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;
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
