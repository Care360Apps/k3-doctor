import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import '../lib/security/consultation_session_client.dart';

void main() {
  Map<String, dynamic> payload({int uid = 1, int id = 9}) => {
    'session_id': id, 'uid': uid, 'cn': 'c${List.filled(48, 'a').join()}',
    'agora_token': 'synthetic-token', 'appId': List.filled(32, 'b').join(),
    'expires_at': DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch ~/ 1000,
  };
  ConsultationSessionClient make(http.Client client, {String base = 'https://example.invalid/api/'}) =>
      ConsultationSessionClient(apiBase: Uri.parse(base), readToken: () async => 'synthetic-auth',
        client: client, expectedUid: 1);
  http.Response response(Map<String, dynamic> data) =>
      http.Response(jsonEncode({'success': true, 'data': data}), 200);

  test('uses exact appointment endpoint and rejects redirects', () async {
    final api = make(MockClient((request) async {
      expect(request.url.toString(), 'https://example.invalid/api/consultations/v1/42/credentials');
      expect(request.method, 'POST');
      expect(request.headers['authorization'], 'Bearer synthetic-auth');
      expect(request.followRedirects, isFalse);
      return response(payload());
    }));
    expect((await api.credentials(42)).uid, 1);
  });
  test('rejects unexpected participant', () async {
    final api = make(MockClient((_) async => response(payload(uid: 2))));
    await expectLater(api.credentials(42), throwsFormatException);
  });
  test('rejects changed session on renewal', () async {
    final api = make(MockClient((_) async => response(payload(id: 10))));
    final previous = ConsultationCredentials.parse(payload());
    await expectLater(api.credentials(42, previous: previous), throwsFormatException);
  });
  test('rejects insecure API before network access', () async {
    final api = make(MockClient((_) async => throw StateError('unexpected network')),
      base: 'http://example.invalid/api/');
    await expectLater(api.credentials(42), throwsFormatException);
  });
  test('rejects oversized response', () async {
    final api = make(MockClient((_) async => http.Response(List.filled(17000, 'a').join(), 200)));
    await expectLater(api.credentials(42), throwsFormatException);
  });
  test('rejects expired credentials', () {
    final data = payload()..['expires_at'] = 1;
    expect(() => ConsultationCredentials.parse(data), throwsFormatException);
  });
  test('does not follow redirect response', () async {
    final api = make(MockClient((_) async => http.Response('', 302,
      headers: {'location': 'https://other.invalid/'})));
    await expectLater(api.credentials(42), throwsStateError);
  });
}
