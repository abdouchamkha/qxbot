// Quotex server-clock estimator.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:qxbot_app/core/clock.dart';
import 'package:qxbot_app/core/engine.dart';
import 'package:qxbot_app/core/quotex.dart';

/// Feeds ticks every 250 ms of server time with network delay `latency + jitter`, phone clock `skew` s fast.
/// Returns the server time of the last tick.
double feed(ServerClock c, void Function(double) setPhone, double start, int n,
    {required double skew, required double latency, Random? rnd}) {
  rnd ??= Random(1);
  var server = start;
  for (var i = 0; i < n; i++) {
    server = start + i * 0.25;
    final jitter = i % 7 == 0 ? 0.0 : rnd.nextDouble() * 0.2; // some ticks arrive with no extra delay
    setPhone(server + latency + jitter + skew);
    c.sample(server);
  }
  return server;
}

void main() {
  late double phone;
  ServerClock clock() => ServerClock(() => phone);

  test('no ticks: phone clock, not verified', () {
    phone = 1000;
    final c = clock();
    expect(c.verified, isFalse);
    expect(c.offset, isNull);
    expect(c.now(), 1000);
  });

  test('phone 700 ms fast + 150 ms latency gives ~700 ms', () {
    final c = clock()..roundTrip(0.300); // measured order round trip -> 150 ms one way
    feed(c, (t) => phone = t, 1.7e9, 200, skew: 0.7, latency: 0.15);
    // ignore: avoid_print
    print('estimated offset ${(c.offset! * 1000).toStringAsFixed(1)} ms (expected 700)');
    expect(c.offset!, closeTo(0.7, 0.01));
    expect(c.now(), closeTo(phone - 0.7, 0.01));
  });

  test('phone 1.2 s slow, latency not measured yet assumes 200 ms one way', () {
    final c = clock();
    feed(c, (t) => phone = t, 1.7e9, 100, skew: -1.2, latency: 0.2);
    expect(c.offset!, closeTo(-1.2, 0.01));
  });

  test('absurd timestamps (> 30 s off) are ignored', () {
    final c = clock()..roundTrip(0.3);
    final last = feed(c, (t) => phone = t, 1.7e9, 50, skew: 0.5, latency: 0.15);
    final before = c.offset;
    phone = last + 0.65;
    c.sample(last - 120); // a stale tick from history
    c.sample(last + 3600); // garbage from the future
    expect(c.offset, before);
  });

  test('a later correction of the phone clock is followed (60 s window + EMA)', () {
    final c = clock()..roundTrip(0.3);
    final last = feed(c, (t) => phone = t, 1.7e9, 100, skew: 2.0, latency: 0.15);
    expect(c.offset!, closeTo(2.0, 0.01));
    feed(c, (t) => phone = t, last + 61, 100, skew: 0.0, latency: 0.15); // phone synced its clock
    expect(c.offset!, closeTo(0.0, 0.01));
  });

  test('engine timing uses the server clock', () {
    phone = 0;
    final c = clock()..roundTrip(0.3);
    feed(c, (t) => phone = t, 1.7e9, 40, skew: 0.7, latency: 0.15);
    final e = Engine(QuotexClient('x', demo: true, clock: c), Settings(), [], (_) {});
    expect(e.now(), closeTo(phone - 0.7, 0.01));
  });

  test('engine warns once when the phone is > 1 s off', () {
    phone = 0;
    final c = clock()..roundTrip(0.3);
    final q = QuotexClient('x', demo: true, clock: c);
    final events = <EngineEvent>[];
    final e = Engine(q, Settings(), [], events.add);
    feed(c, (t) => phone = t, 1.7e9, 40, skew: 1.5, latency: 0.15);
    for (var i = 0; i < 3; i++) {
      e.checkClock(); // runs on every Quotex message
    }
    expect(events.where((e) => e.key == 'clockWarning').length, 1);
    expect(events.first.args['offset'] as double, closeTo(1.5, 0.01));
  });

  test('socket ping (pure network) beats the order round trip for latency', () {
    final c = clock()..roundTrip(0.5); // order: 500 ms incl. Quotex processing
    expect(c.latency, 0.25);
    c.networkRoundTrip(0.09);
    c.networkRoundTrip(0.11);
    c.networkRoundTrip(0.10);
    c.roundTrip(0.6); // ignored now
    expect(c.latency, closeTo(0.05, 1e-9));
    feed(c, (t) => phone = t, 1.7e9, 100, skew: 0.47, latency: 0.05);
    expect(c.offset!, closeTo(0.47, 0.01));
  });
}
