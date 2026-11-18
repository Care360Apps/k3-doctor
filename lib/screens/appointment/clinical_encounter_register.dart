import 'package:flutter/material.dart';
import 'clinical_workspace_api.dart';
import 'clinical_workspace_screen.dart';

class ClinicalEncounterRegisterScreen extends StatefulWidget {
  const ClinicalEncounterRegisterScreen({super.key, this.api});
  final ClinicalWorkspaceApi? api;
  @override
  State<ClinicalEncounterRegisterScreen> createState() =>
      _ClinicalEncounterRegisterScreenState();
}

class _ClinicalEncounterRegisterScreenState
    extends State<ClinicalEncounterRegisterScreen> {
  late final ClinicalWorkspaceApi _api;
  final _query = TextEditingController();
  bool _loading = true;
  String? _error;
  int _page = 1;
  int _lastPage = 1;
  List<Map<String, dynamic>> _rows = [];
  @override
  void initState() {
    super.initState();
    _api = widget.api ?? ClinicalWorkspaceApi();
    _load();
  }

  @override
  void dispose() {
    _api.close();
    _query.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await _api.encounters(_page, query: _query.text.trim());
      if (!mounted) return;
      setState(() {
        _rows = (d['encounters'] as List)
            .map((r) => Map<String, dynamic>.from(r as Map))
            .toList();
        _lastPage = ((d['meta'] as Map)['last_page'] as num).toInt();
      });
    } catch (e) {
      if (mounted)
        setState(
          () => _error = e is ClinicalWorkspaceFailure
              ? e.message
              : 'Unable to load assigned encounters.',
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Clinical encounter register')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _query,
            maxLength: 120,
            decoration: InputDecoration(
              labelText: 'Search patient name',
              counterText: '',
              suffixIcon: IconButton(
                tooltip: 'Search assigned encounters',
                onPressed: _loading
                    ? null
                    : () {
                        _page = 1;
                        _load();
                      },
                icon: const Icon(Icons.search),
              ),
            ),
            onSubmitted: (_) {
              if (!_loading) {
                _page = 1;
                _load();
              }
            },
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!),
                        TextButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        'Assigned appointments and retained encounter records. Confirm the patient before documenting findings. Appointment booking status is shown separately from clinical records.',
                      ),
                      if (_rows.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No assigned encounters match this search.',
                          ),
                        ),
                      for (final row in _rows)
                        Card(
                          child: ListTile(
                            title: Text('${row['patient_name'] ?? 'Patient'}'),
                            subtitle: Text(
                              '${row['appointment_id'] ?? '#${row['id']}'} | ${row['date'] ?? ''} ${row['time'] ?? ''}\nBooking status: ${row['appointment_status'] ?? 'Unavailable'}',
                            ),
                            isThreeLine: true,
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => ClinicalWorkspaceScreen(
                                  appointmentId: (row['id'] as num).toInt(),
                                  patientName: row['patient_name']?.toString(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: 8,
                        runSpacing: 8,
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
                          Text('Page $_page of $_lastPage'),
                          TextButton(
                            onPressed: _page < _lastPage
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
                ),
        ),
      ],
    ),
  );
}
