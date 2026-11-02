import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/brand/care360_partner_showcase.dart';
import '../lib/localization/language_localization.dart';

void main() {
  testWidgets('MindCheck opens only a clean external HTTPS destination', (tester) async {
    Uri? opened;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Care360PartnerShowcase(
        openExternal: (url) async { opened = url; return true; },
      )),
    ));
    await tester.tap(find.text('MindCheck'));
    await tester.pump();
    expect(opened.toString(), 'https://mindcheck.speakoutmentalhealth.org/');
    expect(opened!.query, isEmpty);
    expect(opened!.fragment, isEmpty);
    expect(find.textContaining('SpeakOut Mental Health Outreach'), findsOneWidget);
  });

  testWidgets('Help is informative and never calls a model', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Care360PartnerShowcase()),
    ));
    await tester.tap(find.text('Care360 Help'));
    await tester.pumpAndSettle();
    expect(find.textContaining('offline help guide'), findsOneWidget);
    expect(find.textContaining('not a generative AI chat'), findsOneWidget);
  });

  test('All four added languages fall back to the original English strings', () async {
    final en = LanguageLocalization(const Locale('en', 'US'));
    await en.load();
    for (final lang in ['ha', 'ig', 'yo', 'fr']) {
      final instance = LanguageLocalization(Locale(lang));
      await instance.load();
      expect(instance.getTranslateValue('chang_language'), isNotNull);
      expect(instance.getTranslateValue('chang_language'), isNot(
        en.getTranslateValue('chang_language')));
      // No fake translations: missing keys remain the exact English content.
      final fallback = en.getTranslateValue('home_account_pending');
      expect(instance.getTranslateValue('home_account_pending'), fallback);
    }
  });
}
