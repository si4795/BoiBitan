import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/book_catalog.dart';
import '../l10n/app_translations.dart';
import '../models/book.dart';
import '../services/download_service.dart';
import '../services/storage_service.dart';
import '../widgets/book_card.dart';
import 'pdf_reader_screen.dart';

class MyLibraryScreen extends StatefulWidget {
  final StorageService storageService;
  final VoidCallback? onExploreTap;

  const MyLibraryScreen({
    super.key,
    required this.storageService,
    this.onExploreTap,
  });

  @override
  State<MyLibraryScreen> createState() => _MyLibraryScreenState();
}

class _MyLibraryScreenState extends State<MyLibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DownloadService _downloadService = DownloadService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 54, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
            if (action != null) ...[const SizedBox(height: 20), action],
          ],
        ),
      ),
    );
  }

  // --- TAB 1: Continue Reading ---
  Widget _buildContinueReadingTab() {
    final progressMap = widget.storageService.readingProgress;
    final inProgressBooks = <MapEntry<Book, int>>[];

    for (final entry in progressMap.entries) {
      final book = BookCatalog.getById(entry.key);
      if (book != null) {
        inProgressBooks.add(MapEntry(book, entry.value.lastReadPage));
      } else {
        final bookmark = widget.storageService.savedBookmarks[entry.key];
        if (bookmark != null) {
          inProgressBooks.add(
            MapEntry(bookmark.toBook(), entry.value.lastReadPage),
          );
        }
      }
    }

    if (inProgressBooks.isEmpty) {
      return _buildEmptyState(
        icon: Icons.menu_book_rounded,
        title: context.tr('empty_continue'),
        subtitle: context.tr('empty_continue_hint'),
      );
    }

    final isBn = context.isBengali;
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: inProgressBooks.length,
      itemBuilder: (context, index) {
        final item = inProgressBooks[index];
        final book = item.key;
        final lastPage = item.value;
        final progress = widget.storageService.getProgress(book.id);
        final pct = progress?.percentage ?? 0;
        final downloadedPath = widget.storageService.getDownloadedFilePath(
          book.id,
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: book.coverUrl,
                    width: 65,
                    height: 90,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(color: Colors.black12),
                    errorWidget: (_, _, _) => Container(
                      color: theme.colorScheme.primary,
                      child: const Icon(Icons.book, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.getLocalizedTitle(isBn),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        book.getLocalizedAuthor(isBn),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(
                            alpha: 0.75,
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      // Linear progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct / 100,
                          minHeight: 6,
                          backgroundColor: theme.colorScheme.primary.withValues(
                            alpha: 0.15,
                          ),
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.tr('reading_progress_label', [
                              context.formatNum(pct),
                            ]),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Text(
                            '${context.tr('pages')}: ${context.formatNum(lastPage + 1)}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.play_arrow_rounded),
                  tooltip: context.tr('read_now'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PdfReaderScreen(
                          book: book,
                          localPdfPath: downloadedPath,
                          storageService: widget.storageService,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- TAB 2: Saved Books (Wishlist) ---
  Widget _buildSavedBooksTab() {
    final savedIds = widget.storageService.savedBookIds;
    final savedBookmarks = widget.storageService.savedBookmarks;
    final savedBooks = <Book>[];

    for (final id in savedIds) {
      final catalogBook = BookCatalog.getById(id);
      if (catalogBook != null) {
        savedBooks.add(catalogBook);
      } else if (savedBookmarks.containsKey(id)) {
        savedBooks.add(savedBookmarks[id]!.toBook());
      }
    }

    if (savedBooks.isEmpty) {
      return _buildEmptyState(
        icon: Icons.bookmark_outline_rounded,
        title: context.tr('empty_saved'),
        subtitle: context.tr('empty_saved_hint'),
        action: widget.onExploreTap != null
            ? ElevatedButton.icon(
                icon: const Icon(Icons.explore_rounded),
                label: Text(context.tr('browse_books')),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: widget.onExploreTap,
              )
            : null,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: savedBooks.length,
      itemBuilder: (context, index) {
        final book = savedBooks[index];
        return BookCard(
          book: book,
          type: BookCardType.list,
          storageService: widget.storageService,
        );
      },
    );
  }

  // --- TAB 3: Downloaded Files (Offline) ---
  Widget _buildDownloadedFilesTab() {
    final downloadedFiles = widget.storageService.downloadedFiles;

    if (downloadedFiles.isEmpty) {
      return _buildEmptyState(
        icon: Icons.download_done_rounded,
        title: context.tr('empty_downloaded'),
        subtitle: context.tr('empty_downloaded_hint'),
      );
    }

    final isBn = context.isBengali;
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: downloadedFiles.length,
      itemBuilder: (context, index) {
        final fileRecord = downloadedFiles[index];
        final bookId = fileRecord['bookId'] as String;
        final localPath = fileRecord['localPath'] as String;
        final book = BookCatalog.getById(bookId);

        final title = isBn
            ? (book?.titleBn ??
                  fileRecord['titleBn'] ??
                  fileRecord['title'] ??
                  fileRecord['fileName'] ??
                  'বই')
            : (book?.title ??
                  fileRecord['title'] ??
                  fileRecord['fileName'] ??
                  'Book');
        final author = isBn
            ? (book?.authorBn ??
                  fileRecord['authorBn'] ??
                  fileRecord['author'] ??
                  'অজ্ঞাত')
            : (book?.author ?? fileRecord['author'] ?? 'Unknown');
        final coverUrl = book?.coverUrl ?? fileRecord['coverUrl'] as String?;
        final fileSize =
            fileRecord['fileSize'] as String? ?? book?.fileSize ?? 'PDF';

        final resolvedBook =
            book ??
            Book(
              id: bookId,
              title: fileRecord['title'] ?? fileRecord['fileName'] ?? 'Book',
              titleBn: fileRecord['titleBn'] ?? fileRecord['title'] ?? 'বই',
              author: fileRecord['author'] ?? 'Unknown',
              authorBn:
                  fileRecord['authorBn'] ?? fileRecord['author'] ?? 'অজ্ঞাত',
              category: 'Downloaded',
              categoryBn: 'ডাউনলোডকৃত',
              rating: 5.0,
              reviewCount: 0,
              pageCount: 100,
              fileSize: fileSize,
              publicationYear: 2024,
              description: '',
              descriptionBn: '',
              coverUrl: coverUrl ?? '',
              downloadUrl: '',
            );

        void openReader() {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PdfReaderScreen(
                book: resolvedBook,
                localPdfPath: localPath,
                storageService: widget.storageService,
              ),
            ),
          );
        }

        final hasValidCover = coverUrl != null && coverUrl.isNotEmpty;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: openReader,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: hasValidCover
                        ? CachedNetworkImage(
                            imageUrl: coverUrl,
                            width: 55,
                            height: 75,
                            fit: BoxFit.cover,
                            placeholder: (_, _) =>
                                Container(color: Colors.black12),
                            errorWidget: (_, _, _) => Container(
                              color: theme.colorScheme.primary,
                              child: const Icon(
                                Icons.picture_as_pdf_rounded,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : Container(
                            width: 55,
                            height: 75,
                            color: theme.colorScheme.primary,
                            child: const Icon(
                              Icons.picture_as_pdf_rounded,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          author,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                fileSize,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '• ${context.tr('offline_ready')}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Action Menu: Read Offline or Open Externally or Delete
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (val) async {
                      if (val == 'read') {
                        openReader();
                      } else if (val == 'external') {
                        _downloadService.openWithExternalViewer(localPath);
                      } else if (val == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(context.tr('delete')),
                            content: Text(
                              context.tr('delete_download_confirm'),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(context.tr('cancel')),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: Text(context.tr('confirm')),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await _downloadService.deleteFile(localPath);
                          await widget.storageService.removeDownloadedFile(
                            bookId,
                          );
                        }
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'read',
                        child: Row(
                          children: [
                            const Icon(Icons.menu_book_rounded, size: 20),
                            const SizedBox(width: 10),
                            Text(context.tr('read_offline')),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'external',
                        child: Row(
                          children: [
                            const Icon(Icons.open_in_new_rounded, size: 20),
                            const SizedBox(width: 10),
                            Text(context.tr('open_external')),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              context.tr('delete'),
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('library_title')),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.textTheme.bodySmall?.color,
          indicatorColor: theme.colorScheme.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: [
            Tab(
              icon: const Icon(Icons.auto_stories_rounded, size: 20),
              text: context.tr('tab_continue_reading'),
            ),
            Tab(
              icon: const Icon(Icons.bookmark_rounded, size: 20),
              text: context.tr('tab_saved_books'),
            ),
            Tab(
              icon: const Icon(Icons.cloud_done_rounded, size: 20),
              text: context.tr('tab_downloaded_files'),
            ),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.storageService,
        builder: (context, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildContinueReadingTab(),
              _buildSavedBooksTab(),
              _buildDownloadedFilesTab(),
            ],
          );
        },
      ),
    );
  }
}
