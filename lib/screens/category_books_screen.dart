import 'package:flutter/material.dart';

import '../l10n/app_translations.dart';
import '../models/book.dart';
import '../services/storage_service.dart';
import '../widgets/book_card.dart';

class CategoryBooksScreen extends StatelessWidget {
  final String title;
  final List<Book> books;
  final StorageService? storageService;

  const CategoryBooksScreen({
    super.key,
    required this.title,
    required this.books,
    this.storageService,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              '${context.formatNum(books.length)} ${context.isBengali ? 'টি বই' : 'books'}',
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
      body: books.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.menu_book_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('no_books_found'),
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.62,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return BookCard(
                  book: book,
                  type: BookCardType.grid,
                  storageService: storageService,
                );
              },
            ),
    );
  }
}
