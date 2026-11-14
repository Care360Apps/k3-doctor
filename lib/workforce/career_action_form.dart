import 'package:flutter/material.dart';
import 'workforce_api.dart';
import 'career_draft_guard.dart';

class CareerField {
  const CareerField(
    this.keyName,
    this.label, {
    this.options,
    this.multiline = false,
    this.kind = 'text',
    this.required = true,
  });
  final String keyName, label, kind;
  final List<String>? options;
  final bool multiline, required;
}

/// This route owns controllers until the submission and closing animation finish.
/// Failed submissions keep every entry and leave the dialog open.
class CareerActionForm extends StatefulWidget {
  const CareerActionForm({
    super.key,
    required this.title,
    required this.fields,
    required this.submit,
  });
  final String title;
  final List<CareerField> fields;
  final Future<void> Function(Map<String, dynamic>) submit;
  @override
  State<CareerActionForm> createState() => _CareerActionFormState();
}

class _CareerActionFormState extends State<CareerActionForm> {
  final _key = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _values = {};
  bool _busy = false, _completed = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    for (final f in widget.fields) {
      _controllers[f.keyName] = TextEditingController();
      if (f.options != null) _values[f.keyName] = f.options!.first;
      if (f.kind == 'consent') _values[f.keyName] = false;
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _date(CareerField f) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final date = await showDatePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 3650)),
      initialDate: today,
    );
    if (date == null || !mounted) return;
    if (f.kind == 'datetime') {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time == null || !mounted) return;
      final local = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _values[f.keyName] =
          '${local.toUtc().toIso8601String().split('.').first}+00:00';
      _controllers[f.keyName]!.text =
          '${date.day}/${date.month}/${date.year} ${time.format(context)} (device time)';
    } else {
      final text =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      _values[f.keyName] = text;
      _controllers[f.keyName]!.text = text;
    }
    setState(() {});
  }

  Future<void> _submit() async {
    if (_busy || !_key.currentState!.validate()) return;
    for (final f in widget.fields) {
      if (f.kind == 'consent' && _values[f.keyName] != true) {
        setState(
          () => _error = 'Confirm the consent statement before continuing.',
        );
        return;
      }
    }
    final data = <String, dynamic>{};
    for (final f in widget.fields) {
      if (f.options != null || ['consent', 'date', 'datetime'].contains(f.kind))
        data[f.keyName] = _values[f.keyName];
      else if (f.kind == 'number')
        data[f.keyName] = int.tryParse(_controllers[f.keyName]!.text.trim());
      else
        data[f.keyName] = _controllers[f.keyName]!.text.trim();
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.submit(data);
      _completed = true;
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted)
        setState(
          () => _error = e is WorkforceApiException
              ? e.message
              : 'Could not save. Your entries have been kept.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => CareerDraftGuard(
    isBusy: () => _busy && !_completed,
    isDirty: () =>
        !_completed &&
        (_controllers.values.any((c) => c.text.trim().isNotEmpty) ||
            widget.fields.any(
              (f) => f.kind == 'consent'
                  ? _values[f.keyName] == true
                  : f.options != null && _values[f.keyName] != f.options!.first,
            )),
    child: Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Form(
          key: _key,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              for (final f in widget.fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: f.kind == 'consent'
                      ? CheckboxListTile(
                          value: _values[f.keyName] == true,
                          onChanged: _busy
                              ? null
                              : (v) => setState(
                                  () => _values[f.keyName] = v == true,
                                ),
                          title: Text(f.label),
                          controlAffinity: ListTileControlAffinity.leading,
                        )
                      : f.options != null
                      ? DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: _values[f.keyName] as String?,
                          decoration: InputDecoration(labelText: f.label),
                          items: f.options!
                              .map(
                                (x) => DropdownMenuItem(
                                  value: x,
                                  child: Text(x.replaceAll('_', ' ')),
                                ),
                              )
                              .toList(),
                          onChanged: _busy
                              ? null
                              : (v) => _values[f.keyName] = v,
                        )
                      : TextFormField(
                          controller: _controllers[f.keyName],
                          enabled: !_busy,
                          readOnly: ['date', 'datetime'].contains(f.kind),
                          onTap: ['date', 'datetime'].contains(f.kind)
                              ? () => _date(f)
                              : null,
                          maxLength: f.multiline ? 4000 : 200,
                          maxLines: f.multiline ? 4 : 1,
                          keyboardType: f.kind == 'number'
                              ? TextInputType.number
                              : TextInputType.text,
                          decoration: InputDecoration(
                            labelText: f.label,
                            alignLabelWithHint: true,
                          ),
                          validator: (v) {
                            if (f.required && (v ?? '').trim().isEmpty)
                              return 'This field is required.';
                            if (f.kind == 'number' &&
                                (f.required || (v ?? '').trim().isNotEmpty) &&
                                (int.tryParse(v ?? '') ?? 0) < 1)
                              return 'Enter a positive whole number.';
                            return null;
                          },
                        ),
                ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: Text(_busy ? 'Saving…' : 'Submit'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<bool> careerForm(
  BuildContext context,
  String title,
  List<CareerField> fields,
  Future<void> Function(Map<String, dynamic>) submit,
) async =>
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CareerActionForm(title: title, fields: fields, submit: submit),
      ),
    ) ==
    true;
