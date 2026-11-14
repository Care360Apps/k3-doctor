import 'package:doctro/workforce/career_privacy_screen.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctro/workforce/workforce_api.dart';
import 'package:doctro/workforce/career_workflow_screen.dart';

class FakeCareerApi extends WorkforceApi {
  bool consent = true, open = true, failFirst = false;
  String? offerResponse;
  int calls = 0, accepted = 0;
  final submissions = <Map<String, dynamic>>[];
  @override
  Future<Map<String, dynamic>> catalogue({Map<String, dynamic>? query}) =>
      workflow('training/v1/courses', query: query);
  @override
  Future<Map<String, dynamic>> me() async => {'notice_current': consent};
  @override
  Future<void> acceptNotice() async {
    accepted++;
    consent = true;
  }

  @override
  Future<Map<String, dynamic>> workflow(
    String path, {
    String method = 'get',
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
  }) async {
    if (method == 'post') {
      submissions.add(Map.of(body ?? {}));
      return {
        'success': true,
        'data': {'id': 1},
      };
    }
    if (path == 'career/v1/status')
      return {
        'data': {'workflows_open': open},
      };
    if (path.endsWith('/recruiters'))
      return {
        'data': {
          'can_invite': false,
          'records': {
            'data': [
              {
                'id': 1,
                'name': 'Synthetic staff',
                'organization_name': 'Synthetic organization',
                'status': 'approved',
              },
            ],
            'last_page': 1,
          },
        },
      };
    if (path.endsWith('/jobs')) {
      calls++;
      if (failFirst && calls == 1)
        throw const WorkforceApiException('Synthetic connection failed.');
      final page = query?['page'] ?? 1;
      return {
        'data': {
          'data': [
            {
              'id': page,
              'title': 'Synthetic vacancy $page',
              'status': 'published',
              'description': 'Fictional vacancy details',
              'requirements': 'Synthetic qualification',
              'organization_name': 'Test organization',
              'profession': 'care_assistant',
              'state': 'Lagos',
              'employment_type': 'full_time',
              'closes_on': '2027-01-01',
            },
          ],
          'last_page': 2,
        },
      };
    }
    if (path.endsWith('/applications'))
      return {
        'data': {
          'data': [
            {
              'id': 1,
              'title': 'Synthetic offer',
              'status': 'offered',
              'offer_response': offerResponse,
              'profile': {
                'name': 'Fictional candidate',
                'qualification': 'Test only',
              },
              'interviews': [],
            },
          ],
          'last_page': 1,
        },
      };
    if (path.endsWith('/courses'))
      return {
        'data': {
          'data': [
            {
              'id': 1,
              'title': 'Synthetic CNU course',
              'description': 'Fictional course only',
              'eligibility': 'Test participants',
              'duration': 'One day',
              'delivery': 'virtual',
              'fee_information': 'No payment in this test',
            },
          ],
          'last_page': 1,
        },
      };
    return {
      'data': {'data': [], 'last_page': 1},
    };
  }
}

class CareerAdapter implements HttpClientAdapter {
  CareerAdapter(this.handle);
  final ResponseBody Function(RequestOptions) handle;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async => handle(options);
  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Failed application keeps entries and back navigation offers keep editing',
    (tester) async {
      var attempts = 0;
      final submitted = <Map<String, dynamic>>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => careerForm(
                  context,
                  'Synthetic application',
                  const [
                    CareerField('cover_letter', 'Cover letter'),
                    CareerField(
                      'share_application',
                      'I authorize sharing this application.',
                      kind: 'consent',
                    ),
                  ],
                  (d) async {
                    attempts++;
                    submitted.add(Map.of(d));
                    if (attempts == 1)
                      throw const WorkforceApiException(
                        'Synthetic save failure.',
                      );
                  },
                ),
                child: const Text('Open form'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open form'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField),
        'Fictional application text',
      );
      await tester.tap(find.byType(CheckboxListTile));
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
      expect(find.text('Synthetic save failure.'), findsOneWidget);
      expect(find.text('Fictional application text'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Discard unsaved entries?'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(submitted[0], submitted[1]);
      expect(find.text('Open form'), findsOneWidget);
    },
  );

  testWidgets('An in-flight submit cannot be duplicated or dismissed', (
    tester,
  ) async {
    final pending = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => careerForm(
                context,
                'Synthetic request',
                const [CareerField('topic', 'Topic')],
                (d) {
                  calls++;
                  return pending.future;
                },
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Test topic');
    await tester.tap(find.text('Submit'));
    await tester.pump();
    expect(calls, 1);
    await tester.pageBack();
    await tester.pump();
    expect(find.text('Synthetic request'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Saving…'))
          .onPressed,
      isNull,
    );
    pending.complete();
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets(
    'Career hub requires current privacy consent before exposing workflows',
    (tester) async {
      final api = FakeCareerApi()..consent = false;
      await tester.pumpWidget(
        MaterialApp(
          home: CareerWorkflowHub(api: api, role: 'candidate'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Explore vacancies'), findsNothing);
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Record consent'));
      await tester.tap(find.text('Record consent'));
      await tester.pumpAndSettle();
      expect(api.accepted, 1);
      expect(find.text('Explore vacancies'), findsOneWidget);
    },
  );

  testWidgets(
    'Hiring action is unavailable until the candidate accepts the offer',
    (tester) async {
      final api = FakeCareerApi();
      await tester.pumpWidget(
        MaterialApp(
          home: CareerRecordsScreen(
            api: api,
            role: 'employer',
            kind: 'applications',
            title: 'Applications',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('hired'), findsNothing);
      api.offerResponse = 'offer_accepted';
      await tester.tap(find.byTooltip('Refresh'));
      await tester.pumpAndSettle();
      expect(find.text('Candidate accepted the offer.'), findsOneWidget);
      expect(find.text('hired'), findsOneWidget);
    },
  );

  testWidgets(
    'Vacancy loading errors retry and pagination loads another page',
    (tester) async {
      final api = FakeCareerApi()..failFirst = true;
      await tester.pumpWidget(
        MaterialApp(
          home: CareerRecordsScreen(
            api: api,
            role: 'candidate',
            kind: 'jobs',
            title: 'Vacancies',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Synthetic connection failed.'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Synthetic vacancy 1'), findsOneWidget);
      await tester.ensureVisible(find.text('Next'));
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Synthetic vacancy 2'), findsOneWidget);
    },
  );

  testWidgets(
    'Training requests require both eligibility and enrollment acknowledgements',
    (tester) async {
      final api = FakeCareerApi();
      await tester.pumpWidget(
        MaterialApp(
          home: CareerRecordsScreen(
            api: api,
            role: 'candidate',
            kind: 'courses',
            title: 'Training',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Request enrollment'));
      await tester.tap(find.text('Request enrollment'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
      expect(api.submissions, isEmpty);
      await tester.tap(find.byType(CheckboxListTile).at(0));
      await tester.tap(find.byType(CheckboxListTile).at(1));
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
      expect(api.submissions.single['eligibility_attestation'], true);
      expect(api.submissions.single['enrollment_terms'], true);
    },
  );

  testWidgets('New record layouts remain usable at 320 pixels and large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.6)),
          child: child!,
        ),
        home: CareerRecordsScreen(
          api: FakeCareerApi(),
          role: 'employer',
          kind: 'applications',
          title: 'Applications & interviews',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'A recruiter must explicitly accept reviewed organization access',
    (tester) async {
      final api = FakeCareerApi();
      await tester.pumpWidget(
        MaterialApp(
          home: CareerRecordsScreen(
            api: api,
            role: 'employer',
            kind: 'recruiters',
            title: 'Recruiter access',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Invite staff recruiter'), findsNothing);
      await tester.tap(find.text('Accept access'));
      await tester.pumpAndSettle();
      expect(api.submissions, isEmpty);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(api.submissions.single['status'], 'accepted');
    },
  );

  testWidgets('Visitors can inspect CNU courses without being signed in', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CareerRecordsScreen(
          api: FakeCareerApi(),
          role: 'visitor',
          kind: 'courses',
          title: 'CNU training',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Synthetic CNU course'), findsOneWidget);
    expect(find.text('Request enrollment'), findsNothing);
    await tester.ensureVisible(
      find.text('Sign in or create a learner account'),
    );
    expect(find.text('Sign in or create a learner account'), findsOneWidget);
  });

  testWidgets(
    'Deletion requests need explicit confirmation and are not presented as completed erasure',
    (tester) async {
      final api = FakeCareerApi();
      await tester.pumpWidget(MaterialApp(home: CareerPrivacyScreen(api: api)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Request career account deletion'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Request deletion'),
            )
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Request deletion'));
      await tester.pumpAndSettle();
      expect(api.submissions.single['confirmation'], true);
      expect(
        find.textContaining('A pending request is not completed erasure.'),
        findsOneWidget,
      );
    },
  );

  test(
    'Public catalogue requests never attach a career or clinical token',
    () async {
      final dio = Dio(
        BaseOptions(baseUrl: 'https://care360.example.test/api/'),
      );
      dio.httpClientAdapter = CareerAdapter((o) {
        expect(o.headers.containsKey('Authorization'), isFalse);
        expect(o.followRedirects, isFalse);
        return ResponseBody.fromString(
          '{"success":true,"data":{"data":[],"last_page":1}}',
          200,
          headers: {
            'content-type': ['application/json'],
          },
        );
      });
      final result = await WorkforceApi(dio: dio).catalogue();
      expect(result['success'], true);
      dio.close(force: true);
    },
  );

  test(
    'Career API rejects foreign routes and rejects non-document or oversized streams',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        WorkforceApi.tokenKey: 'synthetic-workforce-token',
      });
      var calls = 0;
      var mode = 'pdf';
      final dio = Dio(
        BaseOptions(baseUrl: 'https://care360.example.test/api/'),
      );
      dio.httpClientAdapter = CareerAdapter((o) {
        calls++;
        expect(o.followRedirects, isFalse);
        expect(o.headers['Authorization'], 'Bearer synthetic-workforce-token');
        if (mode == 'json')
          return ResponseBody.fromString(
            '{}',
            200,
            headers: {
              'content-type': ['application/json'],
            },
          );
        if (mode == 'large')
          return ResponseBody.fromBytes(
            Uint8List(5 * 1024 * 1024 + 1),
            200,
            headers: {
              'content-type': ['application/pdf'],
            },
          );
        return ResponseBody.fromString(
          '%PDF-1.4\nSynthetic only\n%%EOF',
          200,
          headers: {
            'content-type': ['application/pdf'],
          },
        );
      });
      final api = WorkforceApi(dio: dio);
      expect(
        () => api.workflow('https://evil.example.test/api/workforce/v1/jobs'),
        throwsA(isA<WorkforceApiException>()),
      );
      expect(calls, 0);
      expect(
        String.fromCharCodes(await api.downloadDocument(1)),
        startsWith('%PDF-'),
      );
      mode = 'json';
      await expectLater(
        api.downloadDocument(1),
        throwsA(isA<WorkforceApiException>()),
      );
      mode = 'large';
      await expectLater(
        api.downloadDocument(1),
        throwsA(isA<WorkforceApiException>()),
      );
      dio.close(force: true);
      FlutterSecureStorage.setMockInitialValues({});
    },
  );
}
