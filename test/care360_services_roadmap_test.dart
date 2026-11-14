import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctro/brand/care360_services_roadmap.dart';

void main() {
  testWidgets('Planned services cannot open unfinished workflows', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Care360ServicesRoadmap()));
    final wallet = find.byKey(const ValueKey(Care360PlannedModule.healthWallet));
    expect(wallet, findsOneWidget);
    expect(tester.widget<ListTile>(wallet).onTap, isNull);
    await tester.tap(wallet);
    await tester.pump();
    expect(find.text('Upcoming services'), findsOneWidget);
  });

  testWidgets('Professional roadmap stays readable on a narrow large-text screen', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.6)), child: child!),
      home: const Care360ServicesRoadmap(professional: true)));
    await tester.scrollUntilVisible(find.text('Workforce & CNU training'), 180);
    expect(find.text('Workforce & CNU training'), findsOneWidget);
    expect(find.byKey(const ValueKey(Care360PlannedModule.familyCare)), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

