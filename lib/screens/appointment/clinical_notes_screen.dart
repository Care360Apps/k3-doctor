import 'package:doctro/model/doctor_note.dart';
import 'package:doctro/brand/care360_professional_role.dart';
import 'package:doctro/constant/preferences.dart';
import 'package:doctro/constant/prefConstatnt.dart';
import 'package:doctro/retrofit/api_header.dart';
import 'package:doctro/retrofit/network_api.dart';
import 'package:flutter/material.dart';
import '../../brand/care360_professional_section_intro.dart';

/// Private, appointment-scoped notes for an approved doctor.
/// Backend permission checks always decide access; this screen is not a gate.
class ClinicalNotesScreen extends StatefulWidget {
  const ClinicalNotesScreen({super.key, required this.appointmentId, this.patientName, this.appointmentReference});

  final int appointmentId;
  final String? patientName;
  final String? appointmentReference;

  @override
  State<ClinicalNotesScreen> createState() => _ClinicalNotesScreenState();
}

class _ClinicalNotesScreenState extends State<ClinicalNotesScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  List<DoctorNote> _notes = const [];
  DoctorNote? _editing;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool get _hasDoctorAccess {
    final token = SharedPreferenceHelper.getString(Preferences.auth_token).trim();
    return Care360ProfessionalRole.canCreatePrescription(
      SharedPreferenceHelper.getString(Preferences.user_role),
    ) && token.isNotEmpty && token != 'N_A' && token != 'null';
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!_hasDoctorAccess || widget.appointmentId <= 0) {
      if (mounted) setState(() {
        _loading = false;
        _notes = const [];
        _error = 'Clinical notes require an approved doctor session.';
      });
      return;
    }
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final result = await RestClient(RetroApi().dioData())
          .doctorNotes(widget.appointmentId);
      if (!mounted) return;
      setState(() {
        _notes = result.success == true ? (result.data ?? []) : [];
        _error = result.success == true ? null : 'Unable to load notes for this appointment.';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Notes are unavailable. Check the connection and your doctor access.';
      });
    }
  }

  void _edit(DoctorNote? note) {
    setState(() {
      _editing = note;
      _title.text = note?.title ?? '';
      _body.text = note?.body ?? '';
    });
  }

  void _read(DoctorNote note) {
    showDialog<void>(context: context, builder: (_) => AlertDialog(
      scrollable: true,
      title: Text(note.title ?? 'Clinical note'),
      content: Care360ClinicalNoteReader(note: note),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
    ));
  }

  void _outline(String type) {
    if (_body.text.trim().isNotEmpty || _title.text.trim().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Start a new empty note to insert an outline. Your draft was kept.')));
      return;
    }
    _title.text = type;
    _body.text = care360ClinicalOutlines[type] ?? '';
  }

  Future<void> _save({required bool finalize}) async {
    if (_saving || !mounted) return;
    if (!_hasDoctorAccess || widget.appointmentId <= 0 ||
        _editing?.status == 'final') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('This account cannot change clinical notes.'),
      ));
      return;
    }
    final title = _title.text.trim();
    final body = _body.text.trim();
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a title and clinical note before saving.')),
      );
      return;
    }
    if (finalize && care360ClinicalOutlines.values.any((outline) => outline.trim() == body)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Complete the clinical findings and plan before finalizing the outline.')));
      return;
    }
    if (finalize) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Finalize this note?'),
          content: const Text(
            'A finalized clinical note is locked against editing. '
            'Corrections must be recorded as a separate addendum.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep editing')),
            FilledButton(onPressed: () => Navigator.pop(context, true),
                child: const Text('Finalize note')),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    if (!_hasDoctorAccess) return;
    setState(() => _saving = true);
    try {
      final client = RestClient(RetroApi().dioData());
      final data = <String, dynamic>{
        'title': title,
        'body': body,
        'status': finalize ? 'final' : 'draft',
      };
      final DoctorNotesResponse result;
      if (_editing?.id != null) {
        result = await client.updateDoctorNote(_editing!.id!, data);
      } else {
        result = await client.createDoctorNote({
          ...data,
          'appointment_id': widget.appointmentId,
        });
      }
      if (!mounted) return;
      if (result.success != true) {
        throw StateError('Note save was not accepted');
      }
      _edit(null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(finalize ? 'Clinical note finalized.' : 'Draft saved.'),
      ));
      await _refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not save the note. No changes were confirmed.'),
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasDoctorAccess || widget.appointmentId <= 0) {
      return Scaffold(
        appBar: AppBar(title: const Text('Clinical notes')),
        body: const Center(child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Clinical notes are available only to authenticated doctors for '
            'their own appointments.',
            textAlign: TextAlign.center,
          ),
        )),
      );
    }
    final theme = Theme.of(context);
    final isEditing = _editing != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F7),
      appBar: AppBar(
        title: const Text('Clinical notes'),
        backgroundColor: const Color(0xFF123E4D),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Care360ProfessionalSectionIntro(
                title: 'Private clinical workspace',
                description: 'Appointment-scoped notes and care plans',
                icon: Icons.lock_person_outlined,
              ),
              if ((widget.patientName ?? '').trim().isNotEmpty)
                Text('Patient: ${widget.patientName}', style: theme.textTheme.titleMedium),
              Text('Appointment: ${widget.appointmentReference ?? widget.appointmentId}'),
              const SizedBox(height: 12),
              Text('Encounter notes', style: theme.textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                'Private notes for this appointment. Only your approved doctor account '
                'can access them. Finalized notes cannot be silently changed.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (_loading) const LinearProgressIndicator(),
              if (_error != null) ...[
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                const SizedBox(height: 8),
                OutlinedButton.icon(onPressed: _refresh,
                    icon: const Icon(Icons.refresh), label: const Text('Retry')),
              ],
              for (final note in _notes) ...[
                Card(
                  child: ListTile(
                    title: Text(note.title ?? 'Untitled'),
                    subtitle: Text(
                      '${note.status == 'final' ? 'Finalized' : 'Draft'}'
                      ' â€¢ ${note.createdAt ?? 'Date unavailable'}',
                    ),
                    leading: Icon(note.status == 'final'
                        ? Icons.verified_user_outlined : Icons.edit_note),
                    trailing: note.status == 'final'
                        ? const Icon(Icons.lock_outline)
                        : const Icon(Icons.chevron_right),
                    onTap: () => note.status == 'final' ? _read(note) : _edit(note),
                  ),
                ),
              ],
              if (!_loading && _notes.isEmpty && _error == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No clinical notes for this appointment yet.'),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(isEditing ? 'Edit draft' : 'New note',
                        style: theme.textTheme.titleMedium),
                  ),
                  if (isEditing)
                    TextButton.icon(
                      onPressed: _saving ? null : () => _edit(null),
                      icon: const Icon(Icons.add),
                      label: const Text('New note'),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              PopupMenuButton<String>(
                tooltip: 'Insert a blank clinical outline',
                enabled: !_saving,
                onSelected: _outline,
                itemBuilder: (_) => care360ClinicalOutlines.keys.map((name) =>
                  PopupMenuItem<String>(value: name, child: Text(name))).toList(),
                child: const Padding(padding: EdgeInsets.symmetric(vertical: 12),
                  child: Row(children: [Icon(Icons.note_add_outlined), SizedBox(width: 8),
                    Flexible(child: Text('Start with a clinical outline'))])),
              ),
              TextField(
                controller: _title,
                maxLength: 160,
                decoration: const InputDecoration(
                  labelText: 'Clinical note title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _body,
                minLines: 6,
                maxLines: 14,
                maxLength: 20000,
                decoration: const InputDecoration(
                  labelText: 'Assessment, observations and care plan',
                  hintText: 'Record your findings, plan and follow-up clearly.',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _saving ? null : () => _save(finalize: false),
                icon: const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Savingâ€¦' : 'Save draft'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _saving ? null : () => _save(finalize: true),
                icon: const Icon(Icons.lock_outline),
                label: const Text('Finalize note'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// Documentation headings only. No findings, diagnoses or treatment are inferred.
const care360ClinicalOutlines = <String, String>{
  'Consultation note': 'Presenting concern:\n\nHistory and current medicines:\n\nAllergies (record status explicitly):\n\nExamination and vitals:\n\nAssessment / diagnosis:\n\nInvestigations requested:\n\nCare plan and patient instructions:\n\nFollow-up and safety-net advice:\n',
  'SOAP note': 'Subjective (patient history):\n\nObjective (observations / examination):\n\nAssessment:\n\nPlan and follow-up:\n',
  'Follow-up note': 'Reason for follow-up:\n\nChanges since previous consultation:\n\nResults reviewed:\n\nAssessment:\n\nUpdated plan and next review:\n',
  'Referral note': 'Reason for referral:\n\nRelevant history and examination:\n\nCurrent medicines and allergies:\n\nInvestigations / results:\n\nReceiving service and urgency:\n\nInformation shared and patient consent:\n',
};

class Care360ClinicalNoteReader extends StatelessWidget {
  const Care360ClinicalNoteReader({super.key, required this.note});
  final DoctorNote note;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
    children: [
      Text('Appointment #${note.appointmentId ?? "Unavailable"}'),
      const SizedBox(height: 8),
      Text(note.status == 'final' ? 'Finalized — read only' : 'Draft'),
      if (note.finalizedAt != null) Text('Finalized: ${note.finalizedAt}'),
      const Divider(height: 24),
      SelectableText(note.body ?? 'Note content is unavailable. Refresh and try again.'),
      if (note.status == 'final') ...[
        const SizedBox(height: 16),
        const Text('Record corrections as a new, clearly referenced addendum. '
          'The original finalized note is retained.'),
      ],
    ],
  );
}
