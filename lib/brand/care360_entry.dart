import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

const _ink = Color(0xFF102B48);
const _green = Color(0xFF137D66);
const _paper = Color(0xFFF8FAF6);
const _hero = 'assets/images/care360_inclusive_hospital.svg';

class Care360Brand extends StatelessWidget {
  const Care360Brand({super.key, required this.professional});
  final bool professional;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Image.asset('assets/images/care360_master_logo.webp', width: 60, height: 60,
        semanticLabel: 'Care360, quality healthcare for all'),
      Text(professional ? 'Care360 Plus' : 'Care360 Patient',
        style: const TextStyle(color: _ink, fontSize: 14, fontWeight: FontWeight.w700)),
    ],
  );
}

class CnuAttribution extends StatelessWidget {
  const CnuAttribution({super.key, this.openLink});
  final Future<bool> Function(Uri)? openLink;
  static final website = Uri.https('www.cnumedical.com', '/');

  Future<void> _open(BuildContext context) async {
    var opened = false;
    try {
      opened = await (openLink?.call(website) ?? launchUrl(website, mode: LaunchMode.externalApplication));
    } catch (_) { /* Offer a readable fallback below. */ }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Visit www.cnumedical.com in your browser.')));
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('A product of', style: TextStyle(color: Color(0xFF52636C), fontSize: 12)),
      Semantics(link: true, child: TextButton(
        onPressed: () => _open(context),
        style: TextButton.styleFrom(foregroundColor: _green,
          minimumSize: const Size(48, 48)),
        child: const Text('CNU Medical Institute', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
            decoration: TextDecoration.underline)),
      )),
    ]),
  );
}

class _LocalIdentity extends StatelessWidget {
  const _LocalIdentity();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    decoration: BoxDecoration(color: const Color(0xFFE7F2EB), borderRadius: BorderRadius.circular(30)),
    child: const Text('Rooted in Nigeria. Connected across Africa.',
      textAlign: TextAlign.center,
      style: TextStyle(color: _green, fontSize: 12, fontWeight: FontWeight.w600)),
  );
}

class _CarePhoto extends StatelessWidget {
  const _CarePhoto();
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(26),
    child: AspectRatio(aspectRatio: 1.6, child: SvgPicture.asset(_hero,
      fit: BoxFit.cover,
      semanticsLabel: 'An inclusive African hospital waiting area with women, men, a child, and healthcare staff')),
  );
}

/// Scrolls naturally on small screens, with the keyboard or larger text enabled.
class Care360AuthShell extends StatelessWidget {
  const Care360AuthShell({super.key, required this.professional, required this.child});
  final bool professional;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _paper,
    body: SafeArea(child: GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(children: [
              Care360Brand(professional: professional),
              const SizedBox(height: 18),
              const _CarePhoto(),
              const SizedBox(height: 16),
              const _LocalIdentity(),
              const SizedBox(height: 22),
              Container(width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 22),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26)),
                child: child),
              const CnuAttribution(),
            ]),
          ),
        )),
      ),
    )),
  );
}

class Care360Welcome extends StatefulWidget {
  const Care360Welcome({super.key, required this.professional, required this.onComplete});
  final bool professional;
  final Future<void> Function() onComplete;
  @override
  State<Care360Welcome> createState() => _Care360WelcomeState();
}

class _Care360WelcomeState extends State<Care360Welcome> {
  int _page = 0;
  bool _finishing = false;

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    try { await widget.onComplete(); }
    catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not continue. Please try again.')));
    } finally { if (mounted) setState(() => _finishing = false); }
  }

  @override
  Widget build(BuildContext context) {
    final titles = widget.professional
      ? ['Your expertise. Our communities.', 'Make room for better care.', 'Build your practice, together.']
      : ['Care that feels closer to home.', 'Your next appointment, made simpler.', 'Your care, in one place.'];
    final descriptions = widget.professional
      ? ['Connect with patients and families, starting in Nigeria and growing across Africa.',
         'Keep appointments and your availability together, with more time for the people you care for.',
         'Create your professional profile and explore a more connected way to deliver care.']
      : ['For you, your family and the people you love. A more connected healthcare journey starts here.',
         'Explore healthcare professionals and manage appointments around your everyday life.',
         'Keep your profile and appointments together, wherever your day takes you.'];

    return Scaffold(backgroundColor: _paper, body: SafeArea(child: LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(child: Center(
        child: ConstrainedBox(constraints: BoxConstraints(minHeight: constraints.maxHeight, maxWidth: 520),
          child: Padding(padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Flexible(child: Care360Brand(professional: widget.professional)),
                  TextButton(onPressed: _finishing ? null : _finish, child: const Text('Skip')),
                ]),
                const SizedBox(height: 22),
                const _CarePhoto(),
                const SizedBox(height: 20),
                const _LocalIdentity(),
                const SizedBox(height: 20),
                Semantics(liveRegion: true, child: Text(titles[_page], textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 30, height: 1.15, color: _ink, fontWeight: FontWeight.w800))),
                const SizedBox(height: 12),
                Text(descriptions[_page], textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, height: 1.5, color: Color(0xFF52636C))),
                const SizedBox(height: 24),
                Semantics(label: 'Introduction ${_page + 1} of 3', child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) => Container(
                    width: i == _page ? 26 : 8, height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(color: i == _page ? _green : const Color(0xFFD1DFD5),
                      borderRadius: BorderRadius.circular(8)))),
                )),
                const SizedBox(height: 24),
                SizedBox(width: double.infinity, child: FilledButton(
                  onPressed: _finishing ? null : () {
                    if (_page < 2) { setState(() => _page++); } else { _finish(); }
                  },
                  style: FilledButton.styleFrom(backgroundColor: _green,
                    padding: const EdgeInsets.symmetric(vertical: 17)),
                  child: Text(_page == 2 ? 'Get started' : 'Continue', style: const TextStyle(fontSize: 16)),
                )),
              ]),
              const CnuAttribution(),
            ]),
          ),
        ),
      )),
    )));
  }
}
