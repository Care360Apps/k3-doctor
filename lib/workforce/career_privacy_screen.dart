import 'dart:convert';
import 'package:flutter/material.dart';
import 'workforce_api.dart';
import 'career_document_picker.dart';

class CareerPrivacyScreen extends StatefulWidget {
  const CareerPrivacyScreen({super.key, required this.api});
  final WorkforceApi api;
  @override
  State<CareerPrivacyScreen> createState() => _CareerPrivacyScreenState();
}

class _CareerPrivacyScreenState extends State<CareerPrivacyScreen> {
  bool _loading = true, _busy = false;
  String? _error;
  List<Map> _requests = [];
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await widget.api.workflow('workforce/v1/privacy');
      final d = r['data'];
      if (mounted)
        setState(() {
          _requests = d is Map && d['data'] is List
              ? (d['data'] as List).whereType<Map>().toList()
              : [];
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = e is WorkforceApiException
              ? e.message
              : 'Could not load privacy requests.';
        });
    }
  }

  Future<void> _export() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await widget.api.workflow('workforce/v1/privacy/export');
      final text = const JsonEncoder.withIndent('  ').convert(r['data']);
      if (utf8.encode(text).length > 10 * 1024 * 1024)
        throw const WorkforceApiException(
          'This export requires the support-assisted process.',
        );
      final saved = await saveCareerExport(text);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              saved
                  ? 'Career export saved to your selected location.'
                  : 'Save cancelled.',
            ),
          ),
        );
    } catch (e) {
      if (mounted)
        setState(
          () => _error = e is WorkforceApiException
              ? e.message
              : 'Export unavailable. Please retry or contact support.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _request() async {
    var accepted = false;
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, update) => AlertDialog(
          title: const Text('Request career account deletion?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Your discoverable profile and new recruitment activity will stop. Organization vacancies will close and recruiter access will be revoked where you own the organization. Export your data first. An authorized reviewer must address lawful retention and complete erasure. Your Patient/Plus clinical account is separate. Deleting career records does not cancel enrollment or payments held separately by CNU; contact CNU about those arrangements.',
                ),
                CheckboxListTile(
                  value: accepted,
                  onChanged: (v) => update(() => accepted = v == true),
                  title: const Text(
                    'I request deletion of my separate career and training account.',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: accepted ? () => Navigator.pop(c, true) : null,
              child: const Text('Request deletion'),
            ),
          ],
        ),
      ),
    );
    if (yes != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.workflow(
        'workforce/v1/privacy',
        method: 'post',
        body: {'confirmation': true},
      );
      await _load();
    } catch (e) {
      if (mounted)
        setState(
          () => _error = e is WorkforceApiException
              ? e.message
              : 'Request not submitted. Please retry.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _document(int id) async {
    setState(() => _busy = true);
    try {
      final bytes = await widget.api.downloadDocument(id, privacy: true);
      await saveCareerDocument(bytes);
    } catch (e) {
      if (mounted)
        setState(
          () => _error = e is WorkforceApiException
              ? e.message
              : 'Document unavailable.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _documents() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final r = await widget.api.workflow('workforce/v1/privacy/export');
      final d = r['data'];
      final docs = d is Map && d['documents'] is List
          ? d['documents'] as List
          : [];
      if (!mounted) return;
      final chosen = await showDialog<int>(
        context: context,
        builder: (c) => SimpleDialog(
          title: const Text('Your private career documents'),
          children: [
            if (docs.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('No private documents.'),
              ),
            for (final doc in docs.whereType<Map>())
              SimpleDialogOption(
                onPressed: () => Navigator.pop(c, (doc['id'] as num).toInt()),
                child: Text('${doc['kind']} · ${doc['created_at']}'),
              ),
          ],
        ),
      );
      if (chosen != null) await _document(chosen);
    } catch (e) {
      if (mounted)
        setState(
          () => _error = e is WorkforceApiException
              ? e.message
              : 'Documents unavailable.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Career data & deletion')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'These controls apply to your separate career, recruitment and CNU training information. Your clinical account and medical records are handled separately.',
        ),
        const SizedBox(height: 12),
        const Text(
          'Exports contain personal information. Save them only to a location you control. Large exports can require support assistance.',
        ),
        FilledButton.icon(
          onPressed: _busy ? null : _export,
          icon: const Icon(Icons.download),
          label: const Text('Export my career data'),
        ),
        TextButton(
          onPressed: _busy ? null : _documents,
          child: const Text('Save my private documents'),
        ),
        const Divider(),
        OutlinedButton(
          onPressed: _busy ? null : _request,
          child: const Text('Request career account deletion'),
        ),
        if (_error != null) ...[
          Text(_error!),
          TextButton(
            onPressed: _busy ? null : _load,
            child: const Text('Retry'),
          ),
        ],
        if (_loading) const Center(child: CircularProgressIndicator()),
        for (final r in _requests)
          Card(
            child: ListTile(
              title: Text('Deletion request #${r['id']}'),
              subtitle: Text('${r['status']} · ${r['created_at']}'),
            ),
          ),
        const Text(
          'A pending request is not completed erasure. Some records may need to be retained under the reviewed policy. Support can use your request reference for follow-up.',
        ),
      ],
    ),
  );
}
