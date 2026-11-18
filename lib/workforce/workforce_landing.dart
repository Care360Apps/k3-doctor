import 'career_workflow_screen.dart';
import 'package:flutter/material.dart';
import '../brand/care360_navigation_copy.dart';

import 'workforce_access_screen.dart';
import 'workforce_api.dart';

/// A separate pilot feature. The tile may be visible in Patient, but
/// sign-up, uploads, employer discovery and messages remain fail-closed
/// until both this build flag and the server feature flag are enabled.
const bool kWorkforcePilotBuildEnabled = bool.fromEnvironment(
  'K3_WORKFORCE_PILOT',
  defaultValue: false,
);

const workforceNavy = Color(0xFF123E4D);
const workforceTeal = Color(0xFF087D76);

class Care360WorkforceHomeTile extends StatelessWidget {
  const Care360WorkforceHomeTile({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 7),
      child: Material(
        color: const Color(0xFFE8F3EF),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          key: const Key('home-workforce'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.work_outline_rounded,
                  color: workforceTeal,
                  size: 30,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        care360NavigationText(
                          context,
                          'care360_workforce_title',
                          'Workforce',
                        ),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: workforceNavy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        care360NavigationText(
                          context,
                          'care360_workforce_subtitle',
                          'Healthcare careers and hiring — pilot preview',
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF46636A),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: workforceTeal,
                  size: 17,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Care360WorkforceLanding extends StatefulWidget {
  const Care360WorkforceLanding({
    super.key,
    this.pilotEnabled = kWorkforcePilotBuildEnabled,
    this.api,
  });

  final bool pilotEnabled;
  final WorkforceApi? api;

  @override
  State<Care360WorkforceLanding> createState() =>
      _Care360WorkforceLandingState();
}

class _Care360WorkforceLandingState extends State<Care360WorkforceLanding> {
  bool _serverOpen = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _loadPilotAvailability();
  }

  Future<void> _loadPilotAvailability() async {
    if (!widget.pilotEnabled) {
      _checked = true;
      return;
    }
    final available = await (widget.api ?? WorkforceApi()).applicationsOpen();
    if (mounted) {
      setState(() {
        _checked = true;
        _serverOpen = available;
      });
    }
  }

  Future<void> _open(String role) async {
    if (!widget.pilotEnabled || !_serverOpen) {
      await showModalBottomSheet<void>(
        context: context,
        builder: (_) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Workforce applications are not open yet',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Recruitment registration will open after institutional '
                  'verification, employer safeguarding and private-data '
                  'security checks are completed. No credentials or contact '
                  'details are being collected on this preview.',
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WorkforceAccessScreen(
          accountType: role,
          api: widget.api ?? WorkforceApi(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final open = widget.pilotEnabled && _serverOpen && _checked;
    return Scaffold(
      appBar: AppBar(title: const Text('Care360 Workforce')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [workforceNavy, Color(0xFF12666A)],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.groups_2_outlined, color: Colors.white, size: 32),
                  SizedBox(height: 13),
                  Text(
                    'Careers in healthcare, closer to home',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      height: 1.16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Connect verified students, graduates and professionals '
                    'with approved hospitals, laboratories, pharmacies and '
                    'home-care employers.',
                    style: TextStyle(color: Color(0xFFE2F0EF), height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (!open)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline, color: workforceNavy),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _checked
                              ? 'Recruitment pilot: not yet open. Explore how it works below.'
                              : 'Checking recruitment pilot availability...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 14),
            ListTile(
              leading: const Icon(Icons.school_outlined),
              title: const Text('Browse CNU course cohorts'),
              subtitle: const Text(
                'Course information before creating an account',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => CareerRecordsScreen(
                    api: widget.api ?? WorkforceApi(),
                    role: 'visitor',
                    kind: 'courses',
                    title: 'CNU training',
                  ),
                ),
              ),
            ),
            _journeyCard(
              keyName: 'workforce-join',
              icon: Icons.school_outlined,
              title: 'Join Workforce',
              subtitle:
                  'Students, graduates, caregivers and qualified '
                  'professionals create a career profile and request verification.',
              action: 'Build career profile',
              onTap: () => _open('candidate'),
            ),
            const SizedBox(height: 12),
            _journeyCard(
              keyName: 'workforce-hire',
              icon: Icons.local_hospital_outlined,
              title: 'Hire Workforce',
              subtitle:
                  'Hospitals and healthcare companies verify their '
                  'organization, find eligible candidates and invite them.',
              action: 'Explore hiring',
              onTap: () => _open('employer'),
            ),
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Already registered? Sign in'),
              subtitle: const Text('Career learners or hiring organizations'),
              onTap: () async {
                final role = await showDialog<String>(
                  context: context,
                  builder: (c) => SimpleDialog(
                    title: const Text('Sign in to your career account'),
                    children: [
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(c, 'candidate'),
                        child: const Text('Candidate / learner'),
                      ),
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(c, 'employer'),
                        child: const Text('Employer / recruiter'),
                      ),
                    ],
                  ),
                );
                if (role != null && context.mounted)
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => WorkforceAccessScreen(
                        accountType: role,
                        api: widget.api ?? WorkforceApi(),
                        initiallyRegistering: false,
                      ),
                    ),
                  );
              },
            ),
            const SizedBox(height: 22),
            const Text(
              'How verification works',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: workforceNavy,
              ),
            ),
            const SizedBox(height: 10),
            _step(
              '01',
              'Create a professional profile',
              'Only the qualifications and availability you choose are listed.',
            ),
            _step(
              '02',
              'Independent checks',
              'School completion and professional licences are checked separately.',
            ),
            _step(
              '03',
              'Approved employer invitations',
              'Candidates control whether to accept job offers or conversations.',
            ),
            const SizedBox(height: 14),
            const Text(
              'A verified course does not authorize independent clinical practice. '
              'Your medical and MindCheck information is never part of recruitment.',
              style: TextStyle(color: Color(0xFF506A70), height: 1.45),
            ),
          ],
        ),
      ),
    );
  }

  Widget _journeyCard({
    required String keyName,
    required IconData icon,
    required String title,
    required String subtitle,
    required String action,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        key: Key(keyName),
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: workforceTeal, size: 32),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: workforceNavy,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                subtitle,
                style: const TextStyle(height: 1.45, color: Color(0xFF526A71)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      action,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: workforceTeal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: workforceTeal,
                    size: 19,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _step(String number, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFE8F3EF),
            child: Text(
              number,
              style: const TextStyle(
                color: workforceTeal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: workforceNavy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF536B72), height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
