import 'package:doctro/constant/prefConstatnt.dart';
import 'package:doctro/constant/preferences.dart';
import 'package:flutter/material.dart';
import 'language_localization.dart';

String? getTranslated(BuildContext context, String key) {
  return LanguageLocalization.of(context)!.getTranslateValue(key);
}

const String ENGLISH = "en";
const String HAUSA = "ha";
const String IGBO = "ig";
const String YORUBA = "yo";
const String FRENCH = "fr";
const String ARABIC = "ar";

Future<Locale> setLocale(String languageCode) async {
  SharedPreferenceHelper.setString(Preferences.current_language_code, languageCode);
  return _locale(languageCode);
}

Locale _locale(String languageCode) {
  Locale _temp;
  switch (languageCode) {
    case ENGLISH:
      _temp = Locale(languageCode, 'US');
      break;
    case HAUSA:
      _temp = Locale(languageCode, 'NG');
      break;
    case IGBO:
      _temp = Locale(languageCode, 'NG');
      break;
    case YORUBA:
      _temp = Locale(languageCode, 'NG');
      break;
    case FRENCH:
      _temp = Locale(languageCode, 'FR');
      break;
    case ARABIC:
      _temp = Locale(languageCode, 'AE');
      break;
    default:
      _temp = Locale(ENGLISH, 'US');
  }
  return _temp;
}

Future<Locale> getLocale() async {
  String languageCode = SharedPreferenceHelper.getString(Preferences.current_language_code);
  return _locale(languageCode);
}
