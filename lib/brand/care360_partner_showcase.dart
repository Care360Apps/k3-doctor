import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Curated discovery only. This deliberately does not import, send, or link
/// Care360 identifiers, patient data, tokens, or navigation state.
class Care360PartnerShowcase extends StatelessWidget {
  const Care360PartnerShowcase({super.key, this.openExternal});
  final Future<bool> Function(Uri)? openExternal;

  static final Uri mindCheckUrl = Uri.https(
    'mindcheck.speakoutmentalhealth.org', '/');

  Future<void> _openMindCheck(BuildContext context) async {
    bool opened = false;
    try {
      opened = await (openExternal?.call(mindCheckUrl) ??
          launchUrl(mindCheckUrl, mode: LaunchMode.externalApplication));
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not open MindCheck. Check your connection.'),
      ));
    }
  }

  void _openLocalGuide(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('Care360 Help', style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w700)),
            SizedBox(height: 10),
            Text('How do I book an appointment?',
              style: TextStyle(fontWeight: FontWeight.w600)),
            Text('Once you have an approved Care360 account, '
              'choose a professional, review availability, and confirm your booking.'),
            SizedBox(height: 12),
            Text('What is MindCheck?',
              style: TextStyle(fontWeight: FontWeight.w600)),
            Text('MindCheck is a separate mental-wellbeing service from '
              'SpeakOut Mental Health Outreach. It opens in your browser.'),
            SizedBox(height: 12),
            Text('Does Care360 share my details?',
              style: TextStyle(fontWeight: FontWeight.w600)),
            Text('Opening a partner link does not send your Care360 account, '
              'appointment, or health records to that partner. '
              'Review the partner’s own privacy notice before using it.'),
            SizedBox(height: 16),
            Text('This is an offline help guide, not a generative AI chat or '
              'a medical assessment. Future AI assistance requires a separate '
              'privacy-reviewed, server-side integration.',
              style: TextStyle(fontSize: 12)),
          ],
        )),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final heading = switch (lang) {
      'fr' => 'Explorer nos partenaires',
      'ha' => 'Bincika abokan haɗin gwiwa',
      'ig' => 'Chọpụta ndị mmekọ anyị',
      'yo' => 'Ṣàwárí àwọn alábàáṣiṣẹ́pọ̀',
      _ => 'Explore partner services',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Card(
        color: const Color(0xFFF0F7F6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(heading, style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF102B48))),
            const SizedBox(height: 4),
            const Text('Independent, reviewed services. Opening a partner '
              'site takes you outside Care360.',
              style: TextStyle(fontSize: 12, color: Color(0xFF47606B))),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                radius: 25,
                backgroundColor: Color(0xFF087D76),
                child: Icon(Icons.psychology_alt_outlined,
                  color: Colors.white, size: 28),
              ),
              title: const Text('MindCheck', style: TextStyle(
                fontWeight: FontWeight.w700)),
              subtitle: const Text('Mental wellbeing • By SpeakOut Mental Health Outreach'),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _openMindCheck(context),
            ),
            const Divider(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _openLocalGuide(context),
                icon: const Icon(Icons.help_outline),
                label: const Text('Care360 Help'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
