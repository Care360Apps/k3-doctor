import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ConsultationCredentials {
  const ConsultationCredentials({
    required this.sessionId, required this.channel, required this.uid,
    required this.token, required this.appId, required this.expiresAt,
  });
  final int sessionId;
  final String channel;
  final int uid;
  final String token;
  final String appId;
  final DateTime expiresAt;

  factory ConsultationCredentials.parse(Map<String, dynamic> data) {
    final id = data['session_id'];
    final uid = data['uid'];
    final channel = data['cn'];
    final token = data['agora_token'];
    final appId = data['appId'];
    final expiry = data['expires_at'];
    if (id is! int || id <= 0 || (uid is! int || (uid != 1 && uid != 2)) ||
        channel is! String || !RegExp(r'^c[a-f0-9]{48}$').hasMatch(channel) ||
        token is! String || token.isEmpty || token.length > 4096 ||
        appId is! String || !RegExp(r'^[a-fA-F0-9]{32}$').hasMatch(appId) ||
        expiry is! int || expiry <= 0 || expiry > 4102444800) {
      throw const FormatException('Invalid consultation credentials.');
    }
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(expiry * 1000, isUtc: true);
    if (!expiresAt.isAfter(DateTime.now().toUtc())) {
      throw const FormatException('Expired consultation credentials.');
    }
    return ConsultationCredentials(sessionId: id, channel: channel,
      uid: uid, token: token, appId: appId, expiresAt: expiresAt);
  }
}

class ConsultationAccessRevoked extends StateError {
  ConsultationAccessRevoked() : super('Consultation access is no longer available.');
}

/// Opt-in transport only. Never automatically fall back to legacy calls.
class ConsultationSessionClient {
  ConsultationSessionClient({required this.apiBase, required this.readToken,
    required this.client, required this.expectedUid});
  final Uri apiBase;
  final Future<String?> Function() readToken;
  final http.Client client;
  final int expectedUid;
  static const timeout = Duration(seconds: 15);

  Future<ConsultationCredentials> credentials(int appointmentId,
      {ConsultationCredentials? previous}) async {
    final data = await _post(appointmentId, 'credentials');
    final next = ConsultationCredentials.parse(data);
    if (next.uid != expectedUid || (previous != null &&
        (next.sessionId != previous.sessionId || next.channel != previous.channel ||
         next.uid != previous.uid || next.appId != previous.appId))) {
      throw const FormatException('Consultation identity changed.');
    }
    return next;
  }

  /// Returns server lifecycle state without requesting RTC credentials.
  Future<String> status(int appointmentId, {int? expectedSessionId}) async {
    final data = await _post(appointmentId, 'status', method: 'GET');
    final state = data['state'];
    if (state == 'not_started' && expectedSessionId == null) return 'not_started';
    final id = data['session_id'];
    final expiry = data['expires_at'];
    if (id is! int || id <= 0 ||
        (expectedSessionId != null && id != expectedSessionId) ||
        expiry is! int || expiry <= 0 || expiry > 4102444800 ||
        (state != 'active' && state != 'ended' && state != 'expired')) {
      throw const FormatException('Invalid consultation status.');
    }
    if (state == 'active' && expiry <= DateTime.now().millisecondsSinceEpoch ~/ 1000) {
      return 'expired';
    }
    return state as String;
  }

  Future<void> invite(int appointmentId) async {
    await _post(appointmentId, 'invite');
  }

  Future<void> end(int appointmentId) async {
    await _post(appointmentId, 'end');
  }

  Future<Map<String, dynamic>> _post(int id, String action, {String method = 'POST'}) async {
    if ((expectedUid != 1 && expectedUid != 2) || id <= 0 || apiBase.scheme != 'https' || apiBase.host.isEmpty ||
        apiBase.userInfo.isNotEmpty || apiBase.hasQuery || apiBase.hasFragment ||
        !apiBase.path.endsWith('/api/')) {
      throw const FormatException('Invalid consultation API configuration.');
    }
    final token = (await readToken().timeout(timeout))?.trim();
    if (token == null || token.isEmpty || token == 'N_A' || token == 'null') {
      throw ConsultationAccessRevoked();
    }
    final request = http.Request(method, apiBase.resolve('consultations/v1/$id/$action'))
      ..followRedirects = false
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept'] = 'application/json';
    final response = await client.send(request).timeout(timeout);
    final iterator = StreamIterator<List<int>>(response.stream);
    final deadline = Stopwatch()..start();
    final bytes = <int>[];
    try {
      if ([401, 403, 404, 409, 410].contains(response.statusCode)) {
        throw ConsultationAccessRevoked();
      }
      if (response.statusCode != 200) {
        throw StateError('Consultation unavailable. Please refresh or contact support.');
      }
      while (true) {
        final remaining = timeout - deadline.elapsed;
        if (remaining <= Duration.zero) throw TimeoutException('Consultation request');
        if (!await iterator.moveNext().timeout(remaining)) break;
        if (bytes.length + iterator.current.length > 16384) {
          throw const FormatException('Invalid consultation response.');
        }
        bytes.addAll(iterator.current);
      }
      final result = jsonDecode(utf8.decode(bytes));
      if (result is! Map<String, dynamic> || result['success'] != true) {
        throw const FormatException('Invalid consultation response.');
      }
      if (action == 'end' || action == 'invite') return <String, dynamic>{};
      final data = result['data'];
      if (data is! Map<String, dynamic>) throw const FormatException('Missing credentials.');
      return data;
    } finally {
      await iterator.cancel();
    }
  }
}
