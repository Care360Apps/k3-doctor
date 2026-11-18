import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'workforce_api.dart';
import 'workforce_access_screen.dart';
import 'career_action_form.dart';
import 'career_document_picker.dart';
import 'career_record_choice.dart';
import 'career_conversation_screen.dart';

class CareerRecordsScreen extends StatefulWidget {
  const CareerRecordsScreen({
    super.key,
    required this.api,
    required this.role,
    required this.kind,
    required this.title,
  });
  final WorkforceApi api;
  final String role, kind, title;
  @override
  State<CareerRecordsScreen> createState() => _CareerRecordsScreenState();
}

class _CareerRecordsScreenState extends State<CareerRecordsScreen> {
  bool _loading = true, _busy = false, _canInvite = false;
  String? _error;
  int _page = 1, _last = 1;
  List<Map<String, dynamic>> _rows = [];
  final _search = TextEditingController();
  Map<String, dynamic> _filters = {};
  String get _path =>
      '${['courses', 'enrollments', 'requests'].contains(widget.kind) ? 'training' : 'workforce'}/v1/${widget.kind}';
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetch(
    String path, {
    Map<String, dynamic>? query,
  }) => widget.kind == 'courses' && widget.role == 'visitor'
      ? widget.api.catalogue(query: query)
      : widget.api.workflow(path, query: query);
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _fetch(
        _path,
        query: {
          'page': _page,
          ..._filters,
          if (_search.text.trim().isNotEmpty) 'q': _search.text.trim(),
        },
      );
      final top = response['data'];
      final data = widget.kind == 'recruiters' && top is Map
          ? top['records']
          : top;
      final list = data is Map ? data['data'] : data;
      final meta = data is Map ? data : response['meta'];
      if (mounted)
        setState(() {
          _canInvite =
              widget.kind == 'recruiters' &&
              top is Map &&
              top['can_invite'] == true;
          _rows = list is List
              ? list
                    .whereType<Map>()
                    .map((x) => Map<String, dynamic>.from(x))
                    .toList()
              : [];
          _last = meta is Map ? (meta['last_page'] as num?)?.toInt() ?? 1 : 1;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = e is WorkforceApiException
              ? e.message
              : 'Could not load records. Please retry.';
        });
    }
  }

  Future<void> _action(String path, {Map<String, dynamic>? body}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.api.workflow(path, method: 'post', body: body ?? {});
      await _load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is WorkforceApiException
                  ? e.message
                  : 'Action unavailable. Please retry.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _form(
    String title,
    List<CareerField> fields,
    String path, {
    Map<String, dynamic> extra = const {},
  }) async {
    if (await careerForm(context, title, fields, (d) async {
      await widget.api.workflow(path, method: 'post', body: {...d, ...extra});
    }))
      await _load();
  }

  Future<void> _confirm(
    String title,
    String path,
    Map<String, dynamic> data,
  ) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (yes == true) await _action(path, body: data);
  }

  void _create() {
    if (widget.kind == 'jobs') {
      _form('Submit vacancy for moderation', const [
        CareerField('title', 'Job title'),
        CareerField(
          'profession',
          'Profession',
          options: [
            'care_assistant',
            'home_care_assistant',
            'supervised_intern',
            'phlebotomy_support',
            'laboratory_assistant',
            'medical_records_assistant',
            'nurse',
            'community_health_practitioner',
            'medical_laboratory_scientist',
            'pharmacist',
            'doctor',
          ],
        ),
        CareerField('state', 'Work location/state'),
        CareerField(
          'employment_type',
          'Employment type',
          options: ['full_time', 'part_time', 'contract', 'internship'],
        ),
        CareerField('description', 'Job description', multiline: true),
        CareerField(
          'requirements',
          'Qualifications and requirements',
          multiline: true,
        ),
        CareerField('closes_on', 'Application closing date', kind: 'date'),
      ], _path);
    } else if (widget.kind == 'recruiters') {
      _form('Invite a recruiter', const [
        CareerField('email', 'Staff career-account email'),
        CareerField(
          'staff_authority_attestation',
          'I am authorized to request recruitment access for this staff member. Administrator review and staff acceptance are required.',
          kind: 'consent',
        ),
      ], _path);
    } else if (widget.kind == 'requests') {
      _form('Request organization training', const [
        CareerField('topic', 'Training topic'),
        CareerField('objectives', 'Training objectives', multiline: true),
        CareerField('participants', 'Number of participants', kind: 'number'),
        CareerField('location', 'Preferred location'),
        CareerField('preferred_date', 'Preferred date', kind: 'date'),
        CareerField(
          'delivery',
          'Delivery method',
          options: ['onsite', 'virtual', 'hybrid'],
        ),
        CareerField('contact_name', 'Contact person'),
        CareerField('contact_phone', 'Contact telephone'),
        CareerField(
          'requirements',
          'Additional requirements',
          multiline: true,
          required: false,
        ),
      ], _path);
    }
  }

  Future<void> _upload() async {
    await careerForm(
      context,
      'Upload private document',
      [
        CareerField(
          'kind',
          'Document type',
          options: widget.role == 'employer'
              ? ['organization', 'identity']
              : ['cv', 'education', 'licence', 'identity'],
        ),
      ],
      (d) async {
        final file = await pickCareerDocument();
        if (file == null)
          throw const WorkforceApiException(
            'No document selected. Your choice has been kept.',
          );
        await widget.api.uploadDocument(
          d['kind'] as String,
          file.bytes,
          file.name,
        );
      },
    );
    await _load();
  }

  Future<void> _saveDocument(int id) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await widget.api.downloadDocument(id);
      final saved = await saveCareerDocument(bytes);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              saved
                  ? 'Document saved to your selected location.'
                  : 'Save cancelled.',
            ),
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is WorkforceApiException ? e.message : 'Document unavailable.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _apply(int job) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final docs = await widget.api.workflow('workforce/v1/documents');
      final data = docs['data'];
      final cvs = data is Map && data['data'] is List
          ? (data['data'] as List)
                .whereType<Map>()
                .where((x) => x['kind'] == 'cv')
                .toList()
          : <Map>[];
      if (!mounted) return;
      await careerForm(
        context,
        'Apply for vacancy',
        [
          const CareerField('cover_letter', 'Cover letter', multiline: true),
          CareerField(
            'cv_choice',
            'Share a CV from your private documents',
            options: [
              'Do not attach a CV',
              ...cvs.map((x) => 'CV uploaded ${x['created_at']} (#${x['id']})'),
            ],
          ),
          const CareerField(
            'share_application',
            'I authorize this verified employer to receive my application and selected CV.',
            kind: 'consent',
          ),
        ],
        (d) async {
          final choice = d.remove('cv_choice') as String;
          final m = RegExp(r'\(#(\d+)\)$').firstMatch(choice);
          if (m != null) d['cv_document_id'] = int.parse(m.group(1)!);
          await widget.api.workflow(
            'workforce/v1/jobs/$job/apply',
            method: 'post',
            body: d,
          );
        },
      );
      await _load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is WorkforceApiException
                  ? e.message
                  : 'Could not prepare the application. Please retry.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _invite(Map<String, dynamic> job) async {
    final candidate = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => CareerRecordChoice(
          api: widget.api,
          profession: job['profession'].toString(),
        ),
      ),
    );
    if (candidate != null)
      await _action(
        'workforce/v1/invitations',
        body: {'job_id': job['id'], 'candidate_id': candidate['candidate_id']},
      );
  }

  Future<void> _filterCandidates() async {
    await careerForm(
      context,
      'Filter candidates',
      const [
        CareerField('state', 'State/location', required: false),
        CareerField('qualification', 'Qualification', required: false),
        CareerField(
          'desired_role',
          'Profession',
          options: [
            'any',
            'care_assistant',
            'home_care_assistant',
            'supervised_intern',
            'phlebotomy_support',
            'laboratory_assistant',
            'medical_records_assistant',
            'nurse',
            'community_health_practitioner',
            'medical_laboratory_scientist',
            'pharmacist',
            'doctor',
          ],
        ),
        CareerField(
          'min_experience_years',
          'Minimum self-reported years of experience',
          kind: 'number',
          required: false,
        ),
      ],
      (d) async {
        d.removeWhere((k, v) => v == null || v == '' || v == 'any');
        setState(() {
          _filters = d;
          _page = 1;
        });
      },
    );
    await _load();
  }

  Widget _record(Map<String, dynamic> row) {
    final id = (row['id'] as num?)?.toInt() ?? 0;
    final status = (row['status'] ?? row['review_status'] ?? '').toString();
    final profile = row['profile'] is Map ? row['profile'] as Map : const {};
    final title =
        (row['title'] ??
                row['role_title'] ??
                row['topic'] ??
                row['display_name'] ??
                row['name'] ??
                row['kind'] ??
                'Record')
            .toString()
            .replaceAll('_', ' ');
    final actions = <Widget>[];
    final lines = <String>[];
    if (row['offer_response'] == 'offer_accepted')
      lines.add('Candidate accepted the offer.');
    if (status.isNotEmpty) lines.add('Status: ${status.replaceAll('_', ' ')}');
    if (widget.kind == 'jobs') {
      lines.addAll([
        '${row['organization_name']} · ${row['state']}',
        '${row['profession']} · ${row['employment_type']}',
        'Closes: ${row['closes_on']}',
        row['description']?.toString() ?? '',
        row['requirements']?.toString() ?? '',
      ]);
      if (widget.role == 'candidate')
        actions.add(
          TextButton(
            onPressed: _busy ? null : () => _apply(id),
            child: const Text('Apply'),
          ),
        );
      if (widget.role == 'employer' && status == 'published')
        actions.add(
          TextButton(
            onPressed: _busy ? null : () => _invite(row),
            child: const Text('Invite candidate'),
          ),
        );
      if (widget.role == 'employer' &&
          ['pending', 'published'].contains(status))
        actions.add(
          TextButton(
            onPressed: _busy
                ? null
                : () => _confirm(
                    'Close this vacancy?',
                    'workforce/v1/jobs/$id/close',
                    {},
                  ),
            child: const Text('Close vacancy'),
          ),
        );
    } else if (widget.kind == 'candidates') {
      lines.addAll([
        '${row['qualification']} · ${row['institution']}',
        '${row['desired_role']} · ${row['state']}',
        '${row['career_stage']} · ${row['shift_preference']}',
      ]);
      actions.add(
        TextButton(
          onPressed: _busy
              ? null
              : () async {
                  try {
                    final result = await widget.api.workflow(
                      'workforce/v1/candidates/${row['candidate_id']}/training',
                    );
                    if (!mounted) return;
                    await showDialog<void>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Shared verified training'),
                        content: SingleChildScrollView(
                          child: Text(
                            (result['data'] as List)
                                    .map((x) => x['title'])
                                    .join('\n')
                                    .isEmpty
                                ? 'No shared completion records.'
                                : (result['data'] as List)
                                      .map((x) => x['title'])
                                      .join('\n'),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  } catch (_) {
                    if (mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'This candidate has not shared training records.',
                          ),
                        ),
                      );
                  }
                },
          child: const Text('Shared training'),
        ),
      );
    } else if (widget.kind == 'applications') {
      if (profile.isNotEmpty)
        lines.addAll([
          '${profile['name']} · ${profile['qualification']}',
          profile['cover_letter']?.toString() ?? '',
        ]);
      if (row['cv_document_id'] is num)
        actions.add(
          TextButton(
            onPressed: _busy
                ? null
                : () => _saveDocument((row['cv_document_id'] as num).toInt()),
            child: const Text('Save shared CV'),
          ),
        );
      if (widget.role == 'candidate' &&
          !['withdrawn', 'rejected', 'hired'].contains(status))
        actions.add(
          TextButton(
            onPressed: () => _form(
              'Withdraw application',
              const [CareerField('note', 'Reason', multiline: true)],
              'workforce/v1/applications/$id/status',
              extra: {'status': 'withdrawn'},
            ),
            child: const Text('Withdraw'),
          ),
        );
      if (widget.role == 'candidate' &&
          status == 'offered' &&
          row['offer_response'] == null)
        for (final accept in [true, false])
          actions.add(
            TextButton(
              onPressed: () => _confirm(
                accept
                    ? 'Accept this employment offer?'
                    : 'Decline this employment offer?',
                'workforce/v1/applications/$id/offer-response',
                {'accepted': accept},
              ),
              child: Text(accept ? 'Accept offer' : 'Decline offer'),
            ),
          );
      if (widget.role == 'employer') {
        final choices =
            <String>[
              'submitted',
              'shortlisted',
              'interview',
              'offered',
            ].contains(status)
            ? [
                'rejected',
                if (status == 'submitted') 'shortlisted',
                if (status == 'interview') 'offered',
                if (status == 'offered' &&
                    row['offer_response'] == 'offer_accepted')
                  'hired',
              ]
            : <String>[];
        for (final next in choices)
          actions.add(
            TextButton(
              onPressed: () => _form(
                next.replaceAll('_', ' '),
                const [CareerField('note', 'Decision note', multiline: true)],
                'workforce/v1/applications/$id/status',
                extra: {'status': next},
              ),
              child: Text(next.replaceAll('_', ' ')),
            ),
          );
        if (['shortlisted', 'interview'].contains(status))
          actions.add(
            TextButton(
              onPressed: () => _form(
                'Schedule interview',
                const [
                  CareerField(
                    'scheduled_at',
                    'Interview date and time',
                    kind: 'datetime',
                  ),
                  CareerField(
                    'instructions',
                    'Interview instructions',
                    multiline: true,
                  ),
                ],
                'workforce/v1/applications/$id/interviews',
                extra: {'timezone': 'UTC'},
              ),
              child: const Text('Schedule interview'),
            ),
          );
      }
      final interviews = row['interviews'];
      if (interviews is List)
        for (final i in interviews.whereType<Map>()) {
          final date = DateTime.tryParse(
            i['scheduled_at'].toString(),
          )?.toLocal();
          lines.add(
            'Interview: ${date ?? i['scheduled_at']} · ${i['candidate_response']}',
          );
          if (i['details'] is Map)
            lines.add(i['details']['instructions']?.toString() ?? '');
          if (widget.role == 'candidate' &&
              status == 'interview' &&
              i['candidate_response'] == 'pending')
            for (final response in ['accepted', 'declined'])
              actions.add(
                TextButton(
                  onPressed: () => _action(
                    'workforce/v1/interviews/${i['id']}/response',
                    body: {'response': response},
                  ),
                  child: Text('$response interview'),
                ),
              );
        }
    } else if (widget.kind == 'invitations') {
      lines.add(row['job_summary']?.toString() ?? '');
      lines.add('Expires: ${row['expires_at']}');
      if (widget.role == 'candidate' && status == 'pending')
        for (final next in ['accepted', 'declined'])
          actions.add(
            TextButton(
              onPressed: () => _action(
                'workforce/v1/invitations/$id/response',
                body: {'status': next},
              ),
              child: Text(next == 'accepted' ? 'Accept invitation' : 'Decline'),
            ),
          );
      if (['accepted', 'closed'].contains(status))
        actions.add(
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => CareerConversation(
                  api: widget.api,
                  id: id,
                  closed: status == 'closed',
                ),
              ),
            ),
            child: const Text('Messages'),
          ),
        );
      if (widget.role == 'candidate' &&
          status == 'accepted' &&
          row['job_id'] is num)
        actions.add(
          TextButton(
            onPressed: () => _apply((row['job_id'] as num).toInt()),
            child: const Text('Apply to vacancy'),
          ),
        );
      if (status == 'accepted')
        actions.add(
          TextButton(
            onPressed: () => _confirm(
              'Close this recruitment conversation?',
              'workforce/v1/invitations/$id/response',
              {'status': 'closed'},
            ),
            child: const Text('Close conversation'),
          ),
        );
      actions.add(
        TextButton(
          onPressed: () => _form('Report recruitment concern', const [
            CareerField(
              'reason',
              'Reason',
              options: ['scam', 'harassment', 'unauthorized_data', 'other'],
            ),
          ], 'workforce/v1/invitations/$id/report'),
          child: const Text('Report'),
        ),
      );
    } else if (widget.kind == 'recruiters') {
      lines.add(row['organization_name']?.toString() ?? '');
      lines.add('Recruitment authority only; no clinical privileges.');
      if (_canInvite &&
          ['pending_review', 'approved', 'accepted'].contains(status))
        actions.add(
          TextButton(
            onPressed: () => _confirm(
              'Revoke this recruiter’s access?',
              'workforce/v1/recruiters/$id/response',
              {'status': 'revoked'},
            ),
            child: const Text('Revoke access'),
          ),
        );
      if (!_canInvite && status == 'approved')
        actions.add(
          TextButton(
            onPressed: () => _confirm(
              'Accept recruitment access for this organization?',
              'workforce/v1/recruiters/$id/response',
              {'status': 'accepted'},
            ),
            child: const Text('Accept access'),
          ),
        );
      if (!_canInvite &&
          ['pending_review', 'approved', 'accepted'].contains(status))
        actions.add(
          TextButton(
            onPressed: () => _confirm(
              'Decline or leave this recruitment role?',
              'workforce/v1/recruiters/$id/response',
              {'status': 'declined'},
            ),
            child: Text(
              status == 'accepted' ? 'Leave organization' : 'Decline',
            ),
          ),
        );
    } else if (widget.kind == 'documents') {
      lines.add('${row['mime']} · ${row['bytes']} bytes');
      actions.add(
        TextButton(
          onPressed: _busy ? null : () => _saveDocument(id),
          child: const Text('Save private document'),
        ),
      );
    } else if (widget.kind == 'courses') {
      lines.addAll([
        row['category']?.toString() ?? '',
        row['description']?.toString() ?? '',
        'Eligibility: ${row['eligibility']}',
        '${row['duration']} · ${row['delivery']}',
        'Fees: ${row['fee_information']}',
        'Schedule: ${row['starts_at'] ?? 'Confirm with CNU'}',
      ]);
      if (widget.role == 'visitor')
        actions.add(
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => WorkforceAccessScreen(
                  accountType: 'candidate',
                  api: widget.api,
                ),
              ),
            ),
            child: const Text('Sign in or create a learner account'),
          ),
        );
      else
        actions.add(
          TextButton(
            onPressed: () => _form('Request CNU enrollment', const [
              CareerField(
                'eligibility_attestation',
                'I have reviewed the course eligibility.',
                kind: 'consent',
              ),
              CareerField(
                'enrollment_terms',
                'I understand this requests administrator confirmation and does not charge payment or guarantee a place.',
                kind: 'consent',
              ),
            ], 'training/v1/courses/$id/enroll'),
            child: const Text('Request enrollment'),
          ),
        );
      final uri = Uri.tryParse(row['website']?.toString() ?? '');
      if (uri != null &&
          uri.scheme == 'https' &&
          uri.userInfo.isEmpty &&
          ['www.cnumedical.com', 'cnumedical.com'].contains(uri.host))
        actions.add(
          TextButton(
            onPressed: () async {
              try {
                if (!await launchUrl(uri, mode: LaunchMode.externalApplication))
                  throw Exception('Unavailable');
              } catch (_) {
                if (mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('CNU website could not be opened.'),
                    ),
                  );
              }
            },
            child: const Text('CNU course information'),
          ),
        );
    } else if (widget.kind == 'enrollments') {
      lines.add('Administrator-recorded progress: ${row['progress']}%');
      if (row['details'] is Map)
        lines.add(row['details']['latest_admin_note']?.toString() ?? '');
      if (row['completion_verified'] == true)
        lines.add('Completion verified by authorized administrator.');
      if (row['certificate_document_id'] is num &&
          row['completion_verified'] == true)
        actions.add(
          TextButton(
            onPressed: () =>
                _saveDocument((row['certificate_document_id'] as num).toInt()),
            child: const Text('Save certificate'),
          ),
        );
      if (['requested', 'confirmed'].contains(status))
        actions.add(
          TextButton(
            onPressed: () => _confirm(
              'Cancel this enrollment request?',
              'training/v1/enrollments/$id/cancel',
              {},
            ),
            child: const Text('Cancel request'),
          ),
        );
    } else if (widget.kind == 'requests') {
      lines.add(
        '${row['participants']} participants · ${row['delivery']} · preferred ${row['preferred_date']}',
      );
      final d = row['details'];
      if (d is Map) {
        if (d['amount_minor'] is num)
          lines.add(
            'Quote: ${d['currency']} ${((d['amount_minor'] as num) / 100).toStringAsFixed(2)} · expires ${d['quote_expires']}',
          );
        for (final k in ['latest_admin_note', 'starts_at', 'facilitator'])
          if (d[k] != null) lines.add(d[k].toString());
      }
      if (status == 'quoted')
        for (final accepted in [true, false])
          actions.add(
            TextButton(
              onPressed: () => _confirm(
                accepted
                    ? 'Accept the quotation? No payment is charged here.'
                    : 'Decline this quotation?',
                'training/v1/requests/$id/response',
                {'accepted': accepted},
              ),
              child: Text(accepted ? 'Accept quotation' : 'Decline'),
            ),
          );
    } else if (widget.kind == 'notifications') {
      lines.add('Received: ${row['created_at']}');
      if (row['read_at'] == null)
        actions.add(
          TextButton(
            onPressed: () => _action('workforce/v1/notifications/$id/read'),
            child: const Text('Mark as read'),
          ),
        );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            for (final line in lines.where((x) => x.isNotEmpty))
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(line),
              ),
            if (actions.isNotEmpty)
              Wrap(spacing: 8, runSpacing: 4, children: actions),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
      actions: [
        IconButton(
          onPressed: _loading ? null : _load,
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (['jobs', 'courses'].contains(widget.kind))
                TextField(
                  controller: _search,
                  onSubmitted: (_) {
                    _page = 1;
                    _load();
                  },
                  decoration: InputDecoration(
                    labelText: 'Search ${widget.kind}',
                    suffixIcon: IconButton(
                      onPressed: () {
                        _page = 1;
                        _load();
                      },
                      icon: const Icon(Icons.search),
                    ),
                  ),
                ),
              if (widget.role == 'employer' &&
                  ['jobs', 'requests'].contains(widget.kind))
                FilledButton(
                  onPressed: _busy ? null : _create,
                  child: Text(
                    widget.kind == 'jobs'
                        ? 'Create vacancy'
                        : 'Request training',
                  ),
                ),
              if (widget.kind == 'recruiters') ...[
                const Text(
                  'A verified organization owner invites an existing staff career account. Care360 administrators review staff identity and authority; staff must accept before access is enabled.',
                ),
                if (_canInvite)
                  FilledButton(
                    onPressed: _create,
                    child: const Text('Invite staff recruiter'),
                  ),
              ],
              if (widget.kind == 'candidates')
                Wrap(
                  children: [
                    TextButton.icon(
                      onPressed: _filterCandidates,
                      icon: const Icon(Icons.filter_list),
                      label: const Text('Filter candidates'),
                    ),
                    if (_filters.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          _filters = {};
                          _page = 1;
                          _load();
                        },
                        child: const Text('Clear filters'),
                      ),
                  ],
                ),
              if (widget.kind == 'documents')
                FilledButton.icon(
                  onPressed: _busy ? null : _upload,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload private document'),
                ),
              if (_error != null) ...[
                Text(_error!),
                TextButton(onPressed: _load, child: const Text('Retry')),
              ] else if (_rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No records yet. Approved courses, vacancies and your submitted requests will appear here.',
                  ),
                ),
              for (final row in _rows) _record(row),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                children: [
                  TextButton(
                    onPressed: _page > 1
                        ? () {
                            _page--;
                            _load();
                          }
                        : null,
                    child: const Text('Previous'),
                  ),
                  Text('Page $_page of $_last'),
                  TextButton(
                    onPressed: _page < _last
                        ? () {
                            _page++;
                            _load();
                          }
                        : null,
                    child: const Text('Next'),
                  ),
                ],
              ),
            ],
          ),
  );
}
