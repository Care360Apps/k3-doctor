import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctro/brand/care360_professional_section_intro.dart';

void main() {
  testWidgets('Clinical intro remains clear and does not display patient data',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Care360ProfessionalSectionIntro(
          title: 'Private clinical workspace',
          description: 'Appointment-scoped notes and care plans',
          icon: Icons.lock_person_outlined,
        ),
      ),
    ));
    expect(find.text('Private clinical workspace'), findsOneWidget);
    expect(find.text('Appointment-scoped notes and care plans'), findsOneWidget);
    expect(find.byKey(const Key('care360-plus-section-intro')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Professional heading is readable on 320px with large type',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(320, 568),
          textScaler: TextScaler.linear(1.6),
        ),
        child: Scaffold(body: Care360ProfessionalSectionIntro(
          title: 'Appointment history',
          description: 'Review upcoming and past care visits',
          icon: Icons.event_note_outlined,
        )),
      ),
    ));
    expect(find.text('Appointment history'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Actual clinical notes and history routes remain guarded and functional',
      () {
    final notes =
        File('lib/screens/appointment/clinical_notes_screen.dart')
            .readAsStringSync();
    final history =
        File('lib/screens/appointment/appointment_history.dart')
            .readAsStringSync();

    expect(notes, contains('Care360ProfessionalSectionIntro('));
    expect(history, contains('Care360ProfessionalSectionIntro('));
    expect(notes, contains('doctorNotes(widget.appointmentId)'));
    expect(notes, contains('finalize: true'));
    expect(notes, contains('finalize: false'));
    expect(notes, contains('note.status =='));
    expect(history, contains('appointmentHistoryScreen'));
    expect(history, contains('_buildUpcomingList()'));
    expect(history, contains('_buildPastList()'));
    expect(notes, isNot(contains('Care360PartnerShowcase')));
    expect(notes, isNot(contains('WorkforceApi')));
  });
}
