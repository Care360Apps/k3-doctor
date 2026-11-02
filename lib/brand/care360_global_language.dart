import 'package:flutter/material.dart';

/// Persistent, compact language selection across all Care360 screens.
/// The host app manages persistence and locale changes; this widget never
/// accesses health records, API endpoints or authentication state.
class Care360GlobalLanguageSwitch extends StatelessWidget {
  const Care360GlobalLanguageSwitch({
    super.key,
    required this.onSelect,
  });

  final Future<void> Function(String) onSelect;

  static const supportedLanguages = <String, String>{
    'en': 'English',
    'ha': 'Hausa',
    'ig': 'Igbo',
    'yo': 'Yorùbá',
    'fr': 'Français',
  };

  @override
  Widget build(BuildContext context) {
    final currentCode = Localizations.localeOf(context).languageCode;
    return Material(
      color: const Color(0xFFF8FAF6),
      borderRadius: BorderRadius.circular(28),
      elevation: 2,
      child: PopupMenuButton<String>(
        key: const Key('care360-language-every-screen'),
        tooltip: 'Change language',
        onSelected: (code) async => onSelect(code),
        itemBuilder: (_) => supportedLanguages.entries.map((entry) =>
          PopupMenuItem<String>(
            value: entry.key,
            child: Row(children: [
              if (currentCode == entry.key)
                const Icon(Icons.check, size: 18, color: Color(0xFF137D66))
              else
                const SizedBox(width: 18),
              const SizedBox(width: 8),
              Text(entry.value),
            ]),
          ),
        ).toList(),
        icon: const Icon(Icons.language, color: Color(0xFF137D66), size: 23),
        iconSize: 23,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      ),
    );
  }
}
