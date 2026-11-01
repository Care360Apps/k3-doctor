import 'package:dio/dio.dart';

/// Sanitized, user-facing API errors. Never show raw HTTP bodies, internal URLs,
/// tokens, stack traces or patient/account identifiers in login notifications.
class Care360ConnectionError {
  static String describe(Object error, {required String apiBaseUrl}) {
    if (apiBaseUrl.contains('127.0.0.1:9') ||
        apiBaseUrl.contains('localhost:9')) {
      return 'This test build is not connected to the Care360 service. '
          'Install a verified connected Android build to sign in.';
    }
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
        case DioExceptionType.badCertificate:
          return 'We could not reach Care360 securely. Check your connection '
              'and try again.';
        case DioExceptionType.badResponse:
          final status = error.response?.statusCode;
          if (status == 401 || status == 403) {
            return 'Your sign-in was not accepted. Check your details and try again.';
          }
          if (status == 429) {
            return 'Too many attempts. Please wait a moment before trying again.';
          }
          if (status != null && status >= 500) {
            return 'Care360 is temporarily unavailable. Please try again later.';
          }
          return 'We could not complete sign-in. Please check your details.';
        case DioExceptionType.cancel:
          return 'The sign-in request was cancelled. Please try again.';
        case DioExceptionType.unknown:
          break;
      }
    }
    return 'We could not complete sign-in. Check your internet connection '
        'and try again.';
  }
}
