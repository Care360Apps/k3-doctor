import 'package:flutter/material.dart';
import 'workforce_api.dart';
import 'career_action_form.dart';
import 'career_draft_guard.dart';

class CareerPortfolioScreen extends StatefulWidget {
  const CareerPortfolioScreen({super.key, required this.api});
  final WorkforceApi api;
  @override
  State<CareerPortfolioScreen> createState() => _CareerPortfolioScreenState();
}

class _CareerPortfolioScreenState extends State<CareerPortfolioScreen> {
  List<Map<String, dynamic>> _education = [], _experience = [];
  final _skills = TextEditingController(),
      _locations = TextEditingController(),
      _preferences = TextEditingController();
  bool _loading = true,
      _share = false,
      _busy = false,
      _edited = false,
      _saved = false,
      _loadFailed = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    for (final c in [_skills, _locations, _preferences])
      c.addListener(() {
        if (!_loading) _edited = true;
      });
    _load();
  }

  @override
  void dispose() {
    _skills.dispose();
    _locations.dispose();
    _preferences.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
      _error = null;
    });
    try {
      final r = await widget.api.workflow('workforce/v1/portfolio');
      final d = r['data'];
      if (d is Map) {
        _education = (d['education'] is List ? d['education'] as List : [])
            .whereType<Map>()
            .map((x) => Map<String, dynamic>.from(x))
            .toList();
        _experience = (d['experience'] is List ? d['experience'] as List : [])
            .whereType<Map>()
            .map((x) => Map<String, dynamic>.from(x))
            .toList();
        _skills.text = d['skills'] is List
            ? (d['skills'] as List).join(', ')
            : '';
        _locations.text = d['preferred_locations'] is List
            ? (d['preferred_locations'] as List).join(', ')
            : '';
        _preferences.text = d['employment_preferences']?.toString() ?? '';
        _share = d['share_training'] == true;
      }
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted)
        setState(() {
          _loading = false;
          _loadFailed = true;
          _error = e is WorkforceApiException
              ? e.message
              : 'Could not load profile.';
        });
    }
  }

  Future<void> _add(bool education) async {
    await careerForm(
      context,
      education ? 'Add education' : 'Add work experience',
      education
          ? const [
              CareerField('institution', 'Institution'),
              CareerField('qualification', 'Qualification'),
              CareerField('year', 'Completion year', kind: 'number'),
            ]
          : const [
              CareerField('organization', 'Organization'),
              CareerField('role', 'Role'),
              CareerField('years', 'Years of experience', kind: 'number'),
            ],
      (d) async {
        setState(() {
          _edited = true;
          (education ? _education : _experience).add(d);
        });
      },
    );
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.workflow(
        'workforce/v1/portfolio',
        method: 'post',
        body: {
          'education': _education,
          'experience': _experience,
          'skills': _skills.text
              .split(',')
              .map((x) => x.trim())
              .where((x) => x.isNotEmpty)
              .toList(),
          'preferred_locations': _locations.text
              .split(',')
              .map((x) => x.trim())
              .where((x) => x.isNotEmpty)
              .toList(),
          'employment_preferences': _preferences.text.trim(),
          'share_training': _share,
        },
      );
      _saved = true;
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted)
        setState(
          () => _error = e is WorkforceApiException
              ? e.message
              : 'Could not save. Entries retained.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => CareerDraftGuard(
    isDirty: () => _edited && !_saved,
    isBusy: () => _busy && !_saved,
    child: Scaffold(
      appBar: AppBar(title: const Text('Education, experience & skills')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadFailed
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error ?? 'Could not load profile.'),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                const Text(
                  'Career records are separate from your clinical records. These entries do not verify qualifications or licenses.',
                ),
                const Text(
                  'Education',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                for (var i = 0; i < _education.length; i++)
                  ListTile(
                    title: Text(
                      '${_education[i]['qualification']} · ${_education[i]['institution']}',
                    ),
                    subtitle: Text('${_education[i]['year']}'),
                    trailing: IconButton(
                      onPressed: () {
                        setState(() {
                          _edited = true;
                          _education.removeAt(i);
                        });
                      },
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Remove education',
                    ),
                  ),
                TextButton(
                  onPressed: () => _add(true),
                  child: const Text('Add education'),
                ),
                const Text(
                  'Work experience',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                for (var i = 0; i < _experience.length; i++)
                  ListTile(
                    title: Text(
                      '${_experience[i]['role']} · ${_experience[i]['organization']}',
                    ),
                    subtitle: Text('${_experience[i]['years']} years'),
                    trailing: IconButton(
                      onPressed: () {
                        setState(() {
                          _edited = true;
                          _experience.removeAt(i);
                        });
                      },
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Remove experience',
                    ),
                  ),
                TextButton(
                  onPressed: () => _add(false),
                  child: const Text('Add experience'),
                ),
                TextField(
                  controller: _skills,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    labelText: 'Skills, separated by commas',
                  ),
                ),
                TextField(
                  controller: _locations,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    labelText: 'Preferred locations, separated by commas',
                  ),
                ),
                TextField(
                  controller: _preferences,
                  maxLength: 1000,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Employment preferences',
                  ),
                ),
                CheckboxListTile(
                  value: _share,
                  onChanged: (v) => setState(() {
                    _edited = true;
                    _share = v == true;
                  }),
                  title: const Text(
                    'Allow verified employers to see my administrator-verified CNU course completions when my profile is discoverable.',
                  ),
                ),
                if (_error != null) Text(_error!),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  child: Text(_busy ? 'Saving…' : 'Save career details'),
                ),
              ],
            ),
    ),
  );
}
