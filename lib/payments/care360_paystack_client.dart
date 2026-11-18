import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class Care360PaystackSession {
  const Care360PaystackSession({
    required this.reference,
    required this.accessCode,
    required this.checkoutUrl,
    required this.callbackUrl,
  });
  final String reference, accessCode;
  final Uri checkoutUrl, callbackUrl;

  bool matchesReturn(String url) {
    final uri = Uri.tryParse(url);
    return uri != null &&
        uri.scheme == callbackUrl.scheme &&
        uri.host == callbackUrl.host &&
        uri.port == callbackUrl.port &&
        uri.path == callbackUrl.path &&
        uri.userInfo.isEmpty &&
        (uri.queryParameters['reference'] == reference ||
            uri.queryParameters['trxref'] == reference);
  }
}

/// Amounts cross the Care360 API in MAJOR units; only the server converts to kobo.
/// This client never receives a gateway secret or treats a redirect as proof of payment.
class Care360PaystackClient {
  Care360PaystackClient(this.dio, {required this.apiBase});
  final Dio dio;
  final Uri apiBase;

  Future<Care360PaystackSession> initialize({
    required num amount,
    required String currency,
  }) async {
    final localDebug =
        kDebugMode &&
        apiBase.scheme == 'http' &&
        const ['127.0.0.1', 'localhost', '::1'].contains(apiBase.host);
    if ((apiBase.scheme != 'https' && !localDebug) ||
        apiBase.userInfo.isNotEmpty ||
        apiBase.hasQuery ||
        apiBase.hasFragment ||
        !apiBase.path.endsWith('/api/')) {
      throw const FormatException('Invalid secure payment API configuration.');
    }
    if (!amount.isFinite ||
        amount < 1 ||
        amount > 10000000 ||
        !RegExp(r'^[A-Z]{3}$').hasMatch(currency)) {
      throw const FormatException('Invalid checkout amount or currency.');
    }
    final response = await dio.postUri(
      apiBase.resolve('paystack_init'),
      data: {
        'amount': (amount * 100).round() / 100,
        'amount_unit': 'major',
        'currency': currency,
      },
      options: Options(followRedirects: false),
    );
    final body = response.data;
    if (body is! Map || body['success'] != true || body['data'] is! Map) {
      throw const FormatException('Checkout could not be opened.');
    }
    final data = body['data'] as Map;
    final reference = data['reference'], code = data['access_code'];
    final checkout = Uri.tryParse(data['authorization_url']?.toString() ?? '');
    final callback = Uri.tryParse(data['callback_url']?.toString() ?? '');
    if (reference is! String ||
        !RegExp(r'^[A-Za-z0-9._=-]{1,200}$').hasMatch(reference) ||
        code is! String ||
        code.isEmpty ||
        checkout == null ||
        checkout.scheme != 'https' ||
        !const [
          'checkout.paystack.com',
          'checkout.paystack.co',
          'standard.paystack.co',
        ].contains(checkout.host) ||
        checkout.port != 443 ||
        checkout.userInfo.isNotEmpty ||
        checkout.hasFragment ||
        callback == null ||
        callback.scheme != apiBase.scheme ||
        callback.host != apiBase.host ||
        callback.port != apiBase.port ||
        callback.userInfo.isNotEmpty ||
        callback.hasQuery ||
        callback.hasFragment ||
        callback.path != apiBase.resolve('paystack/return').path) {
      throw const FormatException('Checkout response could not be verified.');
    }
    return Care360PaystackSession(
      reference: reference,
      accessCode: code,
      checkoutUrl: checkout,
      callbackUrl: callback,
    );
  }
}
