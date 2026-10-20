import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/theme/app_theme.dart';

class LibraryPdfViewer extends StatefulWidget {
  final String fileUrl;
  final String title;

  const LibraryPdfViewer({
    super.key,
    required this.fileUrl,
    required this.title,
  });

  @override
  State<LibraryPdfViewer> createState() => _LibraryPdfViewerState();
}

class _LibraryPdfViewerState extends State<LibraryPdfViewer> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _buildController();
  }

  void _buildController() {
    final uri = Uri.parse(widget.fileUrl);
    final baseUrl = '${uri.scheme}://${uri.host}';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF2D2D3A))
      ..addJavaScriptChannel(
        'PdfBridge',
        onMessageReceived: (msg) {
          if (!mounted) return;
          if (msg.message == 'ready') {
            setState(() => _isLoading = false);
          } else if (msg.message == 'error') {
            setState(() { _isLoading = false; _hasError = true; });
          }
        },
      )
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) {
          final url = request.url;
          if (url.startsWith('blob:') ||
              url.startsWith('data:') ||
              url.contains('download')) {
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadHtmlString(_buildHtml(widget.fileUrl), baseUrl: baseUrl);
  }

  String _buildHtml(String pdfUrl) => '''<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=yes">
  <style>
    *{margin:0;padding:0;box-sizing:border-box}
    html,body{background:#2D2D3A;min-height:100%}
    #container{padding:6px 0 16px}
    canvas{display:block;margin:4px auto;background:#fff;box-shadow:0 2px 8px rgba(0,0,0,.45)}
    *{-webkit-user-select:none;user-select:none;-webkit-touch-callout:none}
  </style>
</head>
<body>
  <div id="container"></div>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.min.js"></script>
  <script>
    pdfjsLib.GlobalWorkerOptions.workerSrc =
      'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js';

    document.addEventListener('contextmenu', e => e.preventDefault(), true);

    (async () => {
      try {
        const pdf = await pdfjsLib.getDocument({ url: '$pdfUrl', withCredentials: false }).promise;
        const w = window.innerWidth;
        const container = document.getElementById('container');
        for (let n = 1; n <= pdf.numPages; n++) {
          const page  = await pdf.getPage(n);
          const nat   = page.getViewport({ scale: 1 });
          const vp    = page.getViewport({ scale: w / nat.width });
          const canvas = document.createElement('canvas');
          canvas.width  = vp.width;
          canvas.height = vp.height;
          container.appendChild(canvas);
          await page.render({ canvasContext: canvas.getContext('2d'), viewport: vp }).promise;
        }
        PdfBridge.postMessage('ready');
      } catch(e) {
        PdfBridge.postMessage('error');
      }
    })();
  </script>
</body>
</html>''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Row(children: [
              Icon(Icons.lock_rounded, size: 14, color: AppColors.secondary),
              SizedBox(width: 4),
              Text('Secured',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ),
        ],
      ),
      body: Stack(children: [
        if (!_hasError)
          WebViewWidget(controller: _controller)
        else
          _ErrorView(onRetry: () {
            setState(() { _isLoading = true; _hasError = false; });
            _buildController();
          }),
        if (_isLoading)
          const Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text('Loading document…',
                  style: TextStyle(color: AppColors.textSecondary)),
            ]),
          ),
      ]),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.broken_image_outlined,
              size: 56, color: AppColors.textMuted),
          const SizedBox(height: 16),
          const Text('Could not load document',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          const Text('Please check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ]),
      ),
    );
  }
}
