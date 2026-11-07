import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctro/brand/care360_professional_quick_actions.dart';

void main() {
  testWidgets('Four professional links open original workflows',
      (tester) async {
    final opened = <String>[];
    await tester.pumpWidget(MaterialApp(home: Scaffold(body:
      SingleChildScrollView(child: Care360ProfessionalQuickActions(
        onAppointments: () => opened.add('appointments'),
        onAvailability: () => opened.add('availability'),
        onNotes: () => opened.add('notes'),
        onMessages: () => opened.add('messages'),
      )),
    )));
    for (final name in [
      'Appointments', 'Availability', 'Clinical notes', 'Messages'
    ]) {
      expect(find.text(name), findsOneWidget);
    }
    await tester.ensureVisible(find.byKey(const Key('care360-plus-0')));
    await tester.tap(find.byKey(const Key('care360-plus-0')));
    await tester.ensureVisible(find.byKey(const Key('care360-plus-3')));
    await tester.tap(find.byKey(const Key('care360-plus-3')));
    expect(opened, ['appointments', 'messages']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Clinical quick actions are readable on small screens',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: MediaQuery(
      data: const MediaQueryData(
        size: Size(320, 568),
        textScaler: TextScaler.linear(1.5),
      ),
      child: Scaffold(body: SingleChildScrollView(
        child: Care360ProfessionalQuickActions(
          onAppointments: () {},
          onAvailability: () {},
          onNotes: () {},
          onMessages: () {},
        ),
      )),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Your practice, organized'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Only existing Plus clinical navigation is used', () {
    final home = File('lib/screens/home page/login_home.dart')
        .readAsStringSync();
    expect(home, contains('Care360ProfessionalQuickActions('));
    for (final route in [
      'AppointmentHistoryScreen', 'Schedule Timings', 'Notes', 'ChatHome',
    ]) {
      expect(home, contains("Navigator.pushNamed(context, '$route')"));
    }
    final grid = File('lib/brand/care360_professional_quick_actions.dart')
        .readAsStringSync();
    expect(grid, isNot(contains('PatientMedicalFile')));
    expect(grid, isNot(contains('FirebaseFirestore')));
  });
}
