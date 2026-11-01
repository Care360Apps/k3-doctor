import 'package:dio/dio.dart';

/// Sanitized, user-facing API errors. Never expose raw response bodies,
/// account identifiers, tokens, internal URLs or stack traces.
class Care360ConnectionError {
  /// Synthetic/offline Android packages intentionally have no login service.
  /// Treat this as a build limitation, not a user's connectivity problem.
  static bool isOfflinePreview(String apiBaseUrl) {
    final uri = Uri.tryParse(apiBaseUrl);
    final host = uri?.host.toLowerCase() ?? '';
    return host.endsWith('.invalid') ||
        ((host == '127.0.0.1' || host == 'localhost' || host == '::1') &&
            uri?.port == 9);
  }

  static String describe(Object error, {required String apiBaseUrl}) {
    if (isOfflinePreview(apiBaseUrl)) {
      return 'This is an offline Care360 design test. Sign-in is not '
          'connected to a server. Please use a verified staging test build.';
    }

    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return 'Care360 is not reachable right now. Check your connection '
              'and try again.';
        case DioExceptionType.badCertificate:
          return 'Care360 could not verify the server connection securely. '
              'Please try again later.';
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
