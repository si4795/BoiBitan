import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/book_catalog.dart';
import '../models/book.dart';
import '../models/bookmark_item.dart';
import '../models/reading_progress.dart';
import '../models/user_book_progress.dart';
import '../repositories/firestore_library_repository.dart';

/// Senior-grade local and cloud storage service managing user library isolation,
/// reading progress, bookmarks, and downloads.
///
/// All library items are strictly scoped per user ID (Firebase Auth UID,
/// sanitized local account, or 'guest' namespace) to prevent cross-account
/// data leakage on shared physical devices.
class StorageService extends ChangeNotifier {
  // Global auth registration key (retained across accounts)
  static const String _registeredUsersKey = 'boibitan_registered_users';

  // Legacy unscoped keys for backward compatibility migration
  static const String _legacySavedBooksKey = 'boibitan_saved_books';
  static const String _legacyReadingProgressKey = 'boibitan_reading_progress';
  static const String _legacyDownloadedFilesKey = 'boibitan_downloaded_files';

  late SharedPreferences _prefs;
  final FirestoreLibraryRepository _firestoreRepo;

  bool _isInitialized = false;
  String _currentUserId = 'guest';

  // In-memory state isolated to [_currentUserId]
  final Set<String> _savedBookIds = {};
  final Map<String, BookmarkItem> _savedBookmarksMap = {};
  final Map<String, ReadingProgress> _progressMap = {};
  final Map<String, Map<String, dynamic>> _downloadsMap = {};
  final Map<String, Map<String, dynamic>> _registeredUsers = {};

  // Active Cloud Firestore stream subscriptions
  StreamSubscription<List<UserBookProgress>>? _readingHistorySubscription;
  StreamSubscription<List<BookmarkItem>>? _bookmarksSubscription;

  /// Creates a [StorageService] instance with an optional injected
  /// [FirestoreLibraryRepository] for test isolation.
  StorageService({FirestoreLibraryRepository? firestoreRepository})
    : _firestoreRepo = firestoreRepository ?? FirestoreLibraryRepository();

  /// Whether the storage service has finished loading its initial state.
  bool get isInitialized => _isInitialized;

  /// The active user ID scoping all current library operations.
  String get currentUserId => _currentUserId;

  /// Read-only view of book IDs currently bookmarked by the active user.
  Set<String> get savedBookIds => Set.unmodifiable(_savedBookIds);

  /// Read-only view of full bookmark metadata for the active user.
  Map<String, BookmarkItem> get savedBookmarks =>
      Map.unmodifiable(_savedBookmarksMap);

  /// Read-only map of reading progress entries for the active user.
  Map<String, ReadingProgress> get readingProgress =>
      Map.unmodifiable(_progressMap);

  /// Read-only list of downloaded file metadata for the active user.
  List<Map<String, dynamic>> get downloadedFiles =>
      _downloadsMap.values.toList();

  // --- Scoped Key Generators ---
  String _scopedSavedBooksKey(String uid) => 'boibitan_${uid}_saved_books';
  String _scopedSavedBookmarksKey(String uid) =>
      'boibitan_${uid}_saved_bookmarks';
  String _scopedReadingProgressKey(String uid) =>
      'boibitan_${uid}_reading_progress';
  String _scopedDownloadedFilesKey(String uid) =>
      'boibitan_${uid}_downloaded_files';

  /// Initializes the service, loads global user registries, and hydrates
  /// local storage for the specified or default guest session.
  Future<void> init({String? initialUserId}) async {
    if (_isInitialized) return;
    _prefs = await SharedPreferences.getInstance();

    // 1. Hydrate global user registry
    _loadRegisteredUsers();

    // 2. Hydrate session scoped to initialUserId
    await switchUser(initialUserId ?? 'guest', skipNotify: true);

    _isInitialized = true;
    notifyListeners();
  }

  // ===========================================================================
  // USER SWITCHING & LIFECYCLE MANAGEMENT
  // ===========================================================================

  /// Switches active user namespace, flushes in-memory cache to prevent data
  /// leakage, loads new user data, and binds Firestore real-time sync.
  Future<void> switchUser(String? newUserId, {bool skipNotify = false}) async {
    final sanitizedUid = (newUserId != null && newUserId.trim().isNotEmpty)
        ? newUserId.trim().replaceAll(RegExp(r'[\\/:*?"<>| ]'), '_')
        : 'guest';

    // 1. Cancel active Firestore subscriptions from previous user
    await _cancelCloudSyncSubscriptions();

    // 2. Thoroughly flush in-memory state
    _savedBookIds.clear();
    _savedBookmarksMap.clear();
    _progressMap.clear();
    _downloadsMap.clear();

    // 3. Update active user pointer
    _currentUserId = sanitizedUid;

    // 4. Load scoped local data from SharedPreferences
    _loadScopedBookmarks(_currentUserId);
    _loadScopedReadingProgress(_currentUserId);
    _loadScopedDownloads(_currentUserId);

    // 5. Initialize bidirectional Cloud Firestore sync if logged in
    if (_currentUserId != 'guest' && _firestoreRepo.isFirebaseAvailable) {
      _bindCloudSyncStreams(_currentUserId);
    }

    if (!skipNotify) {
      notifyListeners();
    }
  }

  /// Handles user logout by flushing active session memory, canceling cloud
  /// subscriptions, and falling back to a clean guest scope.
  Future<void> onUserLogout() async {
    await _cancelCloudSyncSubscriptions();
    _savedBookIds.clear();
    _savedBookmarksMap.clear();
    _progressMap.clear();
    _downloadsMap.clear();

    _currentUserId = 'guest';
    _loadScopedBookmarks(_currentUserId);
    _loadScopedReadingProgress(_currentUserId);
    _loadScopedDownloads(_currentUserId);

    notifyListeners();
  }

  /// Cancels active Firestore stream subscriptions safely.
  Future<void> _cancelCloudSyncSubscriptions() async {
    await _readingHistorySubscription?.cancel();
    _readingHistorySubscription = null;
    await _bookmarksSubscription?.cancel();
    _bookmarksSubscription = null;
  }

  // ===========================================================================
  // SCOPED LOCAL HYDRATION HELPERS
  // ===========================================================================

  void _loadRegisteredUsers() {
    final usersRaw = _prefs.getString(_registeredUsersKey);
    if (usersRaw != null) {
      try {
        final decoded = jsonDecode(usersRaw) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          _registeredUsers[key.toLowerCase()] = Map<String, dynamic>.from(
            value as Map,
          );
        });
      } catch (e) {
        debugPrint('Error parsing registered users: $e');
      }
    }

    // Seed default demo account if registry is empty
    if (_registeredUsers.isEmpty) {
      const defaultEmail = 'reader@boibitan.app';
      _registeredUsers[defaultEmail] = {
        'name': 'সুধী পাঠক',
        'email': defaultEmail,
        'password': 'password123',
        'isVerified': true,
        'registeredAt': DateTime.now().toIso8601String(),
      };
      _prefs.setString(_registeredUsersKey, jsonEncode(_registeredUsers));
    }
  }

  void _loadScopedBookmarks(String uid) {
    // 1. Try rich bookmarks map first
    final bookmarksRaw = _prefs.getString(_scopedSavedBookmarksKey(uid));
    if (bookmarksRaw != null) {
      try {
        final decoded = jsonDecode(bookmarksRaw) as Map<String, dynamic>;
        decoded.forEach((key, val) {
          final bookmark = BookmarkItem.fromMap(val as Map<String, dynamic>);
          _savedBookmarksMap[key] = bookmark;
          _savedBookIds.add(key);
        });
        return;
      } catch (e) {
        debugPrint('Error decoding scoped bookmarks: $e');
      }
    }

    // 2. Try string list for this user
    final savedList = _prefs.getStringList(_scopedSavedBooksKey(uid));
    if (savedList != null && savedList.isNotEmpty) {
      _savedBookIds.addAll(savedList);
      for (final id in savedList) {
        final book = BookCatalog.getById(id);
        if (book != null) {
          _savedBookmarksMap[id] = BookmarkItem.fromBook(book);
        }
      }
      return;
    }

    // 3. Fallback: Migrate legacy unscoped bookmarks into guest if applicable
    if (uid == 'guest') {
      final legacyList = _prefs.getStringList(_legacySavedBooksKey) ?? [];
      if (legacyList.isNotEmpty) {
        _savedBookIds.addAll(legacyList);
        for (final id in legacyList) {
          final book = BookCatalog.getById(id);
          if (book != null) {
            _savedBookmarksMap[id] = BookmarkItem.fromBook(book);
          }
        }
        _persistBookmarks(uid);
      }
    }
  }

  void _loadScopedReadingProgress(String uid) {
    final progressRaw = _prefs.getString(_scopedReadingProgressKey(uid));
    if (progressRaw != null) {
      try {
        final decoded = jsonDecode(progressRaw) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          _progressMap[key] = ReadingProgress.fromMap(
            value as Map<String, dynamic>,
          );
        });
        return;
      } catch (e) {
        debugPrint('Error parsing scoped reading progress: $e');
      }
    }

    // Fallback: Migrate legacy reading progress for guest
    if (uid == 'guest') {
      final legacyRaw = _prefs.getString(_legacyReadingProgressKey);
      if (legacyRaw != null) {
        try {
          final decoded = jsonDecode(legacyRaw) as Map<String, dynamic>;
          decoded.forEach((key, value) {
            _progressMap[key] = ReadingProgress.fromMap(
              value as Map<String, dynamic>,
            );
          });
          _persistReadingProgress(uid);
        } catch (e) {
          debugPrint('Error migrating legacy reading progress: $e');
        }
      }
    }
  }

  void _loadScopedDownloads(String uid) {
    final downloadsRaw = _prefs.getString(_scopedDownloadedFilesKey(uid));
    if (downloadsRaw != null) {
      try {
        final decoded = jsonDecode(downloadsRaw) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          final map = Map<String, dynamic>.from(value as Map);
          final path = map['localPath'] as String?;
          // Retain only entries whose physical file still exists
          if (path != null && File(path).existsSync()) {
            _downloadsMap[key] = map;
          }
        });
        return;
      } catch (e) {
        debugPrint('Error parsing scoped downloads: $e');
      }
    }

    // Fallback: Migrate legacy downloads for guest
    if (uid == 'guest') {
      final legacyRaw = _prefs.getString(_legacyDownloadedFilesKey);
      if (legacyRaw != null) {
        try {
          final decoded = jsonDecode(legacyRaw) as Map<String, dynamic>;
          decoded.forEach((key, value) {
            final map = Map<String, dynamic>.from(value as Map);
            final path = map['localPath'] as String?;
            if (path != null && File(path).existsSync()) {
              _downloadsMap[key] = map;
            }
          });
          _persistDownloads(uid);
        } catch (e) {
          debugPrint('Error migrating legacy downloads: $e');
        }
      }
    }
  }

  // ===========================================================================
  // CLOUD FIRESTORE SYNC & CONFLICT RESOLUTION
  // ===========================================================================

  void _bindCloudSyncStreams(String uid) {
    _readingHistorySubscription = _firestoreRepo
        .streamReadingHistory(uid)
        .listen(
          (remoteList) => _mergeRemoteReadingHistory(remoteList, uid),
          onError: (e) {
            debugPrint('Firestore reading history stream error: $e');
          },
        );

    _bookmarksSubscription = _firestoreRepo
        .streamBookmarks(uid)
        .listen(
          (remoteBookmarks) => _mergeRemoteBookmarks(remoteBookmarks, uid),
          onError: (e) {
            debugPrint('Firestore bookmarks stream error: $e');
          },
        );
  }

  /// Two-way sync with latest-timestamp-wins conflict resolution.
  void _mergeRemoteReadingHistory(
    List<UserBookProgress> remoteList,
    String uid,
  ) {
    if (uid != _currentUserId) return;
    bool hasChanges = false;

    for (final remote in remoteList) {
      final local = _progressMap[remote.bookId];
      if (local == null) {
        // Remote has reading progress that local does not
        _progressMap[remote.bookId] = remote.toReadingProgress();
        hasChanges = true;
      } else if (remote.lastReadTimestamp.isAfter(local.lastReadAt)) {
        // Remote is newer, take remote
        _progressMap[remote.bookId] = remote.toReadingProgress();
        hasChanges = true;
      } else if (local.lastReadAt.isAfter(remote.lastReadTimestamp)) {
        // Local is newer, push local to cloud
        final book = BookCatalog.getById(local.bookId);
        final userProgress = UserBookProgress.fromReadingProgress(
          local,
          book: book,
        );
        _firestoreRepo.saveProgress(uid, userProgress).catchError((_) {});
      }
    }

    if (hasChanges) {
      _persistReadingProgress(uid);
      notifyListeners();
    }
  }

  /// Merges remote bookmarks with local bookmarks.
  void _mergeRemoteBookmarks(List<BookmarkItem> remoteList, String uid) {
    if (uid != _currentUserId) return;
    bool hasChanges = false;

    for (final remote in remoteList) {
      if (!_savedBookmarksMap.containsKey(remote.bookId)) {
        _savedBookmarksMap[remote.bookId] = remote;
        _savedBookIds.add(remote.bookId);
        hasChanges = true;
      }
    }

    // If local has bookmarks not yet in remote, push them to remote
    for (final entry in _savedBookmarksMap.entries) {
      final existsInRemote = remoteList.any((b) => b.bookId == entry.key);
      if (!existsInRemote) {
        _firestoreRepo.saveBookmark(uid, entry.value).catchError((_) {});
      }
    }

    if (hasChanges) {
      _persistBookmarks(uid);
      notifyListeners();
    }
  }

  // ===========================================================================
  // SAVED BOOKS (BOOKMARKS / WISHLIST)
  // ===========================================================================

  /// Checks whether a book is currently bookmarked by the active user.
  bool isBookSaved(String bookId) {
    return _savedBookIds.contains(bookId) ||
        _savedBookmarksMap.containsKey(bookId);
  }

  /// Toggles a book's saved state. If [book] is provided, it enriches the bookmark
  /// record with full metadata for offline and cloud sync.
  Future<void> toggleSaveBook(String bookId, {Book? book}) async {
    final isSaved = isBookSaved(bookId);
    final targetUid = _currentUserId;

    if (isSaved) {
      _savedBookIds.remove(bookId);
      _savedBookmarksMap.remove(bookId);
      await _persistBookmarks(targetUid);
      notifyListeners();

      if (targetUid != 'guest' && _firestoreRepo.isFirebaseAvailable) {
        _firestoreRepo.deleteBookmark(targetUid, bookId).catchError((e) {
          debugPrint('Firestore deleteBookmark background error: $e');
        });
      }
    } else {
      final resolvedBook = book ?? BookCatalog.getById(bookId);
      final bookmark = resolvedBook != null
          ? BookmarkItem.fromBook(resolvedBook)
          : BookmarkItem(
              bookId: bookId,
              title: bookId,
              titleBn: bookId,
              author: 'Unknown',
              authorBn: 'অজ্ঞাত',
              coverUrl: '',
              category: 'General',
              bookmarkedAt: DateTime.now(),
            );

      _savedBookIds.add(bookId);
      _savedBookmarksMap[bookId] = bookmark;
      await _persistBookmarks(targetUid);
      notifyListeners();

      if (targetUid != 'guest' && _firestoreRepo.isFirebaseAvailable) {
        _firestoreRepo.saveBookmark(targetUid, bookmark).catchError((e) {
          debugPrint('Firestore saveBookmark background error: $e');
        });
      }
    }
  }

  Future<void> _persistBookmarks(String uid) async {
    await _prefs.setStringList(
      _scopedSavedBooksKey(uid),
      _savedBookIds.toList(),
    );
    final encoded = jsonEncode(
      _savedBookmarksMap.map((key, val) => MapEntry(key, val.toMap())),
    );
    await _prefs.setString(_scopedSavedBookmarksKey(uid), encoded);
  }

  // ===========================================================================
  // READING PROGRESS
  // ===========================================================================

  /// Retrieves reading progress for a specific book under the active user.
  ReadingProgress? getProgress(String bookId) => _progressMap[bookId];

  /// Retrieves the last read page index (0-indexed) for a specific book.
  int getLastReadPage(String bookId) => _progressMap[bookId]?.lastReadPage ?? 0;

  /// Optimistically records reading progress locally, then queues sync to Cloud Firestore.
  Future<void> saveReadingProgress({
    required String bookId,
    required int lastReadPage,
    required int totalPages,
    Book? book,
  }) async {
    final progress = ReadingProgress(
      bookId: bookId,
      lastReadPage: lastReadPage,
      totalPages: totalPages,
      lastReadAt: DateTime.now(),
    );

    _progressMap[bookId] = progress;
    final targetUid = _currentUserId;
    await _persistReadingProgress(targetUid);
    notifyListeners();

    // Background cloud sync
    if (targetUid != 'guest' && _firestoreRepo.isFirebaseAvailable) {
      final resolvedBook = book ?? BookCatalog.getById(bookId);
      final userProgress = UserBookProgress.fromReadingProgress(
        progress,
        book: resolvedBook,
      );
      _firestoreRepo.saveProgress(targetUid, userProgress).catchError((e) {
        debugPrint('Firestore saveProgress background error: $e');
      });
    }
  }

  Future<void> _persistReadingProgress([String? uid]) async {
    final targetUid = uid ?? _currentUserId;
    final encoded = jsonEncode(
      _progressMap.map((key, val) => MapEntry(key, val.toMap())),
    );
    await _prefs.setString(_scopedReadingProgressKey(targetUid), encoded);
  }

  // ===========================================================================
  // DOWNLOADED FILES REGISTRY (SCOPED)
  // ===========================================================================

  /// Checks if a book has a verified downloaded PDF file on disk for the active user.
  bool isBookDownloaded(String bookId) {
    final record = _downloadsMap[bookId];
    if (record == null) return false;
    final path = record['localPath'] as String?;
    if (path == null) return false;
    final file = File(path);
    if (!file.existsSync()) {
      _downloadsMap.remove(bookId);
      _persistDownloads(_currentUserId);
      return false;
    }
    return true;
  }

  /// Returns the validated file path of a downloaded book, or `null`.
  String? getDownloadedFilePath(String bookId) {
    final record = _downloadsMap[bookId];
    if (record == null) return null;
    final path = record['localPath'] as String?;
    if (path != null && File(path).existsSync()) {
      return path;
    }
    return null;
  }

  /// Registers a newly completed download in the active user's download catalog.
  Future<void> registerBookDownload({
    required Book book,
    required String localPath,
    required String fileSize,
  }) async {
    _downloadsMap[book.id] = {
      'bookId': book.id,
      'title': book.title,
      'titleBn': book.titleBn,
      'author': book.author,
      'authorBn': book.authorBn,
      'coverUrl': book.coverUrl,
      'localPath': localPath,
      'fileName': '${book.title}.pdf',
      'fileSize': fileSize,
      'downloadedAt': DateTime.now().toIso8601String(),
    };
    await _persistDownloads(_currentUserId);
    notifyListeners();
  }

  /// Registers download with custom or raw parameters.
  Future<void> registerDownload({
    required String bookId,
    required String localPath,
    required String fileName,
    required String fileSize,
    String? title,
    String? titleBn,
    String? author,
    String? authorBn,
    String? coverUrl,
  }) async {
    _downloadsMap[bookId] = {
      'bookId': bookId,
      'title': title ?? fileName,
      'titleBn': titleBn ?? title ?? fileName,
      'author': author ?? '',
      'authorBn': authorBn ?? author ?? '',
      'coverUrl': coverUrl ?? '',
      'localPath': localPath,
      'fileName': fileName,
      'fileSize': fileSize,
      'downloadedAt': DateTime.now().toIso8601String(),
    };
    await _persistDownloads(_currentUserId);
    notifyListeners();
  }

  /// Removes a downloaded book from the registry and deletes its local file.
  Future<void> removeDownloadedFile(String bookId) async {
    final record = _downloadsMap.remove(bookId);
    if (record != null) {
      final path = record['localPath'] as String?;
      if (path != null) {
        try {
          final file = File(path);
          if (file.existsSync()) {
            await file.delete();
          }
        } catch (e) {
          debugPrint('Error deleting downloaded file at $path: $e');
        }
      }
      await _persistDownloads(_currentUserId);
      notifyListeners();
    }
  }

  Future<void> _persistDownloads([String? uid]) async {
    final targetUid = uid ?? _currentUserId;
    await _prefs.setString(
      _scopedDownloadedFilesKey(targetUid),
      jsonEncode(_downloadsMap),
    );
  }

  // ===========================================================================
  // LOCAL AUTHENTICATION DATABASE
  // ===========================================================================

  bool isEmailRegistered(String email) {
    return _registeredUsers.containsKey(email.trim().toLowerCase());
  }

  Map<String, dynamic>? getRegisteredUser(String email) {
    return _registeredUsers[email.trim().toLowerCase()];
  }

  Future<bool> registerUser({
    required String name,
    required String email,
    required String password,
    String? photoUrl,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (_registeredUsers.containsKey(cleanEmail)) {
      return false;
    }

    _registeredUsers[cleanEmail] = {
      'name': name.trim(),
      'email': cleanEmail,
      'password': password,
      'photoUrl': photoUrl,
      'isVerified': photoUrl != null,
      'registeredAt': DateTime.now().toIso8601String(),
    };

    await _prefs.setString(_registeredUsersKey, jsonEncode(_registeredUsers));
    notifyListeners();
    return true;
  }

  bool isEmailVerified(String email) {
    final user = _registeredUsers[email.trim().toLowerCase()];
    return user != null && (user['isVerified'] == true);
  }

  Future<void> markEmailVerified(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (_registeredUsers.containsKey(cleanEmail)) {
      _registeredUsers[cleanEmail]!['isVerified'] = true;
      await _prefs.setString(_registeredUsersKey, jsonEncode(_registeredUsers));
      notifyListeners();
    }
  }

  Future<bool> updateUserPassword({
    required String email,
    required String newPassword,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (_registeredUsers.containsKey(cleanEmail)) {
      _registeredUsers[cleanEmail]!['password'] = newPassword;
      await _prefs.setString(_registeredUsersKey, jsonEncode(_registeredUsers));
      notifyListeners();
      return true;
    }
    return false;
  }

  // ===========================================================================
  // SESSION TEARDOWN & RECOVERY
  // ===========================================================================

  /// Clears only the active user's local scoped caches.
  Future<void> clearAll() async {
    final targetUid = _currentUserId;
    _savedBookIds.clear();
    _savedBookmarksMap.clear();
    _progressMap.clear();
    _downloadsMap.clear();

    await _prefs.remove(_scopedSavedBooksKey(targetUid));
    await _prefs.remove(_scopedSavedBookmarksKey(targetUid));
    await _prefs.remove(_scopedReadingProgressKey(targetUid));
    await _prefs.remove(_scopedDownloadedFilesKey(targetUid));

    notifyListeners();
  }

  @override
  void dispose() {
    _readingHistorySubscription?.cancel();
    _bookmarksSubscription?.cancel();
    super.dispose();
  }
}
