import 'package:flutter/material.dart';

/// Persistent nonclinical language selection. The root Navigator owns
/// the dialog overlay; MaterialApp.builder lives ABOVE Navigator's Overlay,
/// and must never create popup routes using its own context.
class Care360GlobalLanguageSwitch extends StatefulWidget {
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
  State<Care360GlobalLanguageSwitch> createState() =>
      _Care360GlobalLanguageSwitchState();
}

class _Care360GlobalLanguageSwitchState
    extends State<Care360GlobalLanguageSwitch> {
  bool _changing = false;

  Future<void> _chooseLanguage() async {
    if (_changing) return;
    final navigator = widget.rootNavigatorKey?.currentState;
    // The MaterialApp builder context is a sibling of Navigator, not a
    // descendant of the overlay. Fail safely if Navigator isn't ready.
    final overlayContext = navigator?.overlay?.context;
    if (navigator == null || !navigator.mounted || overlayContext == null) {
      return;
    }

    setState(() => _changing = true);
    try {
      final currentCode =
          Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
      // Return the selection from the route, and wait until the route has
      // completely closed BEFORE rebuilding MaterialApp/localizations.
      // This avoids locale changes racing an exiting modal's widget tree.
      ModalRoute<dynamic>? sheetRoute;
      final selected = await showModalBottomSheet<String>(
        context: overlayContext,
        useRootNavigator: true,
        isScrollControlled: false,
        builder: (sheetContext) {
          sheetRoute = ModalRoute.of(sheetContext);
          return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 18, 16, 8),
                child: Text('Choose language',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              for (final entry
                  in Care360GlobalLanguageSwitch.supportedLanguages.entries)
                ListTile(
                  key: Key('language-${entry.key}'),
                  title: Text(entry.value),
                  leading: Icon(
                    currentCode == entry.key
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: const Color(0xFF137D66),
                  ),
                  onTap: () => Navigator.of(sheetContext).pop(entry.key),
                ),
            ],
          ),
        );
        },
      );

      // showModalBottomSheet's result can resolve before its reverse
      // animation finishes. Avoid rebuilding a still-exiting route.
      if (selected != null) {
        await sheetRoute?.completed;
      }
      if (!mounted || selected == null || selected == currentCode) return;
      if (!Care360GlobalLanguageSwitch.supportedLanguages
          .containsKey(selected)) return;
      await widget.onSelect(selected);
    } catch (_) {
      // Language selection is optional. Never replace a clinical screen
      // with a Flutter error because navigation/local storage failed.
      if (mounted) {
        final state = widget.rootNavigatorKey?.currentState;
        final messenger = state == null
            ? null
            : ScaffoldMessenger.maybeOf(state.context);
        messenger?.showSnackBar(
          const SnackBar(content: Text(
              'Could not change language. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _changing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAF6),
      borderRadius: BorderRadius.circular(28),
      elevation: 2,
      child: Semantics(
        label: 'Change language',
        button: true,
        child: IconButton(
          key: const Key('care360-language-every-screen'),
          icon: const Icon(
              Icons.language, color: Color(0xFF137D66), size: 23),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: _changing ? null : _chooseLanguage,
        ),
      ),
    );
  }
}
