import 'package:flutter/material.dart';

/// Persistent, compact language selection across all Care360 screens.
/// The host app manages persistence and locale changes; this widget never
/// accesses health records, API endpoints or authentication state.
class Care360GlobalLanguageSwitch extends StatelessWidget {
  const Care360GlobalLanguageSwitch({
    super.key,
    required this.onSelect,
    this.rootNavigatorKey,
  });

  final Future<void> Function(String) onSelect;
  final GlobalKey<NavigatorState>? rootNavigatorKey;

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
      child: IconButton(
        key: const Key('care360-language-every-screen'),
        tooltip: 'Change language',
        icon: const Icon(Icons.language, color: Color(0xFF137D66), size: 23),
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        onPressed: () async {
          // MaterialApp.builder sits above the Navigator. Use the navigator's
          // overlay context so the bottom sheet opens on any app route.
          final routeContext = rootNavigatorKey?.currentState?.overlay?.context ??
              context;
          await showModalBottomSheet<void>(
            context: routeContext,
            isScrollControlled: false,
            builder: (sheetContext) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 18, 16, 8),
                    child: Text('Choose language',
                        style: TextStyle(fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
                  ...supportedLanguages.entries.map((entry) => ListTile(
                    key: Key('language-${entry.key}'),
                    title: Text(entry.value),
                    leading: Icon(
                      currentCode == entry.key
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: const Color(0xFF137D66),
                    ),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onSelect(entry.key);
                    },
                  )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
