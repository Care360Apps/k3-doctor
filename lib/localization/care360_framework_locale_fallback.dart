import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Flutter's framework delegates do not support every Nigerian language.
/// Keep Care360's user-selected locale for its own authored translations,
/// while falling back to framework English controls where a locale is absent.
///
/// This prevents unsupported-locale Flutter errors on Hausa / Igbo / Yoruba
/// without pretending that untranslated clinical text is localized.
class Care360MaterialFallbackDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const Care360MaterialFallbackDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(
        GlobalMaterialLocalizations.delegate.isSupported(locale)
            ? locale
            : const Locale('en', 'US'),
      );

  @override
  bool shouldReload(Care360MaterialFallbackDelegate old) => false;
}

class Care360WidgetsFallbackDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const Care360WidgetsFallbackDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      GlobalWidgetsLocalizations.delegate.load(
        GlobalWidgetsLocalizations.delegate.isSupported(locale)
            ? locale
            : const Locale('en', 'US'),
      );

  @override
  bool shouldReload(Care360WidgetsFallbackDelegate old) => false;
}

class Care360CupertinoFallbackDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const Care360CupertinoFallbackDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(
        GlobalCupertinoLocalizations.delegate.isSupported(locale)
            ? locale
            : const Locale('en', 'US'),
      );

  @override
  bool shouldReload(Care360CupertinoFallbackDelegate old) => false;
}
