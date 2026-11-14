import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctro/model/doctor_note.dart';
import 'package:doctro/screens/appointment/clinical_notes_screen.dart';

void main() {
  testWidgets(
    'finalized note is readable with encounter context and no editor',
    (tester) async {
      final note = DoctorNote(
        id: 8,
        appointmentId: 14,
        status: 'final',
        body: 'Synthetic encounter findings and follow-up plan — TEST ONLY',
        finalizedAt: '2026-11-09',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Care360ClinicalNoteReader(note: note)),
        ),
      );
      expect(find.text('Appointment #14'), findsOneWidget);
      expect(
        find.textContaining('Synthetic encounter findings'),
        findsOneWidget,
      );
      expect(find.text('Finalized — read only'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    },
  );
  testWidgets(
    'long final note remains scrollable on a small large-text screen',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 568),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(
              body: AlertDialog(
                scrollable: true,
                title: const Text('Final note'),
                content: Care360ClinicalNoteReader(
                  note: DoctorNote(
                    appointmentId: 14,
                    status: 'final',
                    body: List.filled(
                      80,
                      'Synthetic test documentation.',
                    ).join(' '),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(Scrollable), findsWidgets);
    },
  );
}
