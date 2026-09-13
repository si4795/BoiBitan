import 'package:cloud_firestore/cloud_firestore.dart';

import 'book.dart';

/// Represents a bookmarked (saved) book in the user's library, suitable
/// for local persistence and Cloud Firestore document synchronization.
///
/// Firestore document path:
/// `users/{uid}/bookmarks/{bookId}`
class BookmarkItem {
  /// The unique identifier of the book (matches [Book.id]).
  final String bookId;

  /// Book title in English / default language.
  final String title;

  /// Book title in Bengali.
  final String titleBn;

  /// Author name in English / default language.
  final String author;

  /// Author name in Bengali.
  final String authorBn;

  /// URL of the book cover artwork.
  final String coverUrl;

  /// Category name (e.g. Fiction, History, etc.).
  final String category;

  /// Timestamp when the user saved this bookmark.
  final DateTime bookmarkedAt;

  /// Creates an immutable [BookmarkItem] instance.
  const BookmarkItem({
    required this.bookId,
    required this.title,
    required this.titleBn,
    required this.author,
    required this.authorBn,
    required this.coverUrl,
    required this.category,
    required this.bookmarkedAt,
  });

  /// Factory constructor to construct a [BookmarkItem] from an existing [Book] entity.
  factory BookmarkItem.fromBook(Book book, [DateTime? timestamp]) {
    return BookmarkItem(
      bookId: book.id,
      title: book.title,
      titleBn: book.titleBn,
      author: book.author,
      authorBn: book.authorBn,
      coverUrl: book.coverUrl,
      category: book.category,
      bookmarkedAt: timestamp ?? DateTime.now(),
    );
  }

  /// Converts this bookmark back into a lightweight [Book] instance for rendering
  /// in UI components when the full catalog entry is not available locally.
  Book toBook() {
    return Book(
      id: bookId,
      title: title,
      titleBn: titleBn.isNotEmpty ? titleBn : title,
      author: author,
      authorBn: authorBn.isNotEmpty ? authorBn : author,
      category: category,
      categoryBn: category,
      description: '',
      descriptionBn: '',
      coverUrl: coverUrl,
      rating: 5.0,
      reviewCount: 0,
      pageCount: 1,
      fileSize: 'PDF',
      publicationYear: DateTime.now().year,
      downloadUrl: '',
    );
  }

  /// Serializes into a standard JSON-compatible map for local SharedPreferences caching.
  Map<String, dynamic> toMap() {
    return {
      'bookId': bookId,
      'title': title,
      'titleBn': titleBn,
      'author': author,
      'authorBn': authorBn,
      'coverUrl': coverUrl,
      'category': category,
      'bookmarkedAt': bookmarkedAt.toIso8601String(),
    };
  }

  /// Serializes into a Cloud Firestore map with a native [Timestamp].
  Map<String, dynamic> toFirestore() {
    return {
      'bookId': bookId,
      'title': title,
      'titleBn': titleBn,
      'author': author,
      'authorBn': authorBn,
      'coverUrl': coverUrl,
      'category': category,
      'bookmarkedAt': Timestamp.fromDate(bookmarkedAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Deserializes a map from local JSON storage or Firestore.
  factory BookmarkItem.fromMap(Map<String, dynamic> map) {
    DateTime parsedTime;
    final rawTime = map['bookmarkedAt'];

    if (rawTime is Timestamp) {
      parsedTime = rawTime.toDate();
    } else if (rawTime is String) {
      parsedTime = DateTime.tryParse(rawTime) ?? DateTime.now();
    } else if (rawTime is int) {
      parsedTime = DateTime.fromMillisecondsSinceEpoch(rawTime);
    } else {
      parsedTime = DateTime.now();
    }

    final bookId = map['bookId'] as String? ?? '';
    final title = map['title'] as String? ?? 'Untitled';
    final titleBn = map['titleBn'] as String? ?? title;
    final author = map['author'] as String? ?? 'Unknown';
    final authorBn = map['authorBn'] as String? ?? author;
    final coverUrl = map['coverUrl'] as String? ?? '';
    final category = map['category'] as String? ?? 'General';

    return BookmarkItem(
      bookId: bookId,
      title: title,
      titleBn: titleBn,
      author: author,
      authorBn: authorBn,
      coverUrl: coverUrl,
      category: category,
      bookmarkedAt: parsedTime,
    );
  }

  /// Factory constructor to deserialize a Firestore document snapshot.
  factory BookmarkItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    final map = Map<String, dynamic>.from(data);
    if (!map.containsKey('bookId') || (map['bookId'] as String).isEmpty) {
      map['bookId'] = snapshot.id;
    }
    return BookmarkItem.fromMap(map);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookmarkItem &&
          runtimeType == other.runtimeType &&
          bookId == other.bookId;

  @override
  int get hashCode => bookId.hashCode;
}
