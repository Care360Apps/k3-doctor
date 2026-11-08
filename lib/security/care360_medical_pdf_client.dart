import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Narrow network boundary for patient prescription PDFs.
///
/// Authenticated documents are fetched only from the configured Care360 API.
/// Never open arbitrary links from an appointment record with an access token.
/// The downloaded bytes are kept in memory until a user explicitly chooses
/// where to save them in the system file picker.
class Care360MedicalPdfClient {
  Care360MedicalPdfClient({
    required this.apiBase,
    required this.readToken,
    http.Client? httpClient,
    this.allowLoopbackHttp = false,
  })  : _client = httpClient ?? http.Client(),
        _ownsClient = httpClient == null;

  final Uri apiBase;
  final Future<String?> Function() readToken;
  final bool allowLoopbackHttp;
  final http.Client _client;
  final bool _ownsClient;

  static const maxPdfBytes = 10 * 1024 * 1024;

  Uri privatePrescriptionUri(int appointmentId) {
    if (appointmentId <= 0) {
      throw const FormatException('Invalid appointment.');
    }
    return apiBase.resolve('medical-files/appointments/$appointmentId/prescription');
  }

  bool isPrivatePrescriptionLink(String? url) {
    final uri = Uri.tryParse(url ?? '');
    return uri != null &&
        RegExp(r'^/api/medical-files/appointments/[1-9][0-9]*/prescription$')
            .hasMatch(uri.path);
  }

  Future<Uint8List> fetchForAppointment(
    int appointmentId, {
    required String? serverPdfUrl,
  }) async {
    final source = (serverPdfUrl ?? '').trim();
    if (source.isEmpty) {
      throw const FormatException('No PDF is available for this appointment.');
    }

    _validateApiBase();
    // For a private PDF, construct our own appointment-scoped API URL rather
    // than trusting the server-supplied path or query.
    final isPrivate = isPrivatePrescriptionLink(source);
    final uri = isPrivate
        ? privatePrescriptionUri(appointmentId)
        : Uri.tryParse(source);
    if (uri == null) {
      throw const FormatException('Invalid prescription link.');
    }
    _requireApprovedOrigin(uri);

    if (!isPrivate) {
      // Temporary compatibility with records not yet migrated from legacy
      // public storage. This never makes old server URLs private.
      if (!RegExp(r'^/prescription/upload/[a-zA-Z0-9_-]{8,100}\.pdf$')
          .hasMatch(uri.path) ||
          uri.hasQuery ||
          uri.hasFragment) {
        throw const FormatException('Untrusted legacy prescription link.');
      }
    }

    final token = isPrivate ? (await readToken())?.trim() : null;
    if (isPrivate && (token == null ||
        token.isEmpty ||
        token == 'N_A' ||
        token == 'null')) {
      throw const MedicalPdfException('Sign in to access this prescription.');
    }

    final request = http.Request('GET', uri)
      ..followRedirects = false
      ..persistentConnection = false
      ..headers['Accept'] = 'application/pdf';
    if (isPrivate) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final response = await _client.send(request);
    if (response.statusCode != 200) {
      throw const MedicalPdfException(
          'Prescription unavailable. Please refresh or contact support.');
    }
    final type = response.headers['content-type']?.toLowerCase() ?? '';
    if (!(type.startsWith('application/pdf') ||
        type.startsWith('application/octet-stream'))) {
      throw const MedicalPdfException('Unexpected document response.');
    }

    final bytes = BytesBuilder(copy: false);
    var total = 0;
    await for (final part in response.stream) {
      total += part.length;
      if (total > maxPdfBytes) {
        throw const MedicalPdfException('Prescription exceeds the file limit.');
      }
      bytes.add(part);
    }
    final pdf = bytes.takeBytes();
    if (pdf.length < 5 ||
        pdf[0] != 0x25 ||
        pdf[1] != 0x50 ||
        pdf[2] != 0x44 ||
        pdf[3] != 0x46 ||
        pdf[4] != 0x2D) {
      throw const MedicalPdfException('Invalid prescription PDF.');
    }
    return pdf;
  }

  void close() {
    if (_ownsClient) _client.close();
  }

  void _validateApiBase() {
    if (apiBase.path.isEmpty ||
        !apiBase.path.endsWith('/api/') ||
        apiBase.hasQuery ||
        apiBase.hasFragment ||
        apiBase.userInfo.isNotEmpty) {
      throw const FormatException('Invalid clinical API configuration.');
    }
    final loopback = apiBase.host == 'localhost' ||
        apiBase.host == '127.0.0.1' ||
        apiBase.host == '::1';
    if (apiBase.scheme != 'https' &&
        !(allowLoopbackHttp && apiBase.scheme == 'http' && loopback)) {
      throw const MedicalPdfException(
          'Secure HTTPS is required for medical document downloads.');
    }
  }

  void _requireApprovedOrigin(Uri uri) {
    if (uri.scheme != apiBase.scheme ||
        uri.host != apiBase.host ||
        uri.port != apiBase.port ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment) {
      throw const FormatException('Prescription link is not from Care360.');
    }
  }
}

class MedicalPdfException implements Exception {
  const MedicalPdfException(this.message);
  final String message;

  @override
  String toString() => message;
}
