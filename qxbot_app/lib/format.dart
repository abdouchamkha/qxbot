/// Text formatting for the UI: engine events in the user's language, and numbers / pairs / times kept
/// left-to-right inside Arabic text with Unicode isolates (LRI ... PDI).
library;

import 'core/engine.dart';
import 'l10n/app_localizations.dart';

/// Keep [v] left-to-right even inside right-to-left text (prices, pairs, times, +/- amounts).
String ltr(Object? v) => '\u2066$v\u2069';

String _signed(num v, int decimals) => '${v >= 0 ? '+' : '-'}${v.abs().toStringAsFixed(decimals)}';

/// "+1.86" / "-1.00", LTR-isolated.
String signedMoney(double v) => ltr(_signed(v, 2));

/// "$2.20", LTR-isolated.
String dollars(num v) => ltr('\$${v.toStringAsFixed(2)}');

/// "+607" (milliseconds and the like), LTR-isolated.
String signedInt(Object? v) => v is num ? ltr(_signed(v, 0)) : ltr(v);

/// "+0.71" seconds, LTR-isolated.
String signedSeconds(double v) => ltr(_signed(v, 2));

String _two(int v) => v.toString().padLeft(2, '0');
String clock(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}:${_two(d.second)}';

/// A unix-seconds instant as the phone's local HH:MM:SS.
String unixClock(Object? at) =>
    at is num ? ltr(clock(DateTime.fromMillisecondsSinceEpoch((at * 1000).round()))) : ltr(at);

String dirLabel(L l, Object? dir) => dir == 'call' ? l.call : l.put;

String resultLabel(L l, Object? r) => switch (r) { 'win' => l.win, 'loss' => l.loss, _ => l.draw };

String entryLabel(L l, String entry) => entry == 'pending' ? l.entryPending : l.entryDirect;

/// Pair symbol as shown to people: "EURUSD (OTC)", LTR-isolated.
String pairLabel(Object? symbol) => ltr('$symbol'.replaceAll('_otc', ' (OTC)'));

String _num(Object? v) => ltr(v is double && v == v.roundToDouble() ? v.toInt() : v);

/// One log line in the user's language.
String formatEvent(L l, EngineEvent e) {
  final a = e.args;
  final pair = pairLabel(a['pair']), dir = dirLabel(l, a['dir']);
  String amount() => dollars(a['amount'] as num);
  return switch (e.key) {
    'connected' => l.evConnected(a['demo'] == true ? l.demo : l.real),
    'connectFailed' => l.evConnectFailed('${a['error']}'),
    'started' => l.scheduled(a['count'] as int),
    'stopped' => l.evStopped,
    'allDone' => l.evAllDone,
    'skipped' => l.evSkipped(ltr(a['time']), pair, dir, formatReason(l, a['reason'] as EngineEvent)),
    'connectionLost' => l.evConnectionLost,
    'reconnectFailed' => l.evReconnectFailed('${a['error']}'),
    'orderNotConfirmed' => l.evOrderNotConfirmed(pair),
    'orderRejected' => l.evOrderRejected(pair, dir, ltr(a['error'])),
    'orderOpened' => l.evOrderOpened(pair, dir, amount(), signedInt(a['delay']), unixClock(a['at']),
        signedInt(a['sent']), ltr(a['ping']), ltr(a['price'])),
    'pendingSet' => l.evPendingSet(pair, dir, amount(), unixClock(a['at'])),
    'pendingNoTicket' => l.evPendingNoTicket(pair),
    'pendingCancelled' => l.evPendingCancelled(pair, formatReason(l, a['reason'] as EngineEvent)),
    'pendingOpened' => l.evPendingOpened(pair, dir, amount(), signedInt(a['delay']), unixClock(a['at']), ltr(a['price'])),
    'pendingNoAnswer' => l.evPendingNoAnswer(pair),
    'pendingFailed' => l.evPendingFailed(pair, ltr(a['error'])),
    'galeReady' => l.evGaleReady(pair, ltr(a['level'])),
    'galeCancelledOverlap' => l.evGaleCancelled(pair, unixClock(a['at'])),
    'galeStart' => l.evGaleStart(ltr(a['level']), pair, amount()),
    'resultNotReceived' => l.evResultNotReceived(pair),
    'result' => l.evResult(pair, dir, (a['level'] as int) > 0 ? ' · ${l.galeTag(ltr(a['level']))}' : '',
        resultLabel(l, a['result']), signedMoney(a['profit'] as double)),
    'error' => l.evError(pair, '${a['error']}'),
    'clockWarning' => l.evClockWarning(signedSeconds(a['offset'] as double)),
    _ => '$e',
  };
}

String formatReason(L l, EngineEvent r) {
  final a = r.args;
  return switch (r.key) {
    'overlap' => l.rOverlap,
    'stopLoss' => l.rStopLoss(signedMoney(a['net'] as double)),
    'takeProfit' => l.rTakeProfit(signedMoney(a['net'] as double)),
    'balance' => l.rBalance(dollars(a['balance'] as num), dollars(a['amount'] as num)),
    'notConnected' => l.rNotConnected,
    'pairNotFound' => l.rPairNotFound,
    'pairClosed' => l.rPairClosed,
    'payout' => l.rPayout(_num(a['payout']), _num(a['min'])),
    'stopped' => l.rStopped,
    _ => '$r',
  };
}

/// Log colour class: 1 good, -1 bad, 0 neutral, 2 warning.
int eventTone(EngineEvent e) => switch (e.key) {
      'result' => e.args['result'] == 'win' ? 1 : e.args['result'] == 'loss' ? -1 : 0,
      'orderRejected' || 'connectFailed' || 'reconnectFailed' || 'error' || 'resultNotReceived' => -1,
      'clockWarning' || 'skipped' || 'pendingCancelled' || 'connectionLost' => 2,
      _ => 0,
    };
