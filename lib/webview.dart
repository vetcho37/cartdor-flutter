import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebView extends StatefulWidget {
  final String url;

  PaymentWebView({required this.url});

  @override
  _PaymentWebViewState createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();
    // Assurez-vous que le WebView est bien initialisé
    WebViewController webViewController = WebViewController();
    webViewController
        .loadRequest(Uri.parse(widget.url)); // Charger l'URL avec loadRequest
    _controller = webViewController;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Paiement WebView'),
      ),
      body: WebViewWidget(
        controller:
            _controller, // Assurez-vous que vous utilisez le contrôleur initialisé
      ),
    );
  }
}
