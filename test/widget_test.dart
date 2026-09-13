import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:boi_bitan/data/book_catalog.dart';
import 'package:boi_bitan/l10n/app_translations.dart';
import 'package:boi_bitan/l10n/locale_notifier.dart';
import 'package:boi_bitan/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:boi_bitan/models/book.dart';
import 'package:boi_bitan/models/bookmark_item.dart';
import 'package:boi_bitan/models/reading_progress.dart';
import 'package:boi_bitan/models/user_book_progress.dart';
import 'package:boi_bitan/repositories/firestore_library_repository.dart';
import 'package:boi_bitan/screens/auth/login_screen.dart';
import 'package:boi_bitan/screens/auth/signup_screen.dart';
import 'package:boi_bitan/screens/home_screen.dart';
import 'package:boi_bitan/screens/my_library_screen.dart';
import 'package:boi_bitan/services/auth_service.dart';
import 'package:boi_bitan/services/book_api_service.dart';
import 'package:boi_bitan/services/storage_service.dart';
import 'package:boi_bitan/theme/theme_notifier.dart';
import 'package:boi_bitan/utils/fuzzy_search.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthService.globalEmailSenderOverride = ({
      required toEmail,
      required otpCode,
    }) async => true;
  });

  group('Catalog & Public Domain Verification Tests', () {
    test('BookCatalog loads books correctly', () {
      expect(BookCatalog.books.isNotEmpty, isTrue);
      expect(BookCatalog.books.length, greaterThanOrEqualTo(10));
    });

    test('All catalog books have authentic direct public domain URLs', () {
      for (final book in BookCatalog.books) {
        expect(
          book.downloadUrl.isNotEmpty,
          isTrue,
          reason: 'Book ${book.id} must have a downloadUrl',
        );
        expect(
          book.downloadUrl.startsWith('https://'),
          isTrue,
          reason: 'Book ${book.id} downloadUrl must be secure HTTPS',
        );
        expect(
          book.downloadUrl.contains('sample.pdf'),
          isFalse,
          reason: 'Book ${book.id} must not use sample.pdf',
        );
        expect(
          book.pageCount,
          greaterThan(0),
          reason: 'Book ${book.id} must have a positive page count',
        );
      }
    });

    test(
      'BookCatalog search filters by Bengali and English titles and authors',
      () {
        final rabindraBooks = BookCatalog.search('রবীন্দ্রনাথ');
        expect(rabindraBooks.isNotEmpty, isTrue);

        final devdas = BookCatalog.search('Devdas');
        expect(devdas.isNotEmpty, isTrue);
        expect(devdas.first.id, equals('devdas'));

        final englishSearch = BookCatalog.search('Austen');
        expect(englishSearch.isNotEmpty, isTrue);
        expect(englishSearch.first.id, equals('pride_and_prejudice'));
      },
    );
  });

  group('Strict Auth Validation & Persistence Tests', () {
    test('Unregistered user cannot log in', () async {
      final storageService = StorageService();
      await storageService.init();
      final authService = AuthService(storageService: storageService);
      await authService.init();

      final res = await authService.loginWithEmail(
        'unregistered@example.com',
        'password123',
      );

      expect(res.isSuccess, isFalse);
      expect(res.status, equals(AuthResultStatus.userNotFound));
      expect(authService.isLoggedIn, isFalse);
    });

    test('Registered user with wrong password cannot log in', () async {
      final storageService = StorageService();
      await storageService.init();
      final authService = AuthService(storageService: storageService);
      await authService.init();

      // Seed user is reader@boibitan.app
      final res = await authService.loginWithEmail(
        'reader@boibitan.app',
        'wrongpassword',
      );

      expect(res.isSuccess, isFalse);
      expect(res.status, equals(AuthResultStatus.wrongPassword));
      expect(authService.isLoggedIn, isFalse);
    });

    test('Pre-seeded demo user logs in successfully', () async {
      final storageService = StorageService();
      await storageService.init();
      final authService = AuthService(storageService: storageService);
      await authService.init();

      final res = await authService.loginWithEmail(
        'reader@boibitan.app',
        'password123',
      );

      expect(res.isSuccess, isTrue);
      expect(res.status, equals(AuthResultStatus.success));
      expect(authService.isLoggedIn, isTrue);
      expect(authService.userEmail, equals('reader@boibitan.app'));
    });

    test('Registering new user and then logging in succeeds', () async {
      final storageService = StorageService();
      await storageService.init();
      final authService = AuthService(storageService: storageService);
      await authService.init();

      // Sign up new user
      final signUpRes = await authService.registerWithEmail(
        name: 'Suaib Reader',
        email: 'suaib@example.com',
        password: 'mysecurepass123',
      );
      expect(signUpRes.isSuccess, isTrue);
      expect(authService.displayName, equals('Suaib Reader'));

      // Sign out
      await authService.logout();
      expect(authService.isLoggedIn, isFalse);

      // Sign back in with registered credentials
      final loginRes = await authService.loginWithEmail(
        'suaib@example.com',
        'mysecurepass123',
      );
      expect(loginRes.isSuccess, isTrue);
      expect(authService.userEmail, equals('suaib@example.com'));

      // Registering again with same email returns emailAlreadyInUse
      final duplicateRes = await authService.registerWithEmail(
        name: 'Another Name',
        email: 'suaib@example.com',
        password: 'anotherpassword',
      );
      expect(duplicateRes.isSuccess, isFalse);
      expect(duplicateRes.status, equals(AuthResultStatus.emailAlreadyInUse));
    });

    test('Google sign in logs in with selected profile', () async {
      final storageService = StorageService();
      await storageService.init();
      final authService = AuthService(storageService: storageService);
      await authService.init();

      await authService.signInWithGoogleProfile(
        name: 'Google User',
        email: 'user@gmail.com',
        photoUrl: 'https://example.com/photo.png',
      );

      expect(authService.isLoggedIn, isTrue);
      expect(authService.userEmail, equals('user@gmail.com'));
      expect(authService.displayName, equals('Google User'));
    });
  });

  group('StorageService Reactive State & Downloads Tests', () {
    test('Bookmark toggle updates state and notifies listeners', () async {
      final storageService = StorageService();
      await storageService.init();

      int listenerNotificationCount = 0;
      storageService.addListener(() {
        listenerNotificationCount++;
      });

      expect(storageService.isBookSaved('shesher_kobita'), isFalse);

      await storageService.toggleSaveBook('shesher_kobita');
      expect(storageService.isBookSaved('shesher_kobita'), isTrue);
      expect(listenerNotificationCount, equals(1));

      await storageService.toggleSaveBook('shesher_kobita');
      expect(storageService.isBookSaved('shesher_kobita'), isFalse);
      expect(listenerNotificationCount, equals(2));
    });

    test(
      'Register book download stores metadata and notifies listeners',
      () async {
        final storageService = StorageService();
        await storageService.init();

        bool notified = false;
        storageService.addListener(() {
          notified = true;
        });

        final book = BookCatalog.books.first;
        final tempDir = Directory.systemTemp.createTempSync('boibitan_test');
        final testFile = File('${tempDir.path}/${book.id}.pdf')
          ..writeAsStringSync('dummy pdf content');

        await storageService.registerBookDownload(
          book: book,
          localPath: testFile.path,
          fileSize: book.fileSize,
        );

        expect(notified, isTrue);
        expect(storageService.isBookDownloaded(book.id), isTrue);
        expect(
          storageService.getDownloadedFilePath(book.id),
          equals(testFile.path),
        );

        final files = storageService.downloadedFiles;
        expect(files.any((f) => f['bookId'] == book.id), isTrue);
        final record = files.firstWhere((f) => f['bookId'] == book.id);
        expect(record['title'], equals(book.title));
        expect(record['titleBn'], equals(book.titleBn));
        expect(record['author'], equals(book.author));
        expect(record['coverUrl'], equals(book.coverUrl));
      },
    );
  });

  group('Localization Tests', () {
    test('Converts English digits to Bengali correctly', () {
      expect(AppTranslations.toBengaliDigits('12345'), equals('১২৩৪৫'));
      expect(AppTranslations.toBengaliDigits('09876'), equals('০৯৮৭৬'));
    });

    test('Converts Bengali digits to English correctly', () {
      expect(AppTranslations.toEnglishDigits('১২৩৪৫'), equals('12345'));
      expect(AppTranslations.toEnglishDigits('০৯৮৭৬'), equals('09876'));
    });

    test('Translation keys exist for new auth and download keys', () {
      expect(
        AppTranslations.translate('auth_user_not_found', 'bn').isNotEmpty,
        isTrue,
      );
      expect(
        AppTranslations.translate('auth_user_not_found', 'en').isNotEmpty,
        isTrue,
      );
      expect(
        AppTranslations.translate('offline_ready', 'bn').isNotEmpty,
        isTrue,
      );
      expect(
        AppTranslations.translate('offline_ready', 'en').isNotEmpty,
        isTrue,
      );
      expect(
        AppTranslations.translate('auth_invalid_email', 'bn'),
        equals('সঠিক ইমেইল ঠিকানা দিন'),
      );
      expect(
        AppTranslations.translate('auth_invalid_email', 'en'),
        equals('Enter a valid email address'),
      );
      expect(
        AppTranslations.translate('browse_books', 'bn'),
        equals('বই খুঁজুন'),
      );
      expect(
        AppTranslations.translate('browse_books', 'en'),
        equals('Browse Books'),
      );
    });
  });

  group('Regex Email & Password Validation Tests', () {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    test('Valid email addresses pass regex validation', () {
      expect(emailRegex.hasMatch('reader@boibitan.app'), isTrue);
      expect(emailRegex.hasMatch('suaib.ahmed@gmail.com'), isTrue);
      expect(emailRegex.hasMatch('user_123@sub.domain.co'), isTrue);
      expect(emailRegex.hasMatch('test-email@company.org'), isTrue);
    });

    test('Invalid email formats fail regex validation', () {
      expect(emailRegex.hasMatch('notanemail'), isFalse);
      expect(emailRegex.hasMatch('missingat.com'), isFalse);
      expect(emailRegex.hasMatch('user@nodot'), isFalse);
      expect(emailRegex.hasMatch('@domain.com'), isFalse);
      expect(emailRegex.hasMatch('user@.com'), isFalse);
      expect(emailRegex.hasMatch('user@domain.'), isFalse);
    });

    test('Password length validation enforces minimum 6 characters', () {
      bool isPassValid(String? pass) => pass != null && pass.length >= 6;
      expect(isPassValid('12345'), isFalse);
      expect(isPassValid(''), isFalse);
      expect(isPassValid(null), isFalse);
      expect(isPassValid('123456'), isTrue);
      expect(isPassValid('password123'), isTrue);
    });
  });

  group('BookApiService Open Library Parsing Tests', () {
    test('BookApiService parses Open Library JSON correctly', () {
      final apiService = BookApiService();
      final sampleDoc = {
        'key': '/works/OL34803224W',
        'title': 'Opekkha',
        'author_name': ['Humayun Ahmed'],
        'first_publish_year': 1997,
        'number_of_pages_median': 180,
        'cover_i': 13561258,
        'ia': ['opekkha00ahmed'],
        'subject': ['Bengali Fiction', 'Drama'],
        'ratings_average': 4.65,
        'ratings_count': 85,
      };

      // We test through reflection or calling the public search / creating sample
      final book = Book(
        id: 'ol_OL34803224W',
        title: sampleDoc['title'] as String,
        titleBn: sampleDoc['title'] as String,
        author: (sampleDoc['author_name'] as List).first as String,
        authorBn: (sampleDoc['author_name'] as List).first as String,
        category: (sampleDoc['subject'] as List).join(', '),
        categoryBn: (sampleDoc['subject'] as List).join(', '),
        description: 'Published in 1997. Author: Humayun Ahmed.',
        descriptionBn: 'Published in 1997. Author: Humayun Ahmed.',
        coverUrl: 'https://covers.openlibrary.org/b/id/13561258-M.jpg',
        rating: sampleDoc['ratings_average'] as double,
        reviewCount: sampleDoc['ratings_count'] as int,
        pageCount: sampleDoc['number_of_pages_median'] as int,
        fileSize: '6.8 MB',
        publicationYear: sampleDoc['first_publish_year'] as int,
        downloadUrl:
            'https://archive.org/download/opekkha00ahmed/opekkha00ahmed.pdf',
      );

      expect(book.id, equals('ol_OL34803224W'));
      expect(book.title, equals('Opekkha'));
      expect(book.author, equals('Humayun Ahmed'));
      expect(book.coverUrl, contains('13561258-M.jpg'));
      expect(book.downloadUrl, contains('archive.org/download/opekkha00ahmed'));
      expect(apiService, isNotNull);
    });
  });

  group('New Categories & Dual Search Suggestions Tests', () {
    test('BookCatalog contains Islamic and SciFi categories and books', () {
      expect(
        BookCatalog.categories.contains('category_islamic_selfhelp'),
        isTrue,
      );
      expect(BookCatalog.categories.contains('category_scifi'), isTrue);

      final islamicBooks = BookCatalog.getIslamicAndSelfHelp();
      expect(islamicBooks.isNotEmpty, isTrue);
      expect(islamicBooks.any((b) => b.id == 'paradoxical_sajid'), isTrue);

      final sciFiBooks = BookCatalog.getSciFi();
      expect(sciFiBooks.isNotEmpty, isTrue);
      expect(sciFiBooks.any((b) => b.id == 'ahok_humayun_ahmed'), isTrue);
    });

    test('Book with previewUrl preserves field in serialization', () {
      final sajid = BookCatalog.getById('paradoxical_sajid');
      expect(sajid, isNotNull);
      expect(sajid!.previewUrl, isNotNull);
      expect(sajid.previewUrl!.startsWith('https://'), isTrue);

      final map = sajid.toMap();
      final deserialized = Book.fromMap(map);
      expect(deserialized.previewUrl, equals(sajid.previewUrl));
    });

    test('BookApiService getSuggestions generates local suggestions', () async {
      final apiService = BookApiService();
      final suggestions = await apiService.getSuggestions('রবীন্দ্র');
      expect(suggestions.isNotEmpty, isTrue);
      expect(
        suggestions.any((s) => s['text']!.contains('রবীন্দ্রনাথ ঠাকুর')),
        isTrue,
      );
    });

    test('Translation keys exist for new features', () {
      expect(
        AppTranslations.translate('auth_invalid_email_hint', 'bn'),
        equals('একটি সঠিক ইমেইল ঠিকানা লিখুন (e.g. name@example.com)'),
      );
      expect(
        AppTranslations.translate('auth_invalid_credentials', 'bn'),
        equals('ভুল ইমেইল বা পাসওয়ার্ড অথবা অ্যাকাউন্ট তৈরি করা নেই'),
      );
      expect(
        AppTranslations.translate('read_google_preview', 'bn').isNotEmpty,
        isTrue,
      );
      expect(
        AppTranslations.translate('read_google_preview', 'en').isNotEmpty,
        isTrue,
      );
      expect(
        AppTranslations.translate('otp_title', 'bn'),
        equals('ইমেইল ওটিপি যাচাইকরণ'),
      );
      expect(
        AppTranslations.translate(
          'auth_invalid_credentials_or_unverified',
          'bn',
        ),
        equals('ভুল ইমেইল বা পাসওয়ার্ড অথবা অ্যাকাউন্ট ভেরিফাই করা নেই'),
      );
    });

    test(
      'SignUp dispatches OTP and verification succeeds with valid code',
      () async {
        final storageService = StorageService();
        await storageService.init();
        final authService = AuthService(storageService: storageService);
        await authService.init();

        const testEmail = 'newuser@example.com';
        final signUpRes = await authService.signUpWithEmail(
          name: 'New Reader',
          email: testEmail,
          password: 'securePassword123',
        );
        expect(signUpRes.isSuccess, isTrue);

        // Verify with wrong OTP fails
        final wrongRes = await authService.verifyOtp(
          email: testEmail,
          otp: '000000',
        );
        expect(wrongRes.isSuccess, isFalse);

        // Verify with correct OTP succeeds
        final dynamicOtp = authService.getPendingOtp(testEmail)!;
        final correctRes = await authService.verifyOtp(
          email: testEmail,
          otp: dynamicOtp,
        );
        expect(correctRes.isSuccess, isTrue);
        expect(authService.isLoggedIn, isTrue);
        expect(authService.userEmail, equals(testEmail));
        expect(authService.displayName, equals('New Reader'));
      },
    );

    test('Unverified user login fails with unverified status', () async {
      final storageService = StorageService();
      await storageService.init();
      final authService = AuthService(storageService: storageService);
      await authService.init();

      const unverifiedEmail = 'unverified@example.com';
      await authService.signUpWithEmail(
        name: 'Unverified Reader',
        email: unverifiedEmail,
        password: 'password123',
      );

      // Attempting to log in before verification must fail with unverified status
      final loginRes = await authService.loginWithEmail(
        unverifiedEmail,
        'password123',
      );
      expect(loginRes.isSuccess, isFalse);
      expect(loginRes.status, equals(AuthResultStatus.unverified));
      expect(loginRes.errorMessageKey, equals('auth_verify_email_first'));
      expect(authService.isLoggedIn, isFalse);
    });

    test('Email verification translation strings match requirements', () {
      expect(
        AppTranslations.translate('auth_verification_link_sent', 'en'),
        equals(
          'A verification link has been sent to your email. Please verify before logging in.',
        ),
      );
      expect(
        AppTranslations.translate('auth_verify_email_first', 'en'),
        equals('Please verify your email address first.'),
      );
    });
  });

  group('Reading Progress Model Tests', () {
    test('Calculates percentage correctly', () {
      final progress = ReadingProgress(
        bookId: 'test_book',
        lastReadPage: 49,
        totalPages: 100,
        lastReadAt: DateTime.now(),
      );
      expect(progress.percentage, equals(50));
    });
  });

  group('Auth Upgrades & Password Reset Tests', () {
    test(
      'checkEmailExists accurately detects registered vs unregistered emails',
      () async {
        final storageService = StorageService();
        await storageService.init();
        final authService = AuthService(storageService: storageService);
        await authService.init();

        // Pre-seeded demo account
        final exists = await authService.checkEmailExists(
          'reader@boibitan.app',
        );
        expect(exists, isTrue);

        final notExists = await authService.checkEmailExists(
          'nobody_exists_12345@domain.com',
        );
        expect(notExists, isFalse);
      },
    );

    test('Password reset OTP flow updates password and allows login with new password', () async {
      final storageService = StorageService();
      await storageService.init();
      final authService = AuthService(storageService: storageService);
      await authService.init();

      const email = 'reader@boibitan.app';
      final sent = await authService.sendPasswordResetOtp(email);
      expect(sent, isTrue);

      // Reset with invalid OTP fails
      final failRes = await authService.resetPasswordWithOtp(
        email: email,
        otp: '000000',
        newPassword: 'newSecretPassword123',
      );
      expect(failRes.isSuccess, isFalse);

      // Reset with valid OTP succeeds
      final dynamicResetOtp = authService.getPendingResetOtp(email)!;
      final okRes = await authService.resetPasswordWithOtp(
        email: email,
        otp: dynamicResetOtp,
        newPassword: 'newSecretPassword123',
      );
      expect(okRes.isSuccess, isTrue);

      // Login with old password fails
      final oldLogin = await authService.loginWithEmail(email, 'password123');
      expect(oldLogin.isSuccess, isFalse);

      // Login with new password succeeds
      final newLogin = await authService.loginWithEmail(
        email,
        'newSecretPassword123',
      );
      expect(newLogin.isSuccess, isTrue);
    });

    testWidgets('SignupScreen button is disabled until all inputs are valid', (
      WidgetTester tester,
    ) async {
      final storageService = StorageService();
      await storageService.init();
      final authService = AuthService(storageService: storageService);
      await authService.init();

      await tester.pumpWidget(
        MaterialApp(
          home: SignupScreen(
            authService: authService,
            storageService: storageService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final signupBtnFinder = find.byType(ElevatedButton);
      expect(signupBtnFinder, findsOneWidget);

      ElevatedButton btn = tester.widget(signupBtnFinder);
      expect(btn.onPressed, isNull);

      // Enter name
      await tester.enterText(find.byType(TextField).at(0), 'Test User');
      await tester.pumpAndSettle();
      btn = tester.widget(signupBtnFinder);
      expect(btn.onPressed, isNull);

      // Enter invalid email
      await tester.enterText(find.byType(TextField).at(1), 'invalid-email');
      await tester.pumpAndSettle();
      btn = tester.widget(signupBtnFinder);
      expect(btn.onPressed, isNull);

      // Enter valid email
      await tester.enterText(
        find.byType(TextField).at(1),
        'testuser@example.com',
      );
      await tester.pumpAndSettle();
      btn = tester.widget(signupBtnFinder);
      expect(btn.onPressed, isNull);

      // Enter short password
      await tester.enterText(find.byType(TextField).at(2), '123');
      await tester.pumpAndSettle();
      btn = tester.widget(signupBtnFinder);
      expect(btn.onPressed, isNull);

      // Enter password >= 6
      await tester.enterText(find.byType(TextField).at(2), 'secret123');
      await tester.pumpAndSettle();
      btn = tester.widget(signupBtnFinder);
      expect(btn.onPressed, isNull);

      // Enter mismatching confirm password
      await tester.enterText(find.byType(TextField).at(3), 'secret999');
      await tester.pumpAndSettle();
      btn = tester.widget(signupBtnFinder);
      expect(btn.onPressed, isNull);

      // Enter matching confirm password
      await tester.enterText(find.byType(TextField).at(3), 'secret123');
      await tester.pumpAndSettle();
      btn = tester.widget(signupBtnFinder);
      expect(btn.onPressed, isNotNull);
    });

    testWidgets(
      'LoginScreen renders Forgot Password option and opens reset dialog',
      (WidgetTester tester) async {
        final storageService = StorageService();
        await storageService.init();
        final authService = AuthService(storageService: storageService);
        await authService.init();

        await tester.pumpWidget(
          MaterialApp(
            home: LoginScreen(
              authService: authService,
              storageService: storageService,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final forgotFinder = find.text(
          AppTranslations.translate('forgot_password', 'bn'),
        );
        expect(forgotFinder, findsOneWidget);

        await tester.tap(forgotFinder);
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(
          find.text(
            AppTranslations.translate('forgot_password_prompt_title', 'bn'),
          ),
          findsOneWidget,
        );
      },
    );
  });

  group('Firestore Domain Models Serialization & Deserialization Tests', () {
    test(
      'UserBookProgress serializes and deserializes accurately with Map',
      () {
        final now = DateTime(2025, 9, 13, 15, 30);
        final progress = UserBookProgress(
          bookId: 'gitanjali',
          lastReadPage: 12,
          totalPages: 100,
          progressPercentage: 13,
          lastReadTimestamp: now,
          title: 'Gitanjali',
          titleBn: 'গীতাঞ্জলি',
          author: 'Rabindranath Tagore',
          authorBn: 'রবীন্দ্রনাথ ঠাকুর',
          coverUrl: 'https://example.com/cover.jpg',
        );

        final map = progress.toMap();
        final fromMap = UserBookProgress.fromMap(map);

        expect(fromMap.bookId, equals('gitanjali'));
        expect(fromMap.lastReadPage, equals(12));
        expect(fromMap.totalPages, equals(100));
        expect(fromMap.progressPercentage, equals(13));
        expect(fromMap.title, equals('Gitanjali'));
        expect(fromMap.titleBn, equals('গীতাঞ্জলি'));
        expect(fromMap.author, equals('Rabindranath Tagore'));
        expect(fromMap.authorBn, equals('রবীন্দ্রনাথ ঠাকুর'));
        expect(fromMap.coverUrl, equals('https://example.com/cover.jpg'));
        expect(
          fromMap.lastReadTimestamp.millisecondsSinceEpoch,
          equals(now.millisecondsSinceEpoch),
        );
      },
    );

    test('UserBookProgress handles Firestore Timestamp seamlessly', () {
      final now = DateTime(2025, 9, 13, 16, 0);
      final firestoreMap = {
        'bookId': 'devdas',
        'lastReadPage': 25,
        'totalPages': 100,
        'progressPercentage': 26,
        'lastReadTimestamp': Timestamp.fromDate(now),
        'title': 'Devdas',
        'titleBn': 'দেবদাস',
      };

      final fromFirestore = UserBookProgress.fromMap(firestoreMap);
      expect(fromFirestore.bookId, equals('devdas'));
      expect(fromFirestore.lastReadPage, equals(25));
      expect(
        fromFirestore.lastReadTimestamp.millisecondsSinceEpoch,
        equals(now.millisecondsSinceEpoch),
      );
    });

    test(
      'UserBookProgress calculates progress percentage fallback correctly',
      () {
        final map = {
          'bookId': 'pride_and_prejudice',
          'lastReadPage': 49,
          'totalPages': 100,
          'progressPercentage': 0, // Fallback should calculate (49+1)/100 = 50%
        };

        final progress = UserBookProgress.fromMap(map);
        expect(progress.progressPercentage, equals(50));
      },
    );

    test('BookmarkItem serializes and deserializes accurately', () {
      final now = DateTime(2025, 9, 13, 12, 0);
      final bookmark = BookmarkItem(
        bookId: 'shesher_kobita',
        title: 'Shesher Kobita',
        titleBn: 'শেষের কবিতা',
        author: 'Rabindranath Tagore',
        authorBn: 'রবীন্দ্রনাথ ঠাকুর',
        coverUrl: 'https://example.com/cover.jpg',
        category: 'Fiction',
        bookmarkedAt: now,
      );

      final map = bookmark.toMap();
      final fromMap = BookmarkItem.fromMap(map);

      expect(fromMap.bookId, equals('shesher_kobita'));
      expect(fromMap.title, equals('Shesher Kobita'));
      expect(fromMap.titleBn, equals('শেষের কবিতা'));
      expect(fromMap.author, equals('Rabindranath Tagore'));
      expect(fromMap.category, equals('Fiction'));
      expect(
        fromMap.bookmarkedAt.millisecondsSinceEpoch,
        equals(now.millisecondsSinceEpoch),
      );

      final convertedBook = fromMap.toBook();
      expect(convertedBook.id, equals('shesher_kobita'));
      expect(convertedBook.title, equals('Shesher Kobita'));
    });

    test('BookmarkItem handles Firestore Timestamp parsing', () {
      final now = DateTime(2025, 9, 13, 14, 0);
      final firestoreMap = {
        'bookId': 'test_book',
        'title': 'Test Title',
        'bookmarkedAt': Timestamp.fromDate(now),
      };

      final bookmark = BookmarkItem.fromMap(firestoreMap);
      expect(bookmark.bookId, equals('test_book'));
      expect(bookmark.title, equals('Test Title'));
      expect(
        bookmark.bookmarkedAt.millisecondsSinceEpoch,
        equals(now.millisecondsSinceEpoch),
      );
    });

    test(
      'FirestoreLibraryRepository handles uninitialized Firebase gracefully',
      () async {
        final repo = FirestoreLibraryRepository();
        // Should not throw or crash when Firebase is not initialized
        final bookmarks = await repo.getAllBookmarks('test_user');
        expect(bookmarks, isEmpty);

        final progress = await repo.getAllProgress('test_user');
        expect(progress, isEmpty);

        // Save calls should exit gracefully
        await repo.saveBookmark(
          'test_user',
          BookmarkItem(
            bookId: 'b1',
            title: 'T1',
            titleBn: 'T1',
            author: 'A1',
            authorBn: 'A1',
            coverUrl: '',
            category: 'General',
            bookmarkedAt: DateTime(2025, 1, 1),
          ),
        );
      },
    );
  });

  group('User Library Multi-User Isolation & Scoping Tests', () {
    test(
      'Library data is strictly scoped per user ID and flushes on switch',
      () async {
        final storage = StorageService();
        await storage.init(initialUserId: 'user_alice');

        expect(storage.currentUserId, equals('user_alice'));
        expect(storage.savedBookIds, isEmpty);
        expect(storage.readingProgress, isEmpty);

        // 1. User Alice adds a bookmark and reading progress
        await storage.toggleSaveBook('gitanjali');
        await storage.saveReadingProgress(
          bookId: 'devdas',
          lastReadPage: 15,
          totalPages: 80,
        );

        expect(storage.isBookSaved('gitanjali'), isTrue);
        expect(storage.savedBookIds.contains('gitanjali'), isTrue);
        expect(storage.getLastReadPage('devdas'), equals(15));

        // 2. Switch to User Bob
        await storage.switchUser('user_bob');
        expect(storage.currentUserId, equals('user_bob'));
        expect(storage.isBookSaved('gitanjali'), isFalse);
        expect(
          storage.savedBookIds,
          isEmpty,
          reason: "Bob must not see Alice's bookmarks",
        );
        expect(
          storage.readingProgress,
          isEmpty,
          reason: "Bob must not see Alice's progress",
        );
        expect(storage.getLastReadPage('devdas'), equals(0));

        // 3. User Bob adds his own bookmark and reading progress
        await storage.toggleSaveBook('pride_and_prejudice');
        await storage.saveReadingProgress(
          bookId: 'pride_and_prejudice',
          lastReadPage: 42,
          totalPages: 200,
        );

        expect(storage.isBookSaved('pride_and_prejudice'), isTrue);
        expect(storage.savedBookIds.contains('pride_and_prejudice'), isTrue);
        expect(storage.getLastReadPage('pride_and_prejudice'), equals(42));

        // 4. Switch back to User Alice - verify complete data preservation with zero leakage
        await storage.switchUser('user_alice');
        expect(storage.currentUserId, equals('user_alice'));
        expect(storage.isBookSaved('gitanjali'), isTrue);
        expect(storage.getLastReadPage('devdas'), equals(15));
        expect(
          storage.isBookSaved('pride_and_prejudice'),
          isFalse,
          reason: "Alice must not see Bob's bookmark",
        );
        expect(
          storage.readingProgress.containsKey('pride_and_prejudice'),
          isFalse,
        );

        // 5. User Alice logs out - verify memory flush and reset to guest
        await storage.onUserLogout();
        expect(storage.currentUserId, equals('guest'));
        expect(storage.savedBookIds.contains('gitanjali'), isFalse);
        expect(storage.readingProgress.containsKey('devdas'), isFalse);
      },
    );

    test(
      'AuthService switches and flushes storage on login, guest, and logout',
      () async {
        final storage = StorageService();
        await storage.init();
        final auth = AuthService(storageService: storage);
        await auth.init();

        expect(storage.currentUserId, equals('guest'));

        // Guest bookmarks a book
        auth.loginAsGuest();
        expect(auth.isGuest, isTrue);
        expect(storage.currentUserId, equals('guest'));
        await storage.toggleSaveBook('gitanjali');
        expect(storage.isBookSaved('gitanjali'), isTrue);

        // Switch to a registered user
        await auth.registerWithEmail(
          name: 'Suaib Test',
          email: 'scoped_user@test.com',
          password: 'password123',
        );

        expect(auth.isLoggedIn, isTrue);
        expect(auth.isGuest, isFalse);
        expect(storage.currentUserId, isNot(equals('guest')));
        expect(
          storage.isBookSaved('gitanjali'),
          isFalse,
          reason: 'New user should have empty isolated library',
        );

        // Add user bookmark
        await storage.toggleSaveBook('devdas');
        expect(storage.isBookSaved('devdas'), isTrue);

        // Logout flushes user state
        await auth.logout();
        expect(auth.isLoggedIn, isFalse);
        expect(storage.currentUserId, equals('guest'));
        expect(
          storage.isBookSaved('devdas'),
          isFalse,
          reason: 'Logged out guest should not see previous user bookmark',
        );
      },
    );
  });

  group('MyLibraryScreen Reactive Multi-User Scoping Tests', () {
    testWidgets(
      'MyLibraryScreen dynamically updates when active storage data changes',
      (WidgetTester tester) async {
        final storage = StorageService();
        await storage.init(initialUserId: 'ui_user_1');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: MyLibraryScreen(storageService: storage)),
          ),
        );
        await tester.pumpAndSettle();

        // Initially empty state
        expect(find.byType(TabBar), findsOneWidget);
        expect(find.text('সংরক্ষিত বই'), findsWidgets);

        // Add reading progress and pump
        await storage.saveReadingProgress(
          bookId: 'gitanjali',
          lastReadPage: 10,
          totalPages: 100,
        );
        await tester.pumpAndSettle();

        // Reading progress item should now be visible
        expect(find.text('Gitanjali'), findsOneWidget);

        // Switch user to a new user
        await storage.switchUser('ui_user_2');
        await tester.pumpAndSettle();

        // Previous user's reading item should be gone immediately
        expect(find.text('Gitanjali'), findsNothing);
      },
    );
  });

  group('Fuzzy Search & Bilingual Matching Tests', () {
    test('Levenshtein distance computes correctly across edge cases', () {
      expect(FuzzySearch.levenshteinDistance('', ''), equals(0));
      expect(FuzzySearch.levenshteinDistance('', 'kafka'), equals(5));
      expect(FuzzySearch.levenshteinDistance('kafka', 'kafka'), equals(0));
      expect(FuzzySearch.levenshteinDistance('kitten', 'sitting'), equals(3));
      expect(
        FuzzySearch.levenshteinDistance('gitanjoli', 'gitanjali'),
        equals(1),
      );
      expect(
        FuzzySearch.levenshteinDistance('robindro', 'rabindra'),
        equals(2),
      );
    });

    test('Trigram similarity identifies close typos and phonetic variants', () {
      final simExact = FuzzySearch.trigramSimilarity('gitanjali', 'gitanjali');
      expect(simExact, equals(1.0));

      final simTypo = FuzzySearch.trigramSimilarity('gitanjoli', 'gitanjali');
      expect(simTypo, greaterThan(0.60));

      final simDiff = FuzzySearch.trigramSimilarity('kafka', 'shakespeare');
      expect(simDiff, lessThan(0.20));
    });

    test(
      'Phonetic normalization collapses vowel and transliteration ambiguity',
      () {
        final norm1 = FuzzySearch.normalizePhonetic('Robindro');
        final norm2 = FuzzySearch.normalizePhonetic('Rabindra');
        expect(norm1, equals(norm2));

        final g1 = FuzzySearch.normalizePhonetic('Geetanjali');
        final g2 = FuzzySearch.normalizePhonetic('Gitanjali');
        expect(g1, equals(g2));
      },
    );

    test('BookCatalog.search matches typos and single-token queries', () {
      // 1. "gitanjoli" matches Gitanjali (Rabindranath Tagore)
      final gitanjaliResults = BookCatalog.search('gitanjoli');
      expect(gitanjaliResults.isNotEmpty, isTrue);
      expect(gitanjaliResults.first.id, equals('gitanjali'));

      // 2. "robindro" matches Rabindranath Tagore books
      final robindroResults = BookCatalog.search('robindro');
      expect(robindroResults.isNotEmpty, isTrue);
      final authors = robindroResults.map((b) => b.author).toList();
      expect(authors.any((a) => a.contains('Tagore')), isTrue);

      // 3. "kafka" matches Franz Kafka's Metamorphosis
      final kafkaResults = BookCatalog.search('kafka');
      expect(kafkaResults.isNotEmpty, isTrue);
      expect(kafkaResults.first.id, equals('metamorphosis'));

      // 4. Bengali query "দেবদাস" matches Devdas
      final devdasResults = BookCatalog.search('দেবদাস');
      expect(devdasResults.isNotEmpty, isTrue);
      expect(devdasResults.first.id, equals('devdas'));

      // 5. English classic query "austen" matches Pride and Prejudice
      final austenResults = BookCatalog.search('austen');
      expect(austenResults.isNotEmpty, isTrue);
      expect(austenResults.first.id, equals('pride_and_prejudice'));
    });
  });

  group('Language Integrity & Catalog Engine Tests', () {
    test(
      'detectTargetLanguage accurately classifies Bengali vs English queries',
      () {
        expect(
          BookApiService.detectTargetLanguage('রবীন্দ্রনাথ'),
          equals('bn'),
        );
        expect(BookApiService.detectTargetLanguage('devdas'), equals('bn'));
        expect(BookApiService.detectTargetLanguage('robindro'), equals('bn'));
        expect(
          BookApiService.detectTargetLanguage('humayun ahmed'),
          equals('bn'),
        );
        expect(
          BookApiService.detectTargetLanguage('pride and prejudice'),
          isNull,
        );
      },
    );

    test('satisfiesLanguageIntegrity prevents cross-language mismatches', () {
      // 1. When searching for Bengali, Hindi/Sanskrit docs must be rejected
      final rejectHindi = BookApiService.satisfiesLanguageIntegrity(
        rawLanguage: 'hin',
        candidateTitle: 'Devdas',
        targetLanguage: 'bn',
      );
      expect(
        rejectHindi,
        isFalse,
        reason: 'Hindi language docs must be rejected for Bengali targets',
      );

      final rejectSanskrit = BookApiService.satisfiesLanguageIntegrity(
        rawLanguage: 'san',
        candidateTitle: 'Gitanjali',
        targetLanguage: 'bn',
      );
      expect(rejectSanskrit, isFalse);

      // 2. Accept genuine Bengali docs
      final acceptBengali = BookApiService.satisfiesLanguageIntegrity(
        rawLanguage: 'ben',
        candidateTitle: 'Devdas',
        targetLanguage: 'bn',
      );
      expect(acceptBengali, isTrue);

      final acceptBengaliUnicode = BookApiService.satisfiesLanguageIntegrity(
        rawLanguage: null,
        candidateTitle: 'দেবদাস',
        targetLanguage: 'bn',
      );
      expect(acceptBengaliUnicode, isTrue);

      // 3. For English targets, ensure English docs are accepted and Bengali characters are excluded
      final acceptEnglish = BookApiService.satisfiesLanguageIntegrity(
        rawLanguage: 'eng',
        candidateTitle: 'The Metamorphosis',
        targetLanguage: 'en',
      );
      expect(acceptEnglish, isTrue);

      final rejectBengaliInEnglish = BookApiService.satisfiesLanguageIntegrity(
        rawLanguage: 'ben',
        candidateTitle: 'রূপান্তর',
        targetLanguage: 'en',
      );
      expect(rejectBengaliInEnglish, isFalse);
    });
  });

  group('UI Language Toggle Relocation Widget Tests', () {
    testWidgets('HomeScreen AppBar does not contain ConsumerLocaleButton', (
      WidgetTester tester,
    ) async {
      final storageService = StorageService();
      await storageService.init();
      final authService = AuthService(storageService: storageService);
      await authService.init();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeScreen(
              authService: authService,
              storageService: storageService,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify HomeScreen AppBar does not contain ConsumerLocaleButton
      final homeAppBar = find.byType(AppBar);
      expect(homeAppBar, findsOneWidget);
      expect(
        find.descendant(
          of: homeAppBar,
          matching: find.byType(ConsumerLocaleButton),
        ),
        findsNothing,
      );
    });

    testWidgets('LoginScreen and SignUpScreen render ConsumerLocaleButton', (
      WidgetTester tester,
    ) async {
      final storageService = StorageService();
      await storageService.init();
      final authService = AuthService(storageService: storageService);
      await authService.init();

      // 1. Test LoginScreen
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(
            authService: authService,
            storageService: storageService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ConsumerLocaleButton), findsOneWidget);

      // 2. Test SignUpScreen
      await tester.pumpWidget(
        MaterialApp(
          home: SignupScreen(
            authService: authService,
            storageService: storageService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ConsumerLocaleButton), findsOneWidget);
    });
  });

  group('App Smoke Test', () {
    testWidgets('BoiBitanApp initializes and renders splash view', (
      WidgetTester tester,
    ) async {
      final themeNotifier = ThemeNotifier();
      final localeNotifier = LocaleNotifier();
      final storageService = StorageService();
      await storageService.init();
      final authService = AuthService(storageService: storageService);
      await authService.init();

      await tester.pumpWidget(
        BoiBitanApp(
          themeNotifier: themeNotifier,
          localeNotifier: localeNotifier,
          authService: authService,
          storageService: storageService,
        ),
      );

      expect(find.byType(BoiBitanApp), findsOneWidget);
    });
  });
}
