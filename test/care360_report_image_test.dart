import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import '../lib/security/care360_report_image.dart';

void main() {
  final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4z8DwHwAFAAH/iZk9HQAAAABJRU5ErkJggg==',
  );
  final base = Uri.parse('https://staging.example.org/api/');
  final url =
      'https://staging.example.org/api/medical-files/appointments/12/reports/k3report_${'a' * 40}.png';
  Care360ReportImageClient client(
    http.Client httpClient, {
    String? address,
    Future<String?> Function()? token,
  }) => Care360ReportImageClient(
    apiBase: base,
    appointmentId: 12,
    url: address ?? url,
    readToken: token ?? () async => 'synthetic-token',
    clientFactory: () => httpClient,
  );
  test(
    'authenticated PNG uses origin-scoped authorization and no disk cache',
    () async {
      final c = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer synthetic-token');
        expect(request.followRedirects, isFalse);
        expect(request.headers['Cache-Control'], 'no-store');
        return http.Response.bytes(
          png,
          200,
          headers: {'content-type': 'image/png'},
        );
      });
      expect(await client(c).fetch(), png);
    },
  );
  test('legacy transition sends no authorization to public URLs', () async {
    final c = MockClient((request) async {
      expect(request.headers.containsKey('Authorization'), isFalse);
      return http.Response.bytes(
        png,
        200,
        headers: {'content-type': 'image/png'},
      );
    });
    expect(
      await client(
        c,
        address: 'https://staging.example.org/images/upload/synthetic.png',
        token: () async => throw StateError('must not read token'),
      ).fetch(),
      png,
    );
  });
  test(
    'cross-origin, other appointment, traversal and signed query URLs are rejected before HTTP',
    () async {
      var calls = 0;
      for (final address in [
        'https://evil.example.org${Uri.parse(url).path}',
        url.replaceFirst('/12/', '/13/'),
        'https://staging.example.org/api/medical-files/appointments/12/reports/../secret.png',
        '$url?token=never',
        '$url#fragment',
      ]) {
        await expectLater(
          client(
            MockClient((r) async {
              calls++;
              return http.Response('', 200);
            }),
            address: address,
          ).fetch(),
          throwsFormatException,
        );
      }
      expect(calls, 0);
    },
  );
  test('expired session is rejected without a network request', () async {
    var calls = 0;
    await expectLater(
      client(
        MockClient((r) async {
          calls++;
          return http.Response('', 200);
        }),
        token: () async => '',
      ).fetch(),
      throwsFormatException,
    );
    expect(calls, 0);
  });
  test('session changes during download discard received pixels', () async {
    var reads = 0;
    await expectLater(
      client(
        MockClient(
          (r) async => http.Response.bytes(
            png,
            200,
            headers: {'content-type': 'image/png'},
          ),
        ),
        token: () async => ++reads == 1 ? 'old' : 'new',
      ).fetch(),
      throwsFormatException,
    );
  });
  test(
    'redirects, unauthorized replies and wrong MIME never become images',
    () async {
      for (final status in [302, 401, 403, 404, 500]) {
        await expectLater(
          client(
            MockClient(
              (r) async => http.Response.bytes(
                png,
                status,
                headers: {
                  'content-type': 'image/png',
                  'location': 'https://evil.example.org',
                },
              ),
            ),
          ).fetch(),
          throwsFormatException,
        );
      }
      await expectLater(
        client(
          MockClient(
            (r) async => http.Response.bytes(
              png,
              200,
              headers: {'content-type': 'text/html'},
            ),
          ),
        ).fetch(),
        throwsFormatException,
      );
    },
  );
  test('oversized PNGs and decompression dimensions are bounded', () async {
    final bomb = Uint8List.fromList(png);
    ByteData.sublistView(bomb).setUint32(16, 100000);
    await expectLater(
      client(
        MockClient(
          (r) async => http.Response.bytes(
            bomb,
            200,
            headers: {'content-type': 'image/png'},
          ),
        ),
      ).fetch(),
      throwsFormatException,
    );
    await expectLater(
      client(
        MockClient(
          (r) async => http.Response.bytes(
            Uint8List(6 * 1024 * 1024 + 1),
            200,
            headers: {'content-type': 'image/png'},
          ),
        ),
      ).fetch(),
      throwsFormatException,
    );
  });
  testWidgets(
    'failed download offers retry and inactive app hides report pixels',
    (tester) async {
      var calls = 0;
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 240,
                child: Care360ReportImage(
                  apiBase: base,
                  appointmentId: 12,
                  url: url,
                  readToken: () async => 'synthetic',
                  clientFactory: () => MockClient((r) async {
                    calls++;
                    return http.Response.bytes(
                      png,
                      calls == 1 ? 401 : 200,
                      headers: {'content-type': 'image/png'},
                    );
                  }),
                ),
              ),
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.text('Retry'));
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(calls, 2);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(find.byType(Image), findsNothing);
      await tester.runAsync(() async {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(calls, 3);
      expect(tester.takeException(), isNull);
    },
  );
}
