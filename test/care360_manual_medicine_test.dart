import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctro/screens/appointment/medicine_entry_dialog.dart';
import 'package:doctro/security/care360_prescription_validation.dart';

void main() {
  Future<void> open(
    WidgetTester tester,
    List<String> options,
    void Function(Map<String, dynamic>?) result,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => result(
                await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (_) =>
                      Care360MedicineEntryDialog(medicines: options),
                ),
              ),
              child: const Text('Open entry'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open entry'));
    await tester.pumpAndSettle();
  }

  testWidgets('editing a draft retains timing and changes only the selected value', (tester) async {
    Map<String,dynamic>? saved;
    final original = <String,dynamic>{'name':'Demo written medicine','day':'3',
      'morning':true,'afternoon':false,'night':false};
    await tester.pumpWidget(MaterialApp(home: Builder(builder:(context) => Scaffold(
      body: TextButton(child:const Text('Edit'),onPressed:() async {
        saved=await showDialog<Map<String,dynamic>>(context:context,builder:(_) =>
          Care360MedicineEntryDialog(medicines:const [],initial:original));
      })))));
    await tester.tap(find.text('Edit')); await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('medicine-duration')),'5');
    await tester.tap(find.text('Save changes')); await tester.pumpAndSettle();
    expect(saved?['day'],'5'); expect(saved?['morning'],true);
    expect(saved?['name'],original['name']); expect(original['day'],'3');
  });

  Future<void> schedule(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const Key('medicine-duration')));
    await tester.enterText(find.byKey(const Key('medicine-duration')), '3');
    await tester.ensureVisible(find.byKey(const Key('medicine-time-morning')));
    await tester.tap(find.byKey(const Key('medicine-time-morning')));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'written medicine retains exact text and existing API/PDF shape',
    (tester) async {
      Map<String, dynamic>? result;
      await open(tester, ['Catalogue demo'], (value) => result = value);
      await tester.tap(find.byKey(const Key('medicine-written-mode')));
      await tester.pumpAndSettle();
      const name = 'Written demo medicine — TEST ONLY';
      await tester.enterText(
        find.byKey(const Key('medicine-written-name')),
        '  $name  ',
      );
      await schedule(tester);
      await tester.tap(find.byKey(const Key('medicine-add')));
      await tester.pumpAndSettle();
      expect(result?['name'], name);
      expect(result?['morning'], true);
      expect(
        Care360PrescriptionValidation.validate([
          {
            'medicine': result!['name'],
            'days': result!['day'],
            'morning': 1,
            'afternoon': 0,
            'night': 0,
          },
        ]),
        isNull,
      );
      expect(result!.containsKey('catalogue_id'), false);
    },
  );
  testWidgets('empty catalogue still permits manual entry', (tester) async {
    Map<String, dynamic>? result;
    await open(tester, [], (value) => result = value);
    expect(find.byKey(const Key('medicine-written-name')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('medicine-written-name')),
      'Unlisted training medicine',
    );
    await schedule(tester);
    await tester.tap(find.byKey(const Key('medicine-add')));
    await tester.pumpAndSettle();
    expect(result?['name'], 'Unlisted training medicine');
  });
  testWidgets('catalogue mode rejects an unlisted name', (tester) async {
    Map<String, dynamic>? result;
    await open(tester, ['Catalogue demo'], (value) => result = value);
    await tester.enterText(
      find.byKey(const Key('medicine-catalogue-name')),
      'Not in catalogue',
    );
    await schedule(tester);
    await tester.tap(find.byKey(const Key('medicine-add')));
    await tester.pumpAndSettle();
    expect(result, isNull);
    expect(
      find.text('Choose a listed medicine or select Write a medicine.'),
      findsOneWidget,
    );
  });
  testWidgets(
    'invalid entries stay open and cancellation does not return a medicine',
    (tester) async {
      Map<String, dynamic>? result;
      await open(tester, [], (value) => result = value);
      await tester.tap(find.byKey(const Key('medicine-add')));
      await tester.pumpAndSettle();
      expect(find.text('Enter a medicine name.'), findsOneWidget);
      expect(
        find.text('Enter a duration between 1 and 365 days.'),
        findsOneWidget,
      );
      expect(find.text('Select at least one daily time.'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(find.byType(Care360MedicineEntryDialog), findsNothing);
    },
  );
  testWidgets(
    'review displays patient and written medicine and requires confirmation',
    (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async => result = await reviewCare360Prescription(
                  context,
                  patientName: 'Demo Patient',
                  appointmentReference: 'DEMO-14',
                  medicines: [
                    {
                      'name': 'Written training medicine',
                      'day': '3',
                      'morning': true,
                      'afternoon': false,
                      'night': false,
                    },
                  ],
                ),
                child: const Text('Review'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();
      expect(find.text('Patient: Demo Patient'), findsOneWidget);
      expect(find.textContaining('Written training medicine'), findsOneWidget);
      expect(result, isNull);
      await tester.tap(find.text('Go back'));
      await tester.pumpAndSettle();
      expect(result, false);
      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('prescription-confirm-save')));
      await tester.pumpAndSettle();
      expect(result, true);
    },
  );

  testWidgets(
    'written entry remains usable on a narrow screen with large text',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      Map<String, dynamic>? result;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (_) =>
                        const Care360MedicineEntryDialog(medicines: []),
                  );
                },
                child: const Text('Open entry'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open entry'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('medicine-written-name')),
      );
      await tester.enterText(
        find.byKey(const Key('medicine-written-name')),
        'Training medicine',
      );
      await schedule(tester);
      await tester.tap(find.byKey(const Key('medicine-add')));
      await tester.pumpAndSettle();
      expect(result?['name'], 'Training medicine');
      expect(tester.takeException(), isNull);
    },
  );
}
