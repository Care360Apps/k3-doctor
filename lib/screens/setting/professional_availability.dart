import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../retrofit/api_header.dart';
import '../../retrofit/apis.dart';
import '../../retrofit/network_api.dart';

/// Explicit, temporary service-area publication. No passive location tracking.
/// Requires backend migration + NearbyCareController before enabling real shifts.
class ProfessionalAvailabilityScreen extends StatefulWidget {
  const ProfessionalAvailabilityScreen({super.key});

  @override
  State<ProfessionalAvailabilityScreen> createState() =>
      _ProfessionalAvailabilityScreenState();
}

class _ProfessionalAvailabilityScreenState
    extends State<ProfessionalAvailabilityScreen> {
  static const _navy = Color(0xFF15364D);
  static const _teal = Color(0xFF08785E);
  final _lat = TextEditingController();
  final _lng = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _backendReady = false;
  bool _accepting = false;
  bool _locationConsent = false;
  int _radiusKm = 10;
  int _durationMinutes = 60;
  String? _availableUntil;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  Dio _client() {
    // Existing authenticated Care360 Doctor/Provider API client.
    final dio = RetroApi().dioData();
    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 20);
    dio.options.sendTimeout = const Duration(seconds: 20);
    return dio;
  }

  String get _endpoint => Uri.parse(Apis.baseUrl)
      .resolve('professional/presence').toString();

  Map<String, dynamic>? _asMap(dynamic input) {
    if (input is Map<String, dynamic>) return input;
    if (input is Map) return input.map(
      (key, value) => MapEntry(key.toString(), value));
    return null;
  }

  Future<void> _load() async {
    try {
      // A 404/connection error means staging has not installed this feature.
      final response = await _client().get<dynamic>(_endpoint);
      final root = _asMap(response.data);
      final details = _asMap(root?['data']);
      if (root?['success'] != true || details == null) return;
      if (!mounted) return;
      setState(() {
        _backendReady = true;
        _accepting = details['accepting_requests'] == true;
        _radiusKm = ((details['service_radius_km'] as num?)?.toInt() ?? 10)
            .clamp(1, 50).toInt();
        _availableUntil = details['on_duty_until']?.toString();
        _lat.text = details['public_lat']?.toString() ?? '';
        _lng.text = details['public_lng']?.toString() ?? '';
      });
      if (_lat.text.isEmpty || _lng.text.isEmpty) {
        // Existing profile coordinates are a convenience ONLY. They are
        // NEVER shared publicly until the professional explicitly consents.
        try {
          final profile = await RestClient(RetroApi().dioData()).doctorProfile();
          if (mounted) {
            setState(() {
              _lat.text = profile.data?.lat?.toString() ?? '';
              _lng.text = profile.data?.lng?.toString() ?? '';
            });
          }
        } catch (_) {
          // A professional may still type a public service-area coordinate.
        }
      }
    } catch (_) {
      // Keep controls disabled until an authenticated backend answers.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save({required bool accepting}) async {
    if (!_backendReady || _saving) return;
    final lat = double.tryParse(_lat.text.trim());
    final lng = double.tryParse(_lng.text.trim());
    if (accepting && (!_locationConsent ||
        lat == null || lng == null ||
        lat < -90 || lat > 90 || lng < -180 || lng > 180 ||
        (lat == 0 && lng == 0))) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Choose a valid public practice/service location '
            'and confirm consent first.'),
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{
        'accepting_requests': accepting ? 1 : 0,
        if (accepting) ...{
          'public_lat': lat,
          'public_lng': lng,
          'service_radius_km': _radiusKm,
          'minutes_on_duty': _durationMinutes,
          'confirm_public_location': 1,
        },
      };
      final response = await _client().post<dynamic>(_endpoint, data: body);
      final root = _asMap(response.data);
      final details = _asMap(root?['data']);
      if (root?['success'] != true || details == null) {
        throw StateError('Shift confirmation not received');
      }
      if (!mounted) return;
      setState(() {
        _accepting = details['accepting_requests'] == true;
        _availableUntil = details['on_duty_until']?.toString();
        _locationConsent = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_accepting
          ? 'Accepting nearby requests until the shift expires. '
            'Actual appointments still require booking confirmation.'
          : 'You are no longer accepting Nearby Care requests.'),
      ));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Unable to save availability. Check your connection '
              'or professional approval and retry.'),
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final until = DateTime.tryParse(_availableUntil ?? '')?.toLocal();
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F6),
      appBar: AppBar(
        title: const Text('Nearby Care availability'),
        backgroundColor: Colors.white,
        foregroundColor: _navy,
      ),
      body: SafeArea(
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: const Color(0xFFE5F3EC),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your public service area',
                      style: TextStyle(color: _navy, fontSize: 20,
                        fontWeight: FontWeight.w800)),
                    const SizedBox(height: 9),
                    const Text('Patients can discover your approved professional '
                      'profile near a service location you explicitly publish. '
                      'Do not use your private residence unless it is a public '
                      'business address you intend patients to see. '
                      'This never enables continuous live GPS tracking.',
                      style: TextStyle(height: 1.45)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Icon(_accepting ? Icons.check_circle : Icons.pause_circle,
                        color: _accepting ? _teal : Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_accepting
                          ? 'Accepting requests (not a confirmed booking)'
                          : 'Offline for new nearby requests',
                        style: const TextStyle(fontWeight: FontWeight.w700))),
                    ]),
                    if (_accepting && until != null) ...[
                      const SizedBox(height: 6),
                      Text('Automatically ends at ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(until))}'),
                    ],
                  ],
                ),
              ),
            ),
            if (!_backendReady) ...[
              const SizedBox(height: 10),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('The availability service is not yet enabled '
                    'on the connected Care360 backend. '
                    'Your existing profile and consultations remain unchanged.'),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _lat,
              enabled: _backendReady && !_saving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true, signed: true),
              decoration: const InputDecoration(
                labelText: 'Public service latitude',
                helperText: 'Practice/service-area point, not live GPS',
                border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lng,
              enabled: _backendReady && !_saving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true, signed: true),
              decoration: const InputDecoration(
                labelText: 'Public service longitude',
                helperText: 'Verify this is safe for patients to see',
                border: OutlineInputBorder()),
            ),
            const SizedBox(height: 18),
            Text('Home-visit service radius: $_radiusKm km',
              style: const TextStyle(fontWeight: FontWeight.w700)),
            Slider(
              min: 1, max: 50, divisions: 49, value: _radiusKm.toDouble(),
              onChanged: _backendReady && !_saving
                ? (value) => setState(() => _radiusKm = value.round())
                : null),
            const SizedBox(height: 4),
            DropdownButtonFormField<int>(
              value: _durationMinutes,
              decoration: const InputDecoration(
                labelText: 'Accept requests for',
                border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 30, child: Text('30 minutes')),
                DropdownMenuItem(value: 60, child: Text('1 hour')),
                DropdownMenuItem(value: 120, child: Text('2 hours')),
                DropdownMenuItem(value: 240, child: Text('4 hours')),
              ],
              onChanged: _backendReady && !_saving
                ? (v) => setState(() => _durationMinutes = v ?? 60)
                : null,
            ),
            const SizedBox(height: 10),
            CheckboxListTile(
              key: const Key('public-service-point-consent'),
              value: _locationConsent,
              onChanged: _backendReady && !_saving
                ? (v) => setState(() => _locationConsent = v ?? false)
                : null,
              title: const Text('I approve publishing this service-area location'),
              subtitle: const Text('I confirm this is a professional/public '
                'location, not a private home or live device position.'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('go-online-nearby-care'),
              style: FilledButton.styleFrom(
                backgroundColor: _teal,
                minimumSize: const Size.fromHeight(52)),
              onPressed: _backendReady && !_saving
                ? () => _save(accepting: true) : null,
              icon: const Icon(Icons.location_on_outlined),
              label: Text(_accepting ? 'Renew available shift' :
                'Start accepting requests'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('go-offline-nearby-care'),
              onPressed: _backendReady && !_saving && _accepting
                ? () => _save(accepting: false) : null,
              icon: const Icon(Icons.pause_circle_outline),
              label: const Text('Stop accepting requests'),
            ),
            const SizedBox(height: 18),
            const Text('Only approved and active professionals can publish '
              'availability. This is not an emergency dispatch service. '
              'A patient request still requires professional acceptance '
              'and booking confirmation.',
              style: TextStyle(fontSize: 12, height: 1.45,
                color: Color(0xFF53656C))),
          ],
        ),
      ),
    );
  }
}
