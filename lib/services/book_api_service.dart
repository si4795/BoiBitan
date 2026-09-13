import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/book_catalog.dart';
import '../models/book.dart';

class BookApiService {
  final Dio _dio;

  BookApiService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 8),
                headers: {
                  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
                  'Accept': 'application/json',
                },
              ),
            );

  /// Dual-engine search: Google Books primary + Archive.org fallback/enhancer.
  Future<List<Book>> searchBooks(String query, {int limit = 25}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final List<Book> combined = [];
    final Set<String> seenTitles = {};

    // 1. Primary: Google Books API
    try {
      final googleBooks = await _searchGoogleBooks(trimmed, limit: limit);
      for (final b in googleBooks) {
        final key = b.title.toLowerCase().trim();
        if (!seenTitles.contains(key)) {
          seenTitles.add(key);
          combined.add(b);
        }
      }
    } catch (e) {
      debugPrint('Google Books search failed/rate-limited: $e');
    }

    // 2. Secondary & Public Domain PDFs: Archive.org API
    try {
      final archiveBooks = await _searchArchiveOrg(trimmed, limit: limit);
      for (final b in archiveBooks) {
        final key = b.title.toLowerCase().trim();
        if (!seenTitles.contains(key)) {
          seenTitles.add(key);
          combined.add(b);
        }
      }
    } catch (e) {
      debugPrint('Archive.org search failed: $e');
    }

    // 3. Fallback: Open Library if both returned few results
    if (combined.length < 3) {
      try {
        final olBooks = await _searchOpenLibrary(trimmed, limit: limit);
        for (final b in olBooks) {
          final key = b.title.toLowerCase().trim();
          if (!seenTitles.contains(key)) {
            seenTitles.add(key);
            combined.add(b);
          }
        }
      } catch (e) {
        debugPrint('Open Library fallback error: $e');
      }
    }

    return combined;
  }

  /// Live quick auto-suggestions for book titles and authors.
  Future<List<Map<String, String>>> getSuggestions(
    String query, {
    int limit = 6,
  }) async {
    final clean = query.trim().toLowerCase();
    if (clean.length < 2) return [];

    final List<Map<String, String>> suggestions = [];
    final Set<String> seen = {};

    // A. Local Catalog candidates
    for (final b in BookCatalog.books) {
      final t = b.title;
      final tBn = b.titleBn;
      final a = b.author;
      final aBn = b.authorBn;

      if (t.toLowerCase().contains(clean) && seen.add(t)) {
        suggestions.add({'text': t, 'title': t, 'subtitle': a, 'type': 'book'});
      } else if (tBn.contains(clean) && seen.add(tBn)) {
        suggestions.add({'text': tBn, 'title': tBn, 'subtitle': aBn, 'type': 'book'});
      } else if (a.toLowerCase().contains(clean) && seen.add(a)) {
        suggestions.add({'text': a, 'title': a, 'subtitle': 'Author', 'type': 'author'});
      } else if (aBn.contains(clean) && seen.add(aBn)) {
        suggestions.add({'text': aBn, 'title': aBn, 'subtitle': 'লেখক', 'type': 'author'});
      }

      if (suggestions.length >= limit) return suggestions;
    }

    // B. Quick candidate query from Google Books (limit 3)
    try {
      final uri = 'https://www.googleapis.com/books/v1/volumes?q=${Uri.encodeComponent(query)}&maxResults=3';
      final res = await _dio.get<Map<String, dynamic>>(uri);
      final items = res.data?['items'] as List?;
      if (items != null) {
        for (final item in items) {
          final info = item['volumeInfo'] as Map<String, dynamic>?;
          if (info == null) continue;
          final title = info['title']?.toString() ?? '';
          final authors = (info['authors'] as List?)?.join(', ') ?? '';
          if (title.isNotEmpty && seen.add(title)) {
            suggestions.add({
              'text': title,
              'title': title,
              'subtitle': authors,
              'type': 'book',
            });
          }
          if (suggestions.length >= limit) break;
        }
      }
    } catch (_) {
      // Ignore network suggestion errors
    }

    return suggestions;
  }

  // --- PRIVATE ENGINES ---

  Future<List<Book>> _searchGoogleBooks(String query, {int limit = 25}) async {
    final uri = 'https://www.googleapis.com/books/v1/volumes?q=${Uri.encodeComponent(query)}&maxResults=$limit';
    final response = await _dio.get<Map<String, dynamic>>(uri);
    final items = response.data?['items'] as List?;
    if (items == null) return [];

    final List<Book> books = [];
    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;
      try {
        final info = item['volumeInfo'] as Map<String, dynamic>? ?? {};
        final id = 'gb_${item['id']}';
        final title = (info['title'] as String?)?.trim() ?? 'Untitled Book';
        final authorsList = info['authors'] as List?;
        final author = authorsList != null && authorsList.isNotEmpty
            ? authorsList.join(', ')
            : 'Unknown Author';

        final desc = (info['description'] as String?)?.trim() ??
            'Published by ${info['publisher'] ?? 'Google Books'}.';
        final pageCount = (info['pageCount'] as num?)?.toInt() ?? 200;
        final rawYear = info['publishedDate']?.toString() ?? '2020';
        final yearMatch = RegExp(r'\d{4}').firstMatch(rawYear);
        final pubYear = yearMatch != null ? int.parse(yearMatch.group(0)!) : 2020;

        String cover = '';
        final imgLinks = info['imageLinks'] as Map<String, dynamic>?;
        if (imgLinks != null) {
          cover = (imgLinks['thumbnail'] ?? imgLinks['smallThumbnail'] ?? '')
              .toString()
              .replaceFirst('http://', 'https://');
        }

        final previewUrl = info['previewLink']?.toString() ??
            info['infoLink']?.toString();

        // Check if accessInfo has direct pdf link
        final accessInfo = item['accessInfo'] as Map<String, dynamic>?;
        final pdfDownload = accessInfo?['pdf']?['downloadLink']?.toString();
        final isPdfAvailable = accessInfo?['pdf']?['isAvailable'] == true;

        final downloadUrl = pdfDownload ??
            (isPdfAvailable ? previewUrl ?? '' : previewUrl ?? 'https://books.google.com');

        final categoriesList = info['categories'] as List?;
        final category = categoriesList != null && categoriesList.isNotEmpty
            ? categoriesList.first.toString()
            : 'General';

        final rating = (info['averageRating'] as num?)?.toDouble() ?? 4.5;
        final ratingsCount = (info['ratingsCount'] as num?)?.toInt() ?? 10;

        books.add(
          Book(
            id: id,
            title: title,
            titleBn: title,
            author: author,
            authorBn: author,
            category: category,
            categoryBn: category,
            description: desc,
            descriptionBn: desc,
            coverUrl: cover,
            rating: rating,
            reviewCount: ratingsCount,
            pageCount: pageCount,
            fileSize: '${((pageCount * 0.035) + 1.2).toStringAsFixed(1)} MB',
            publicationYear: pubYear,
            downloadUrl: downloadUrl,
            previewUrl: previewUrl,
          ),
        );
      } catch (e) {
        debugPrint('Error parsing Google Book: $e');
      }
    }
    return books;
  }

  Future<List<Book>> _searchArchiveOrg(String query, {int limit = 25}) async {
    final cleanQuery = Uri.encodeComponent(query);
    final uri = 'https://archive.org/advancedsearch.php?q=$cleanQuery&fl[]=identifier,title,creator,year,description,downloads&output=json&rows=$limit';

    final response = await _dio.get<Map<String, dynamic>>(uri);
    final docs = response.data?['response']?['docs'] as List?;
    if (docs == null) return [];

    final List<Book> books = [];
    for (final doc in docs) {
      if (doc is! Map<String, dynamic>) continue;
      try {
        final id = doc['identifier']?.toString();
        if (id == null || id.isEmpty) continue;

        final title = (doc['title'] as String?)?.trim() ?? id;
        final creator = (doc['creator'] as String?)?.trim() ?? 'Unknown Author';
        final rawYear = doc['year']?.toString() ?? '2000';
        final pubYear = int.tryParse(rawYear) ?? 2000;
        final desc = (doc['description'] as String?)?.trim() ??
            'Public domain archive work by $creator.';

        final downloadUrl =
            'https://ia801901.us.archive.org/24/items/$id/$id.pdf';
        final previewUrl = 'https://archive.org/details/$id';
        final coverUrl = 'https://archive.org/services/img/$id';

        books.add(
          Book(
            id: 'ia_$id',
            title: title,
            titleBn: title,
            author: creator,
            authorBn: creator,
            category: 'Archive Collection',
            categoryBn: 'সংগ্রহশালা',
            description: desc,
            descriptionBn: desc,
            coverUrl: coverUrl,
            rating: 4.8,
            reviewCount: 24,
            pageCount: 180,
            fileSize: '6.5 MB',
            publicationYear: pubYear,
            downloadUrl: downloadUrl,
            previewUrl: previewUrl,
          ),
        );
      } catch (e) {
        debugPrint('Error parsing Archive.org doc: $e');
      }
    }
    return books;
  }

  Future<List<Book>> _searchOpenLibrary(String query, {int limit = 25}) async {
    final uri = 'https://openlibrary.org/search.json?q=${Uri.encodeComponent(query)}&limit=$limit';
    final response = await _dio.get<Map<String, dynamic>>(uri);
    final docs = response.data?['docs'] as List?;
    if (docs == null) return [];

    final List<Book> books = [];
    for (final doc in docs) {
      if (doc is! Map<String, dynamic>) continue;
      try {
        final rawKey = doc['key']?.toString() ?? '';
        final cleanKey = rawKey.replaceAll('/works/', '').replaceAll('/', '_');
        final id = cleanKey.isNotEmpty
            ? 'ol_$cleanKey'
            : 'ol_${DateTime.now().microsecondsSinceEpoch}';

        final title = (doc['title'] as String?)?.trim() ?? 'Untitled Book';
        final authorsList = doc['author_name'];
        String author = 'Unknown Author';
        if (authorsList is List && authorsList.isNotEmpty) {
          author = authorsList.first.toString();
        }

        final pubYear = (doc['first_publish_year'] as num?)?.toInt() ?? 2000;
        final pageCount =
            (doc['number_of_pages_median'] as num?)?.toInt() ?? 200;

        String coverUrl = '';
        if (doc['cover_i'] != null) {
          coverUrl =
              'https://covers.openlibrary.org/b/id/${doc['cover_i']}-M.jpg';
        }

        String downloadUrl = '';
        final iaList = doc['ia'];
        if (iaList is List && iaList.isNotEmpty) {
          final iaId = iaList.first.toString();
          downloadUrl = 'https://ia801901.us.archive.org/24/items/$iaId/$iaId.pdf';
        } else {
          downloadUrl = 'https://openlibrary.org$rawKey';
        }

        books.add(
          Book(
            id: id,
            title: title,
            titleBn: title,
            author: author,
            authorBn: author,
            category: 'Literature',
            categoryBn: 'সাহিত্য',
            description: 'Written by $author. First published in $pubYear.',
            descriptionBn: 'লেখক: $author। প্রকাশকাল: $pubYear।',
            coverUrl: coverUrl,
            rating: (doc['ratings_average'] as num?)?.toDouble() ?? 4.5,
            reviewCount: (doc['ratings_count'] as num?)?.toInt() ?? 10,
            pageCount: pageCount,
            fileSize: '5.5 MB',
            publicationYear: pubYear,
            downloadUrl: downloadUrl,
            previewUrl: 'https://openlibrary.org$rawKey',
          ),
        );
      } catch (e) {
        debugPrint('Error in OL fallback: $e');
      }
    }
    return books;
  }
}
