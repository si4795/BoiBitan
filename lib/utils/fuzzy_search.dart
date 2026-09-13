import 'dart:math';

import '../models/book.dart';

/// Fuzzy string matching and bilingual search ranking utilities.
///
/// Implements Levenshtein distance, Trigram similarity, token matching,
/// and phonetic normalization for English and Bengali search queries.
class FuzzySearch {
  /// Computes the Levenshtein edit distance between [s1] and [s2].
  static int levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final m = s1.length;
    final n = s2.length;

    List<int> v0 = List<int>.generate(n + 1, (i) => i);
    List<int> v1 = List<int>.filled(n + 1, 0);

    for (int i = 0; i < m; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < n; j++) {
        final cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j <= n; j++) {
        v0[j] = v1[j];
      }
    }
    return v0[n];
  }

  /// Calculates normalized similarity between 0.0 (completely distinct) and 1.0 (identical)
  /// based on Levenshtein distance.
  static double levenshteinSimilarity(String s1, String s2) {
    final maxLen = max(s1.length, s2.length);
    if (maxLen == 0) return 1.0;
    final dist = levenshteinDistance(s1, s2);
    return (1.0 - (dist / maxLen)).clamp(0.0, 1.0);
  }

  /// Extracts character 3-grams with edge padding from [input].
  static Set<String> getTrigrams(String input) {
    final clean = '  $input ';
    final Set<String> trigrams = {};
    if (clean.length < 3) return trigrams;
    for (int i = 0; i <= clean.length - 3; i++) {
      trigrams.add(clean.substring(i, i + 3));
    }
    return trigrams;
  }

  /// Calculates the Trigram Dice similarity coefficient between [s1] and [s2].
  static double trigramSimilarity(String s1, String s2) {
    if (s1.isEmpty && s2.isEmpty) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final t1 = getTrigrams(s1);
    final t2 = getTrigrams(s2);
    if (t1.isEmpty || t2.isEmpty) return 0.0;

    int intersection = 0;
    for (final gram in t1) {
      if (t2.contains(gram)) {
        intersection++;
      }
    }
    return (2.0 * intersection) / (t1.length + t2.length);
  }

  /// Normalizes English and transliterated Bengali text by collapsing common
  /// phonetic variations (e.g., 'ee' -> 'i', 'oo' -> 'u', 'o' -> 'a').
  static String normalizePhonetic(String text) {
    String s = text.trim().toLowerCase();
    // Retain alphanumeric characters and Bengali Unicode block
    s = s.replaceAll(RegExp(r'[^\w\s\u0980-\u09FF]'), '');

    // Transliteration normalizations
    s = s.replaceAll('ee', 'i');
    s = s.replaceAll('oo', 'u');
    s = s.replaceAll('sh', 's');
    s = s.replaceAll('ch', 'c');
    s = s.replaceAll('ph', 'f');
    s = s.replaceAll('bh', 'b');
    s = s.replaceAll('kh', 'k');
    s = s.replaceAll('gh', 'g');
    s = s.replaceAll('dh', 'd');
    s = s.replaceAll('th', 't');
    s = s.replaceAll('zh', 'z');
    s = s.replaceAll('rh', 'r');
    s = s.replaceAll('o', 'a');
    return s;
  }

  /// Strips punctuation and collapses extra whitespace.
  static String normalize(String text) {
    return text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\u0980-\u09FF]'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Evaluates the match score between [rawQuery] and [rawTarget] between 0.0 and 1.0.
  static double matchScore(String rawQuery, String rawTarget) {
    final query = normalize(rawQuery);
    final target = normalize(rawTarget);

    if (query.isEmpty || target.isEmpty) return 0.0;
    if (query == target) return 1.0;

    // Substring match
    if (target.contains(query)) {
      return target.startsWith(query) ? 0.95 : 0.88;
    }

    // Token-level comparison
    final queryTokens = query.split(' ').where((t) => t.isNotEmpty).toList();
    final targetTokens = target.split(' ').where((t) => t.isNotEmpty).toList();

    double maxTokenScore = 0.0;
    for (final qToken in queryTokens) {
      for (final tToken in targetTokens) {
        if (qToken == tToken) {
          maxTokenScore = max(maxTokenScore, 0.92);
        } else if (tToken.contains(qToken)) {
          maxTokenScore = max(maxTokenScore, 0.85);
        } else if (qToken.contains(tToken) && tToken.length >= 3) {
          maxTokenScore = max(maxTokenScore, 0.80);
        } else {
          final dist = levenshteinDistance(qToken, tToken);
          if (dist <= 1 && min(qToken.length, tToken.length) >= 4) {
            maxTokenScore = max(maxTokenScore, 0.82);
          } else if (dist <= 2 && min(qToken.length, tToken.length) >= 6) {
            maxTokenScore = max(maxTokenScore, 0.74);
          }
        }
      }
    }

    if (maxTokenScore >= 0.74) {
      return maxTokenScore;
    }

    // Phonetic & transliteration comparison
    final phoneticQuery = normalizePhonetic(rawQuery);
    final phoneticTarget = normalizePhonetic(rawTarget);
    if (phoneticTarget.contains(phoneticQuery)) {
      return 0.84;
    }
    for (final qToken in phoneticQuery.split(' ')) {
      for (final tToken in phoneticTarget.split(' ')) {
        if (qToken.isNotEmpty &&
            (tToken == qToken || tToken.contains(qToken))) {
          return 0.82;
        }
        if (qToken.length >= 4 && tToken.length >= 4) {
          final dist = levenshteinDistance(qToken, tToken);
          if (dist <= 1) return 0.78;
        }
      }
    }

    // Trigram similarity check
    final triSim = trigramSimilarity(query, target);
    if (triSim >= 0.35) {
      return triSim;
    }

    // Overall Levenshtein similarity fallback
    final levSim = levenshteinSimilarity(query, target);
    if (levSim >= 0.65) {
      return levSim * 0.85;
    }

    return max(triSim, levSim * 0.7);
  }

  /// Canonical author names and their phonetic / typo variations
  static const Map<String, List<String>> canonicalAuthors = {
    'J.K. Rowling': [
      'jk rawling',
      'jk rowling',
      'j.k. rowling',
      'j k rowling',
      'rowling',
    ],
    'Franz Kafka': ['franz kafka', 'kafka', 'kafk', 'কাফকা', 'ফ্রাঞ্জ কাফকা'],
    'Sarat Chandra Chattopadhyay': [
      'sarat chandra',
      'saratchandra',
      'shorot chondro',
      'sharat chandra',
      'sarat chandra chattopadhyay',
      'saratchandra chattopadhyay',
      'শরৎচন্দ্র',
      'শরৎচন্দ্র চট্টোপাধ্যায়',
    ],
    'Rabindranath Tagore': [
      'rabindranath',
      'tagore',
      'robindro',
      'rabindra',
      'rabindranath tagore',
      'রবীন্দ্রনাথ',
      'রবীন্দ্রনাথ ঠাকুর',
    ],
    'Humayun Ahmed': ['humayun', 'humayun ahmed', 'হুমায়ূন', 'হুমায়ূন আহমেদ'],
    'Muhammed Zafar Iqbal': [
      'zafar iqbal',
      'muhammed zafar iqbal',
      'muhammad zafar iqbal',
      'জাফর ইকবাল',
      'মুহম্মদ জাফর ইকবাল',
      'মুহাম্মদ জাফর ইকবাল',
    ],
    'Bankim Chandra Chattopadhyay': [
      'bankim',
      'bankim chandra',
      'bankimchandra',
      'bankim chandra chattopadhyay',
      'বঙ্কিমচন্দ্র',
      'বঙ্কিমচন্দ্র চট্টোপাধ্যায়',
    ],
    'Kazi Nazrul Islam': [
      'kazi nazrul',
      'nazrul islam',
      'nazrul',
      'নজরুল',
      'কাজী নজরুল ইসলাম',
    ],
    'Bibhutibhushan Bandyopadhyay': [
      'bibhutibhushan',
      'bibhuti bhushan',
      'bibhutibhushan bandyopadhyay',
      'বিভূতিভূষণ',
      'বিভূতিভূষণ বন্দ্যোপাধ্যায়',
    ],
    'Jane Austen': ['jane austen', 'austen'],
    'George Orwell': ['george orwell', 'orwell'],
    'Arthur Conan Doyle': ['conan doyle', 'arthur conan doyle'],
    'H.G. Wells': ['h.g. wells', 'hg wells', 'wells'],
  };

  /// Resolves raw author query or candidate author to a canonical form if known.
  static String? detectCanonicalAuthor(String query) {
    final clean = normalize(query);
    final phonetic = normalizePhonetic(query);
    if (clean.isEmpty) return null;

    // Pass 1: Exact match against canonical name
    for (final canonical in canonicalAuthors.keys) {
      if (clean == normalize(canonical) ||
          phonetic == normalizePhonetic(canonical)) {
        return canonical;
      }
    }

    // Pass 2: Exact match against any alias
    for (final entry in canonicalAuthors.entries) {
      for (final alias in entry.value) {
        if (clean == normalize(alias) || phonetic == normalizePhonetic(alias)) {
          return entry.key;
        }
      }
    }

    // Pass 3: Longest alias contained in clean or phonetic
    String? bestCanonical;
    int bestMatchLength = 0;

    for (final entry in canonicalAuthors.entries) {
      for (final alias in entry.value) {
        final normAlias = normalize(alias);
        final phonAlias = normalizePhonetic(alias);
        if (normAlias.length < 4) continue;

        if (clean.contains(normAlias) || phonetic.contains(phonAlias)) {
          if (normAlias.length > bestMatchLength) {
            bestMatchLength = normAlias.length;
            bestCanonical = entry.key;
          }
        }
      }
    }

    if (bestCanonical != null) {
      return bestCanonical;
    }

    // Pass 4: Alias contains the query (only for specific queries >= 4 chars)
    if (clean.length >= 4) {
      for (final entry in canonicalAuthors.entries) {
        for (final alias in entry.value) {
          final normAlias = normalize(alias);
          if (normAlias.contains(clean)) {
            if (clean.length > bestMatchLength) {
              bestMatchLength = clean.length;
              bestCanonical = entry.key;
            }
          }
        }
      }
    }

    return bestCanonical;
  }

  /// Checks if a candidate author satisfies strict author boundaries for a target author query.
  /// If the query targets a specific author (e.g. "Sarat Chandra"), this method returns true
  /// ONLY if the candidate author matches that target, and explicitly returns false if the candidate
  /// belongs to a different known author (e.g. Bankim Chandra, Hemingway, Tagore).
  static bool satisfiesAuthorBoundary({
    required String query,
    required String candidateAuthor,
  }) {
    final targetAuthor = detectCanonicalAuthor(query);
    if (targetAuthor == null) {
      // Query does not target a recognized canonical author constraint
      return true;
    }

    final candidateCanonical = detectCanonicalAuthor(candidateAuthor);
    if (candidateCanonical != null) {
      // Both are recognized canonical authors: they must match!
      return candidateCanonical == targetAuthor;
    }

    // Candidate is not in canonical map: check match score against target author
    final score = max(
      matchScore(targetAuthor, candidateAuthor),
      matchScore(query, candidateAuthor),
    );
    return score >= 0.52;
  }

  /// Evaluates whether [book] is a junk document (e.g., <= 40 pages, thesis, dissertation,
  /// research paper, study guide, fanfiction).
  static bool isJunkDocument(Book book) {
    // Minimum page limit: discard single-page documents and pamphlets
    if (book.pageCount <= 40) {
      return true;
    }

    final lowerTitle = book.title.toLowerCase();
    final lowerDesc = book.description.toLowerCase();
    final combined = '$lowerTitle $lowerDesc';

    const junkKeywords = [
      'thesis',
      'dissertation',
      'research paper',
      'journal article',
      'summary of',
      'analysis of',
      'study guide',
      'fanfiction',
      'unofficial fan',
      'pamphlet',
      'syllabus',
      'question paper',
      'exam paper',
      'class notes',
    ];

    for (final kw in junkKeywords) {
      if (combined.contains(kw)) {
        return true;
      }
    }

    return false;
  }

  /// Ranks [books] against [query] by calculating weighted scores across
  /// titles, authors, and categories while enforcing author boundaries and junk filtering.
  static List<Book> rankBooks(
    List<Book> books,
    String query, {
    double threshold = 0.38,
    bool filterJunk = false,
  }) {
    final clean = query.trim();
    if (clean.isEmpty) return List.from(books);

    final targetAuthor = detectCanonicalAuthor(clean);
    final List<MapEntry<Book, double>> scored = [];

    for (final book in books) {
      // 1. Strict author boundary enforcement
      if (targetAuthor != null &&
          !satisfiesAuthorBoundary(
            query: clean,
            candidateAuthor: book.author,
          )) {
        continue;
      }

      // 2. Junk filter if enabled
      if (filterJunk && isJunkDocument(book)) {
        continue;
      }

      final scoreTitle = matchScore(clean, book.title) * 1.0;
      final scoreTitleBn = matchScore(clean, book.titleBn) * 1.0;
      final scoreAuthor = matchScore(clean, book.author) * 0.95;
      final scoreAuthorBn = matchScore(clean, book.authorBn) * 0.95;
      final scoreCat = matchScore(clean, book.category) * 0.6;
      final scoreCatBn = matchScore(clean, book.categoryBn) * 0.6;

      final highestScore = [
        scoreTitle,
        scoreTitleBn,
        scoreAuthor,
        scoreAuthorBn,
        scoreCat,
        scoreCatBn,
      ].reduce(max);

      if (highestScore >= threshold) {
        scored.add(MapEntry(book, highestScore));
      }
    }

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).toList();
  }
}
