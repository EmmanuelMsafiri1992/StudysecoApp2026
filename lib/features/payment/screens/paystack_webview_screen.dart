import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/payment_provider.dart';

class PaystackWebViewScreen extends ConsumerStatefulWidget {
  final String authorizationUrl;
  final String reference;

  const PaystackWebViewScreen({
    super.key,
    required this.authorizationUrl,
    required this.reference,
  });

  @override
  ConsumerState<PaystackWebViewScreen> createState() =>
      _PaystackWebViewScreenState();
}

class _PaystackWebViewScreenState
    extends ConsumerState<PaystackWebViewScreen> {
  late WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: (request) {
            final url = request.url;
            if (url.startsWith(AppConstants.paystackCallbackUrl) ||
                url.contains('/payment/callback') ||
                url.contains('trxref=') ||
                url.contains('reference=')) {
              _handlePaymentComplete(url);
              return NavigationDecision.prevent;
            }
            if (url.contains('paystack.co/close')) {
              _handlePaymentCancelled();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authorizationUrl));
  }

  void _handlePaymentComplete(String url) async {
    final uri = Uri.tryParse(url);
    final reference = uri?.queryParameters['reference'] ??
        uri?.queryParameters['trxref'] ??
        widget.reference;

    final success =
        await ref.read(paymentFlowProvider.notifier).verifyPaystack(reference);
    if (mounted) {
      context.pop(success);
    }
  }

  void _handlePaymentCancelled() {
    if (mounted) context.pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentFlowProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: AppColors.surface,
                title: const Text('Cancel Payment?'),
                content: const Text(
                    'Are you sure you want to cancel this payment?',
                    style: TextStyle(color: AppColors.textSecondary)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Continue Paying')),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.pop(false);
                    },
                    child: const Text('Cancel Payment',
                        style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          Row(
            children: const [
              Icon(Icons.lock_rounded, size: 14, color: AppColors.secondary),
              SizedBox(width: 4),
              Text('Secured by Paystack',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              SizedBox(width: 12),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading || paymentState.isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Processing payment...',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
