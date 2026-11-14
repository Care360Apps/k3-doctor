import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'workforce_notice_gate.dart';

/// Human-readable, role-specific data-use summary. It is NOT a substitute
/// for a legally approved, published and accessible recruitment privacy notice.
class WorkforceDataUseNotice extends StatelessWidget {
  const WorkforceDataUseNotice({
    super.key,
    required this.accountType,
    this.openNotice,
  });

  final String accountType;
  final Future<bool> Function(Uri)? openNotice;

  Future<void> _open(BuildContext context, Uri url) async {
    var opened = false;
    try {
      opened =
          await (openNotice?.call(url) ??
              launchUrl(url, mode: LaunchMode.externalApplication));
    } catch (_) {
      // A failed link must not silently be recorded as informed consent.
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recruitment notice could not be opened.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notice = WorkforceNoticeGate.approvedUrl();
    final candidate = accountType == 'candidate';
    return Container(
      key: const Key('workforce-data-use-notice'),
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7F5),
        border: Border.all(color: const Color(0xFFD2E5DF)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.privacy_tip_outlined,
                color: Color(0xFF087D76),
                size: 23,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'How Workforce handles your information',
                  style: TextStyle(
                    color: Color(0xFF123E4D),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const Text(
            'CNU enrollment requests, administrator-recorded progress and completion certificates are separate from clinical records. Verified training is shared with employers only when you allow it.',
          ),
          const SizedBox(height: 9),
          Text(
            candidate
                ? 'Your name, training, qualifications and work preferences '
                      'are used to review your application. Only approved employers '
                      'may find your verified professional profile after you '
                      'separately choose to appear in talent search.'
                : 'Your organization details are used for independent approval. '
                      'Only approved employers may access eligible candidate '
                      'profiles, subject to each candidate\'s separate listing consent.',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF405E66),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Workforce does not grant access to Care360 Patient clinical '
            'records. Recruitment does not guarantee a placement.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF405E66),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 9),
          if (WorkforceNoticeGate.localDemo)
            const Text(
              'LOCAL TEST ONLY. Use fictional details and an email ending '
              'in @care360.example.test. No real applicants or employers. '
              'This test summary does not open public recruitment.',
              style: TextStyle(fontWeight: FontWeight.bold),
            )
          else if (notice == null)
            const Text(
              'Recruitment privacy notice awaiting approval. '
              'New registrations remain closed.',
              key: Key('workforce-notice-pending'),
              style: TextStyle(
                color: Color(0xFF805B17),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            TextButton.icon(
              key: const Key('workforce-read-notice'),
              onPressed: () => _open(context, notice),
              icon: const Icon(Icons.open_in_new_outlined),
              label: const Text('Read the recruitment privacy notice'),
            ),
        ],
      ),
    );
  }
}
