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

  /// Ranks [books] against [query] by calculating weighted scores across
  /// titles, authors, and categories.
  static List<Book> rankBooks(
    List<Book> books,
    String query, {
    double threshold = 0.38,
  }) {
    final clean = query.trim();
    if (clean.isEmpty) return List.from(books);

    final List<MapEntry<Book, double>> scored = [];

    for (final book in books) {
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
