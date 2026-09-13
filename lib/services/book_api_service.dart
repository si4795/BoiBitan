import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/book_catalog.dart';
import '../models/book.dart';
import '../utils/fuzzy_search.dart';
import 'scraper_service.dart';

/// Service for searching and aggregating books from open repositories including
/// Curated Bengali Scraper (Amarbooks), Internet Archive, Google Books, Gutendex,
/// and Open Library.
///
/// Applies language integrity checks, strict author boundaries, and junk document filtering.
class BookApiService {
  final Dio _dio;
  final ScraperService _scraperService;

  BookApiService({Dio? dio, ScraperService? scraperService})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
              headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
                'Accept': 'application/json',
              },
            ),
          ),
      _scraperService = scraperService ?? ScraperService();

  /// Detects whether the search query targets Bengali ('bn') or English ('en') content.
  /// Returns null if ambiguous or general.
  static String? detectTargetLanguage(String query) {
    if (RegExp(r'[\u0980-\u09FF]').hasMatch(query)) {
      return 'bn';
    }

    final lower = query.toLowerCase().trim();
    final phonetic = FuzzySearch.normalizePhonetic(lower);

    const bengaliKeywords = [
      'rabindra',
      'robindro',
      'tagore',
      'sarat',
      'saratchandra',
      'chattopadhyay',
      'chatterjee',
      'chandra',
      'humayun',
      'ahmed',
      'sharat',
      'bibhutibhushan',
      'bandyopadhyay',
      'tarasankar',
      'manik',
      'zafar',
      'iqbal',
      'bankim',
      'sukumar',
      'satyajit',
      'shirshendu',
      'sunil',
      'gangopadhyay',
      'kazi',
      'nazrul',
      'devdas',
      'gitanjali',
      'shesher',
      'kobita',
      'srikanta',
      'anandamath',
      'pather',
      'panchali',
      'chokher',
      'bali',
      'feluda',
      'byomkesh',
      'sukanta',
      'jashim',
      'jasim',
    ];

    for (final kw in bengaliKeywords) {
      if (lower.contains(kw) || phonetic.contains(kw)) {
        return 'bn';
      }
    }

    return null;
  }

  /// Evaluates whether a candidate record's language metadata satisfies the
  /// intended [targetLanguage] constraint.
  ///
  /// Prevents language mismatches such as Hindi or Sanskrit translations appearing
  /// for Bengali classic queries.
  static bool satisfiesLanguageIntegrity({
    required dynamic rawLanguage,
    required String candidateTitle,
    required String? targetLanguage,
  }) {
    if (targetLanguage == null) return true;

    List<String> langCodes = [];
    if (rawLanguage is String) {
      langCodes.add(rawLanguage.toLowerCase().trim());
    } else if (rawLanguage is List) {
      langCodes.addAll(
        rawLanguage.map((e) => e.toString().toLowerCase().trim()),
      );
    }

    final hasBengaliChars = RegExp(r'[\u0980-\u09FF]').hasMatch(candidateTitle);

    if (targetLanguage == 'bn') {
      const excludedLanguages = [
        'hin',
        'hindi',
        'san',
        'sanskrit',
        'urd',
        'urdu',
        'tam',
        'tamil',
        'tel',
        'telugu',
        'mar',
        'marathi',
        'guj',
        'gujarati',
        'kan',
        'kannada',
      ];

      for (final code in langCodes) {
        for (final excluded in excludedLanguages) {
          if (code == excluded || code.contains(excluded)) {
            return false;
          }
        }
      }

      final isTaggedBengali = langCodes.any(
        (c) => c.contains('ben') || c.contains('bn') || c.contains('bengali'),
      );
      if (isTaggedBengali) return true;

      return hasBengaliChars;
    }

    if (targetLanguage == 'en') {
      if (hasBengaliChars) return false;
      if (langCodes.isEmpty) return true;
      return langCodes.any(
        (c) => c.contains('eng') || c.contains('en') || c.contains('english'),
      );
    }

    return true;
  }

  /// Searches books across curated Bengali repositories (Amarbooks),
  /// Archive.org, Google Books, Gutendex (Project Gutenberg), and Open Library.
  ///
  /// Prioritizes curated Bengali scraping for Bengali queries, and Google Books
  /// for English/Global queries, while strictly eliminating junk documents and
  /// enforcing strict author boundaries.
  Future<List<Book>> searchBooks(String query, {int limit = 25}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final targetLang = detectTargetLanguage(trimmed);
    final canonicalAuthor = FuzzySearch.detectCanonicalAuthor(trimmed);
    final isBengali = targetLang == 'bn';

    final List<Book> combined = [];
    final Set<String> seenKeys = {};

    void addUnique(List<Book> candidates) {
      for (final b in candidates) {
        // 1. Enforce junk document filter (>40 pages, no thesis/research/fanfiction)
        if (FuzzySearch.isJunkDocument(b)) {
          continue;
        }

        // 2. Enforce strict author boundary
        if (!FuzzySearch.satisfiesAuthorBoundary(
          query: trimmed,
          candidateAuthor: b.author,
        )) {
          continue;
        }

        final key =
            '${b.title.toLowerCase().trim()}_${b.author.toLowerCase().trim()}';
        if (seenKeys.add(key)) {
          combined.add(b);
        }
      }
    }

    if (isBengali) {
      // Priority 1: Curated Bengali Background Scraper (Amarbooks)
      try {
        final scrapedBooks = await _scraperService.scrapeBooks(
          trimmed,
          limit: limit,
        );
        addUnique(scrapedBooks);
      } catch (e) {
        debugPrint('Scraper search notice: $e');
      }

      // Priority 2: Archive.org strictly filtered with creator & Bengali language tags
      if (combined.length < limit) {
        try {
          final archiveBooks = await _searchArchiveOrg(
            trimmed,
            limit: limit,
            targetLanguage: 'bn',
            canonicalAuthor: canonicalAuthor,
          );
          addUnique(archiveBooks);
        } catch (e) {
          debugPrint('Archive.org search notice: $e');
        }
      }

      // Priority 3: Google Books Volume API with Bengali filter
      if (combined.length < limit) {
        try {
          final googleBooks = await _searchGoogleBooks(
            trimmed,
            limit: limit,
            targetLanguage: 'bn',
            canonicalAuthor: canonicalAuthor,
          );
          addUnique(googleBooks);
        } catch (e) {
          debugPrint('Google Books search notice: $e');
        }
      }

      // Priority 4: Open Library
      if (combined.length < 5) {
        try {
          final olBooks = await _searchOpenLibrary(
            trimmed,
            limit: limit,
            targetLanguage: 'bn',
          );
          addUnique(olBooks);
        } catch (e) {
          debugPrint('Open Library search notice: $e');
        }
      }
    } else {
      // Global / English queries:
      // Priority 1: Google Books Volume API with inauthor/title targeting
      try {
        final googleBooks = await _searchGoogleBooks(
          trimmed,
          limit: limit,
          targetLanguage: 'en',
          canonicalAuthor: canonicalAuthor,
        );
        addUnique(googleBooks);
      } catch (e) {
        debugPrint('Google Books search notice: $e');
      }

      // Priority 2: Gutendex (Project Gutenberg)
      if (combined.length < limit) {
        try {
          final gutenbergBooks = await _searchGutendex(
            trimmed,
            limit: limit,
            targetLanguage: 'en',
          );
          addUnique(gutenbergBooks);
        } catch (e) {
          debugPrint('Gutendex search notice: $e');
        }
      }

      // Priority 3: Archive.org
      if (combined.length < limit) {
        try {
          final archiveBooks = await _searchArchiveOrg(
            trimmed,
            limit: limit,
            targetLanguage: 'en',
            canonicalAuthor: canonicalAuthor,
          );
          addUnique(archiveBooks);
        } catch (e) {
          debugPrint('Archive.org search notice: $e');
        }
      }

      // Priority 4: Open Library
      if (combined.length < 5) {
        try {
          final olBooks = await _searchOpenLibrary(
            trimmed,
            limit: limit,
            targetLanguage: 'en',
          );
          addUnique(olBooks);
        } catch (e) {
          debugPrint('Open Library search notice: $e');
        }
      }
    }

    return FuzzySearch.rankBooks(
      combined,
      trimmed,
      threshold: 0.15,
      filterJunk: true,
    );
  }

  /// Generates live auto-suggestions using local catalog fuzzy matching
  /// combined with live Google Books volume titles.
  Future<List<Map<String, String>>> getSuggestions(
    String query, {
    int limit = 6,
  }) async {
    final clean = query.trim();
    if (clean.length < 2) return [];

    final List<Map<String, String>> suggestions = [];
    final Set<String> seen = {};

    // Match against the curated local catalog
    final scoredLocal = <MapEntry<Map<String, String>, double>>[];
    for (final b in BookCatalog.books) {
      final t = b.title;
      final tBn = b.titleBn;
      final a = b.author;
      final aBn = b.authorBn;

      final scoreT = FuzzySearch.matchScore(clean, t);
      final scoreTBn = FuzzySearch.matchScore(clean, tBn);
      final scoreA = FuzzySearch.matchScore(clean, a);
      final scoreABn = FuzzySearch.matchScore(clean, aBn);

      if (scoreT >= 0.45 && seen.add(t)) {
        scoredLocal.add(
          MapEntry({
            'text': t,
            'title': t,
            'subtitle': a,
            'type': 'book',
          }, scoreT),
        );
      } else if (scoreTBn >= 0.45 && seen.add(tBn)) {
        scoredLocal.add(
          MapEntry({
            'text': tBn,
            'title': tBn,
            'subtitle': aBn,
            'type': 'book',
          }, scoreTBn),
        );
      } else if (scoreA >= 0.50 && seen.add(a)) {
        scoredLocal.add(
          MapEntry({
            'text': a,
            'title': a,
            'subtitle': 'Author',
            'type': 'author',
          }, scoreA),
        );
      } else if (scoreABn >= 0.50 && seen.add(aBn)) {
        scoredLocal.add(
          MapEntry({
            'text': aBn,
            'title': aBn,
            'subtitle': 'লেখক',
            'type': 'author',
          }, scoreABn),
        );
      }
    }

    scoredLocal.sort((a, b) => b.value.compareTo(a.value));
    for (final entry in scoredLocal) {
      suggestions.add(entry.key);
      if (suggestions.length >= limit) return suggestions;
    }

    // Supplementary suggestions from Google Books
    try {
      final uri =
          'https://www.googleapis.com/books/v1/volumes?q=${Uri.encodeComponent(clean)}&maxResults=3';
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
      // Gracefully ignore network errors on suggestions
    }

    return suggestions;
  }

  /// Queries Internet Archive with public domain text filtering and language integrity.
  Future<List<Book>> _searchArchiveOrg(
    String query, {
    int limit = 25,
    String? targetLanguage,
    String? canonicalAuthor,
  }) async {
    final cleanQuery = query.replaceAll('"', '').trim();
    final isBengaliScript = RegExp(r'[\u0980-\u09FF]').hasMatch(cleanQuery);
    final isBengaliTarget = targetLanguage == 'bn' || isBengaliScript;

    // When querying Archive.org API for Bengali book titles or authors, append language filter priority:
    // `AND (language:(bengali OR ben) OR mediatype:(texts))` to prioritize Bengali versions first.
    String languageClause = '';
    if (isBengaliTarget) {
      languageClause = ' AND (language:(bengali OR ben) OR mediatype:(texts))';
    }

    String creatorClause = 'creator:("$cleanQuery")';
    if (canonicalAuthor != null && canonicalAuthor.isNotEmpty) {
      creatorClause = 'creator:("$canonicalAuthor") OR creator:("$cleanQuery")';
    }

    final q =
        '(title:("$cleanQuery") OR $creatorClause) AND mediatype:(texts) AND format:(PDF)$languageClause';
    final uri =
        'https://archive.org/advancedsearch.php?q=${Uri.encodeComponent(q)}&fl[]=identifier,title,creator,year,description,downloads,language,format&sort[]=downloads+desc&output=json&rows=$limit';

    final response = await _dio.get<Map<String, dynamic>>(uri);
    final docs = response.data?['response']?['docs'] as List?;
    if (docs == null) return [];

    // For queries entered in Bengali script or literature, strictly prioritize records with language tags ben or bengali
    if (isBengaliTarget) {
      docs.sort((a, b) {
        if (a is! Map || b is! Map) return 0;
        final aLang = (a['language'] ?? '').toString().toLowerCase();
        final bLang = (b['language'] ?? '').toString().toLowerCase();
        final aIsBen = aLang.contains('ben') || aLang.contains('bengali');
        final bIsBen = bLang.contains('ben') || bLang.contains('bengali');
        if (aIsBen && !bIsBen) return -1;
        if (!aIsBen && bIsBen) return 1;

        if (isBengaliScript) {
          final aTitle = (a['title'] ?? '').toString();
          final bTitle = (b['title'] ?? '').toString();
          final aHasBn = RegExp(r'[\u0980-\u09FF]').hasMatch(aTitle);
          final bHasBn = RegExp(r'[\u0980-\u09FF]').hasMatch(bTitle);
          if (aHasBn && !bHasBn) return -1;
          if (!aHasBn && bHasBn) return 1;
        }

        final aDl = (a['downloads'] is num) ? (a['downloads'] as num) : 0;
        final bDl = (b['downloads'] is num) ? (b['downloads'] as num) : 0;
        return bDl.compareTo(aDl);
      });
    }

    final List<Book> books = [];
    for (final doc in docs) {
      if (doc is! Map<String, dynamic>) continue;
      try {
        final id = doc['identifier']?.toString();
        if (id == null || id.isEmpty) continue;

        final title = (doc['title'] as String?)?.trim() ?? id;
        final rawLang = doc['language'];

        if (!satisfiesLanguageIntegrity(
          rawLanguage: rawLang,
          candidateTitle: title,
          targetLanguage: targetLanguage,
        )) {
          continue;
        }

        final creator = (doc['creator'] as String?)?.trim() ?? 'Unknown Author';
        final rawYear = doc['year']?.toString() ?? '2000';
        final pubYear = int.tryParse(rawYear) ?? 2000;
        final desc =
            (doc['description'] as String?)?.trim() ??
            'Public domain archive work by $creator.';

        final downloadUrl = 'https://archive.org/download/$id/$id.pdf';
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

  /// Queries Gutendex (Project Gutenberg) for verified public domain literature.
  Future<List<Book>> _searchGutendex(
    String query, {
    int limit = 20,
    String? targetLanguage,
  }) async {
    final uri =
        'https://gutendex.com/books/?search=${Uri.encodeComponent(query)}';
    final response = await _dio.get<Map<String, dynamic>>(uri);
    final results = response.data?['results'] as List?;
    if (results == null) return [];

    final List<Book> books = [];
    for (final item in results) {
      if (item is! Map<String, dynamic>) continue;
      try {
        final idNum = item['id'];
        if (idNum == null) continue;
        final id = 'pg_$idNum';

        final title = (item['title'] as String?)?.trim() ?? 'Untitled Classic';
        final rawLangs = item['languages'];

        if (!satisfiesLanguageIntegrity(
          rawLanguage: rawLangs,
          candidateTitle: title,
          targetLanguage: targetLanguage,
        )) {
          continue;
        }

        final authorsList = item['authors'] as List?;
        String author = 'Unknown Author';
        if (authorsList != null && authorsList.isNotEmpty) {
          final firstAuthor = authorsList.first as Map<String, dynamic>?;
          author = firstAuthor?['name']?.toString() ?? 'Unknown Author';
        }

        final formats = item['formats'] as Map<String, dynamic>? ?? {};
        final pdfUrl = formats['application/pdf']?.toString();
        final epubUrl = formats['application/epub+zip']?.toString();
        final htmlUrl = formats['text/html']?.toString();
        final textUrl = formats['text/plain; charset=utf-8']?.toString();
        final coverUrl = formats['image/jpeg']?.toString() ?? '';

        final downloadUrl =
            pdfUrl ??
            epubUrl ??
            htmlUrl ??
            textUrl ??
            'https://www.gutenberg.org/ebooks/$idNum';

        final previewUrl = 'https://www.gutenberg.org/ebooks/$idNum';

        books.add(
          Book(
            id: id,
            title: title,
            titleBn: title,
            author: author,
            authorBn: author,
            category: 'Gutenberg Classics',
            categoryBn: 'গুটেনবার্গ ক্লাসিকস',
            description: 'Public domain literary classic by $author.',
            descriptionBn: 'উন্মুক্ত বিশ্বসাহিত্যের অমর সৃষ্টি। লেখক: $author।',
            coverUrl: coverUrl,
            rating: 4.9,
            reviewCount: (item['download_count'] as num?)?.toInt() ?? 100,
            pageCount: 220,
            fileSize: '4.2 MB',
            publicationYear: 1900,
            downloadUrl: downloadUrl,
            previewUrl: previewUrl,
          ),
        );
        if (books.length >= limit) break;
      } catch (e) {
        debugPrint('Error parsing Gutendex book: $e');
      }
    }
    return books;
  }

  /// Queries Google Books API with access checks, high-res covers, and language filtering.
  Future<List<Book>> _searchGoogleBooks(
    String query, {
    int limit = 25,
    String? targetLanguage,
    String? canonicalAuthor,
  }) async {
    String apiQuery = query;
    if (canonicalAuthor != null && canonicalAuthor.isNotEmpty) {
      apiQuery = 'inauthor:"$canonicalAuthor"';
    }
    final langParam = targetLanguage == 'bn' ? '&langRestrict=bn' : '';
    final uri =
        'https://www.googleapis.com/books/v1/volumes?q=${Uri.encodeComponent(apiQuery)}$langParam&maxResults=$limit';
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
        final rawLang = info['language'];

        if (!satisfiesLanguageIntegrity(
          rawLanguage: rawLang,
          candidateTitle: title,
          targetLanguage: targetLanguage,
        )) {
          continue;
        }

        final authorsList = info['authors'] as List?;
        final author = authorsList != null && authorsList.isNotEmpty
            ? authorsList.join(', ')
            : 'Unknown Author';

        final desc =
            (info['description'] as String?)?.trim() ??
            'Published by ${info['publisher'] ?? 'Google Books'}.';
        final pageCount = (info['pageCount'] as num?)?.toInt() ?? 200;

        // Discard junk single-page documents / short samples
        if (pageCount <= 40) continue;

        final rawYear = info['publishedDate']?.toString() ?? '2020';
        final yearMatch = RegExp(r'\d{4}').firstMatch(rawYear);
        final pubYear = yearMatch != null
            ? int.parse(yearMatch.group(0)!)
            : 2020;

        String cover = '';
        final imgLinks = info['imageLinks'] as Map<String, dynamic>?;
        if (imgLinks != null) {
          String rawImg =
              (imgLinks['extraLarge'] ??
                      imgLinks['large'] ??
                      imgLinks['medium'] ??
                      imgLinks['thumbnail'] ??
                      imgLinks['smallThumbnail'] ??
                      '')
                  .toString()
                  .replaceFirst('http://', 'https://');
          if (rawImg.contains('zoom=1')) {
            rawImg = rawImg.replaceAll('zoom=1', 'zoom=2');
          }
          rawImg = rawImg.replaceAll('&edge=curl', '');
          cover = rawImg;
        }

        final previewUrl =
            info['previewLink']?.toString() ?? info['infoLink']?.toString();

        final accessInfo = item['accessInfo'] as Map<String, dynamic>?;
        final pdfDownload = accessInfo?['pdf']?['downloadLink']?.toString();
        final isPdfAvailable = accessInfo?['pdf']?['isAvailable'] == true;

        final downloadUrl =
            pdfDownload ??
            (isPdfAvailable
                ? previewUrl ?? ''
                : previewUrl ?? 'https://books.google.com');

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

  /// Queries Open Library with Internet Archive link extraction.
  Future<List<Book>> _searchOpenLibrary(
    String query, {
    int limit = 25,
    String? targetLanguage,
  }) async {
    final uri =
        'https://openlibrary.org/search.json?q=${Uri.encodeComponent(query)}&limit=$limit';
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
        final rawLang = doc['language'];

        if (!satisfiesLanguageIntegrity(
          rawLanguage: rawLang,
          candidateTitle: title,
          targetLanguage: targetLanguage,
        )) {
          continue;
        }

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
          downloadUrl = 'https://archive.org/download/$iaId/$iaId.pdf';
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
        debugPrint('Error in OL search: $e');
      }
    }
    return books;
  }
}
