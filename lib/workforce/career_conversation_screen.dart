import 'package:flutter/material.dart';
import 'workforce_api.dart';

class CareerConversation extends StatefulWidget {
  const CareerConversation({
    super.key,
    required this.api,
    required this.id,
    required this.closed,
  });
  final WorkforceApi api;
  final int id;
  final bool closed;
  @override
  State<CareerConversation> createState() => _CareerConversationState();
}

class _CareerConversationState extends State<CareerConversation> {
  final _message = TextEditingController();
  List<Map> _messages = [];
  String? _error;
  bool _busy = false;
  int _page = 1, _last = 1;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final r = await widget.api.workflow(
        'workforce/v1/invitations/${widget.id}/messages',
        query: {'page': _page},
      );
      final d = r['data'];
      if (mounted)
        setState(() {
          _messages = d is Map && d['data'] is List
              ? (d['data'] as List).whereType<Map>().toList()
              : [];
          _last = d is Map ? (d['last_page'] as num?)?.toInt() ?? 1 : 1;
          _error = null;
        });
    } catch (e) {
      if (mounted)
        setState(
          () => _error = e is WorkforceApiException
              ? e.message
              : 'Could not load messages.',
        );
    }
  }

  Future<void> _send() async {
    if (_busy || _message.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await widget.api.workflow(
        'workforce/v1/invitations/${widget.id}/messages',
        method: 'post',
        body: {'body': _message.text.trim()},
      );
      _message.clear();
      _page = 1;
      await _load();
    } catch (e) {
      if (mounted)
        setState(
          () => _error = e is WorkforceApiException
              ? e.message
              : 'Not sent. Your message has been kept.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Recruitment conversation'),
      actions: [
        IconButton(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'Do not share patient records, medical details, passwords or payment credentials in recruitment messages.',
        ),
        if (_error != null) Text(_error!),
        if (!widget.closed) ...[
          TextField(
            controller: _message,
            maxLength: 4000,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Recruitment message'),
          ),
          FilledButton(
            onPressed: _busy ? null : _send,
            child: Text(_busy ? 'Sending…' : 'Send'),
          ),
        ],
        for (final m in _messages)
          Card(
            child: ListTile(
              title: Text(m['body']?.toString() ?? ''),
              subtitle: Text(m['created_at']?.toString() ?? ''),
            ),
          ),
        Wrap(
          spacing: 12,
          children: [
            TextButton(
              onPressed: _page > 1
                  ? () {
                      _page--;
                      _load();
                    }
                  : null,
              child: const Text('Newer'),
            ),
            TextButton(
              onPressed: _page < _last
                  ? () {
                      _page++;
                      _load();
                    }
                  : null,
              child: const Text('Older'),
            ),
          ],
        ),
      ],
    ),
  );
}
