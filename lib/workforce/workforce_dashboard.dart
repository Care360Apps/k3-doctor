import 'career_privacy_screen.dart';
import 'career_workflow_screen.dart';
import 'package:flutter/material.dart';

import 'workforce_api.dart';
import 'workforce_landing.dart';

class WorkforceDashboardScreen extends StatefulWidget {
  const WorkforceDashboardScreen({
    super.key,
    required this.api,
    required this.role,
  });

  final WorkforceApi api;
  final String role;

  @override
  State<WorkforceDashboardScreen> createState() =>
      _WorkforceDashboardScreenState();
}

class _WorkforceDashboardScreenState extends State<WorkforceDashboardScreen> {
  final _form = GlobalKey<FormState>();
  final _institution = TextEditingController();
  final _qualification = TextEditingController();
  static const _roles = <String>[
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
  ];
  String _desiredRoleCode = 'care_assistant';
  final _stateName = TextEditingController();
  final _city = TextEditingController();
  final _organizationName = TextEditingController();
  final _registrationNumber = TextEditingController();
  String _stage = 'student';
  String _shift = 'flexible';
  String _organizationType = 'hospital';
  bool _available = false;
  bool _consentToList = false;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _message;
  String _verification = 'pending';
  List<Map<String, dynamic>> _results = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _fill(TextEditingController controller, dynamic value) {
    controller.text = value is String ? value : '';
  }

  Future<void> _load() async {
    try {
      final details = await widget.api.me();
      if (!mounted) return;
      final data = details['profile'];
      final profile = data is Map ? data : <String, dynamic>{};
      setState(() {
        _verification = (profile['verification_status'] ?? 'pending')
            .toString();
        _fill(_stateName, profile['state']);
        if (widget.role == 'candidate') {
          _fill(_institution, profile['institution']);
          _fill(_qualification, profile['qualification']);
          final role = profile['desired_role']?.toString();
          if (_roles.contains(role)) _desiredRoleCode = role!;
          _fill(_city, profile['city']);
          final stage = profile['career_stage']?.toString();
          if (['student', 'graduate', 'licensed'].contains(stage)) {
            _stage = stage!;
          }
          final shift = profile['shift_preference']?.toString();
          if (['weekdays', 'weekends', 'nights', 'flexible'].contains(shift)) {
            _shift = shift!;
          }
          _available = profile['available_for_work'] == true;
          _consentToList = profile['consent_to_list'] == true;
        } else {
          _fill(_organizationName, profile['organization_name']);
          _fill(_registrationNumber, profile['registration_number']);
          final type = profile['organization_type']?.toString();
          if ([
            'hospital',
            'clinic',
            'pharmacy',
            'laboratory',
            'home_care',
            'other',
          ].contains(type)) {
            _organizationType = type!;
          }
        }
        _loading = false;
      });
    } catch (error) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = error is WorkforceApiException
              ? error.message
              : 'Profile could not be loaded.';
        });
    }
  }

  @override
  void dispose() {
    for (final c in [
      _institution,
      _qualification,
      _stateName,
      _city,
      _organizationName,
      _registrationNumber,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      if (widget.role == 'candidate') {
        await widget.api.saveCandidate({
          'career_stage': _stage,
          'institution': _institution.text.trim(),
          'qualification': _qualification.text.trim(),
          'desired_role': _desiredRoleCode,
          'state': _stateName.text.trim(),
          'city': _city.text.trim(),
          'shift_preference': _shift,
          'available_for_work': _available,
          'consent_to_list': _consentToList,
        });
      } else {
        await widget.api.saveEmployer({
          'organization_name': _organizationName.text.trim(),
          'organization_type': _organizationType,
          'registration_number': _registrationNumber.text.trim(),
          'state': _stateName.text.trim(),
        });
      }
      if (mounted)
        setState(
          () => _message =
              'Saved. Your details remain under independent verification.',
        );
    } catch (error) {
      if (mounted)
        setState(
          () => _message = error is WorkforceApiException
              ? error.message
              : 'Could not save your profile.',
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _search() async {
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final people = await widget.api.searchCandidates();
      if (mounted)
        setState(() {
          _results = people;
          _message = people.isEmpty
              ? 'No approved and available candidates currently match.'
              : null;
        });
    } catch (error) {
      if (mounted)
        setState(
          () => _message = error is WorkforceApiException
              ? error.message
              : 'Candidate search is currently unavailable.',
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await widget.api.logout();
    } catch (_) {}
    if (mounted) Navigator.of(context).pop();
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    int minimum = 2,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          if (required && (value?.trim().length ?? 0) < minimum) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> values,
    ValueChanged<String?> onChange,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: values
            .map(
              (option) => DropdownMenuItem(
                value: option,
                child: Text(option.replaceAll('_', ' ')),
              ),
            )
            .toList(),
        onChanged: onChange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final candidate = widget.role == 'candidate';
    return Scaffold(
      appBar: AppBar(
        title: Text(candidate ? 'My career profile' : 'Hiring organization'),
        actions: [
          IconButton(
            tooltip: 'Career data & deletion',
            icon: const Icon(Icons.privacy_tip_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => CareerPrivacyScreen(api: widget.api),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Sign out of Workforce',
            onPressed: _signOut,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(_error!, key: const Key('workforce-profile-error')),
              ),
            )
          : SafeArea(
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.work_outline),
                        title: const Text('Jobs, applications & CNU training'),
                        subtitle: const Text(
                          'Vacancies, interviews, private documents and training records',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => CareerWorkflowHub(
                              api: widget.api,
                              role: widget.role,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Card(
                      color: const Color(0xFFE8F3EF),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Verification status',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: workforceNavy,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _verification.toUpperCase(),
                              key: const Key('workforce-verification-state'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: workforceTeal,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Only independent reviewers can approve education, '
                              'licences and employer credentials. No applicant '
                              'can approve themselves.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF526A71),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (candidate) ...[
                      _dropdown(
                        'Career stage',
                        _stage,
                        ['student', 'graduate', 'licensed'],
                        (v) => setState(() => _stage = v ?? _stage),
                      ),
                      _field('Training institution', _institution, minimum: 3),
                      _field(
                        'Qualification or programme',
                        _qualification,
                        minimum: 3,
                      ),
                      _dropdown(
                        'Role you seek',
                        _desiredRoleCode,
                        _roles,
                        (v) => setState(
                          () => _desiredRoleCode = v ?? _desiredRoleCode,
                        ),
                      ),
                      if ([
                        'nurse',
                        'community_health_practitioner',
                        'medical_laboratory_scientist',
                        'pharmacist',
                        'doctor',
                      ].contains(_desiredRoleCode))
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                            'This is a regulated profession. Independent '
                            'licence verification is required before you can '
                            'appear in employer searches for this role.',
                            style: TextStyle(color: Color(0xFF8D4E20)),
                          ),
                        ),
                    ] else ...[
                      _field(
                        'Legal organization name',
                        _organizationName,
                        minimum: 3,
                      ),
                      _dropdown(
                        'Organization category',
                        _organizationType,
                        [
                          'hospital',
                          'clinic',
                          'pharmacy',
                          'laboratory',
                          'home_care',
                          'other',
                        ],
                        (v) => setState(
                          () => _organizationType = v ?? _organizationType,
                        ),
                      ),
                      _field(
                        'Registration number',
                        _registrationNumber,
                        minimum: 5,
                      ),
                    ],
                    _field('State', _stateName),
                    if (candidate) ...[
                      _field('City (optional)', _city, required: false),
                      _dropdown(
                        'Preferred shifts',
                        _shift,
                        ['weekdays', 'weekends', 'nights', 'flexible'],
                        (v) => setState(() => _shift = v ?? _shift),
                      ),
                      SwitchListTile(
                        key: const Key('workforce-availability'),
                        title: const Text('Available for work'),
                        subtitle: const Text(
                          'Choose when employers may consider you',
                        ),
                        value: _available,
                        onChanged: (v) => setState(() => _available = v),
                      ),
                      CheckboxListTile(
                        key: const Key('workforce-list-consent'),
                        title: const Text(
                          'Allow approved employers to see my '
                          'professional profile after verification',
                        ),
                        value: _consentToList,
                        onChanged: (v) =>
                            setState(() => _consentToList = v ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                    if (_message != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _message!,
                        key: const Key('workforce-dashboard-message'),
                        style: const TextStyle(color: workforceNavy),
                      ),
                    ],
                    const SizedBox(height: 18),
                    ElevatedButton(
                      key: const Key('workforce-save-profile'),
                      onPressed: _saving ? null : _save,
                      child: Padding(
                        padding: const EdgeInsets.all(13),
                        child: Text(
                          _saving ? 'Saving...' : 'Save Workforce profile',
                        ),
                      ),
                    ),
                    if (!candidate) ...[
                      const SizedBox(height: 20),
                      const Divider(),
                      const Text(
                        'Verified talent',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: workforceNavy,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Only independently approved employers may view '
                        'candidates who explicitly choose to be listed.',
                        style: TextStyle(color: Color(0xFF526A71)),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        key: const Key('workforce-search-candidates'),
                        onPressed: _verification == 'verified' && !_saving
                            ? _search
                            : null,
                        child: const Text('Find available professionals'),
                      ),
                      for (final person in _results)
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: Text(
                              (person['display_name'] ?? '').toString(),
                            ),
                            subtitle: Text(
                              '${person['qualification'] ?? 'Qualification pending'} • '
                              '${person['state'] ?? ''}\n'
                              '${(person['desired_role'] ?? '').toString().replaceAll('_', ' ')}',
                            ),
                            isThreeLine: true,
                            trailing: const Icon(
                              Icons.verified_outlined,
                              color: workforceTeal,
                            ),
                          ),
                        ),
                      if (_results.isNotEmpty)
                        const Text(
                          'Use Jobs, applications & CNU training above for '
                          'recruitment invitations and messages. Candidate contact '
                          'details are protected.',
                          style: TextStyle(color: Color(0xFF536B72)),
                        ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
