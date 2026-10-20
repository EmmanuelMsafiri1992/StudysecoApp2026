import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/payment_provider.dart';

/// Shows PayChangu's hosted checkout (Airtel Money, TNM Mpamba, card, bank)
/// and pops with the verified status: 'success', 'pending' or 'failed'.
class PayChanguCheckoutScreen extends ConsumerStatefulWidget {
  final String checkoutUrl;
  final String txRef;

  const PayChanguCheckoutScreen({
    super.key,
    required this.checkoutUrl,
    required this.txRef,
  });

  @override
  ConsumerState<PayChanguCheckoutScreen> createState() =>
      _PayChanguCheckoutScreenState();
}

class _PayChanguCheckoutScreenState
    extends ConsumerState<PayChanguCheckoutScreen> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            if (mounted) setState(() => _isLoading = false);
            // Redirect window.open() back into this WebView so PayChangu's
            // sub-pages (mobile money, card forms) never open in Chrome.
            _controller.runJavaScript(
              'window.open = function(u,t,f){ window.location.href = u; return window; };',
            );
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.navigate;

            if (uri.path.endsWith(AppConstants.payChanguCallbackPath) ||
                uri.path.endsWith(AppConstants.payChanguReturnPath)) {
              _finish();
              return NavigationDecision.prevent;
            }
            // tel:, intent:, mobile money / banking app deep links
            if (uri.scheme != 'http' && uri.scheme != 'https') {
              launchUrl(uri, mode: LaunchMode.externalApplication)
                  .catchError((_) => false);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  /// Always confirm with the server: even a closed checkout may have been paid.
  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    final status =
        await ref.read(paymentFlowProvider.notifier).verifyPayChangu(widget.txRef);
    if (mounted) Navigator.of(context).pop(status);
  }

  void _confirmClose() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Leave Payment?'),
        content: const Text(
            'If you have already approved the payment on your phone, we will still confirm it.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Continue Paying')),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _finish();
            },
            child: const Text('Leave',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentFlowProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmClose();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Secure Payment'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: _confirmClose,
          ),
          actions: const [
            Row(
              children: [
                Icon(Icons.lock_rounded, size: 14, color: AppColors.secondary),
                SizedBox(width: 4),
                Text('Secured by PayChangu',
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
      ),
    );
  }
}
