import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/utils/snackbar_utils.dart';

import 'payment_success_page.dart';

class PaymentWebviewPage extends StatefulWidget {
  final String url;

  const PaymentWebviewPage({super.key, required this.url});

  @override
  State<PaymentWebviewPage> createState() => _PaymentWebviewPageState();
}

class _PaymentWebviewPageState extends State<PaymentWebviewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            final String url = request.url.toLowerCase();

            if (url.contains('status_code=200') ||
                url.contains('settlement') ||
                url.contains('success')) {
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const PaymentSuccessPage()),
                );
              }
              return NavigationDecision.prevent;
            }

            if (!request.url.startsWith('http')) {
              if (mounted) {
                SnackbarUtils.showInfo(
                  context,
                  'Gunakan BCA Virtual Account untuk testing Sandbox',
                );
              }
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = const Color(0xFFD4AF37);
    final Color bgColor = isDark
        ? const Color(0xFF111827)
        : const Color(0xFFF9FAFB);
    final Color onSurfaceColor = isDark
        ? Colors.white
        : const Color(0xFF111827);

    _controller.setBackgroundColor(bgColor);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: onSurfaceColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pembayaran',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Center(child: CircularProgressIndicator(color: primaryColor)),
        ],
      ),
    );
  }
}
