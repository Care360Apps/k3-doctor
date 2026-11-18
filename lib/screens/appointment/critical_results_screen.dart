import 'clinical_dialog_scope.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'clinical_workspace_api.dart';

Future<void> saveClinicalResult(
  BuildContext context,
  ClinicalWorkspaceApi api,
  int orderId,
) async {
  try {
    final result = await api.result(orderId);
    if (!context.mounted) return;
    await FilePicker.saveFile(
      dialogTitle: 'Save result for clinical review',
      fileName: 'care360-investigation-$orderId.${result.extension}',
      type: FileType.custom,
      allowedExtensions: [result.extension],
      bytes: result.bytes,
    );
  } catch (_) {
    if (context.mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to save the released result. Please retry or contact the laboratory.',
          ),
        ),
      );
  }
}

Future<String?> clinicalActionNote(
  BuildContext context, {
  required String title,
  bool acknowledgement = false,
  String initialText = '',
}) async {
  final text = TextEditingController(text: initialText);
  bool checked = false;
  String? error;
  final result = await showDialog<String>(
    context: context,
    builder: (context) => ClinicalDialogControllerScope(
      controllers: [text],
      child: StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          scrollable: true,
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: text,
                minLines: 3,
                maxLines: 7,
                maxLength: 2000,
                decoration: const InputDecoration(
                  labelText: 'Clinical follow-up / action recorded',
                ),
              ),
              if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red)),
              if (acknowledgement)
                CheckboxListTile(
                  value: checked,
                  onChanged: (v) => setState(() => checked = v ?? false),
                  title: const Text(
                    'I reviewed the released result and recorded the follow-up. Acknowledgement does not mean the concern is resolved.',
                  ),
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
                if (text.text.trim().isEmpty || (acknowledgement && !checked)) {
                  setState(
                    () => error =
                        'Record the follow-up and confirm result review to continue.',
                  );
                  return;
                }
                Navigator.pop(context, text.text.trim());
              },
              child: const Text('Record action'),
            ),
          ],
        ),
      ),
    ),
  );
  return result;
}

class CriticalResultsScreen extends StatefulWidget {
  const CriticalResultsScreen({super.key});
  @override
  State<CriticalResultsScreen> createState() => _CriticalResultsScreenState();
}

class _CriticalResultsScreenState extends State<CriticalResultsScreen> {
  final _api = ClinicalWorkspaceApi();
  bool _loading = true;
  bool _busy = false;
  String? _error;
  int _page = 1;
  int _lastPage = 1;
  List<Map<String, dynamic>> _flags = [];
  final Map<int, String> _draftAcks = {};
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await _api.critical(_page);
      if (!mounted) return;
      setState(() {
        _flags = (d['critical_results'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _lastPage = ((d['meta'] as Map)['last_page'] as num).toInt();
      });
      if (_page > _lastPage) {
        _page = _lastPage;
        await _load();
      }
    } catch (e) {
      if (mounted)
        setState(
          () => _error = e is ClinicalWorkspaceFailure
              ? e.message
              : 'Unable to load critical results.',
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _ack(Map<String, dynamic> f) async {
    if (_busy) return;
    final note = await clinicalActionNote(
      context,
      title: 'Acknowledge critical result',
      acknowledgement: true,
      initialText: _draftAcks[(f['id'] as num).toInt()] ?? '',
    );
    if (note == null || !mounted) return;
    _draftAcks[(f['id'] as num).toInt()] = note;
    setState(() => _busy = true);
    try {
      await _api.acknowledge((f['id'] as num).toInt(), note);
      _draftAcks.remove((f['id'] as num).toInt());
      await _load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ClinicalWorkspaceFailure
                  ? e.message
                  : 'Acknowledgement not saved. Retry.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Critical results'),
      actions: [
        IconButton(
          onPressed: _busy ? null : _load,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh pending acknowledgements',
        ),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(_error!),
            ),
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Manually flagged results awaiting your acknowledgement. Follow your clinical escalation procedure. Refresh this page; app notifications are not a guaranteed urgent contact channel.',
              ),
              if (_flags.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No pending critical acknowledgements for this doctor.',
                  ),
                ),
              for (final f in _flags)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${f['patient_name'] ?? 'Patient'} - appointment #${f['appointment_id']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('${f['request_title'] ?? ''}'),
                        Text('Flagged: ${f['created_at'] ?? ''}'),
                        Text('${f['reason'] ?? ''}'),
                        Text(
                          'Laboratory contact attempt: ${f['contact_attempt'] ?? ''}',
                        ),
                        for (final update
                            in (f['contact_updates'] as List? ?? []))
                          Text(
                            'Contact update ${update['created_at'] ?? ''}: ${update['details'] ?? ''}',
                          ),
                        TextButton.icon(
                          onPressed: _busy
                              ? null
                              : () async {
                                  setState(() => _busy = true);
                                  await saveClinicalResult(
                                    context,
                                    _api,
                                    (f['order_id'] as num).toInt(),
                                  );
                                  if (mounted) setState(() => _busy = false);
                                },
                          icon: const Icon(Icons.download_outlined),
                          label: const Text('Save released result for review'),
                        ),
                        FilledButton(
                          onPressed: _busy ? null : () => _ack(f),
                          child: const Text(
                            'Record acknowledgement and follow-up',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: _page > 1 && !_busy
                        ? () {
                            _page--;
                            _load();
                          }
                        : null,
                    child: const Text('Previous'),
                  ),
                  Text('Page $_page of $_lastPage'),
                  TextButton(
                    onPressed: _page < _lastPage && !_busy
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
