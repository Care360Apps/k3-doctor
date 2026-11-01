import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/startup_gate.dart';

void main() {
  const actual = MaterialApp(home: Scaffold(body: Text('Actual app')));
  testWidgets('shows progress then real app; optional work starts after frame', (tester) async {
    final pending = Completer<Widget>();
    var ready = false;
    await tester.pumpWidget(StartupGate(
      initialize: () => pending.future, onReady: () => ready = true,
    ));
    expect(find.text('Starting Care360…'), findsOneWidget);
    expect(ready, isFalse);
    pending.complete(actual);
    await tester.pump();
    await tester.pump();
    expect(find.text('Actual app'), findsOneWidget);
    expect(ready, isTrue);
  });
  testWidgets('initialization errors offer retry without exposing details', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(StartupGate(initialize: () async {
      if (++attempts == 1) throw StateError('private configuration');
      return actual;
    }));
    await tester.pump();
    expect(find.textContaining('private configuration'), findsNothing);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Actual app'), findsOneWidget);
    expect(attempts, 2);
  });
  testWidgets('a stalled initializer times out visibly', (tester) async {
    await tester.pumpWidget(StartupGate(
      timeout: const Duration(milliseconds: 10),
      initialize: () => Completer<Widget>().future,
    ));
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump();
    expect(find.text('Try again'), findsOneWidget);
  });
}
