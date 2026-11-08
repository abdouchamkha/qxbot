/// Quotex server clock estimated from price ticks, so entries don't depend on the phone's clock.
///
/// Each tick carries Quotex's server timestamp. For a tick received at phone time `recv`,
/// `recv - serverTs = one-way latency + offset` (offset = how far the phone clock is ahead).
/// The smallest gap in a recent window is the tick that travelled fastest, so
/// `offset ≈ minGap - oneWayLatency`, with the one-way latency taken as half a measured round trip:
/// the socket ping/pong when known (pure network), else the order round trip, else 0.2 s.
/// The estimate is smoothed with an EMA.
library;

import 'dart:math';

double phoneSeconds() => DateTime.now().microsecondsSinceEpoch / 1e6;

class ServerClock {
  /// The phone's clock in unix seconds (injectable for tests).
  final double Function() phoneNow;
  ServerClock([double Function()? phoneNow]) : phoneNow = phoneNow ?? phoneSeconds;

  static const window = 60.0; // seconds of samples kept
  static const maxSamples = 200;
  static const maxOffset = 30.0; // larger = a wrong/stale timestamp, ignored
  static const alpha = 0.3; // EMA weight of a new estimate

  final _samples = <(double recv, double gap)>[];
  double latency = 0.2; // one-way, seconds
  double? _offset;

  /// Phone clock minus Quotex clock in seconds; null until a tick was seen.
  double? get offset => _offset;
  bool get verified => _offset != null;

  /// Quotex time now (unix seconds). Falls back to the phone clock until verified.
  double now() => phoneNow() - (_offset ?? 0);

  /// A server timestamp received now (a price tick, or an order's openTimestamp).
  void sample(double serverTs, [double? recv]) {
    recv ??= phoneNow();
    final gap = recv - serverTs;
    if ((gap - latency).abs() > maxOffset) return;
    _samples.add((recv, gap));
    _samples.removeWhere((s) => recv! - s.$1 > window);
    if (_samples.length > maxSamples) _samples.removeRange(0, _samples.length - maxSamples);
    final estimate = _samples.map((s) => s.$2).reduce(min) - latency;
    _offset = _offset == null ? estimate : _offset! + alpha * (estimate - _offset!);
  }

  final _network = <double>[];

  /// Measured order round trip in seconds: one-way latency is half of it. Used until a pure network
  /// round trip is known (an order's round trip also holds Quotex's processing time, which is not latency).
  void roundTrip(double seconds) {
    if (_network.isEmpty) latency = (seconds / 2).clamp(0.005, 2.0);
  }

  /// Socket ping/pong round trip in seconds (network only): the median of the last 5 sets the latency.
  void networkRoundTrip(double seconds) {
    if (seconds <= 0 || seconds > 10) return;
    _network.add(seconds);
    if (_network.length > 5) _network.removeAt(0);
    final sorted = [..._network]..sort();
    latency = (sorted[sorted.length ~/ 2] / 2).clamp(0.005, 2.0);
  }
}
