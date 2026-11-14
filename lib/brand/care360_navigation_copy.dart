import 'package:flutter/widgets.dart';

import '../localization/language_localization.dart';

/// UI-only copy for the Care360 navigation and discovery surfaces.
///
/// The existing locale loader overlays Nigerian/French translation JSON on
/// English, so unsupported/missing keys stay readable and never become null.
/// No medical advice or regulated role names are translated here.
String care360NavigationText(
  BuildContext context,
  String key,
  String englishFallback,
) {
  if (key.isEmpty) return englishFallback;
  final translated =
      LanguageLocalization.of(context)?.getTranslateValue(key)?.trim();
  if (translated == null || translated.isEmpty || translated == key) {
    return englishFallback;
  }
  return translated;
}
