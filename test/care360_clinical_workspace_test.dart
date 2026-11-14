import 'package:doctro/screens/appointment/clinical_encounter_register.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctro/screens/appointment/clinical_workspace_api.dart';
import 'package:doctro/screens/appointment/clinical_workspace_screen.dart';
import 'package:doctro/screens/appointment/critical_results_screen.dart';

class ClinicalAdapter implements HttpClientAdapter {
  ClinicalAdapter(this.handle);
  final ResponseBody Function(RequestOptions) handle;
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? s,
    Future<void>? c,
  ) async => handle(o);
  @override
  void close({bool force = false}) {}
}

class FakeClinicalApi extends ClinicalWorkspaceApi {
  FakeClinicalApi()
    : super(dio: Dio(), baseUrl: 'https://care360.example.test/api/');
  final requests = <Map<String, dynamic>>[];
  @override
  Future<Map<String, dynamic>> workspace(int id, {int page = 1}) async => {
    'observations': [],
    'orders': [],
    'labs': [
      {'id': 7, 'name': 'Synthetic laboratory'},
    ],
    'meta': {'last_page': 1},
  };
  @override
  Future<void> order(int id, Map<String, dynamic> data) async {
    requests.add(Map<String, dynamic>.from(data));
    if (requests.length == 1)
      throw const ClinicalWorkspaceFailure(
        'Synthetic connection failure. Entries retained.',
      );
  }
}

class FakeRegisterApi extends FakeClinicalApi {
  int attempts = 0;
  @override
  Future<Map<String, dynamic>> encounters(int page, {String query = ''}) async {
    attempts++;
    if (attempts == 1)
      throw const ClinicalWorkspaceFailure(
        'Synthetic register connection failure',
      );
    return {
      'encounters': [
        {
          'id': 301,
          'patient_name': 'Synthetic registry patient',
          'appointment_id': 'TEST-301',
          'date': '2026-11-09',
          'time': '12:00',
          'appointment_status': 'approved',
        },
      ],
      'meta': {'last_page': 1},
    };
  }
}

void main() {
  test('vital units and unrecorded values remain explicit', () {
    expect(
      parseClinicalVitals({
        'temperature_c': '37.2',
        'weight_kg': '',
        'spo2_percent': '98',
      }),
      {'temperature_c': 37.2, 'spo2_percent': 98},
    );
    expect(parseClinicalVitals({'pulse_bpm': '0'}), {'pulse_bpm': 0});
  });
  test('invalid numeric and percentage entries are rejected', () {
    for (final values in [
      {'pulse_bpm': 'NaN'},
      {'pulse_bpm': '-1'},
      {'spo2_percent': '101'},
      {'unknown': '4'},
      {'temperature_c': 'not measured'},
    ]) {
      expect(() => parseClinicalVitals(values), throwsFormatException);
    }
  });
  test(
    'clinical client uses fixed scoped paths without following redirects',
    () async {
      final dio = Dio(
        BaseOptions(headers: {'Authorization': 'Bearer synthetic-token'}),
      );
      dio.httpClientAdapter = ClinicalAdapter((o) {
        expect(
          o.uri.toString(),
          'https://care360.example.test/api/clinical/appointments/301?page=2',
        );
        expect(o.followRedirects, isFalse);
        expect(o.headers['Authorization'], 'Bearer synthetic-token');
        return ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'data': {'orders': []},
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });
      final api = ClinicalWorkspaceApi(
        dio: dio,
        baseUrl: 'https://care360.example.test/api/',
      );
      expect((await api.workspace(301, page: 2))['orders'], isEmpty);
      api.close();
    },
  );
  test(
    'clinical client blocks remote plaintext before sending credentials',
    () async {
      var sent = false;
      final dio = Dio();
      dio.httpClientAdapter = ClinicalAdapter((o) {
        sent = true;
        return ResponseBody.fromString('{}', 200);
      });
      final api = ClinicalWorkspaceApi(
        dio: dio,
        baseUrl: 'http://remote.example.test/api/',
      );
      await expectLater(
        api.workspace(301),
        throwsA(isA<ClinicalWorkspaceFailure>()),
      );
      expect(sent, isFalse);
      api.close();
    },
  );
  testWidgets(
    'unknown allergies are distinct from assessed no-known allergies',
    (tester) async {
      Map<String, dynamic> record(String status) => {
        'observed_at': '2026-11-09T12:00:00Z',
        'payload': {
          'allergy_status': status,
          'allergies': [],
          'vitals': [],
          'source': 'measured',
        },
      };
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                ClinicalObservationCard(record: record('unknown')),
                ClinicalObservationCard(record: record('none_known')),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Allergies unknown / not assessed'), findsOneWidget);
      expect(find.text('No known allergies - assessed'), findsOneWidget);
    },
  );
  testWidgets(
    'long observation history supports small screens and large text',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: ListView(
                children: [
                  ClinicalObservationCard(
                    record: {
                      'observed_at': '2026-11-09T12:00:00Z',
                      'payload': {
                        'allergy_status': 'reported',
                        'allergies': [
                          {
                            'substance': 'Synthetic substance',
                            'reaction': List.filled(
                              25,
                              'Synthetic reported reaction.',
                            ).join(' '),
                            'severity': 'unknown',
                          },
                        ],
                        'source': 'patient_reported',
                        'vitals': {'systolic_mmHg': 120},
                      },
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(Scrollable), findsWidgets);
    },
  );
  testWidgets(
    'failed referral retains fields and retry uses the same request key',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(480, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeClinicalApi();
      await tester.pumpWidget(
        MaterialApp(
          home: ClinicalWorkspaceScreen(
            appointmentId: 301,
            patientName: 'Synthetic Patient',
            api: api,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Request referral'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Request referral'));
      await tester.pumpAndSettle();
      Finder field(String label) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == label,
      );
      await tester.enterText(
        field('Reason / referral title'),
        'Synthetic referral',
      );
      await tester.enterText(
        field('Clinical indication and relevant information'),
        'Synthetic indication',
      );
      await tester.enterText(
        field('Clinical contact for follow-up'),
        'Synthetic clinic contact - TEST ONLY',
      );
      await tester.tap(find.text('Clinician-selected urgency'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('routine').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        field('Receiving clinician / service'),
        'Synthetic receiving service',
      );
      await tester.tap(find.text('Record request'));
      await tester.pumpAndSettle();
      expect(
        find.text('Synthetic connection failure. Entries retained.'),
        findsOneWidget,
      );
      expect(find.text('Synthetic referral'), findsOneWidget);
      expect(find.text('Synthetic receiving service'), findsOneWidget);
      await tester.tap(find.text('Record request'));
      await tester.pumpAndSettle();
      expect(api.requests.length, 2);
      expect(
        api.requests.first['client_request_id'],
        api.requests.last['client_request_id'],
      );
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'critical acknowledgement requires follow-up and explicit review',
    (tester) async {
      String? saved;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  saved = await clinicalActionNote(
                    context,
                    title: 'Critical review',
                    acknowledgement: true,
                  );
                },
                child: const Text('Open acknowledgement'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open acknowledgement'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Record action'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Record the follow-up and confirm result review to continue.',
        ),
        findsOneWidget,
      );
      await tester.enterText(
        find.byType(TextField),
        'Synthetic follow-up documented',
      );
      await tester.tap(find.text('Record action'));
      await tester.pumpAndSettle();
      expect(saved, isNull);
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Record action'));
      await tester.pumpAndSettle();
      expect(saved, 'Synthetic follow-up documented');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('unsaved observations can be kept or explicitly discarded', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(480, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = FakeClinicalApi();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      ClinicalWorkspaceScreen(appointmentId: 301, api: api),
                ),
              ),
              child: const Text('Open clinical record'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open clinical record'));
    await tester.pumpAndSettle();
    final pulse = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == 'Pulse (beats/min)',
    );
    await tester.ensureVisible(pulse);
    await tester.enterText(pulse, '72');
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Discard unsaved observations?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.text('72'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard unsaved entries'));
    await tester.pumpAndSettle();
    expect(find.text('Open clinical record'), findsOneWidget);
    expect(api.requests, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'clinical register shows retry on failure and loads assigned encounters',
    (tester) async {
      final api = FakeRegisterApi();
      await tester.pumpWidget(
        MaterialApp(home: ClinicalEncounterRegisterScreen(api: api)),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Synthetic register connection failure'),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Synthetic registry patient'), findsOneWidget);
      expect(api.attempts, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
