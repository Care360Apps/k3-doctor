import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Narrow network boundary for patient prescription PDFs.
///
/// Authenticated documents are fetched only from the configured Care360 API.
/// Never open arbitrary links from an appointment record with an access token.
/// Downloaded PDF bytes remain in memory and are not handed to external apps.
class Care360MedicalPdfClient {
  Care360MedicalPdfClient({
    required this.apiBase,
    required this.readToken,
    http.Client? httpClient,
    this.allowLoopbackHttp = false,
    this.networkTimeout = const Duration(seconds: 30),
  })  : _client = httpClient ?? http.Client(),
        _ownsClient = httpClient == null;

  final Uri apiBase;
  final Future<String?> Function() readToken;
  final bool allowLoopbackHttp;
  /// Maximum time allowed for each authentication/connection phase and
  /// the total response body transfer, including slow trickle responses.
  final Duration networkTimeout;
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
    // Legacy /prescription/upload links were publicly accessible. Never
    // download them even from our own host: serving them in an authenticated
    // mobile viewer does not revoke the public web URL. The backend must
    // migrate existing files and return appointment-scoped private endpoints.
    if (!isPrivatePrescriptionLink(source)) {
      throw const FormatException(
          'Legacy prescription requires private-file migration.');
    }
    final suppliedUri = Uri.tryParse(source);
    if (suppliedUri == null) {
      throw const FormatException('Invalid prescription link.');
    }
    _requireApprovedOrigin(suppliedUri);
    final uri = privatePrescriptionUri(appointmentId);
    if (suppliedUri.path != uri.path ||
        suppliedUri.hasQuery || suppliedUri.hasFragment) {
      throw const FormatException('Prescription appointment mismatch.');
    }

    final String? storedToken;
    try {
      storedToken = await readToken().timeout(networkTimeout);
    } on TimeoutException {
      throw const MedicalPdfException('Prescription access timed out. Please retry.');
    }
    final token = storedToken?.trim();
    if (token == null || token.isEmpty ||
        token == 'N_A' || token == 'null') {
      throw const MedicalPdfException('Sign in to access this prescription.');
    }

    final request = http.Request('GET', uri)
      ..followRedirects = false
      ..persistentConnection = false
      ..headers['Accept'] = 'application/pdf';
    request.headers['Authorization'] = 'Bearer $token';

    late final http.StreamedResponse response;
    try {
      response = await _client.send(request).timeout(networkTimeout);
    } on TimeoutException {
      throw const MedicalPdfException('Prescription connection timed out. Please retry.');
    }
    // Always cancel the response subscription, including rejected responses
    // and oversized or stalled streams. An idle timeout alone is insufficient:
    // a slow trickle of bytes can otherwise keep a download alive forever.
    final iterator = StreamIterator<List<int>>(response.stream);
    final deadline = Stopwatch()..start();
    try {
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
      while (true) {
        final remaining = networkTimeout - deadline.elapsed;
        if (remaining <= Duration.zero) {
          throw const MedicalPdfException(
              'Prescription download timed out. Please retry.');
        }
        final available = await iterator.moveNext().timeout(remaining);
        if (!available) break;
        final part = iterator.current;
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
    } on TimeoutException {
      throw const MedicalPdfException(
          'Prescription download timed out. Please retry.');
    } finally {
      await iterator.cancel();
    }
  }

  void close() {
    if (_ownsClient) _client.close();
  }

  void _validateApiBase() {
    if (networkTimeout <= Duration.zero) {
      throw const FormatException('Invalid clinical network timeout.');
    }
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
