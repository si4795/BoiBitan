import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_translations.dart';
import '../models/book.dart';
import '../services/download_service.dart';
import '../services/storage_service.dart';
import '../widgets/captcha_dialog.dart';
import 'home_screen.dart';
import 'pdf_reader_screen.dart';

class BookDetailsScreen extends StatefulWidget {
  final Book book;
  final StorageService? storageService;

  const BookDetailsScreen({super.key, required this.book, this.storageService});

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  late StorageService _storageService;
  final DownloadService _downloadService = DownloadService();
  bool _isInit = false;

  StorageService get _activeStorage =>
      widget.storageService ?? context.storage ?? _storageService;

  @override
  void initState() {
    super.initState();
    _storageService = widget.storageService ?? StorageService();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      _initStorage();
    }
  }

  Future<void> _initStorage() async {
    await _activeStorage.init();
    if (mounted) {
      setState(() {
        _isInit = true;
      });
    }
  }

  void _triggerCaptchaDownload() {
    CaptchaDialog.show(
      context,
      book: widget.book,
      downloadService: _downloadService,
      storageService: _activeStorage,
    );
  }

  void _openReader() {
    final downloadedPath = _activeStorage.getDownloadedFilePath(widget.book.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfReaderScreen(
          book: widget.book,
          localPdfPath: downloadedPath,
          storageService: _activeStorage,
        ),
      ),
    );
  }

  Future<void> _openGooglePreview() async {
    final urlString = widget.book.previewUrl ?? widget.book.downloadUrl;
    final uri = Uri.tryParse(urlString);
    if (uri != null) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot open preview URL: $urlString')),
          );
        }
      }
    }
  }

  Widget _buildMetaPill({
    required IconData icon,
    required String label,
    required String value,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E242C) : const Color(0xFFF3ECE1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBn = context.isBengali;
    final book = widget.book;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          book.getLocalizedTitle(isBn),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_isInit)
            ListenableBuilder(
              listenable: _activeStorage,
              builder: (context, _) {
                final isSaved = _activeStorage.isBookSaved(book.id);
                return IconButton(
                  tooltip: isSaved
                      ? context.tr('remove_from_saved')
                      : context.tr('add_to_saved'),
                  icon: Icon(
                    isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_outline_rounded,
                    color: isSaved ? const Color(0xFFF5A623) : null,
                  ),
                  onPressed: () async {
                    await _activeStorage.toggleSaveBook(book.id, book: book);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isSaved
                                ? context.tr('removed_success')
                                : context.tr('saved_success'),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Cover Banner
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.12),
                    theme.scaffoldBackgroundColor,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: Container(
                  height: 240,
                  width: 165,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: book.coverUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(
                        color: Colors.black12,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, _, _) => Container(
                        color: theme.colorScheme.primary,
                        child: const Icon(
                          Icons.menu_book_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Book Details Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    book.getLocalizedTitle(isBn),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    book.getLocalizedAuthor(isBn),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Rating Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RatingBarIndicator(
                        rating: book.rating,
                        itemBuilder: (context, index) => const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFF5A623),
                        ),
                        itemCount: 5,
                        itemSize: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${context.formatNum(book.rating)} (${context.formatNum(book.reviewCount)})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Metadata Pills
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMetaPill(
                        icon: Icons.pages_rounded,
                        label: context.tr('pages'),
                        value: context.formatNum(book.pageCount),
                        context: context,
                      ),
                      _buildMetaPill(
                        icon: Icons.data_usage_rounded,
                        label: context.tr('file_size'),
                        value: book.fileSize,
                        context: context,
                      ),
                      _buildMetaPill(
                        icon: Icons.calendar_today_rounded,
                        label: context.tr('published'),
                        value: context.formatNum(book.publicationYear),
                        context: context,
                      ),
                      _buildMetaPill(
                        icon: Icons.category_rounded,
                        label: context.tr('category'),
                        value: book.getLocalizedCategory(isBn),
                        context: context,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Synopsis Block
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      context.tr('synopsis'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.dividerTheme.color ?? Colors.black12,
                      ),
                    ),
                    child: Text(
                      book.getLocalizedDescription(isBn),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.6,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Builder(
            builder: (context) {
              final isDirectPdf = widget.book.downloadUrl
                  .toLowerCase()
                  .contains('.pdf');
              final hasPreview =
                  widget.book.previewUrl != null &&
                  widget.book.previewUrl!.isNotEmpty;

              if (!isDirectPdf && hasPreview) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.open_in_browser_rounded),
                    label: Text(context.tr('read_google_preview')),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _openGooglePreview,
                  ),
                );
              }

              return Row(
                children: [
                  // Read Now button
                  Expanded(
                    flex: 5,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.menu_book_rounded),
                      label: Text(context.tr('read_now')),
                      onPressed: _openReader,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Amarbooks Captcha Download Button
                  Expanded(
                    flex: 5,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.file_download_outlined),
                      label: Text(context.tr('download_pdf')),
                      onPressed: _triggerCaptchaDownload,
                    ),
                  ),

                  if (hasPreview) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: context.tr('read_google_preview'),
                      icon: const Icon(Icons.preview_rounded),
                      onPressed: _openGooglePreview,
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
