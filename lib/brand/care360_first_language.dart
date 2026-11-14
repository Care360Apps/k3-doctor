import 'package:flutter/material.dart';

/// First-launch entry only. Existing logins bypass this page, and the choice
/// is persisted by the hosting route before the user enters onboarding.
/// Everything is built from the shipped Care360 logo and clinician photos.
class Care360FirstLanguageScreen extends StatefulWidget {
  const Care360FirstLanguageScreen({
    super.key,
    required this.onContinue,
    this.initialLanguage = 'en',
  });

  final String initialLanguage;
  final Future<void> Function(String language) onContinue;

  @override
  State<Care360FirstLanguageScreen> createState() =>
      _Care360FirstLanguageScreenState();
}

class _Care360FirstLanguageScreenState
    extends State<Care360FirstLanguageScreen> {
  static const _navy = Color(0xFF123E4D);
  static const _teal = Color(0xFF087D76);
  static const _labels = <String, String>{
    'en': 'English',
    'ha': 'Hausa',
    'ig': 'Igbo',
    'yo': 'Yorùbá',
    'fr': 'Français',
  };

  late String _selected;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selected = _labels.containsKey(widget.initialLanguage)
        ? widget.initialLanguage
        : 'en';
  }

  Future<void> _continue() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.onContinue(_selected);
    } catch (_) {
      if (mounted) {
        setState(() =>
            _error = 'Could not save your language. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F7),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 520,
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/care360_master_logo.webp',
                            width: 62,
                            height: 62,
                            semanticLabel: 'Care360 official logo',
                          ),
                          const SizedBox(width: 12),
                          const Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Care360 Plus',
                                    style: TextStyle(
                                        color: _navy,
                                        fontSize: 27,
                                        fontWeight: FontWeight.w800)),
                                Text('Connected care for professionals',
                                    style: TextStyle(
                                        color: Color(0xFF526F77),
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(21),
                        child: AspectRatio(
                          aspectRatio: 2.05,
                          child: Image.asset(
                            'assets/images/care360_clinician_team.webp',
                            fit: BoxFit.cover,
                            semanticLabel: 'African healthcare professionals',
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Welcome to Care360 Plus',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _navy,
                          fontSize: 25,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Choose your preferred language for professional care.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF536B72),
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 19),
                      const Text(
                        'Select language',
                        style: TextStyle(
                          color: _navy,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._labels.entries.map((entry) {
                        final active = _selected == entry.key;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: active
                                ? const Color(0xFFE6F4EE)
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                              side: BorderSide(
                                color: active
                                    ? _teal
                                    : const Color(0xFFE0E8E7),
                                width: active ? 1.8 : 1,
                              ),
                            ),
                            child: InkWell(
                              key: Key('first-language-${entry.key}'),
                              onTap: _submitting
                                  ? null
                                  : () => setState(() => _selected = entry.key),
                              borderRadius: BorderRadius.circular(13),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 13, vertical: 9),
                                child: Row(
                                  children: [
                                    Icon(
                                      active
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_unchecked,
                                      color: active
                                          ? _teal
                                          : const Color(0xFF73888D),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        entry.value,
                                        style: TextStyle(
                                          color: _navy,
                                          fontWeight: active
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if (active)
                                      const Icon(Icons.check_circle_rounded,
                                          color: _teal, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            _error!,
                            key: const Key('first-language-error'),
                            style: const TextStyle(color: Color(0xFFA33F25)),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          key: const Key('first-language-continue'),
                          onPressed: _submitting ? null : _continue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _teal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white))
                              : const Text(
                                  'Continue',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'You can change language later on any screen. '
                        'Some text may remain in English while translations '
                        'are being reviewed.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.5,
                          color: Color(0xFF63757C),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'A product of CNU Medical Institute',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF526F77),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
