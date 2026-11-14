import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:doctro/security/care360_medical_pdf_client.dart';

void main() {
  final base = Uri.parse('https://api.example.test/api/');
  const validPdf = '%PDF-1.4\n% test document';

  test('Authenticated medical PDF uses same-origin, nonredirecting GET', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.followRedirects, isFalse);
      expect(request.url.toString(),
          'https://api.example.test/api/medical-files/appointments/12/prescription');
      expect(request.headers['Authorization'], 'Bearer synthetic-token');
      return http.Response(validPdf, 200, headers: {
        'content-type': 'application/pdf',
      });
    });
    final service = Care360MedicalPdfClient(
      apiBase: base,
      httpClient: client,
      readToken: () async => 'synthetic-token',
    );
    final bytes = await service.fetchForAppointment(12,
      serverPdfUrl:
          'https://api.example.test/api/medical-files/appointments/12/prescription');
    expect(String.fromCharCodes(bytes), validPdf);
    service.close();
  });

  test('Legacy publicly hosted PDFs fail closed pending backend migration', () async {
    var requests = 0;
    final service = Care360MedicalPdfClient(
      apiBase: base,
      httpClient: MockClient((request) async {
        requests++;
        return http.Response(validPdf, 200);
      }),
      readToken: () async => 'synthetic-token',
    );
    await expectLater(service.fetchForAppointment(12,
      serverPdfUrl:
        'https://api.example.test/prescription/upload/0123456789abcdef0123456789abcdef.pdf'),
        throwsFormatException);
    expect(requests, 0);
  });

  test('Different appointment and foreign private URLs are rejected', () async {
    var requests = 0;
    final service = Care360MedicalPdfClient(
      apiBase: base,
      httpClient: MockClient((request) async {
        requests++;
        return http.Response(validPdf, 200);
      }),
      readToken: () async => 'synthetic-token',
    );
    for (final link in [
      'https://api.example.test/api/medical-files/appointments/13/prescription',
      'https://other.example/api/medical-files/appointments/12/prescription',
      'https://api.example.test/api/medical-files/appointments/12/prescription?access=public',
    ]) {
      await expectLater(service.fetchForAppointment(12, serverPdfUrl: link),
          throwsFormatException);
    }
    expect(requests, 0);
  });

  test('Foreign host, tampered path and HTTP are rejected before request', () async {
    var calls = 0;
    final service = Care360MedicalPdfClient(
      apiBase: base,
      httpClient: MockClient((_) async {
        calls++;
        return http.Response(validPdf, 200);
      }),
      readToken: () async => 'synthetic-token',
    );
    for (final link in [
      'https://malicious.example/prescription/upload/0123456789abcdef.pdf',
      'http://api.example.test/prescription/upload/0123456789abcdef.pdf',
      'https://api.example.test/other/file.pdf',
      'https://api.example.test/prescription/upload/../../secret.pdf',
      'https://api.example.test/prescription/upload/0123456789abcdef.pdf?token=abc'
    ]) {
      await expectLater(service.fetchForAppointment(12, serverPdfUrl: link),
          throwsFormatException);
    }
    expect(calls, 0);
  });

  test('Private PDF requires a real login token', () async {
    final service = Care360MedicalPdfClient(
      apiBase: base,
      httpClient: MockClient((_) async => http.Response(validPdf, 200)),
      readToken: () async => null,
    );
    await expectLater(service.fetchForAppointment(12, serverPdfUrl:
      'https://api.example.test/api/medical-files/appointments/12/prescription'),
      throwsA(isA<MedicalPdfException>()));
  });

  test('HTTP redirect, error payload, non-PDF and network failure never save data', () async {
    for (final response in [
      http.Response('', 302, headers: {'location':'https://other.example/'}),
      http.Response('{"error":"not found"}', 404,
        headers: {'content-type':'application/json'}),
      http.Response('error', 200, headers: {'content-type':'text/html'}),
      http.Response('not a pdf', 200,
        headers: {'content-type':'application/pdf'}),
    ]) {
      final service = Care360MedicalPdfClient(
        apiBase: base,
        httpClient: MockClient((_) async => response),
        readToken: () async => 'synthetic-token',
      );
      await expectLater(service.fetchForAppointment(12,
        serverPdfUrl:
          'https://api.example.test/api/medical-files/appointments/12/prescription'),
        throwsA(isA<MedicalPdfException>()));
    }
  });

  test('No plaintext HTTP medical files in production mode', () async {
    final service = Care360MedicalPdfClient(
      apiBase: Uri.parse('http://127.0.0.1:8021/api/'),
      httpClient: MockClient((_) async =>
          http.Response(validPdf, 200, headers: {'content-type':'application/pdf'})),
      readToken: () async => 'synthetic-token',
    );
    await expectLater(service.fetchForAppointment(12,
      serverPdfUrl:'http://127.0.0.1:8021/api/medical-files/appointments/12/prescription'),
      throwsA(isA<MedicalPdfException>()));
  });

  test('Token retrieval cannot hang private medical-file access', () async {
    final stalledToken = Completer<String?>();
    final service = Care360MedicalPdfClient(
      apiBase: base,
      networkTimeout: const Duration(milliseconds: 40),
      httpClient: MockClient((_) async =>
          throw StateError('No request may be sent without a token')),
      readToken: () => stalledToken.future,
    );
    await expectLater(
      service.fetchForAppointment(12, serverPdfUrl:
          'https://api.example.test/api/medical-files/appointments/12/prescription'),
      throwsA(isA<MedicalPdfException>()),
    );
  });

  test('Stalled response headers are bounded by a timeout', () async {
    final service = Care360MedicalPdfClient(
      apiBase: base,
      networkTimeout: const Duration(milliseconds: 40),
      httpClient: MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return http.Response(validPdf, 200,
            headers: {'content-type': 'application/pdf'});
      }),
      readToken: () async => 'synthetic-token',
    );
    await expectLater(
      service.fetchForAppointment(12, serverPdfUrl:
          'https://api.example.test/api/medical-files/appointments/12/prescription'),
      throwsA(isA<MedicalPdfException>()),
    );
  });

  test('A trickle of PDF bytes cannot evade the total download deadline', () async {
    final service = Care360MedicalPdfClient(
      apiBase: base,
      networkTimeout: const Duration(milliseconds: 110),
      httpClient: _TricklingPdfClient(),
      readToken: () async => 'synthetic-token',
    );
    await expectLater(
      service.fetchForAppointment(12, serverPdfUrl:
          'https://api.example.test/api/medical-files/appointments/12/prescription'),
      throwsA(isA<MedicalPdfException>()),
    );
  });

  test('Plus clinician opens prescriptions using an in-app private viewer', () {
    final screen = File('lib/screens/home page/patient_information.dart')
        .readAsStringSync();
    final viewer = File('lib/security/care360_protected_pdf_viewer.dart')
        .readAsStringSync();
    final upload = File('lib/pdf_creation/report_pdf.dart')
        .readAsStringSync();

    expect(screen, contains('Care360MedicalPdfClient('));
    expect(screen, contains('Care360ProtectedPdfViewer('));
    expect(screen, contains('SharedPreferenceHelper.getString(Preferences.auth_token)'));
    expect(RegExp(r'onPressed\s*:\s*_openProtectedPrescription\b').hasMatch(screen), isTrue);
    expect(screen, isNot(contains('launchUrl(Uri.parse("\$pdf"))')));
    expect(viewer, contains('SfPdfViewer.memory('));
    expect(viewer, isNot(contains('launchUrl(')));
    expect(viewer, isNot(contains('File(')));
    expect(upload, contains('_sendCare360Prescription(ctx, request)'));
  });
}

class _TricklingPdfClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream<List<int>>.periodic(
        const Duration(milliseconds: 20),
        (_) => '%PDF-1.4\n'.codeUnits,
      ),
      200,
      headers: {'content-type': 'application/pdf'},
    );
  }
}
