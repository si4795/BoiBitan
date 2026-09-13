import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/app_translations.dart';
import '../models/book.dart';
import '../screens/pdf_reader_screen.dart';
import '../services/download_service.dart';
import '../services/storage_service.dart';

class CaptchaDialog extends StatefulWidget {
  final Book book;
  final DownloadService downloadService;
  final StorageService storageService;

  const CaptchaDialog({
    super.key,
    required this.book,
    required this.downloadService,
    required this.storageService,
  });

  static Future<void> show(
    BuildContext context, {
    required Book book,
    required DownloadService downloadService,
    required StorageService storageService,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CaptchaDialog(
        book: book,
        downloadService: downloadService,
        storageService: storageService,
      ),
    );
  }

  @override
  State<CaptchaDialog> createState() => _CaptchaDialogState();
}

class _CaptchaDialogState extends State<CaptchaDialog> {
  late int _num1;
  late int _num2;
  late String _operator;
  late int _expectedAnswer;
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _hasError = false;
  bool _isDownloading = false;
  bool _isDownloaded = false;
  double _downloadProgress = 0.0;
  String? _downloadedFilePath;

  @override
  void initState() {
    super.initState();
    _generateCaptcha();
  }

  @override
  void dispose() {
    _answerController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _generateCaptcha() {
    final rand = Random();
    final ops = ['+', '-', '*'];
    final op = ops[rand.nextInt(ops.length)];

    int n1, n2, ans;
    if (op == '+') {
      n1 = rand.nextInt(15) + 3;
      n2 = rand.nextInt(15) + 2;
      ans = n1 + n2;
    } else if (op == '-') {
      n1 = rand.nextInt(20) + 10;
      n2 = rand.nextInt(n1 - 1) + 1;
      ans = n1 - n2;
    } else {
      n1 = rand.nextInt(9) + 2;
      n2 = rand.nextInt(8) + 2;
      ans = n1 * n2;
    }

    setState(() {
      _num1 = n1;
      _num2 = n2;
      _operator = op;
      _expectedAnswer = ans;
      _answerController.clear();
      _hasError = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _verifyAndDownload() {
    final input = _answerController.text.trim();
    final normalized = AppTranslations.toEnglishDigits(input);
    final parsed = int.tryParse(normalized);

    if (parsed == _expectedAnswer) {
      setState(() {
        _hasError = false;
        _isDownloading = true;
      });
      _startDownload();
    } else {
      setState(() {
        _hasError = true;
      });
      _generateCaptcha();
    }
  }

  Future<void> _startDownload() async {
    try {
      final file = await widget.downloadService.downloadBook(
        book: widget.book,
        storageService: widget.storageService,
        onProgress: (received, total, progress) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _isDownloaded = true;
          _downloadedFilePath = file.path;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _hasError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('error')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getCaptchaExpression(bool isBn) {
    String s1 = isBn
        ? AppTranslations.toBengaliDigits(_num1.toString())
        : _num1.toString();
    String s2 = isBn
        ? AppTranslations.toBengaliDigits(_num2.toString())
        : _num2.toString();
    String opSymbol;
    switch (_operator) {
      case '+':
        opSymbol = '+';
        break;
      case '-':
        opSymbol = '-';
        break;
      case '*':
        opSymbol = '×';
        break;
      default:
        opSymbol = '+';
    }
    return '$s1 $opSymbol $s2 = ?';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBn = context.isBengali;
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: !_isDownloading,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isDownloaded
                          ? Icons.check_circle_rounded
                          : (_isDownloading
                                ? Icons.downloading_rounded
                                : Icons.security_rounded),
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isDownloaded
                              ? context.tr('download_complete')
                              : (_isDownloading
                                    ? context.tr('download_progress_title')
                                    : context.tr('captcha_title')),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.book.getLocalizedTitle(isBn),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (!_isDownloading)
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                ],
              ),
              const Divider(height: 24),

              // Content based on state
              if (_isDownloaded) ...[
                // Download Finished View
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 30,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          context.tr('download_complete'),
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.auto_stories_rounded),
                  label: Text(context.tr('open_file')),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PdfReaderScreen(
                          book: widget.book,
                          localPdfPath: _downloadedFilePath,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(context.tr('open_external')),
                  onPressed: () {
                    if (_downloadedFilePath != null) {
                      widget.downloadService.openWithExternalViewer(
                        _downloadedFilePath!,
                      );
                    }
                  },
                ),
              ] else if (_isDownloading) ...[
                // Downloading View
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _downloadProgress > 0 ? _downloadProgress : null,
                    minHeight: 12,
                    backgroundColor: isDark
                        ? const Color(0xFF2D333B)
                        : const Color(0xFFE5E0D8),
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr('downloading'),
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      '${context.formatNum((_downloadProgress * 100).toInt())}%',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ] else ...[
                // Amarbooks Captcha Prompt
                Text(
                  context.tr('captcha_subtitle'),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),

                // Stylized Captcha Challenge Box (Amarbooks Security Box)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1F242C)
                        : const Color(0xFFF3EFE6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Distorted math challenge text
                      Text(
                        _getCaptchaExpression(isBn),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                          color: theme.colorScheme.primary,
                          fontFamily: 'monospace',
                        ),
                      ),
                      IconButton(
                        tooltip: context.tr('captcha_refresh'),
                        icon: const Icon(Icons.refresh_rounded),
                        color: theme.colorScheme.primary,
                        onPressed: _generateCaptcha,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Error feedback
                if (_hasError)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 16,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            context.tr('captcha_error'),
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Input Field
                TextField(
                  controller: _answerController,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _verifyAndDownload(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: context.tr('captcha_input_hint'),
                    prefixIcon: const Icon(Icons.dialpad_rounded),
                  ),
                ),
                const SizedBox(height: 20),

                // Action Buttons
                ElevatedButton.icon(
                  icon: const Icon(Icons.cloud_download_rounded),
                  label: Text(context.tr('captcha_verify')),
                  onPressed: _verifyAndDownload,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
