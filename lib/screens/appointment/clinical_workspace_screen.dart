import 'clinical_dialog_scope.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'clinical_workspace_api.dart';
import 'critical_results_screen.dart';

const clinicalVitalLabels = <String, String>{
  'systolic_mmHg': 'Systolic blood pressure (mmHg)',
  'diastolic_mmHg': 'Diastolic blood pressure (mmHg)',
  'pulse_bpm': 'Pulse (beats/min)',
  'respiratory_rate_per_min': 'Respiratory rate (breaths/min)',
  'temperature_c': 'Temperature (Celsius)',
  'spo2_percent': 'Oxygen saturation (%)',
  'weight_kg': 'Weight (kg)',
  'height_cm': 'Height (cm)',
};
Map<String, num> parseClinicalVitals(Map<String, String> text) {
  final result = <String, num>{};
  for (final entry in text.entries) {
    final value = entry.value.trim();
    if (value.isEmpty) continue;
    if (!clinicalVitalLabels.containsKey(entry.key))
      throw const FormatException('Unknown vital field.');
    final number = num.tryParse(value);
    if (number == null ||
        !number.isFinite ||
        number < 0 ||
        number > (entry.key == 'spo2_percent' ? 100 : 9999))
      throw FormatException('Check ${clinicalVitalLabels[entry.key]}.');
    result[entry.key] = number;
  }
  return result;
}

class ClinicalWorkspaceScreen extends StatefulWidget {
  const ClinicalWorkspaceScreen({
    super.key,
    required this.appointmentId,
    this.patientName,
    this.api,
  });
  final ClinicalWorkspaceApi? api;
  final int appointmentId;
  final String? patientName;
  @override
  State<ClinicalWorkspaceScreen> createState() =>
      _ClinicalWorkspaceScreenState();
}

class _ClinicalWorkspaceScreenState extends State<ClinicalWorkspaceScreen> {
  late final ClinicalWorkspaceApi _api;
  final _vitals = {
    for (final key in clinicalVitalLabels.keys) key: TextEditingController(),
  };
  String _allergyStatus = 'unknown';
  String _source = 'measured';
  DateTime _observedAt = DateTime.now();
  List<Map<String, String>> _allergies = [];
  bool _loading = true;
  bool _busy = false;
  bool _dirty = false;
  bool _allowPop = false;
  String? _error;
  Map<String, dynamic> _data = {};
  int _historyPage = 1;
  int _lastHistoryPage = 1;
  @override
  void initState() {
    super.initState();
    _api = widget.api ?? ClinicalWorkspaceApi();
    _load();
  }

  @override
  void dispose() {
    _api.close();
    for (final c in _vitals.values) c.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await _api.workspace(widget.appointmentId, page: _historyPage);
      if (mounted)
        setState(() {
          _data = d;
          _lastHistoryPage =
              ((d['meta'] as Map?)?['last_page'] as num?)?.toInt() ?? 1;
        });
    } catch (e) {
      if (mounted)
        setState(
          () => _error = e is ClinicalWorkspaceFailure
              ? e.message
              : 'Unable to load clinical records.',
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _message(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _leave() async {
    if (_busy) return;
    if (!_dirty) {
      setState(() => _allowPop = true);
      Navigator.pop(context);
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard unsaved observations?'),
        content: const Text(
          'Your last saved clinical records will be retained. These unsaved entries will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard unsaved entries'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      setState(() => _allowPop = true);
      Navigator.pop(context);
    }
  }

  Future<void> _time() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _observedAt,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_observedAt),
    );
    if (time == null || !mounted) return;
    final chosen = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (chosen.isAfter(DateTime.now())) {
      _message('Observation time must be in the past or present.');
      return;
    }
    setState(() {
      _observedAt = chosen;
      _dirty = true;
    });
  }

  Future<void> _allergy() async {
    final name = TextEditingController();
    final reaction = TextEditingController();
    String severity = 'unknown';
    final row = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => ClinicalDialogControllerScope(
        controllers: [name, reaction],
        child: StatefulBuilder(
          builder: (context, update) => AlertDialog(
            scrollable: true,
            title: const Text('Record an allergy'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  maxLength: 160,
                  decoration: const InputDecoration(
                    labelText: 'Substance / medicine',
                  ),
                ),
                TextField(
                  controller: reaction,
                  maxLength: 500,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Reported reaction',
                  ),
                ),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: severity,
                  decoration: const InputDecoration(
                    labelText: 'Recorded severity',
                  ),
                  items: ['unknown', 'mild', 'moderate', 'severe']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => update(() => severity = v ?? severity),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (name.text.trim().isEmpty || reaction.text.trim().isEmpty)
                    return;
                  Navigator.pop(context, {
                    'substance': name.text.trim(),
                    'reaction': reaction.text.trim(),
                    'severity': severity,
                  });
                },
                child: const Text('Add allergy'),
              ),
            ],
          ),
        ),
      ),
    );
    if (row != null && mounted)
      setState(() {
        _allergies.add(row);
        _allergyStatus = 'reported';
        _dirty = true;
      });
  }

  Future<void> _status(String? status) async {
    if (status == null) return;
    if (status != 'reported' && _allergies.isNotEmpty) {
      final clear = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remove unsaved allergy entries?'),
          content: const Text(
            'Changing this status will clear the unsaved allergy entries. Previously saved records remain in the history.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep entries'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Change status'),
            ),
          ],
        ),
      );
      if (clear != true || !mounted) return;
    }
    if (mounted)
      setState(() {
        _allergyStatus = status;
        if (status != 'reported') _allergies = [];
        _dirty = true;
      });
  }

  Future<void> _save() async {
    if (_busy) return;
    Map<String, num> values;
    try {
      values = parseClinicalVitals(_vitals.map((k, v) => MapEntry(k, v.text)));
    } on FormatException catch (e) {
      _message(e.message);
      return;
    }
    if (_allergyStatus == 'reported' && _allergies.isEmpty) {
      _message('Add at least one allergy or choose the correct status.');
      return;
    }
    setState(() => _busy = true);
    try {
      await _api.observe(widget.appointmentId, {
        'allergy_status': _allergyStatus,
        'allergies': _allergies,
        'source': _source,
        'observed_at': _observedAt.toUtc().toIso8601String(),
        'vitals': values,
      });
      if (!mounted) return;
      setState(() => _dirty = false);
      _historyPage = 1;
      _message('Observations saved as a new record.');
      await _load();
    } catch (e) {
      _message(
        e is ClinicalWorkspaceFailure
            ? e.message
            : 'Observations not saved. Your entries remain here.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _request(String kind) async {
    if (_busy) return;
    final title = TextEditingController();
    final details = TextEditingController();
    final target = TextEditingController();
    final contact = TextEditingController();
    String? urgency;
    int? lab;
    String? error;
    bool saving = false;
    final labs = (_data['labs'] as List? ?? []).whereType<Map>().toList();
    final requestId = const Uuid().v4();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ClinicalDialogControllerScope(
        controllers: [title, details, target, contact],
        child: StatefulBuilder(
          builder: (context, update) => PopScope(
            canPop: !saving,
            child: AlertDialog(
              scrollable: true,
              title: Text(
                kind == 'referral'
                    ? 'Request referral'
                    : 'Request investigation',
              ),
              content: AbsorbPointer(
                absorbing: saving,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: title,
                      maxLength: 200,
                      decoration: InputDecoration(
                        labelText: kind == 'referral'
                            ? 'Reason / referral title'
                            : 'Investigation / test requested',
                      ),
                    ),
                    TextField(
                      controller: details,
                      minLines: 3,
                      maxLines: 6,
                      maxLength: 4000,
                      decoration: const InputDecoration(
                        labelText:
                            'Clinical indication and relevant information',
                      ),
                    ),
                    TextField(
                      controller: contact,
                      maxLength: 240,
                      decoration: const InputDecoration(
                        labelText: 'Clinical contact for follow-up',
                        helperText:
                            'Reachable clinician / clinic contact details',
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: urgency,
                      decoration: const InputDecoration(
                        labelText: 'Clinician-selected urgency',
                      ),
                      items: ['routine', 'urgent', 'emergency']
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (v) => update(() => urgency = v),
                    ),
                    if (kind == 'referral')
                      TextField(
                        controller: target,
                        maxLength: 240,
                        decoration: const InputDecoration(
                          labelText: 'Receiving clinician / service',
                        ),
                      )
                    else
                      DropdownButtonFormField<int>(
                        initialValue: lab,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Assigned laboratory',
                        ),
                        items: labs
                            .map(
                              (l) => DropdownMenuItem<int>(
                                value: (l['id'] as num).toInt(),
                                child: Text(
                                  '${l['name']}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: labs.isEmpty
                            ? null
                            : (v) => update(() => lab = v),
                      ),
                    const Text(
                      'This records a request. It does not book a test, make a payment or send an external referral. Arrange the receiving service directly; use your urgent escalation procedure where needed.',
                    ),
                    if (error != null)
                      Text(error!, style: const TextStyle(color: Colors.red)),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: saving
                      ? null
                      : () {
                          if (title.text.trim().isEmpty ||
                              details.text.trim().isEmpty ||
                              contact.text.trim().isEmpty ||
                              urgency == null ||
                              (kind == 'referral'
                                  ? target.text.trim().isEmpty
                                  : lab == null)) {
                            update(
                              () => error =
                                  'Complete the required request fields.',
                            );
                            return;
                          }
                          update(() => saving = true);
                          _api
                              .order(widget.appointmentId, {
                                'client_request_id': requestId,
                                'kind': kind,
                                'title': title.text.trim(),
                                'details': details.text.trim(),
                                'clinical_contact': contact.text.trim(),
                                'urgency': urgency,
                                if (kind == 'referral')
                                  'target': target.text.trim(),
                                if (kind == 'investigation') 'lab_id': lab,
                              })
                              .then((_) {
                                if (context.mounted) {
                                  update(() => saving = false);
                                  Navigator.pop(context);
                                }
                                if (mounted) {
                                  _historyPage = 1;
                                  _message('Request recorded.');
                                  _load();
                                }
                              })
                              .catchError((Object e) {
                                if (context.mounted)
                                  update(() {
                                    saving = false;
                                    error = e is ClinicalWorkspaceFailure
                                        ? e.message
                                        : 'Request not saved. Your entries remain here.';
                                  });
                              });
                        },
                  child: Text(saving ? 'Saving...' : 'Record request'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _transition(Map order, String status) async {
    if (_busy) return;
    final note = await clinicalActionNote(
      context,
      title: 'Record ${status.replaceAll('_', ' ')} request',
    );
    if (note == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await _api.transition((order['id'] as num).toInt(), status, note);
      await _load();
    } catch (e) {
      _message(e is ClinicalWorkspaceFailure ? e.message : 'Change not saved.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _allowPop,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _leave();
    },
    child: Scaffold(
      appBar: AppBar(title: const Text('Clinical observations and requests')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(_error!),
                  ),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  '${widget.patientName ?? 'Patient'} - appointment #${widget.appointmentId}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Allergies and vitals',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Record assessed findings with their units and source. Unknown is different from no known allergies. Review allergies and current medicines before prescribing. No values are interpreted automatically.',
                ),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  key: ValueKey(_allergyStatus),
                  initialValue: _allergyStatus,
                  decoration: const InputDecoration(
                    labelText: 'Allergy status',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'unknown',
                      child: Text('Unknown / not assessed'),
                    ),
                    DropdownMenuItem(
                      value: 'none_known',
                      child: Text('No known allergies - assessed'),
                    ),
                    DropdownMenuItem(
                      value: 'reported',
                      child: Text('Allergies reported'),
                    ),
                  ],
                  onChanged: _busy ? null : _status,
                ),
                for (final allergy in _allergies)
                  ListTile(
                    title: Text(allergy['substance']!),
                    subtitle: Text(
                      '${allergy['reaction']} (${allergy['severity']})',
                    ),
                    trailing: IconButton(
                      tooltip: 'Remove unsaved allergy',
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                              _allergies.remove(allergy);
                              _dirty = true;
                            }),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                TextButton.icon(
                  onPressed: _busy ? null : _allergy,
                  icon: const Icon(Icons.add),
                  label: const Text('Add allergy'),
                ),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _source,
                  decoration: const InputDecoration(
                    labelText: 'Vital measurements source',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'measured',
                      child: Text('Measured'),
                    ),
                    DropdownMenuItem(
                      value: 'patient_reported',
                      child: Text('Patient reported'),
                    ),
                  ],
                  onChanged: _busy
                      ? null
                      : (v) => setState(() {
                          _source = v ?? _source;
                          _dirty = true;
                        }),
                ),
                TextButton(
                  onPressed: _busy ? null : _time,
                  child: Text(
                    'Observation time: ${DateFormat.yMd().add_Hm().format(_observedAt)}',
                  ),
                ),
                for (final field in clinicalVitalLabels.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextField(
                      controller: _vitals[field.key],
                      enabled: !_busy,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      maxLength: 10,
                      decoration: InputDecoration(
                        labelText: field.value,
                        helperText: 'Optional - leave blank if not recorded',
                        counterText: '',
                      ),
                      onChanged: (_) => setState(() => _dirty = true),
                    ),
                  ),
                FilledButton(
                  onPressed: _busy || !_dirty ? null : _save,
                  child: Text(_busy ? 'Saving...' : 'Save new observations'),
                ),
                const Divider(height: 32),
                const Text(
                  'Saved observation history',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
                for (final row in (_data['observations'] as List? ?? []))
                  ClinicalObservationCard(
                    record: Map<String, dynamic>.from(row as Map),
                  ),
                const Divider(height: 32),
                const Text(
                  'Investigations and referrals',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
                Wrap(
                  spacing: 10,
                  children: [
                    OutlinedButton(
                      onPressed: _busy ? null : () => _request('investigation'),
                      child: const Text('Request investigation'),
                    ),
                    OutlinedButton(
                      onPressed: _busy ? null : () => _request('referral'),
                      child: const Text('Request referral'),
                    ),
                  ],
                ),
                for (final raw in (_data['orders'] as List? ?? []))
                  Builder(
                    builder: (context) {
                      final o = raw as Map;
                      final payload = o['payload'] as Map;
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '#${o['id']} ${payload['title']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${o['kind']} | ${o['urgency']} | ${o['status']}',
                              ),
                              Text('${payload['details']}'),
                              if (payload['target'] != null)
                                Text('Receiving service: ${payload['target']}'),
                              if (o['report_id'] != null)
                                Text(
                                  'Linked laboratory booking #${o['report_id']}',
                                ),
                              if (o['report_id'] != null)
                                TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () async {
                                          setState(() => _busy = true);
                                          await saveClinicalResult(
                                            context,
                                            _api,
                                            (o['id'] as num).toInt(),
                                          );
                                          if (mounted)
                                            setState(() => _busy = false);
                                        },
                                  child: const Text(
                                    'Save released result for review',
                                  ),
                                ),
                              if (o['status'] == 'requested')
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    if (o['report_id'] == null)
                                      TextButton(
                                        onPressed: _busy
                                            ? null
                                            : () => _transition(o, 'cancelled'),
                                        child: const Text('Cancel request'),
                                      ),
                                    if (o['kind'] == 'referral')
                                      TextButton(
                                        onPressed: _busy
                                            ? null
                                            : () => _transition(o, 'completed'),
                                        child: const Text(
                                          'Record referral completed',
                                        ),
                                      ),
                                    if (o['kind'] == 'investigation' &&
                                        o['report_id'] != null)
                                      TextButton(
                                        onPressed: _busy
                                            ? null
                                            : () => _transition(o, 'reviewed'),
                                        child: const Text(
                                          'Record result reviewed',
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: _historyPage > 1 && !_busy
                          ? () {
                              _historyPage--;
                              _load();
                            }
                          : null,
                      child: const Text('Newer records'),
                    ),
                    Text('Page $_historyPage of $_lastHistoryPage'),
                    TextButton(
                      onPressed: _historyPage < _lastHistoryPage && !_busy
                          ? () {
                              _historyPage++;
                              _load();
                            }
                          : null,
                      child: const Text('Older records'),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const CriticalResultsScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.priority_high),
                  label: const Text('Check critical result acknowledgements'),
                ),
              ],
            ),
    ),
  );
}

class ClinicalObservationCard extends StatelessWidget {
  const ClinicalObservationCard({super.key, required this.record});
  final Map<String, dynamic> record;
  @override
  Widget build(BuildContext context) {
    final p = record['payload'] as Map;
    final status = p['allergy_status'];
    final vitals = p['vitals'] is Map
        ? p['vitals'] as Map
        : <String, dynamic>{};
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Observed: ${record['observed_at'] ?? ''} | ${p['source'] ?? ''}',
            ),
            Text(
              status == 'none_known'
                  ? 'No known allergies - assessed'
                  : status == 'reported'
                  ? 'Allergies reported'
                  : 'Allergies unknown / not assessed',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            for (final a in (p['allergies'] as List? ?? []))
              Text('${a['substance']}: ${a['reaction']} (${a['severity']})'),
            for (final v in vitals.entries)
              Text('${clinicalVitalLabels[v.key] ?? v.key}: ${v.value}'),
            const Text(
              'Saved record retained. Record corrections as a new observation.',
            ),
          ],
        ),
      ),
    );
  }
}
