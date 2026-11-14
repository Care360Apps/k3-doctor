import 'package:flutter/foundation.dart';
import '../retrofit/apis.dart';

/// Workforce recruitment must have a separately approved privacy notice.
/// The generic Care360 Patient medical privacy policy is NOT that notice.
///
/// A deployment must provide a live, reviewed Care360-hosted notice using
/// --dart-define=K3_WORKFORCE_PRIVACY_NOTICE_URL=https://care360apps.com/...
/// This gate never enables the separate client/server pilot feature flags.
class WorkforceNoticeGate {
  const WorkforceNoticeGate._();

  static const configuredVersion = String.fromEnvironment(
    'K3_WORKFORCE_PRIVACY_NOTICE_VERSION',
    defaultValue: '',
  );

  static const configuredUrl = String.fromEnvironment(
    'K3_WORKFORCE_PRIVACY_NOTICE_URL',
    defaultValue: '',
  );

  static Uri? approvedUrl([String? candidate]) {
    final uri = Uri.tryParse((candidate ?? configuredUrl).trim());
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.port != 443) {
      return null;
    }
    final host = uri.host.toLowerCase();
    final ownedByCare360 =
        host == 'care360apps.com' || host.endsWith('.care360apps.com');
    if (!ownedByCare360 ||
        uri.pathSegments.where((segment) => segment.isNotEmpty).isEmpty) {
      return null;
    }
    return uri;
  }

  /// Explicit fictional-data testing only; never enabled in a release build.
  static bool get localDemo {
    const enabled = bool.fromEnvironment(
      'K3_WORKFORCE_LOCAL_DEMO',
      defaultValue: false,
    );
    final base = Uri.tryParse(Apis.baseUrl);
    return kDebugMode &&
        enabled &&
        base != null &&
        base.scheme == 'http' &&
        ['127.0.0.1', 'localhost', '::1'].contains(base.host) &&
        base.path == '/api/';
  }

  static bool get configured =>
      localDemo ||
      (approvedUrl() != null &&
          RegExp(r'^[A-Za-z0-9._-]{1,80}$').hasMatch(configuredVersion));
}
