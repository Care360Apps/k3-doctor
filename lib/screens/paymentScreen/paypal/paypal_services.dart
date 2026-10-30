import 'dart:async';
import 'package:doctro/retrofit/api_header.dart';
import 'package:doctro/retrofit/apis.dart';

/// PayPal calls go through the backend, which holds the PayPal secret.
class PaypalServices {
  Future<Map<String, String>> createPaypalPayment({required String total, required String returnUrl, required String cancelUrl, String? description}) async {
    final response = await RetroApi().dioData().post(
      '${Apis.baseUrl}paypal/create_payment',
      data: {"amount": total, "return_url": returnUrl, "cancel_url": cancelUrl, if (description != null) "description": description},
    );
    final data = response.data['data'];
    return {"paymentId": data['id'].toString(), "approvalUrl": data['approval_url'].toString()};
  }

  Future<String?> executePayment(String paymentId, String payerId) async {
    final response = await RetroApi().dioData().post(
      '${Apis.baseUrl}paypal/execute_payment',
      data: {"payment_id": paymentId, "payer_id": payerId},
    );
    return response.data['data']?['id']?.toString();
  }
}
