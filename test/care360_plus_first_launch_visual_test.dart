import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctro/brand/care360_entry.dart';
import 'package:doctro/brand/care360_first_language.dart';

void main() {
  testWidgets('Plus first launch uses approved Care360 identity and clinician image',
      (tester) async {
    String? selected;
    await tester.pumpWidget(MaterialApp(
      home: Care360FirstLanguageScreen(
        initialLanguage: 'en',
        onContinue: (code) async { selected = code; },
      ),
    ));
    expect(find.text('Care360 Plus'), findsOneWidget);
    expect(find.text('Welcome to Care360 Plus'), findsOneWidget);
    for (final code in ['en', 'ha', 'ig', 'yo', 'fr']) {
      expect(find.byKey(Key('first-language-$code')), findsOneWidget);
    }
    expect(find.byWidgetPredicate((widget) =>
        widget is Image && widget.image is AssetImage &&
        (widget.image as AssetImage).assetName
            .endsWith('care360_master_logo.webp')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('first-language-ig')));
    await tester.tap(find.byKey(const Key('first-language-ig')));
    await tester.ensureVisible(find.byKey(
        const Key('first-language-continue')));
    await tester.tap(find.byKey(const Key('first-language-continue')));
    await tester.pumpAndSettle();
    expect(selected, 'ig');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Professional onboarding retains three existing photo slides',
      (tester) async {
    var finished = 0;
    await tester.pumpWidget(MaterialApp(
      home: Care360Welcome(
        professional: true,
        onComplete: () async { finished++; },
      ),
    ));
    await tester.pumpAndSettle();
    const images = [
      'care360_clinician_team.webp',
      'care360_appointments.webp',
      'care360_family_care.webp',
    ];
    for (var i = 0; i < images.length; i++) {
      expect(find.byWidgetPredicate((widget) =>
          widget is Image && widget.image is AssetImage &&
          (widget.image as AssetImage).assetName
              .endsWith(images[i])), findsOneWidget);
      if (i < images.length - 1) {
        await tester.ensureVisible(find.text('Continue'));
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }
    }
    await tester.ensureVisible(find.text('Get started'));
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(finished, 1);
    expect(tester.takeException(), isNull);
  });

  test('Doctor/Provider clinical routes remain separate from first launch', () {
    final main = File('lib/main.dart').readAsStringSync();
    final locale =
        File('lib/localization/localization_constant.dart')
            .readAsStringSync();
    expect(main, contains("'FirstLanguage': (routeContext)"));
    expect(main, contains("navigator.pushReplacementNamed('Onboarding')"));
    expect(main, contains("SharedPreferenceHelper.getBoolean(Preferences.is_logged_in)"));
    expect(main, contains("'loginHome'"));
    expect(main, contains("'SignIn'"));
    expect(main, contains("'signup': (context) => CreateAccount()"));
    expect(main, contains("'Notes': (context) => const NotesScreen()"));
    expect(main, contains("'Schedule Timings': (context) => ScheduleTimings()"));
    expect(locale, contains('await SharedPreferenceHelper.setString('));
    expect(locale, contains('LanguageLocalization.of(context)?.getTranslateValue(key) ?? key'));
    expect(main, contains('Care360MaterialFallbackDelegate()'));
  });
}
