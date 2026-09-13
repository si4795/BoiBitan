import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_translations.dart';
import '../models/book.dart';
import '../services/download_service.dart';
import '../services/storage_service.dart';
import 'home_screen.dart';

class PdfReaderScreen extends StatefulWidget {
  final Book book;
  final String? localPdfPath;
  final StorageService? storageService;

  const PdfReaderScreen({
    super.key,
    required this.book,
    this.localPdfPath,
    this.storageService,
  });

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  late StorageService _activeStorage;
  final DownloadService _downloadService = DownloadService();

  String? _pdfPath;
  bool _isLoading = true;
  double _downloadProgress = 0.0;
  String? _errorMessage;

  PDFViewController? _pdfViewController;
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isNightMode = false;

  @override
  void initState() {
    super.initState();
    _activeStorage = widget.storageService ?? StorageService();
    _initPdfFile();
  }

  Future<void> _initPdfFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _downloadProgress = 0.0;
    });

    try {
      if (mounted && widget.storageService == null) {
        final inheritedStorage = context.storage;
        if (inheritedStorage != null) {
          _activeStorage = inheritedStorage;
        }
      }
      await _activeStorage.init();

      if (widget.localPdfPath != null &&
          await File(widget.localPdfPath!).exists()) {
        _pdfPath = widget.localPdfPath;
      } else {
        final existingPath = _activeStorage.getDownloadedFilePath(
          widget.book.id,
        );
        if (existingPath != null && await File(existingPath).exists()) {
          _pdfPath = existingPath;
        } else {
          final downloadUrl = widget.book.downloadUrl.trim();
          if (downloadUrl.startsWith('http://') ||
              downloadUrl.startsWith('https://')) {
            final file = await _downloadService.getOrFetchBookForReading(
              book: widget.book,
              storageService: _activeStorage,
              onProgress: (received, total, progress) {
                if (mounted) {
                  setState(() {
                    _downloadProgress = progress;
                  });
                }
              },
            );
            _pdfPath = file.path;
          } else if (await File(downloadUrl).exists()) {
            _pdfPath = downloadUrl;
          } else {
            throw Exception(
              'Invalid PDF location or unsupported URL: $downloadUrl',
            );
          }
        }
      }

      final savedPage = _activeStorage.getLastReadPage(widget.book.id);
      _currentPage = savedPage;

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _openInBrowser() async {
    final target = widget.book.downloadUrl.isNotEmpty
        ? widget.book.downloadUrl
        : (widget.book.previewUrl ?? '');
    if (target.isEmpty) return;
    final uri = Uri.parse(target);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not open link: $e')));
      }
    }
  }

  void _onPdfRenderReady(PDFViewController controller, int pages) {
    _pdfViewController = controller;
    setState(() {
      _totalPages = pages > 0 ? pages : 1;
    });

    final lastPage = _activeStorage.getLastReadPage(widget.book.id);
    if (lastPage > 0 && lastPage < pages) {
      controller.setPage(lastPage);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr('reader_resumed_toast', [
              context.formatNum(lastPage + 1),
            ]),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _onPageChanged(int? page, int? total) {
    if (page == null) return;
    setState(() {
      _currentPage = page;
      if (total != null && total > 0) _totalPages = total;
    });

    _activeStorage.saveReadingProgress(
      bookId: widget.book.id,
      lastReadPage: page,
      totalPages: _totalPages > 0 ? _totalPages : (total ?? 1),
      book: widget.book,
    );
  }

  void _jumpToPageDialog() {
    final controller = TextEditingController(text: '${_currentPage + 1}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('reader_jump_to_page')),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: context.tr('reader_enter_page'),
            suffixText: '/ ${context.formatNum(_totalPages)}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              final raw = controller.text.trim();
              final normalized = AppTranslations.toEnglishDigits(raw);
              final target = int.tryParse(normalized);
              if (target != null && target >= 1 && target <= _totalPages) {
                _pdfViewController?.setPage(target - 1);
                Navigator.pop(ctx);
              }
            },
            child: Text(context.tr('reader_go')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBn = context.isBengali;

    return Scaffold(
      backgroundColor: _isNightMode
          ? const Color(0xFF121212)
          : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: _isNightMode
            ? const Color(0xFF1E1E1E)
            : theme.appBarTheme.backgroundColor,
        iconTheme: IconThemeData(
          color: _isNightMode
              ? Colors.white
              : theme.appBarTheme.iconTheme?.color,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.book.getLocalizedTitle(isBn),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _isNightMode ? Colors.white : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              context.tr('reader_page', [
                context.formatNum(_currentPage + 1),
                context.formatNum(_totalPages > 0 ? _totalPages : 1),
              ]),
              style: TextStyle(
                fontSize: 12,
                color: _isNightMode
                    ? Colors.white70
                    : theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
        actions: [
          // Night mode toggle
          IconButton(
            tooltip: context.tr('reader_toggle_theme'),
            icon: Icon(
              _isNightMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
            onPressed: () {
              setState(() {
                _isNightMode = !_isNightMode;
              });
            },
          ),
          // Bookmark current page
          IconButton(
            tooltip: 'Bookmark',
            icon: const Icon(Icons.bookmark_add_rounded),
            onPressed: () {
              _activeStorage.saveReadingProgress(
                bookId: widget.book.id,
                lastReadPage: _currentPage,
                totalPages: _totalPages > 0 ? _totalPages : 1,
                book: widget.book,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    context.tr('reader_bookmark_saved', [
                      context.formatNum(_currentPage + 1),
                    ]),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: CircularProgressIndicator(
                        strokeWidth: 3.5,
                        value: _downloadProgress > 0 ? _downloadProgress : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      context.tr('reading_preparing_book'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_downloadProgress > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${context.formatNum((_downloadProgress * 100).toInt())}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cloud_off_rounded,
                        size: 48,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('error_loading_pdf'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _initPdfFile,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(context.tr('retry')),
                        ),
                        OutlinedButton.icon(
                          onPressed: _openInBrowser,
                          icon: const Icon(Icons.open_in_browser_rounded),
                          label: Text(context.tr('reader_open_in_browser')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                ColorFiltered(
                  colorFilter: _isNightMode
                      ? const ColorFilter.matrix([
                          -1,
                          0,
                          0,
                          0,
                          255,
                          0,
                          -1,
                          0,
                          0,
                          255,
                          0,
                          0,
                          -1,
                          0,
                          255,
                          0,
                          0,
                          0,
                          1,
                          0,
                        ])
                      : const ColorFilter.mode(
                          Colors.transparent,
                          BlendMode.multiply,
                        ),
                  child: PDFView(
                    filePath: _pdfPath!,
                    enableSwipe: true,
                    swipeHorizontal: false,
                    autoSpacing: true,
                    pageFling: true,
                    pageSnap: true,
                    defaultPage: _currentPage,
                    fitPolicy: FitPolicy.BOTH,
                    preventLinkNavigation: false,
                    onRender: (pages) {
                      setState(() {
                        _totalPages = pages ?? 0;
                      });
                      if (pages != null && _pdfViewController != null) {
                        _onPdfRenderReady(_pdfViewController!, pages);
                      }
                    },
                    onViewCreated: (PDFViewController controller) {
                      _pdfViewController = controller;
                      if (_totalPages > 0) {
                        _onPdfRenderReady(controller, _totalPages);
                      }
                    },
                    onPageChanged: _onPageChanged,
                    onError: (error) {
                      setState(() {
                        _errorMessage = error.toString();
                      });
                    },
                    onPageError: (page, error) {
                      debugPrint('Error on page $page: $error');
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _isNightMode
              ? const Color(0xFF1E1E1E)
              : theme.bottomNavigationBarTheme.backgroundColor,
          border: Border(
            top: BorderSide(
              color: _isNightMode
                  ? Colors.white12
                  : theme.dividerTheme.color ?? Colors.black12,
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
                color: _isNightMode ? Colors.white : null,
                onPressed: _currentPage > 0
                    ? () => _pdfViewController?.setPage(_currentPage - 1)
                    : null,
              ),
              InkWell(
                onTap: _totalPages > 0 ? _jumpToPageDialog : null,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.touch_app_outlined, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${context.formatNum(_currentPage + 1)} / ${context.formatNum(_totalPages > 0 ? _totalPages : 1)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isNightMode ? Colors.white : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
                color: _isNightMode ? Colors.white : null,
                onPressed: _currentPage < _totalPages - 1
                    ? () => _pdfViewController?.setPage(_currentPage + 1)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
