import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../retrofit/apis.dart';
import 'workforce_notice_gate.dart';

/// The Workforce API uses a *separate* 64-character opaque session token.
/// Do not reuse Retrofit/Patient OAuth interceptors or clinical Firestore chat.
class WorkforceApi {
  WorkforceApi({Dio? dio, FlutterSecureStorage? storage})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: Apis.baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
              sendTimeout: const Duration(seconds: 20),
              followRedirects: false,
              headers: const {'Accept': 'application/json'},
            ),
          ),
      _storage = storage ?? const FlutterSecureStorage();

  static const tokenKey = 'care360_workforce_session';
  final Dio _dio;
  final FlutterSecureStorage _storage;

  /// Workforce credentials are never sent over plaintext HTTP, even if the
  /// separate Patient API was configured for a LAN debugging session.
  void _requireSecureWorkforceOrigin() {
    final base = Uri.tryParse(_dio.options.baseUrl);
    if (base == null ||
        base.host.isEmpty ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment ||
        base.path != '/api/') {
      throw const WorkforceApiException('Invalid Workforce API configuration.');
    }
    if (base.scheme == 'https') return;

    // The exception is ONLY for a deliberately opted-in loopback debug build,
    // never a remote LAN device, raw IP or public plain-HTTP hostname.
    const localOnly = bool.fromEnvironment(
      'K3_ALLOW_LOCAL_WORKFORCE_HTTP',
      defaultValue: false,
    );
    final loopback =
        base.host == 'localhost' ||
        base.host == '127.0.0.1' ||
        base.host == '::1';
    if (kDebugMode && localOnly && base.scheme == 'http' && loopback) return;

    throw const WorkforceApiException(
      'Secure HTTPS is required for Workforce accounts.',
    );
  }

  Future<bool> applicationsOpen() async {
    try {
      _requireSecureWorkforceOrigin();
      final response = await _dio.get('workforce/v1/status');
      final data = _body(response)['data'];
      return data is Map && data['applications_open'] == true;
    } catch (_) {
      return false; // Network uncertainty never opens registrations.
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String accountType,
    required bool adultAttestation,
    required bool acceptedTerms,
  }) async {
    // Transport security is mandatory even when the recruitment notice has
    // not yet been approved. Neither case can submit credentials.
    _requireSecureWorkforceOrigin();
    if (!WorkforceNoticeGate.configured) {
      throw const WorkforceApiException(
        'Workforce registration is paused until its privacy notice is approved.',
      );
    }
    if (WorkforceNoticeGate.localDemo &&
        !RegExp(
          r'^[a-zA-Z0-9._+-]+@care360\.example\.test$',
        ).hasMatch(email.trim())) {
      throw const WorkforceApiException(
        'Local testing requires a fictional @care360.example.test email.',
      );
    }
    final notice = await _registrationNotice();
    await _request(
      'post',
      'workforce/v1/register',
      body: {
        'notice_version': notice,
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'password_confirmation': password,
        'account_type': accountType,
        'adult_attestation': adultAttestation,
        'workforce_terms_accepted': acceptedTerms,
      },
      authenticated: false,
    );
  }

  Future<String> login(String email, String password) async {
    final result = await _request(
      'post',
      'workforce/v1/login',
      body: {'email': email.trim().toLowerCase(), 'password': password},
      authenticated: false,
    );
    final data = result['data'];
    final token = data is Map ? data['token'] : null;
    final role = data is Map ? data['role'] : null;
    if (token is! String ||
        !RegExp(r'^[A-Za-z0-9_-]{60,70}$').hasMatch(token) ||
        (role != 'candidate' && role != 'employer')) {
      throw const FormatException('Workforce login response is invalid.');
    }
    await _storage.write(key: tokenKey, value: token);
    return role as String;
  }

  Future<Map<String, dynamic>> me() async {
    final result = await _request('get', 'workforce/v1/me');
    final data = result['data'];
    if (data is! Map) throw const FormatException('Invalid Workforce profile.');
    return Map<String, dynamic>.from(data);
  }

  Future<void> saveCandidate(Map<String, dynamic> profile) async {
    await _request('post', 'workforce/v1/candidate/profile', body: profile);
  }

  Future<void> saveEmployer(Map<String, dynamic> profile) async {
    await _request('post', 'workforce/v1/employer/profile', body: profile);
  }

  Future<List<Map<String, dynamic>>> searchCandidates({
    String? state,
    String? desiredRole,
  }) async {
    final result = await _request(
      'get',
      'workforce/v1/candidates',
      query: {
        if (state != null && state.isNotEmpty) 'state': state,
        if (desiredRole != null && desiredRole.isNotEmpty)
          'desired_role': desiredRole,
      },
    );
    final data = result['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  Future<String> _registrationNotice() async {
    final result = await _request(
      'get',
      'workforce/v1/status',
      authenticated: false,
    );
    final data = result['data'];
    final notice = data is Map ? data['notice'] : null;
    final version = notice is Map ? notice['version'] : null;
    if (version is! String ||
        (WorkforceNoticeGate.localDemo
            ? version != 'local-demo-v1'
            : (version != WorkforceNoticeGate.configuredVersion ||
                  notice['url'] !=
                      WorkforceNoticeGate.approvedUrl()?.toString()))) {
      throw const WorkforceApiException(
        'The current privacy notice needs review before continuing.',
      );
    }
    return version;
  }

  Future<Map<String, dynamic>> catalogue({Map<String, dynamic>? query}) =>
      _request(
        'get',
        'training/v1/courses',
        query: query,
        authenticated: false,
      );

  Future<void> requestRecovery(String email) async {
    await _request(
      'post',
      'workforce/v1/password-reset/request',
      body: {'email': email.trim().toLowerCase()},
      authenticated: false,
    );
  }

  Future<void> completeRecovery(
    String email,
    String code,
    String password,
  ) async {
    await _request(
      'post',
      'workforce/v1/password-reset/complete',
      body: {
        'email': email.trim().toLowerCase(),
        'code': code.trim().toLowerCase(),
        'password': password,
        'password_confirmation': password,
      },
      authenticated: false,
    );
    await _storage.delete(key: tokenKey);
  }

  Future<void> acceptNotice() async {
    final version = await _registrationNotice();
    await _request(
      'post',
      'workforce/v1/consent',
      body: {'accepted': true, 'notice_version': version},
    );
  }

  Future<Map<String, dynamic>> workflow(
    String path, {
    String method = 'get',
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
  }) {
    if (!RegExp(
          r'^(workforce|training|career)/v1/[a-z]+(/[1-9][0-9]*)?(/[a-z-]+)?$',
        ).hasMatch(path) ||
        !['get', 'post'].contains(method)) {
      throw const WorkforceApiException('Invalid career workflow.');
    }
    return _request(method, path, body: body, query: query);
  }

  Future<void> uploadDocument(String kind, Uint8List bytes, String name) async {
    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024)
      throw const WorkforceApiException(
        'Choose a PDF, JPEG or PNG of 5 MB or less.',
      );
    await _request(
      'post',
      'workforce/v1/documents',
      body: FormData.fromMap({
        'kind': kind,
        'file': MultipartFile.fromBytes(bytes, filename: name),
      }),
    );
  }

  Future<Uint8List> downloadDocument(int id, {bool privacy = false}) async {
    _requireSecureWorkforceOrigin();
    if (id <= 0) throw const WorkforceApiException('Invalid document.');
    final token = await _storage
        .read(key: tokenKey)
        .timeout(const Duration(seconds: 10));
    if (token == null || token.isEmpty)
      throw const WorkforceApiException('Sign in to Workforce first.');
    StreamIterator<Uint8List>? iterator;
    try {
      final response = await _dio
          .get<ResponseBody>(
            privacy
                ? 'workforce/v1/privacy/documents/$id'
                : 'workforce/v1/documents/$id',
            options: Options(
              responseType: ResponseType.stream,
              followRedirects: false,
              headers: {
                'Authorization': 'Bearer $token',
                'Accept': 'application/pdf,image/jpeg,image/png',
              },
            ),
          )
          .timeout(const Duration(seconds: 20));
      final stream = response.data;
      if (stream == null)
        throw const WorkforceApiException('Document unavailable.');
      iterator = StreamIterator(stream.stream);
      final type = response.headers.value('content-type')?.split(';').first;
      if (response.statusCode != 200 ||
          !['application/pdf', 'image/jpeg', 'image/png'].contains(type))
        throw const WorkforceApiException('Document unavailable.');
      final bytes = BytesBuilder(copy: false);
      var count = 0;
      final deadline = DateTime.now().add(const Duration(seconds: 30));
      while (true) {
        final left = deadline.difference(DateTime.now());
        if (left <= Duration.zero) throw TimeoutException('Document deadline');
        if (!await iterator.moveNext().timeout(left)) break;
        count += iterator.current.length;
        if (count > 5 * 1024 * 1024)
          throw const WorkforceApiException('Document exceeds the size limit.');
        bytes.add(iterator.current);
      }
      final data = bytes.takeBytes();
      final pdf =
          data.length >= 5 && String.fromCharCodes(data.take(5)) == '%PDF-';
      final png =
          data.length >= 8 &&
          listEquals(data.take(8).toList(), [137, 80, 78, 71, 13, 10, 26, 10]);
      final jpeg =
          data.length >= 3 &&
          data[0] == 255 &&
          data[1] == 216 &&
          data[2] == 255;
      if (!(type == 'application/pdf' && pdf ||
          type == 'image/png' && png ||
          type == 'image/jpeg' && jpeg))
        throw const WorkforceApiException('Invalid document response.');
      return data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) await _storage.delete(key: tokenKey);
      throw const WorkforceApiException(
        'Document unavailable. Check your session and connection.',
      );
    } finally {
      await iterator?.cancel();
    }
  }

  Future<void> logout() async {
    try {
      await _request('post', 'workforce/v1/logout');
    } finally {
      await _storage.delete(key: tokenKey);
    }
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool authenticated = true,
  }) async {
    _requireSecureWorkforceOrigin();
    final headers = <String, String>{'Accept': 'application/json'};
    if (authenticated) {
      final token = await _storage
          .read(key: tokenKey)
          .timeout(const Duration(seconds: 10));
      if (token == null || token.isEmpty) {
        throw const WorkforceApiException('Sign in to Workforce first.');
      }
      headers['Authorization'] = 'Bearer $token';
    }
    try {
      final response = await _dio.request<dynamic>(
        path,
        options: Options(
          method: method.toUpperCase(),
          headers: headers,
          followRedirects: false,
        ),
        data: body,
        queryParameters: query,
      );
      final result = _body(response);
      if (result['success'] != true) {
        throw const WorkforceApiException('Request could not be completed.');
      }
      return result;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        // A revoked token must not remain cached after an authorization
        // failure, even if the user has not opened the logout screen.
        if (authenticated) await _storage.delete(key: tokenKey);
        throw const WorkforceApiException(
          'Your Workforce session has expired. Sign in again.',
        );
      }
      if (error.response?.statusCode == 404) {
        throw const WorkforceApiException(
          'This item is no longer available or you do not have access.',
        );
      }
      if (error.response?.statusCode == 403) {
        throw const WorkforceApiException(
          'Organization approval is required to access this area.',
        );
      }
      if (error.response?.statusCode == 413) {
        throw const WorkforceApiException(
          'This export requires the support-assisted process.',
        );
      }
      if (error.response?.statusCode == 409) {
        if (error.response?.data is Map &&
            error.response?.data['code'] == 'ACCOUNT_CLOSURE_PENDING')
          throw const WorkforceApiException(
            'Career account closure is pending. Use Career data & deletion to export your data or view the request.',
          );
        throw const WorkforceApiException(
          'This action is no longer available or your privacy consent needs updating. Refresh and try again.',
        );
      }
      if (error.response?.statusCode == 422) {
        throw const WorkforceApiException(
          'Check the required fields, dates and verification status. Your entries have been kept.',
        );
      }
      if (error.response?.statusCode == 503) {
        throw const WorkforceApiException(
          'Workforce pilot is not accepting requests yet.',
        );
      }
      throw const WorkforceApiException(
        'Connection unavailable. Please try again.',
      );
    }
  }

  Map<String, dynamic> _body(Response<dynamic> response) {
    final value = response.data;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException('Unexpected Workforce response.');
  }
}

class WorkforceApiException implements Exception {
  const WorkforceApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
