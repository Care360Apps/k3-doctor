import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'localization_constant.dart';

class LanguageLocalization {
  final Locale locale;

  LanguageLocalization(this.locale);

  static LanguageLocalization? of(BuildContext context) {
    return Localizations.of<LanguageLocalization>(context, LanguageLocalization);
  }

  late Map<String, String> _localizationValue;

  Future<void> load() async {
    // A translated key is opt-in; untranslated clinical and technical strings
    // remain in English rather than displaying 'null' or guessing meaning.
    final english = json.decode(await rootBundle.loadString(
      'lib/localization/language/en.json')) as Map<String, dynamic>;
    _localizationValue = english.map(
      (key, value) => MapEntry(key, value?.toString() ?? ''),
    );
    if (locale.languageCode != ENGLISH) {
      final translated = json.decode(await rootBundle.loadString(
        'lib/localization/language/${locale.languageCode}.json')) as Map<String, dynamic>;
      for (final item in translated.entries) {
        if (item.value is String && (item.value as String).trim().isNotEmpty) {
          _localizationValue[item.key] = item.value as String;
        }
      }
    }
  }

  String? getTranslateValue(String key) => _localizationValue[key];

  static const LocalizationsDelegate<LanguageLocalization> delegate = _LanguageLocalizationDelegate();
}

class _LanguageLocalizationDelegate extends LocalizationsDelegate<LanguageLocalization> {
  const _LanguageLocalizationDelegate();

  @override
  bool isSupported(Locale locale) {
    return [ENGLISH, HAUSA, IGBO, YORUBA, FRENCH, SPANISH, ARABIC].contains(locale.languageCode);
  }

  @override
  Future<LanguageLocalization> load(Locale locale) async {
    LanguageLocalization localization = new LanguageLocalization(locale);
    await localization.load();
    return localization;
  }

  @override
  bool shouldReload(_LanguageLocalizationDelegate old) => false;
}
