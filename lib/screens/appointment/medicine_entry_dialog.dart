import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Appointment-local entry only: written medicines never change the catalogue.
class Care360MedicineEntryDialog extends StatefulWidget {
  const Care360MedicineEntryDialog({super.key, required this.medicines, this.initial});
  final List<String> medicines;
  final Map<String, dynamic>? initial;
  @override
  State<Care360MedicineEntryDialog> createState() => _MedicineEntryState();
}

class _MedicineEntryState extends State<Care360MedicineEntryDialog> {
  final _form = GlobalKey<FormState>();
  final _written = TextEditingController();
  final _days = TextEditingController();
  late final List<String> _options;
  late bool _manual;
  String _catalogueName = '';
  final _times = <String, bool>{
    'morning': false,
    'afternoon': false,
    'night': false,
  };
  @override
  void initState() {
    super.initState();
    _options = widget.medicines
        .map((m) => m.trim())
        .where((m) => m.isNotEmpty)
        .toSet()
        .toList();
    _manual = _options.isEmpty;
    final initial = widget.initial;
    if (initial != null) {
      _manual = true;
      _written.text = initial['name']?.toString() ?? '';
      _days.text = initial['day']?.toString() ?? '';
      for (final time in _times.keys) { _times[time] = initial[time] == true; }
    }
  }

  @override
  void dispose() {
    _written.dispose();
    _days.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Enter a medicine name.';
    if (name.length > 160 || utf8.encode(name).length > 200)
      return 'Shorten the medicine name and strength.';
    if (!_manual && !_options.contains(name))
      return 'Choose a listed medicine or select Write a medicine.';
    return null;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.initial == null ? 'Add medicine' : 'Edit medicine'),
    scrollable: true,
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    content: SizedBox(
      width: 460,
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  key: const Key('medicine-catalogue-mode'),
                  label: const Text('Existing medicines'),
                  selected: !_manual,
                  onSelected: _options.isEmpty
                      ? null
                      : (_) => setState(() => _manual = false),
                ),
                ChoiceChip(
                  key: const Key('medicine-written-mode'),
                  label: const Text('Write a medicine'),
                  selected: _manual,
                  onSelected: (_) => setState(() => _manual = true),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_manual)
              TextFormField(
                key: const Key('medicine-written-name'),
                controller: _written,
                maxLength: 160,
                inputFormatters: [
                  FilteringTextInputFormatter.singleLineFormatter,
                ],
                textCapitalization: TextCapitalization.none,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Medicine name and strength',
                  helperText:
                      'Write exactly what you intend to prescribe. This does not add it to the medicine list.',
                  helperMaxLines: 3,
                ),
                validator: _validateName,
              )
            else
              Autocomplete<String>(
                optionsBuilder: (value) => _options.where(
                  (m) => m.toLowerCase().contains(value.text.toLowerCase()),
                ),
                onSelected: (value) => _catalogueName = value,
                fieldViewBuilder: (context, controller, focus, submit) =>
                    TextFormField(
                      key: const Key('medicine-catalogue-name'),
                      controller: controller,
                      focusNode: focus,
                      decoration: const InputDecoration(
                        labelText: 'Find an existing medicine',
                      ),
                      onChanged: (value) => _catalogueName = value,
                      validator: _validateName,
                    ),
              ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('medicine-duration'),
              controller: _days,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Duration (days)'),
              validator: (value) {
                final days = int.tryParse(value ?? '');
                return days == null || days < 1 || days > 365
                    ? 'Enter a duration between 1 and 365 days.'
                    : null;
              },
            ),
            const SizedBox(height: 12),
            FormField<bool>(
              validator: (_) => _times.values.any((v) => v)
                  ? null
                  : 'Select at least one daily time.',
              builder: (field) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Daily times'),
                  for (final name in _times.keys)
                    CheckboxListTile(
                      key: Key('medicine-time-$name'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${name[0].toUpperCase()}${name.substring(1)}',
                      ),
                      value: _times[name],
                      onChanged: (value) => setState(() {
                        _times[name] = value ?? false;
                        field.didChange(true);
                      }),
                    ),
                  if (field.hasError)
                    Text(
                      field.errorText!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const Key('medicine-add'),
        onPressed: () {
          if (!_form.currentState!.validate()) return;
          Navigator.pop(context, <String, dynamic>{
            'name': (_manual ? _written.text : _catalogueName).trim(),
            'day': int.parse(_days.text).toString(),
            ..._times,
          });
        },
        child: Text(widget.initial == null ? 'Add medicine' : 'Save changes'),
      ),
    ],
  );
}

Future<bool> reviewCare360Prescription(
  BuildContext context, {
  required String patientName,
  required String appointmentReference,
  required List<Map<String, dynamic>> medicines,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review prescription'),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Patient: $patientName'),
            Text('Appointment: $appointmentReference'),
            const SizedBox(height: 12),
            for (final medicine in medicines)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '${medicine['name']}\n${medicine['day']} days · ${['morning', 'afternoon', 'night'].where((t) => medicine[t] == true).join(', ')}',
                ),
              ),
            const Text(
              'Check the patient, spelling, strength and schedule before saving. Medicine names, doses and interactions are not automatically verified.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Go back'),
          ),
          FilledButton(
            key: const Key('prescription-confirm-save'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm and save'),
          ),
        ],
      ),
    ) ??
    false;
