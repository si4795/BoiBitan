import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../l10n/app_translations.dart';
import '../models/book.dart';
import '../screens/book_details_screen.dart';
import '../screens/home_screen.dart';
import '../services/storage_service.dart';
import 'typography_cover.dart';

enum BookCardType { shelf, grid, list }

class BookCard extends StatelessWidget {
  final Book book;
  final BookCardType type;
  final StorageService? storageService;
  final VoidCallback? onTap;

  const BookCard({
    super.key,
    required this.book,
    this.type = BookCardType.shelf,
    this.storageService,
    this.onTap,
  });

  void _navigateToDetails(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookDetailsScreen(
          book: book,
          storageService: storageService ?? context.storage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case BookCardType.shelf:
        return _buildShelfCard(context);
      case BookCardType.grid:
        return _buildGridCard(context);
      case BookCardType.list:
        return _buildListCard(context);
    }
  }

  Widget _buildCoverImage({
    required double width,
    required double height,
    required double borderRadius,
    required BuildContext context,
  }) {
    final hasCover = book.coverUrl.trim().isNotEmpty;
    final isBn = context.isBengali;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Stack(
        children: [
          if (hasCover)
            CachedNetworkImage(
              imageUrl: book.coverUrl,
              width: width,
              height: height,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: width,
                height: height,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF22272E)
                    : const Color(0xFFE5E0D8),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => TypographyCover(
                title: book.getLocalizedTitle(isBn),
                author: book.getLocalizedAuthor(isBn),
                width: width,
                height: height,
                borderRadius: borderRadius,
              ),
            )
          else
            TypographyCover(
              title: book.getLocalizedTitle(isBn),
              author: book.getLocalizedAuthor(isBn),
              width: width,
              height: height,
              borderRadius: borderRadius,
            ),
          // Bookmark quick toggle button
          if ((storageService ?? context.storage) != null)
            PositionfulBookmark(
              bookId: book.id,
              book: book,
              storageService: (storageService ?? context.storage)!,
            ),
        ],
      ),
    );
  }

  // 1. Shelf Card (Horizontal list)
  Widget _buildShelfCard(BuildContext context) {
    final theme = Theme.of(context);
    final isBn = context.isBengali;

    return GestureDetector(
      onTap: () => _navigateToDetails(context),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCoverImage(
              width: 140,
              height: 190,
              borderRadius: 14,
              context: context,
            ),
            const SizedBox(height: 8),
            Text(
              book.getLocalizedTitle(isBn),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              book.getLocalizedAuthor(isBn),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.7,
                ),
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                RatingBarIndicator(
                  rating: book.rating,
                  itemBuilder: (context, index) =>
                      const Icon(Icons.star_rounded, color: Color(0xFFF5A623)),
                  itemCount: 5,
                  itemSize: 13,
                ),
                const SizedBox(width: 4),
                Text(
                  context.formatNum(book.rating),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 2. Grid Card (Search results & categories)
  Widget _buildGridCard(BuildContext context) {
    final theme = Theme.of(context);
    final isBn = context.isBengali;

    return GestureDetector(
      onTap: () => _navigateToDetails(context),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildCoverImage(
                width: double.infinity,
                height: double.infinity,
                borderRadius: 0,
                context: context,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.getLocalizedTitle(isBn),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    book.getLocalizedAuthor(isBn),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.7,
                      ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: Color(0xFFF5A623),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            context.formatNum(book.rating),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        book.fileSize,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. List Card
  Widget _buildListCard(BuildContext context) {
    final theme = Theme.of(context);
    final isBn = context.isBengali;

    return GestureDetector(
      onTap: () => _navigateToDetails(context),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              _buildCoverImage(
                width: 70,
                height: 95,
                borderRadius: 10,
                context: context,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.getLocalizedTitle(isBn),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.getLocalizedAuthor(isBn),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withValues(
                          alpha: 0.75,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            book.getLocalizedCategory(isBn),
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.star_rounded,
                          size: 15,
                          color: Color(0xFFF5A623),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          context.formatNum(book.rating),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PositionfulBookmark extends StatelessWidget {
  final String bookId;
  final Book? book;
  final StorageService storageService;

  const PositionfulBookmark({
    super.key,
    required this.bookId,
    this.book,
    required this.storageService,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 6,
      right: 6,
      child: ListenableBuilder(
        listenable: storageService,
        builder: (context, _) {
          final isSaved = storageService.isBookSaved(bookId);
          return GestureDetector(
            onTap: () => storageService.toggleSaveBook(bookId, book: book),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSaved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_outline_rounded,
                color: isSaved ? const Color(0xFFF5A623) : Colors.white,
                size: 18,
              ),
            ),
          );
        },
      ),
    );
  }
}
