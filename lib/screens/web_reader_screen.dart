import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../l10n/app_translations.dart';
import '../models/book.dart';

/// In-app web reader providing a seamless reading portal for Archive.org,
/// Open Library streams, and digital previews without kicking the user out of BoiBitan.
class WebReaderScreen extends StatefulWidget {
  final String url;
  final String title;
  final Book? book;

  const WebReaderScreen({
    super.key,
    required this.url,
    required this.title,
    this.book,
  });

  @override
  State<WebReaderScreen> createState() => _WebReaderScreenState();
}

class _WebReaderScreenState extends State<WebReaderScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  double _progress = 0.0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    final cleanUrl = widget.url.trim();
    final uri = Uri.tryParse(cleanUrl);

    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      return;
    }

    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              if (mounted) {
                setState(() {
                  _progress = progress / 100.0;
                });
              }
            },
            onPageStarted: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
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
            onWebResourceError: (WebResourceError error) {
              if (error.isForMainFrame ?? true) {
                if (mounted) {
                  setState(() {
                    _hasError = true;
                    _isLoading = false;
                  });
                }
              }
            },
          ),
        );

      controller.loadRequest(uri);
      _controller = controller;
    } catch (_) {
      // Handles environments without webview platform (e.g. headless unit/widget tests)
      _isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: context.tr('back'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (_controller != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: context.tr('retry'),
              onPressed: () {
                _controller?.reload();
              },
            ),
        ],
        bottom: _isLoading && _progress < 1.0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3.0),
                child: LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  backgroundColor: Colors.transparent,
                ),
              )
            : null,
      ),
      body: _hasError
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_off_rounded,
                      size: 64,
                      color: theme.colorScheme.error.withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('digital_copy_load_failed'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _hasError = false;
                          _isLoading = true;
                          _progress = 0.0;
                        });
                        final uri = Uri.tryParse(widget.url.trim());
                        if (uri != null) {
                          _controller?.loadRequest(uri);
                        }
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(context.tr('retry')),
                    ),
                  ],
                ),
              ),
            )
          : (_controller != null
                ? WebViewWidget(controller: _controller!)
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        widget.title,
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )),
    );
  }
}
