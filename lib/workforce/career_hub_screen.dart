import 'package:flutter/material.dart';
import 'workforce_api.dart';
import 'workforce_data_use_notice.dart';
import 'career_records_screen.dart';
import 'career_portfolio_screen.dart';
import 'career_privacy_screen.dart';

class CareerWorkflowHub extends StatefulWidget {
  const CareerWorkflowHub({super.key, required this.api, required this.role});
  final WorkforceApi api;
  final String role;
  @override
  State<CareerWorkflowHub> createState() => _CareerWorkflowHubState();
}

class _CareerWorkflowHubState extends State<CareerWorkflowHub> {
  bool _loading = true,
      _consent = false,
      _accepted = false,
      _open = false,
      _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final me = await widget.api.me();
      final status = await widget.api.workflow('career/v1/status');
      if (mounted)
        setState(() {
          _consent = me['notice_current'] == true;
          _open =
              status['data'] is Map && status['data']['workflows_open'] == true;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = e is WorkforceApiException
              ? e.message
              : 'Career services could not be loaded.';
        });
    }
  }

  void _page(String kind, String title) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => CareerRecordsScreen(
        api: widget.api,
        role: widget.role,
        kind: kind,
        title: title,
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Career & CNU training')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(18),
            children: [
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Career data & deletion'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => CareerPrivacyScreen(api: widget.api),
                  ),
                ),
              ),
              if (_error != null) ...[
                Text(_error!),
                TextButton(onPressed: _load, child: const Text('Retry')),
              ] else if (!_open)
                const Text(
                  'These workflows are not open in this environment yet. Course and recruitment administrators must complete release checks.',
                )
              else if (!_consent) ...[
                WorkforceDataUseNotice(accountType: widget.role),
                const Text(
                  'Review the current privacy notice before using recruitment or training records.',
                ),
                CheckboxListTile(
                  value: _accepted,
                  onChanged: _busy
                      ? null
                      : (v) => setState(() => _accepted = v == true),
                  title: const Text(
                    'I accept the current recruitment and training privacy notice.',
                  ),
                ),
                FilledButton(
                  onPressed: !_accepted || _busy
                      ? null
                      : () async {
                          setState(() => _busy = true);
                          try {
                            await widget.api.acceptNotice();
                            await _load();
                          } catch (e) {
                            if (mounted)
                              setState(
                                () => _error = e is WorkforceApiException
                                    ? e.message
                                    : 'Could not record consent.',
                              );
                          } finally {
                            if (mounted) setState(() => _busy = false);
                          }
                        },
                  child: const Text('Record consent'),
                ),
              ] else ...[
                const Text(
                  'Workforce',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                if (widget.role == 'candidate')
                  ListTile(
                    leading: const Icon(Icons.badge_outlined),
                    title: const Text('Education, experience & skills'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => CareerPortfolioScreen(api: widget.api),
                      ),
                    ),
                  ),
                ListTile(
                  leading: const Icon(Icons.work_outline),
                  title: Text(
                    widget.role == 'employer'
                        ? 'Manage vacancies'
                        : 'Explore vacancies',
                  ),
                  onTap: () => _page('jobs', 'Vacancies'),
                ),
                if (widget.role == 'employer')
                  ListTile(
                    leading: const Icon(Icons.manage_accounts_outlined),
                    title: const Text('Recruiter access & invitations'),
                    onTap: () => _page('recruiters', 'Recruiter access'),
                  ),
                if (widget.role == 'employer')
                  ListTile(
                    leading: const Icon(Icons.person_search),
                    title: const Text('Find consenting verified candidates'),
                    onTap: () => _page('candidates', 'Candidate discovery'),
                  ),
                ListTile(
                  leading: const Icon(Icons.assignment_outlined),
                  title: const Text('Applications & interviews'),
                  onTap: () =>
                      _page('applications', 'Applications & interviews'),
                ),
                ListTile(
                  leading: const Icon(Icons.mail_outline),
                  title: const Text('Recruitment invitations & messages'),
                  onTap: () => _page('invitations', 'Recruitment invitations'),
                ),
                ListTile(
                  leading: const Icon(Icons.upload_file),
                  title: const Text('Private verification documents'),
                  onTap: () => _page('documents', 'Private documents'),
                ),
                const Divider(),
                const Text(
                  'CNU training',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Requests and completion records are managed by authorized administrators. This does not provide automatic learning-platform progress or unverified CPD credits.',
                ),
                ListTile(
                  leading: const Icon(Icons.school_outlined),
                  title: const Text('Course catalogue'),
                  onTap: () => _page('courses', 'CNU course cohorts'),
                ),
                ListTile(
                  leading: const Icon(Icons.menu_book),
                  title: const Text('My enrollments & completion records'),
                  onTap: () => _page('enrollments', 'My CNU training'),
                ),
                if (widget.role == 'employer')
                  ListTile(
                    leading: const Icon(Icons.business),
                    title: const Text('Organization training requests'),
                    onTap: () => _page('requests', 'Organization training'),
                  ),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Career & training updates'),
                  onTap: () => _page('notifications', 'Updates'),
                ),
              ],
            ],
          ),
  );
}
