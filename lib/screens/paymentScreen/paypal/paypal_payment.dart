import 'dart:core';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'paypal_services.dart';

class PaypalPayment extends StatefulWidget {
  final Function onFinish;
  final String total;
  final String duration;
  final String name;

  PaypalPayment({required this.total, required this.onFinish, required this.duration, required this.name});

  @override
  State<StatefulWidget> createState() {
    return PaypalPaymentState();
  }
}

class PaypalPaymentState extends State<PaypalPayment> {
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String? checkoutUrl;
  String? paymentId;
  PaypalServices services = PaypalServices();
  WebViewController? _controller;

  String returnURL = 'https://return.example.com';
  String cancelURL = 'https://cancel.example.com';
  String totalAmount = '';

  void getToken() async {
    Future.delayed(const Duration(seconds: 1), () async {
      try {
        final res = await services.createPaypalPayment(total: totalAmount, returnUrl: returnURL, cancelUrl: cancelURL, description: widget.name);
        setState(() {
          checkoutUrl = res["approvalUrl"];
          paymentId = res["paymentId"];
          if (checkoutUrl != null && checkoutUrl!.isNotEmpty) {
            _controller = WebViewController()
              ..setJavaScriptMode(JavaScriptMode.unrestricted)
              ..setNavigationDelegate(
                NavigationDelegate(
                  onNavigationRequest: (request) {
                    final url = request.url;
                    if (url.contains(returnURL)) {
                      final uri = Uri.parse(url);
                      final payerID = uri.queryParameters['PayerID'];
                      if (payerID != null) {
                        services.executePayment(paymentId!, payerID).then((id) {
                          widget.onFinish(id);
                        }).catchError((e) {
                          print('exception:  $e');
                        });
                      }
                      Navigator.of(context).pop();
                      return NavigationDecision.prevent;
                    }
                    if (url.contains(cancelURL)) {
                      Navigator.of(context).pop();
                      return NavigationDecision.prevent;
                    }
                    return NavigationDecision.navigate;
                  },
                ),
              )
              ..loadRequest(Uri.parse(checkoutUrl!));
          }
        });
      } catch (e) {
        print('exception:  $e');
        final snackBar = SnackBar(
          content: Text('$e'),
          duration: const Duration(seconds: 10),
          action: SnackBarAction(label: 'Close', onPressed: () {}),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    });
  }

  @override
  void initState() {
    super.initState();

    totalAmount = widget.total;

    getToken();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Theme.of(context).colorScheme.background,
        leading: GestureDetector(
          child: const Icon(Icons.arrow_back),
          onTap: () => Navigator.pop(context),
        ),
      ),
      body: checkoutUrl != null
          ? _controller == null
              ? const Center(child: CircularProgressIndicator(color: Colors.orangeAccent))
              : WebViewWidget(controller: _controller!)
          : const Center(child: CircularProgressIndicator(color: Colors.orangeAccent)),
    );
  }
}
