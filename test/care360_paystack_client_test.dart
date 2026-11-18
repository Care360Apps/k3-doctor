import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctro/payments/care360_paystack_client.dart';

class CheckoutAdapter implements HttpClientAdapter {
  RequestOptions? sent;
  int calls = 0;
  Map<String, dynamic> payload = {
    'success': true,
    'data': {
      'access_code': 'synthetic_access',
      'reference': 'synthetic-ref',
      'authorization_url': 'https://checkout.paystack.com/synthetic',
      'callback_url': 'https://care360.example.test/api/paystack/return',
    },
  };
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    sent = options;
    calls++;
    return ResponseBody.fromString(
      jsonEncode(payload),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late CheckoutAdapter adapter;
  late Care360PaystackClient client;
  setUp(() {
    adapter = CheckoutAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    client = Care360PaystackClient(
      dio,
      apiBase: Uri.parse('https://care360.example.test/api/'),
    );
  });
  test('NGN 100.50 stays 100.50 at the API boundary, not 10050', () async {
    final session = await client.initialize(amount: 100.5, currency: 'NGN');
    expect(adapter.sent!.data, {
      'amount': 100.5,
      'amount_unit': 'major',
      'currency': 'NGN',
    });
    expect(
      adapter.sent!.uri.toString(),
      'https://care360.example.test/api/paystack_init',
    );
    expect(session.reference, 'synthetic-ref');
    expect(adapter.sent!.followRedirects, isFalse);
  });
  test('invalid amount and currency never initialize checkout', () async {
    for (final amount in [0, -1, double.nan, double.infinity, 10000001]) {
      await expectLater(
        client.initialize(amount: amount, currency: 'NGN'),
        throwsFormatException,
      );
    }
    await expectLater(
      client.initialize(amount: 100, currency: ''),
      throwsFormatException,
    );
    expect(adapter.calls, 0);
  });
  test('untrusted payment and return URLs are rejected', () async {
    for (final url in [
      'http://checkout.paystack.com/test',
      'https://checkout.paystack.com.evil.example/test',
      'https://user:pass@checkout.paystack.com/test',
      'https://checkout.paystack.com:444/test',
    ]) {
      (adapter.payload['data'] as Map)['authorization_url'] = url;
      await expectLater(
        client.initialize(amount: 100, currency: 'NGN'),
        throwsFormatException,
      );
    }
    (adapter.payload['data'] as Map)['authorization_url'] =
        'https://checkout.paystack.com/test';
    (adapter.payload['data'] as Map)['callback_url'] =
        'https://another.example/api/paystack/return';
    await expectLater(
      client.initialize(amount: 100, currency: 'NGN'),
      throwsFormatException,
    );
  });
  test('only the expected return origin, route and receipt end checkout', () async {
    final session = await client.initialize(amount: 100, currency: 'NGN');
    expect(
      session.matchesReturn(
        'https://care360.example.test/api/paystack/return?reference=synthetic-ref',
      ),
      isTrue,
    );
    expect(
      session.matchesReturn(
        'https://care360.example.test/api/paystack/return?trxref=synthetic-ref',
      ),
      isTrue,
    );
    for (final url in [
      'https://evil.example/api/paystack/return?reference=synthetic-ref',
      'https://care360.example.test/another?reference=synthetic-ref',
      'https://care360.example.test/api/paystack/return?reference=wrong',
    ]) {
      expect(session.matchesReturn(url), isFalse);
    }
  });
  test(
    'remote plaintext API is rejected before credentials could be sent',
    () async {
      final dio = Dio()..httpClientAdapter = adapter;
      final unsafe = Care360PaystackClient(
        dio,
        apiBase: Uri.parse('http://care360.example.test/api/'),
      );
      await expectLater(
        unsafe.initialize(amount: 100, currency: 'NGN'),
        throwsFormatException,
      );
      expect(adapter.calls, 0);
    },
  );
  test(
    'missing or unsuccessful gateway data cannot imply payment success',
    () async {
      adapter.payload = {'success': false};
      await expectLater(
        client.initialize(amount: 100, currency: 'NGN'),
        throwsFormatException,
      );
      adapter.payload = {'success': true, 'data': {}};
      await expectLater(
        client.initialize(amount: 100, currency: 'NGN'),
        throwsFormatException,
      );
    },
  );
}
