import 'package:cloud_firestore/cloud_firestore.dart';

import 'book.dart';
import 'reading_progress.dart';

/// Represents a user's reading progress for a specific book, suitable for
/// both local persistence and Cloud Firestore document synchronization.
///
/// Firestore document path:
/// `users/{uid}/reading_history/{bookId}`
class UserBookProgress {
  /// The unique identifier of the book (matches [Book.id]).
  final String bookId;

  /// The index of the last read page (0-indexed).
  final int lastReadPage;

  /// Total number of pages in the book.
  final int totalPages;

  /// The percentage of completion (0 to 100).
  final int progressPercentage;

  /// Timestamp of when the book was last read.
  final DateTime lastReadTimestamp;

  /// Cached book title in English/default language.
  final String? title;

  /// Cached book title in Bengali.
  final String? titleBn;

  /// Cached author name.
  final String? author;

  /// Cached author name in Bengali.
  final String? authorBn;

  /// Cached URL of the book cover image.
  final String? coverUrl;

  /// Creates an immutable [UserBookProgress] record.
  const UserBookProgress({
    required this.bookId,
    required this.lastReadPage,
    required this.totalPages,
    required this.progressPercentage,
    required this.lastReadTimestamp,
    this.title,
    this.titleBn,
    this.author,
    this.authorBn,
    this.coverUrl,
  });

  /// Factory constructor to build [UserBookProgress] from a [ReadingProgress]
  /// instance with optional [Book] metadata for enriched cloud storage.
  factory UserBookProgress.fromReadingProgress(
    ReadingProgress progress, {
    Book? book,
  }) {
    return UserBookProgress(
      bookId: progress.bookId,
      lastReadPage: progress.lastReadPage,
      totalPages: progress.totalPages,
      progressPercentage: progress.percentage,
      lastReadTimestamp: progress.lastReadAt,
      title: book?.title,
      titleBn: book?.titleBn,
      author: book?.author,
      authorBn: book?.authorBn,
      coverUrl: book?.coverUrl,
    );
  }

  /// Converts this progress record back into a local [ReadingProgress] entity.
  ReadingProgress toReadingProgress() {
    return ReadingProgress(
      bookId: bookId,
      lastReadPage: lastReadPage,
      totalPages: totalPages,
      lastReadAt: lastReadTimestamp,
    );
  }

  /// Creates a copy of this object with the given fields replaced by new values.
  UserBookProgress copyWith({
    String? bookId,
    int? lastReadPage,
    int? totalPages,
    int? progressPercentage,
    DateTime? lastReadTimestamp,
    String? title,
    String? titleBn,
    String? author,
    String? authorBn,
    String? coverUrl,
  }) {
    return UserBookProgress(
      bookId: bookId ?? this.bookId,
      lastReadPage: lastReadPage ?? this.lastReadPage,
      totalPages: totalPages ?? this.totalPages,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      lastReadTimestamp: lastReadTimestamp ?? this.lastReadTimestamp,
      title: title ?? this.title,
      titleBn: titleBn ?? this.titleBn,
      author: author ?? this.author,
      authorBn: authorBn ?? this.authorBn,
      coverUrl: coverUrl ?? this.coverUrl,
    );
  }

  /// Serializes the model into a standard JSON-compatible map for local SharedPreferences caching.
  Map<String, dynamic> toMap() {
    return {
      'bookId': bookId,
      'lastReadPage': lastReadPage,
      'totalPages': totalPages,
      'progressPercentage': progressPercentage,
      'lastReadTimestamp': lastReadTimestamp.toIso8601String(),
      'title': title,
      'titleBn': titleBn,
      'author': author,
      'authorBn': authorBn,
      'coverUrl': coverUrl,
    };
  }

  /// Serializes the model for Cloud Firestore with a native [Timestamp].
  Map<String, dynamic> toFirestore() {
    return {
      'bookId': bookId,
      'lastReadPage': lastReadPage,
      'totalPages': totalPages,
      'progressPercentage': progressPercentage,
      'lastReadTimestamp': Timestamp.fromDate(lastReadTimestamp),
      'title': title ?? '',
      'titleBn': titleBn ?? '',
      'author': author ?? '',
      'authorBn': authorBn ?? '',
      'coverUrl': coverUrl ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Deserializes a map from local JSON storage or Firestore.
  factory UserBookProgress.fromMap(Map<String, dynamic> map) {
    DateTime parsedTime;
    final rawTime = map['lastReadTimestamp'];

    if (rawTime is Timestamp) {
      parsedTime = rawTime.toDate();
    } else if (rawTime is String) {
      parsedTime = DateTime.tryParse(rawTime) ?? DateTime.now();
    } else if (rawTime is int) {
      parsedTime = DateTime.fromMillisecondsSinceEpoch(rawTime);
    } else {
      parsedTime = DateTime.now();
    }

    final totalPages = (map['totalPages'] as num?)?.toInt() ?? 1;
    final lastReadPage = (map['lastReadPage'] as num?)?.toInt() ?? 0;

    int pct = (map['progressPercentage'] as num?)?.toInt() ?? 0;
    if (pct <= 0 && totalPages > 0) {
      pct = ((lastReadPage + 1) / totalPages * 100).round();
      if (pct > 100) pct = 100;
      if (pct < 0) pct = 0;
    }

    return UserBookProgress(
      bookId: map['bookId'] as String? ?? '',
      lastReadPage: lastReadPage,
      totalPages: totalPages,
      progressPercentage: pct,
      lastReadTimestamp: parsedTime,
      title: map['title'] as String?,
      titleBn: map['titleBn'] as String?,
      author: map['author'] as String?,
      authorBn: map['authorBn'] as String?,
      coverUrl: map['coverUrl'] as String?,
    );
  }

  /// Factory constructor to deserialize a Firestore document snapshot.
  factory UserBookProgress.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    final map = Map<String, dynamic>.from(data);
    if (!map.containsKey('bookId') || (map['bookId'] as String).isEmpty) {
      map['bookId'] = snapshot.id;
    }
    return UserBookProgress.fromMap(map);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserBookProgress &&
          runtimeType == other.runtimeType &&
          bookId == other.bookId &&
          lastReadPage == other.lastReadPage &&
          totalPages == other.totalPages &&
          lastReadTimestamp.millisecondsSinceEpoch ==
              other.lastReadTimestamp.millisecondsSinceEpoch;

  @override
  int get hashCode =>
      bookId.hashCode ^
      lastReadPage.hashCode ^
      totalPages.hashCode ^
      lastReadTimestamp.millisecondsSinceEpoch.hashCode;
}
