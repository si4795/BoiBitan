import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../l10n/app_translations.dart';
import '../models/book.dart';
import '../services/download_service.dart';
import '../services/storage_service.dart';
import '../utils/fuzzy_search.dart';
import '../widgets/captcha_dialog.dart';
import '../widgets/typography_cover.dart';
import 'home_screen.dart';
import 'pdf_reader_screen.dart';
import 'web_reader_screen.dart';

enum ReadingTier { tier1DirectPdf, tier2WebStream, tier3MetadataOnly }

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
    final dl = widget.book.downloadUrl.trim();
    final hasAsset =
        widget.book.assetPdfPath != null &&
        widget.book.assetPdfPath!.trim().isNotEmpty;

    if (!hasAsset &&
        (dl.isEmpty ||
            (!dl.startsWith('http://') && !dl.startsWith('https://')))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('digital_copy_load_failed'))),
      );
      return;
    }

    CaptchaDialog.show(
      context,
      book: widget.book,
      downloadService: _downloadService,
      storageService: _activeStorage,
    );
  }

  /// Validates that a link does not point to a conflicting, entirely different author.
  bool _isMismatchedBinding(String url) {
    final lowerUrl = url.toLowerCase();
    final bookAuthor = widget.book.author.toLowerCase();
    final canonicalBookAuthor = FuzzySearch.detectCanonicalAuthor(
      widget.book.author,
    );

    for (final entry in FuzzySearch.canonicalAuthors.entries) {
      final otherAuthor = entry.key;
      if (canonicalBookAuthor != null && otherAuthor == canonicalBookAuthor) {
        continue;
      }
      if (bookAuthor.contains(otherAuthor.toLowerCase())) {
        continue;
      }
      for (final alias in entry.value) {
        final normAlias = alias.replaceAll(' ', '').toLowerCase();
        if (normAlias.length >= 6 && lowerUrl.contains(normAlias)) {
          return true;
        }
      }
    }
    return false;
  }

  bool get _hasDirectPdfDocument {
    // 1. Check if downloaded file exists in local storage
    final downloadedPath = _activeStorage.getDownloadedFilePath(widget.book.id);
    if (downloadedPath != null && downloadedPath.trim().isNotEmpty) {
      return true;
    }

    // 2. Check bundled asset PDF
    if (widget.book.assetPdfPath != null &&
        widget.book.assetPdfPath!.trim().isNotEmpty) {
      return true;
    }

    // 3. Check direct PDF URL (e.g. *.pdf, /download/...)
    final dl = widget.book.downloadUrl.trim().toLowerCase();
    if (dl.endsWith('.pdf') ||
        dl.contains('.pdf') ||
        dl.contains('/download/')) {
      if (_isMismatchedBinding(dl)) {
        return false;
      }
      return true;
    }

    return false;
  }

  String? get _webReaderUrl {
    final preview = widget.book.previewUrl?.trim();
    if (preview != null &&
        (preview.startsWith('http://') || preview.startsWith('https://'))) {
      if (!_isMismatchedBinding(preview)) {
        return preview;
      }
    }

    final dl = widget.book.downloadUrl.trim();
    if (dl.startsWith('http://') || dl.startsWith('https://')) {
      if (!_isMismatchedBinding(dl)) {
        return dl;
      }
    }

    return null;
  }

  ReadingTier get _readingTier {
    if (_hasDirectPdfDocument) {
      return ReadingTier.tier1DirectPdf;
    }
    final webUrl = _webReaderUrl;
    if (webUrl != null && webUrl.isNotEmpty) {
      return ReadingTier.tier2WebStream;
    }
    return ReadingTier.tier3MetadataOnly;
  }

  void _openUnifiedReader() {
    // Case A (Direct Document): If the link points directly to a .pdf file, open in native PDF viewer
    if (_hasDirectPdfDocument) {
      final downloadedPath = _activeStorage.getDownloadedFilePath(
        widget.book.id,
      );
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
      return;
    }

    // Case B (Web Reading Portal/Archive Stream): Launch inside in-app WebReaderScreen
    final webUrl = _webReaderUrl;
    if (webUrl != null && webUrl.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WebReaderScreen(
            url: webUrl,
            title: widget.book.getLocalizedTitle(context.isBengali),
            book: widget.book,
          ),
        ),
      );
      return;
    }

    // Error Handling: Invalid or empty URLs
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('digital_copy_load_failed'))),
    );
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
                  child: book.coverUrl.trim().isEmpty
                      ? TypographyCover(
                          title: book.getLocalizedTitle(isBn),
                          author: book.getLocalizedAuthor(isBn),
                          width: 165,
                          height: 240,
                          borderRadius: 16,
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: book.coverUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => Container(
                              color: Colors.black12,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (_, _, _) => TypographyCover(
                              title: book.getLocalizedTitle(isBn),
                              author: book.getLocalizedAuthor(isBn),
                              width: 165,
                              height: 240,
                              borderRadius: 16,
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
              final tier = _readingTier;

              // Tier 3: Metadata Only - No digital reading copy or valid stream exists anywhere online
              if (tier == ReadingTier.tier3MetadataOnly) {
                final isDark = theme.brightness == Brightness.dark;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E242C)
                        : const Color(0xFFF4ECE1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          context.tr('tier3_no_copy_info'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Tier 1 (Direct PDF) & Tier 2 (Web Reading Portal / Archive Stream)
              return Row(
                children: [
                  // Read Book button ("বইটি পড়ুন")
                  Expanded(
                    flex: 5,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.menu_book_rounded),
                      label: Text(context.tr('read_book')),
                      onPressed: _openUnifiedReader,
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
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
