import 'package:dio/dio.dart';
import 'package:doctro/retrofit/network_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final provider in [false, true]) {
    test('Plus ' + (provider ? 'provider' : 'doctor') + ' login API contract', () async {
      String? route;
      String? method;
      Map<String, dynamic>? payload;
      final dio = Dio()..interceptors.add(InterceptorsWrapper(
        onRequest: (request, handler) {
          route = request.uri.path;
          method = request.method;
          payload = Map<String, dynamic>.from(request.data as Map);
          handler.resolve(Response(
            requestOptions: request,
            statusCode: 200,
            data: {'success': true, 'msg': 'Synthetic contract OK', 'data': {
              'id': 2001, 'name': 'Synthetic Clinician', 'verify': 1,
              'is_filled': 1, 'token': 'not-a-real-session-token',
              'firebase_custom_token': null,
            }},
          ));
        },
      ));
      final client = RestClient(dio, baseUrl: 'https://staging.example.test/api/');
      final body = {'email': 'clinician@example.test', 'password': 'synthetic-secret'};
      final response = provider ? await client.providerLoginRequest(body)
          : await client.loginRequest(body);
      expect(route, provider ? '/api/provider_login' : '/api/doctor_login');
      expect(method, 'POST');
      expect(payload?['email'], 'clinician@example.test');
      expect(payload?['password'], 'synthetic-secret');
      expect(response.success, isTrue);
      expect(response.data?.id, 2001);
    });
  }
}
