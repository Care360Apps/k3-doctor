import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctro/brand/care360_professional_quick_actions.dart';

void main() {
  testWidgets('Four professional tools navigate via existing guarded routes',
      (tester) async {
    final opened = <Care360ProfessionalDestination>[];
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: SingleChildScrollView(
        child: Care360ProfessionalQuickActions(onOpen: opened.add),
      ),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Your care workspace'), findsOneWidget);
    expect(find.byKey(const Key('care360-plus-dashboard-photo')),
        findsOneWidget);
    for (final item in Care360ProfessionalDestination.values) {
      final target = find.byKey(Key('care360-plus-action-${item.name}'));
      await tester.ensureVisible(target);
      await tester.tap(target);
    }
    expect(opened, Care360ProfessionalDestination.values);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Plus dashboard tiles scroll on narrow 320px screen',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: MediaQuery(
      data: const MediaQueryData(
        size: Size(320, 640),
        textScaler: TextScaler.linear(1.6),
      ),
      child: Scaffold(body: SingleChildScrollView(
        child: Care360ProfessionalQuickActions(onOpen: (_) {}),
      )),
    )));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
        find.byKey(const Key('care360-plus-action-messages')));
    expect(tester.takeException(), isNull);
  });

  test('Plus dashboard keeps appointment data and professional access gates', () {
    final source = File('lib/screens/home page/login_home.dart').readAsStringSync();
    expect(source, contains('Care360ProfessionalQuickActions('));
    expect(source, contains('subscription == 0'));
    expect(source, contains("Navigator.pushNamed(context, 'AppointmentHistoryScreen')"));
    expect(source, contains("Navigator.pushNamed(context, 'Schedule Timings')"));
    expect(source, contains("Navigator.pushNamed(context, 'Notes')"));
    expect(source, contains("Navigator.pushNamed(context, 'ChatHome')"));
    expect(source, contains('ProfessionalAvailabilityScreen()'));
    expect(source, contains('todayAppointmentsFunction()'));
    expect(source, contains('fetchHistoryUpcoming()'));
    expect(source, isNot(contains('badCertificateCallback')));
  });
}
