import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/bookmark_item.dart';
import '../models/user_book_progress.dart';

/// Repository interface and implementation managing bidirectional Cloud Firestore
/// synchronization for user reading progress and bookmarked items.
///
/// Implements offline persistence with unlimited cache size and provides both
/// asynchronous one-off and real-time streaming interfaces.
class FirestoreLibraryRepository {
  final FirebaseFirestore? _customFirestore;

  /// Creates a [FirestoreLibraryRepository] instance with optional injected
  /// [FirebaseFirestore] instance for unit and widget testing.
  FirestoreLibraryRepository({FirebaseFirestore? firestore})
    : _customFirestore = firestore {
    _initializePersistence();
  }

  /// Whether Firebase is initialized in the current runtime environment.
  bool get isFirebaseAvailable =>
      _customFirestore != null || Firebase.apps.isNotEmpty;

  /// Lazily resolves the active [FirebaseFirestore] instance.
  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  /// Configures unlimited offline cache persistence for reliable offline-first UX.
  void _initializePersistence() {
    if (!isFirebaseAvailable) return;
    try {
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (e) {
      // Settings can only be configured once per app lifecycle; ignore subsequent calls.
      debugPrint('Firestore settings initialization note: $e');
    }
  }

  /// Reference to the user's reading history subcollection:
  /// `users/{uid}/reading_history`
  CollectionReference<Map<String, dynamic>> _readingHistoryRef(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('reading_history');
  }

  /// Reference to the user's bookmarks subcollection:
  /// `users/{uid}/bookmarks`
  CollectionReference<Map<String, dynamic>> _bookmarksRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('bookmarks');
  }

  // ===========================================================================
  // READING HISTORY OPERATIONS
  // ===========================================================================

  /// Persists reading progress for a user's book to Cloud Firestore.
  ///
  /// Guarantees idempotency via `SetOptions(merge: true)`. If offline,
  /// Firestore's offline queue seamlessly caches the write until connectivity resumes.
  Future<void> saveProgress(String uid, UserBookProgress progress) async {
    if (!isFirebaseAvailable || uid.isEmpty || uid == 'guest') {
      return;
    }

    try {
      await _readingHistoryRef(uid)
          .doc(progress.bookId)
          .set(progress.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      debugPrint(
        'FirestoreLibraryRepository.saveProgress error for $uid/${progress.bookId}: $e',
      );
      rethrow;
    }
  }

  /// Deletes reading progress record for a specific book.
  Future<void> deleteProgress(String uid, String bookId) async {
    if (!isFirebaseAvailable || uid.isEmpty || uid == 'guest') {
      return;
    }

    try {
      await _readingHistoryRef(uid).doc(bookId).delete();
    } catch (e) {
      debugPrint('FirestoreLibraryRepository.deleteProgress error: $e');
      rethrow;
    }
  }

  /// Retrieves a single reading progress record for a book, returning `null` if not found.
  Future<UserBookProgress?> getProgress(String uid, String bookId) async {
    if (!isFirebaseAvailable || uid.isEmpty || uid == 'guest') {
      return null;
    }

    try {
      final doc = await _readingHistoryRef(uid).doc(bookId).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return UserBookProgress.fromFirestore(doc);
    } catch (e) {
      debugPrint('FirestoreLibraryRepository.getProgress error: $e');
      return null;
    }
  }

  /// Fetches all reading history records for a given user.
  Future<List<UserBookProgress>> getAllProgress(String uid) async {
    if (!isFirebaseAvailable || uid.isEmpty || uid == 'guest') {
      return [];
    }

    try {
      final querySnapshot = await _readingHistoryRef(uid).get();
      return querySnapshot.docs
          .map((doc) => UserBookProgress.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('FirestoreLibraryRepository.getAllProgress error: $e');
      return [];
    }
  }

  /// Provides a real-time reactive [Stream] of the user's reading history,
  /// ordered by most recently read.
  Stream<List<UserBookProgress>> streamReadingHistory(String uid) {
    if (!isFirebaseAvailable || uid.isEmpty || uid == 'guest') {
      return Stream.value([]);
    }

    return _readingHistoryRef(uid)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => UserBookProgress.fromFirestore(doc))
              .toList();
          list.sort(
            (a, b) => b.lastReadTimestamp.compareTo(a.lastReadTimestamp),
          );
          return list;
        })
        .handleError((error) {
          debugPrint('Firestore streamReadingHistory error: $error');
          return <UserBookProgress>[];
        });
  }

  // ===========================================================================
  // BOOKMARK (SAVED BOOKS) OPERATIONS
  // ===========================================================================

  /// Persists a bookmark to Cloud Firestore.
  Future<void> saveBookmark(String uid, BookmarkItem bookmark) async {
    if (!isFirebaseAvailable || uid.isEmpty || uid == 'guest') {
      return;
    }

    try {
      await _bookmarksRef(uid)
          .doc(bookmark.bookId)
          .set(bookmark.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreLibraryRepository.saveBookmark error: $e');
      rethrow;
    }
  }

  /// Deletes a bookmark record from Cloud Firestore.
  Future<void> deleteBookmark(String uid, String bookId) async {
    if (!isFirebaseAvailable || uid.isEmpty || uid == 'guest') {
      return;
    }

    try {
      await _bookmarksRef(uid).doc(bookId).delete();
    } catch (e) {
      debugPrint('FirestoreLibraryRepository.deleteBookmark error: $e');
      rethrow;
    }
  }

  /// Fetches all bookmarks for a given user from Cloud Firestore.
  Future<List<BookmarkItem>> getAllBookmarks(String uid) async {
    if (!isFirebaseAvailable || uid.isEmpty || uid == 'guest') {
      return [];
    }

    try {
      final querySnapshot = await _bookmarksRef(uid).get();
      return querySnapshot.docs
          .map((doc) => BookmarkItem.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('FirestoreLibraryRepository.getAllBookmarks error: $e');
      return [];
    }
  }

  /// Provides a real-time reactive [Stream] of the user's bookmarked books,
  /// ordered by bookmark timestamp descending.
  Stream<List<BookmarkItem>> streamBookmarks(String uid) {
    if (!isFirebaseAvailable || uid.isEmpty || uid == 'guest') {
      return Stream.value([]);
    }

    return _bookmarksRef(uid)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => BookmarkItem.fromFirestore(doc))
              .toList();
          list.sort((a, b) => b.bookmarkedAt.compareTo(a.bookmarkedAt));
          return list;
        })
        .handleError((error) {
          debugPrint('Firestore streamBookmarks error: $error');
          return <BookmarkItem>[];
        });
  }
}
