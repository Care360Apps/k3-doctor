import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../retrofit/api_header.dart';
import '../../retrofit/apis.dart';

class ClinicalWorkspaceApi {
  ClinicalWorkspaceApi({Dio? dio, String? baseUrl})
    : _dio = dio ?? RetroApi().dioData() {
    _dio.options.baseUrl = baseUrl ?? Apis.baseUrl;
    _dio.options.followRedirects = false;
    _dio.options.contentType = Headers.jsonContentType;
  }
  final Dio _dio;
  void close() => _dio.close();
  void _checkOrigin() {
    final u = Uri.parse(_dio.options.baseUrl);
    final local = ['127.0.0.1', 'localhost', '::1'].contains(u.host);
    if (u.host.isEmpty ||
        u.userInfo.isNotEmpty ||
        u.hasQuery ||
        u.hasFragment ||
        u.path != '/api/' ||
        (u.scheme != 'https' && !(local && u.scheme == 'http')))
      throw const ClinicalWorkspaceFailure(
        'Secure Care360 connection required.',
      );
  }

  Future<Map<String, dynamic>> _request(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    _checkOrigin();
    try {
      final r = body == null
          ? await _dio.get<dynamic>(path)
          : await _dio.post<dynamic>(path, data: body);
      if (r.data is! Map || r.data['success'] != true || r.data['data'] is! Map)
        throw const ClinicalWorkspaceFailure(
          'Unexpected clinical response. Refresh and try again.',
        );
      return Map<String, dynamic>.from(r.data['data'] as Map);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      throw ClinicalWorkspaceFailure(
        status == 401
            ? 'Sign in again to continue.'
            : status == 403 || status == 404
            ? 'This clinical record is unavailable to this account.'
            : status == 409
            ? 'The record cannot make that change. Refresh and check its current status.'
            : status == 422
            ? 'Check the required fields, values and observation time.'
            : 'Unable to connect. Your unsaved entries remain on this screen.',
      );
    }
  }

  Future<Map<String, dynamic>> encounters(int page, {String query = ''}) =>
      _request(
        'clinical/encounters?page=$page&q=${Uri.encodeQueryComponent(query)}',
      );
  Future<Map<String, dynamic>> workspace(int id, {int page = 1}) =>
      _request('clinical/appointments/$id?page=$page');
  Future<void> observe(int id, Map<String, dynamic> data) async {
    await _request('clinical/appointments/$id/observations', body: data);
  }

  Future<void> order(int id, Map<String, dynamic> data) async {
    await _request('clinical/appointments/$id/orders', body: data);
  }

  Future<void> transition(int id, String status, String note) async {
    await _request(
      'clinical/orders/$id/status',
      body: {'status': status, 'note': note},
    );
  }

  Future<Map<String, dynamic>> critical(int page) =>
      _request('clinical/critical-results?page=$page');
  Future<void> acknowledge(int id, String note) async {
    await _request(
      'clinical/critical-results/$id/acknowledge',
      body: {'reviewed_result': true, 'note': note},
    );
  }

  Future<({Uint8List bytes, String extension})> result(int id) async {
    _checkOrigin();
    final r = await _dio.get<ResponseBody>(
      'clinical/orders/$id/result',
      options: Options(
        responseType: ResponseType.stream,
        headers: {'Accept': 'application/pdf,image/png,image/jpeg'},
      ),
    );
    if (r.statusCode != 200 || r.data == null)
      throw const ClinicalWorkspaceFailure('Result unavailable.');
    final bytes = BytesBuilder(copy: false);
    await for (final part in r.data!.stream.timeout(
      const Duration(seconds: 20),
    )) {
      bytes.add(part);
      if (bytes.length > 10 * 1024 * 1024)
        throw const ClinicalWorkspaceFailure(
          'Result exceeds the download limit.',
        );
    }
    final b = bytes.takeBytes();
    final pdf = b.length >= 5 && String.fromCharCodes(b.take(5)) == '%PDF-';
    final png =
        b.length >= 8 &&
        b[0] == 137 &&
        b[1] == 80 &&
        b[2] == 78 &&
        b[3] == 71 &&
        b[4] == 13 &&
        b[5] == 10 &&
        b[6] == 26 &&
        b[7] == 10;
    final jpg = b.length >= 3 && b[0] == 255 && b[1] == 216 && b[2] == 255;
    if (!pdf && !png && !jpg)
      throw const ClinicalWorkspaceFailure('Unsupported result document.');
    return (
      bytes: b,
      extension: pdf
          ? 'pdf'
          : png
          ? 'png'
          : 'jpg',
    );
  }
}

class ClinicalWorkspaceFailure implements Exception {
  const ClinicalWorkspaceFailure(this.message);
  final String message;
}
