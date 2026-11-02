import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/localization/language_localization.dart';

void main() {
  test('Plus has five-language localization with English fallback', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final en = LanguageLocalization(const Locale('en', 'US'));
    await en.load();
    for (final lang in ['ha', 'ig', 'yo', 'fr']) {
      final locale = LanguageLocalization(Locale(lang));
      await locale.load();
      expect(locale.getTranslateValue('chang_language'), isNotNull);
      expect(locale.getTranslateValue('chang_language'),
          isNot(en.getTranslateValue('chang_language')));
      expect(locale.getTranslateValue('home_account_pending'),
          en.getTranslateValue('home_account_pending'));
    }
  });

  test('Plus clinician dashboard never displays MindCheck partner discovery', () {
    final dashboard =
        File('lib/screens/home page/login_home.dart').readAsStringSync();
    expect(dashboard.contains('Care360PartnerShowcase('), isFalse);
    expect(dashboard.contains('care360_partner_showcase.dart'), isFalse);
    final signIn = File('lib/brand/care360_entry.dart').readAsStringSync();
    expect(signIn.contains('MindCheck'), isFalse);
  });
}
