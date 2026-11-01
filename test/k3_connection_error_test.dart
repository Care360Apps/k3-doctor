import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctro/retrofit/care360_connection_error.dart';

void main() {
  final request = RequestOptions(path: '/api/login');

  test('Disconnected preview does not mislead users into thinking their credentials failed', () {
    final message = Care360ConnectionError.describe(
      DioException(requestOptions: request, type: DioExceptionType.connectionError),
      apiBaseUrl: 'http://127.0.0.1:9/api/',
    );
    expect(message, contains('test build'));
    expect(message, contains('not connected'));
  });

  test('Real offline APK host is recognized and sign-in is unavailable', () {
    expect(Care360ConnectionError.isOfflinePreview('https://k3-offline.invalid/api/'), isTrue);
    expect(Care360ConnectionError.isOfflinePreview('http://127.0.0.1:9/api/'), isTrue);
    expect(Care360ConnectionError.isOfflinePreview('https://staging.care360.example.com/api/'), isFalse);
    final message = Care360ConnectionError.describe(
      DioException(requestOptions: request, type: DioExceptionType.connectionError),
      apiBaseUrl: 'https://k3-offline.invalid/api/',
    );
    expect(message, contains('offline Care360 design test'));
    expect(message, contains('not connected'));
    expect(message, isNot(contains('Check your connection')));
  });

  test('Network timeouts have nontechnical retry guidance without leaking URLs', () {
    final message = Care360ConnectionError.describe(
      DioException(requestOptions: request, type: DioExceptionType.connectionTimeout),
      apiBaseUrl: 'https://example.test/api/',
    );
    expect(message, contains('Check your connection'));
    expect(message, isNot(contains('example.test')));
  });

  test('API rejects bad credentials without exposing the response body', () {
    final message = Care360ConnectionError.describe(
      DioException(
        requestOptions: request,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: request,
          statusCode: 401,
          data: {'secret': 'must-not-be-displayed'},
        ),
      ),
      apiBaseUrl: 'https://example.test/api/',
    );
    expect(message, contains('sign-in was not accepted'));
    expect(message, isNot(contains('secret')));
  });

  test('Server errors and rate limits get separate feedback', () {
    String messageFor(int code) => Care360ConnectionError.describe(
      DioException(
        requestOptions: request,
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: request, statusCode: code),
      ),
      apiBaseUrl: 'https://example.test/api/',
    );
    expect(messageFor(429), contains('Too many attempts'));
    expect(messageFor(503), contains('temporarily unavailable'));
  });
}
