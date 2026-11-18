import 'package:flutter/material.dart';
import 'workforce_api.dart';

/// Paginated selection avoids typing internal candidate/account identifiers.
class CareerRecordChoice extends StatefulWidget {
  const CareerRecordChoice({
    super.key,
    required this.api,
    required this.profession,
  });
  final WorkforceApi api;
  final String profession;
  @override
  State<CareerRecordChoice> createState() => _CareerRecordChoiceState();
}

class _CareerRecordChoiceState extends State<CareerRecordChoice> {
  int _page = 1, _last = 1;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await widget.api.workflow(
        'workforce/v1/candidates',
        query: {'page': _page, 'desired_role': widget.profession},
      );
      if (mounted)
        setState(() {
          _rows = r['data'] is List
              ? (r['data'] as List)
                    .whereType<Map>()
                    .map((x) => Map<String, dynamic>.from(x))
                    .toList()
              : [];
          _last = r['meta'] is Map
              ? (r['meta']['last_page'] as num?)?.toInt() ?? 1
              : 1;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e is WorkforceApiException
              ? e.message
              : 'Could not load candidates.';
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Select a consenting candidate')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_error != null) ...[
                Text(_error!),
                TextButton(onPressed: _load, child: const Text('Retry')),
              ] else if (_rows.isEmpty)
                const Text(
                  'No eligible, consenting candidates match this vacancy.',
                ),
              for (final r in _rows)
                Card(
                  child: ListTile(
                    title: Text(r['display_name']?.toString() ?? 'Candidate'),
                    subtitle: Text(
                      '${r['qualification']} · ${r['institution']} · ${r['state']}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pop(context, r),
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
