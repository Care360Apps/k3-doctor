import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../localization/localization_constant.dart';
import 'care360_partner_showcase.dart';

/// Small, independent pre-login controls for language and approved partners.
/// Never sends account identifiers, health details, auth tokens or tracking
/// parameters to the linked partner.
class Care360PublicAccess extends StatelessWidget {
  const Care360PublicAccess({
    super.key,
    this.onLanguageSelected,
    this.openExternal,
  });

  /// Optional injection for an offline widget test (no app preferences needed).
  final Future<void> Function(String)? onLanguageSelected;
  final Future<bool> Function(Uri)? openExternal;

  static const languages = <String, String>{
    'en': 'English',
    'ha': 'Hausa',
    'ig': 'Igbo',
    'yo': 'Yorùbá',
    'fr': 'Français',
  };

  Future<void> _selectLanguage(BuildContext context, String code) async {
    if (onLanguageSelected != null) {
      await onLanguageSelected!(code);
      return;
    }
    final locale = await setLocale(code);
    if (!context.mounted) return;
    MyApp.setLocale(context, locale);
  }

  Future<void> _openPartner(BuildContext context) async {
    var opened = false;
    try {
      opened = await (openExternal?.call(Care360PartnerShowcase.mindCheckUrl) ??
          launchUrl(
            Care360PartnerShowcase.mindCheckUrl,
            mode: LaunchMode.externalApplication,
          ));
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Cannot open MindCheck. Please check your connection.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    final label = languages[code] ?? 'English';
    return Semantics(
      container: true,
      child: Wrap(
        key: const Key('care360-public-access'),
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 2,
        children: [
          PopupMenuButton<String>(
            key: const Key('care360-public-language'),
            tooltip: 'Choose a language',
            onSelected: (code) => _selectLanguage(context, code),
            itemBuilder: (_) => languages.entries
                .map((entry) => PopupMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    ))
                .toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.language, size: 18, color: Color(0xFF137D66)),
                const SizedBox(width: 5),
                Text(label, style: const TextStyle(
                  fontSize: 13, color: Color(0xFF102B48),
                  fontWeight: FontWeight.w600,
                )),
                const Icon(Icons.arrow_drop_down, color: Color(0xFF102B48)),
              ]),
            ),
          ),
          TextButton.icon(
            key: const Key('care360-public-mindcheck'),
            onPressed: () => _openPartner(context),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('MindCheck · SpeakOut'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF137D66),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ],
      ),
    );
  }
}
