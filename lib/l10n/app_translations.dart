import 'package:flutter/material.dart';

class AppTranslations {
  final Locale locale;

  AppTranslations(this.locale);

  static AppTranslations of(BuildContext context) {
    return Localizations.of<AppTranslations>(context, AppTranslations) ??
        AppTranslations(const Locale('bn'));
  }

  static const LocalizationsDelegate<AppTranslations> delegate =
      _AppTranslationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'bn': {
      // General
      'app_title': 'বইবিতান',
      'app_tagline': 'আপনার ডিজিটাল সাহিত্য ও জ্ঞানের ভাণ্ডার',
      'loading': 'লোড হচ্ছে...',
      'search_placeholder': 'বইয়ের নাম বা লেখক দিয়ে খুঁজুন...',
      'cancel': 'বাতিল',
      'ok': 'ঠিক আছে',
      'confirm': 'নিশ্চিত করুন',
      'error': 'সমস্যা হয়েছে',
      'success': 'সফল হয়েছে',
      'retry': 'আবার চেষ্টা করুন',
      'back': 'ফিরে যান',
      'save': 'সংরক্ষণ',
      'delete': 'মুছে ফেলুন',
      'explore': 'ব্রাউজ করুন',
      'view_all': 'সব দেখুন',

      // Navigation
      'nav_home': 'হোম',
      'nav_library': 'আমার সংগ্রহ',
      'nav_settings': 'সেটিংস',

      // Home Screen
      'greeting_guest': 'স্বাগতম, পাঠক!',
      'greeting_user': 'স্বাগতম, %s!',
      'featured_title': 'পাঠকপ্রিয় সেরা বই',
      'featured_subtitle': 'আজই পড়া শুরু করুন অমর সাহিত্য সম্ভার',
      'categories': 'বিভাগসমূহ',
      'category_all': 'সব বই',
      'category_bangla_novel': 'বাংলা উপন্যাস',
      'category_translated': 'অনূদিত সাহিত্য',
      'category_english_classics': 'ইংরেজি ক্লাসিকস',
      'category_poetry_drama': 'কবিতা ও নাটক',
      'category_self_help': 'মোটিভেশন ও ক্যারিয়ার',
      'shelf_trending': 'পাঠকদের শীর্ষ পছন্দ',
      'shelf_new_arrivals': 'নতুন সংযোজন',
      'shelf_bengali_classics': 'চিরায়ত বাংলা উপন্যাস',
      'shelf_translated': 'অনূদিত বিশ্বসাহিত্য',
      'shelf_english_classics': 'জনপ্রিয় ইংরেজি ক্লাসিকস',
      'no_books_found': 'কোনো বই খুঁজে পাওয়া যায়নি',
      'no_category_results': 'এই ক্যাটাগরিতে কোনো ফলাফল পাওয়া যায়নি',
      'reset_category_filter': 'সব ফলাফল দেখুন',
      'try_another_search': 'অন্য কোনো নাম বা লেখকের নাম দিয়ে অনুসন্ধান করুন',

      // Book Details
      'author': 'লেখক',
      'category': 'বিভাগ',
      'pages': 'পৃষ্ঠা',
      'file_size': 'আকার',
      'published': 'প্রকাশকাল',
      'rating': 'রেটিং',
      'reviews': 'মতামত',
      'synopsis': 'বইয়ের সারসংক্ষেপ',
      'read_now': 'এখনই পড়ুন',
      'read_book': 'বইটি পড়ুন',
      'digital_copy_unavailable': 'এই বইটির ডিজিটাল কপি বর্তমানে উপলব্ধ নেই',
      'digital_copy_load_failed': 'বইটির ডিজিটাল কপি লোড করা সম্ভব হয়নি',
      'tier3_no_copy_info': 'নোট: এই বইটির ডিজিটাল কপি বর্তমানে সংরক্ষিত নেই।',
      'download_pdf': 'পিডিএফ ডাউনলোড',
      'downloading': 'ডাউনলোড হচ্ছে...',
      'download_complete': 'ডাউনলোড সম্পন্ন!',
      'add_to_saved': 'সংগ্রহে রাখুন',
      'remove_from_saved': 'সংগ্রহ থেকে মুছুন',
      'saved_success': 'বইটি আপনার সংগ্রহে যুক্ত করা হয়েছে',
      'removed_success': 'বইটি সংগ্রহ থেকে সরানো হয়েছে',

      // Amarbooks Captcha Flow
      'captcha_title': 'নিরাপত্তা যাচাইকরণ',
      'captcha_subtitle':
          'ডাউনলোড শুরু করতে নিচের গাণিতিক প্রশ্নের সঠিক সমাধান লিখুন:',
      'captcha_input_hint': 'ফলাফল লিখুন',
      'captcha_verify': 'যাচাই ও ডাউনলোড',
      'captcha_error': 'ভুল উত্তর! দয়া করে নতুন প্রশ্নে চেষ্টা করুন।',
      'captcha_correct': 'সঠিক উত্তর! ডাউনলোড শুরু হচ্ছে...',
      'captcha_refresh': 'নতুন প্রশ্ন নিন',

      // Download Progress
      'download_progress_title': 'ফাইল ডাউনলোড হচ্ছে',
      'download_speed': 'গতি',
      'open_file': 'সরাসরি পড়ুন',
      'open_external': 'ডিভাইসে খুলুন',
      'file_saved_at': 'ফাইল সংরক্ষিত হয়েছে: %s',

      // In-app Reader
      'reader_page': 'পৃষ্ঠা %s / %s',
      'reader_resumed_toast': 'পূর্বের পৃষ্ঠা %s থেকে পড়া শুরু হয়েছে',
      'reader_bookmark_saved': 'বর্তমান পৃষ্ঠা %s চিহ্নিত করা হয়েছে',
      'reader_toggle_theme': 'নাইট মোড',
      'reader_jump_to_page': 'নির্দিষ্ট পৃষ্ঠায় যান',
      'reader_enter_page': 'পৃষ্ঠা নম্বর লিখুন',
      'reader_go': 'যান',

      // My Library
      'library_title': 'আমার সংগ্রহ',
      'tab_continue_reading': 'পড়া চালিয়ে যান',
      'tab_saved_books': 'সংরক্ষিত বই',
      'tab_downloaded_files': 'ডাউনলোডকৃত ফাইল',
      'empty_continue': 'এখনো কোনো বই পড়া শুরু করেননি',
      'empty_continue_hint': 'হোম থেকে আপনার পছন্দের যেকোনো বই পড়া শুরু করুন।',
      'empty_saved': 'আপনার সংগ্রহে কোনো সংরক্ষিত বই নেই',
      'empty_saved_hint':
          'বইয়ের বিস্তারিত পাতায় বুকমার্ক আইকনে ক্লিক করে সংরক্ষণ করুন।',
      'empty_downloaded': 'কোনো অফলাইন বই ডাউনলোড করা নেই',
      'empty_downloaded_hint':
          'বই বিস্তারিত থেকে ডাউনলোড করে ইন্টারনেট ছাড়াই পড়ুন।',
      'reading_progress_label': '%s% পড়া সম্পন্ন',
      'last_read_label': 'সর্বশেষ পড়া: %s',
      'read_offline': 'অফলাইনে পড়ুন',
      'delete_download_confirm':
          'আপনি কি এই ডাউনলোড করা ফাইলটি মুছে ফেলতে চান?',

      // Auth
      'login_title': 'বইবিতানে স্বাগতম',
      'login_subtitle': 'আপনার অ্যাকাউন্টে লগইন করে প্রিয় বইগুলো সহজে পড়ুন',
      'email': 'ইমেইল ঠিকানা',
      'email_hint': 'example@mail.com',
      'password': 'পাসওয়ার্ড',
      'password_hint': 'কমপক্ষে ৬ অক্ষরের পাসওয়ার্ড',
      'remember_me': 'আমাকে মনে রাখুন',
      'forgot_password': 'পাসওয়ার্ড ভুলে গেছেন?',
      'login_btn': 'লগইন করুন',
      'google_signin': 'গুগল দিয়ে প্রবেশ করুন',
      'guest_signin': 'অতিথি হিসেবে ঘুরে দেখুন',
      'no_account': 'অ্যাকাউন্ট নেই?',
      'signup_link': 'নতুন অ্যাকাউন্ট খুলুন',
      'signup_title': 'নতুন অ্যাকাউন্ট তৈরি করুন',
      'signup_subtitle': 'বইবিতানের বিশাল লাইব্রেরিতে আপনার যাত্রা শুরু হোক',
      'full_name': 'আপনার পুরো নাম',
      'full_name_hint': 'যেমন: আনিসুল হক',
      'confirm_password': 'পাসওয়ার্ড নিশ্চিত করুন',
      'confirm_password_hint': 'পুনরায় পাসওয়ার্ড লিখুন',
      'signup_btn': 'নিবন্ধন সম্পন্ন করুন',
      'have_account': 'ইতিমধ্যে অ্যাকাউন্ট আছে?',
      'login_link': 'এখানে লগইন করুন',
      'password_mismatch': 'উভয় পাসওয়ার্ড একই হতে হবে',
      'auth_invalid': 'ভুল ইমেইল বা পাসওয়ার্ড',
      'auth_user_not_found': 'এই ইমেইলে কোনো একাউন্ট পাওয়া যায়নি',
      'auth_invalid_email': 'সঠিক ইমেইল ঠিকানা দিন',
      'auth_invalid_email_hint':
          'একটি সঠিক ইমেইল ঠিকানা লিখুন (e.g. name@example.com)',
      'auth_invalid_credentials':
          'ভুল ইমেইল বা পাসওয়ার্ড অথবা অ্যাকাউন্ট তৈরি করা নেই',
      'auth_wrong_password': 'ভুল পাসওয়ার্ড, আবার চেষ্টা করুন',
      'auth_email_in_use':
          'এই ইমেইল দিয়ে ইতিমধ্যেই একটি অ্যাকাউন্ট রয়েছে। দয়া করে লগইন করুন।',
      'google_account_picker_title': 'গুগল অ্যাকাউন্ট নির্বাচন করুন',
      'google_account_picker_subtitle':
          'বইবিতানে প্রবেশ করতে একটি অ্যাকাউন্ট বেছে নিন',
      'add_google_account': 'অন্য অ্যাকাউন্ট যোগ করুন',
      'reading_loading_pdf': 'বইটির সম্পূর্ণ সংস্করণ লোড করা হচ্ছে...',
      'reading_preparing_book': 'বইটি প্রস্তুত হচ্ছে...',
      'reader_open_in_browser': 'ব্রাউজারে পড়ুন',
      'offline_ready': 'অফলাইন প্রস্তুত',
      'browse_books': 'বই খুঁজুন',
      'read_google_preview': 'গুগল প্রিভিউ পড়ুন',
      'search_openlibrary_loading': 'বিশ্বজুড়ে বই খোঁজা হচ্ছে...',
      'search_results_global': 'বৈশ্বিক ফলাফল',
      'suggestions_title': 'প্রস্তাবিত বই ও লেখক',
      'category_islamic_selfhelp': 'ইসলামিক ও আত্মউন্নয়ন',
      'category_scifi': 'বিজ্ঞান ও ফিকশন',
      'shelf_islamic_selfhelp': 'ইসলামিক ও আত্মউন্নয়ন',
      'shelf_scifi': 'বিজ্ঞান ও কল্পবিজ্ঞান',
      'otp_title': 'ইমেইল ওটিপি যাচাইকরণ',
      'otp_subtitle': 'আপনার ইমেইলে একটি ৬ ডিজিটের যাচাইকরণ কোড পাঠানো হয়েছে',
      'otp_enter_code': '৬ ডিজিটের ওটিপি কোডটি লিখুন',
      'otp_verify_btn': 'কোড যাচাই করুন',
      'otp_resend_in': 'পুনরায় কোড পাঠান (%s সে.)',
      'otp_resend_now': 'কোড পুনরায় পাঠান',
      'otp_invalid_code': 'ভুল ওটিপি কোড! অনুগ্রহ করে আপনার ইমেইল ইনবক্স বা স্প্যাম ফোল্ডার চেক করুন',
      'otp_welcome_msg':
          'অভিনন্দন! আপনার অ্যাকাউন্ট সফলভাবে যাচাই সম্পন্ন হয়েছে।',
      'auth_invalid_credentials_or_unverified':
          'ভুল ইমেইল বা পাসওয়ার্ড অথবা অ্যাকাউন্ট ভেরিফাই করা নেই',
      'auth_verification_link_sent': 'A verification link has been sent to your email. Please verify before logging in.',
      'auth_verify_email_first': 'Please verify your email address first.',
      'auth_invalid_email_short': 'Invalid email.',
      'auth_please_signup_first': 'Please sign up first.',
      'reset_password_title': 'পাসওয়ার্ড রিসেট (Reset Password)',
      'enter_new_password': 'নতুন পাসওয়ার্ড (Enter new password)',
      'reenter_new_password': 'পুনরায় পাসওয়ার্ড (Re-enter new password)',
      'reset_password_btn': 'পাসওয়ার্ড রিসেট করুন (Reset Password)',
      'reset_password_success': 'পাসওয়ার্ড সফলভাবে পরিবর্তন হয়েছে! নতুন পাসওয়ার্ড দিয়ে লগইন করুন।',
      'forgot_password_prompt_title': 'পাসওয়ার্ড রিসেট',
      'forgot_password_prompt_desc':
          'আপনার নিবন্ধিত ইমেইল ঠিকানা দিন, সেখানে ভেরিফিকেশন কোড পাঠানো হবে।',
      'send_reset_code': 'রিসেট কোড পাঠান',
      'email_verification_title': 'ইমেইল ভেরিফিকেশন (Email Verification)',
      'google_signin_failed': 'গুগল সাইন-ইন সম্পন্ন হয়নি বা বাতিল করা হয়েছে',
      'logout': 'লগআউট',
      'logout_confirm': 'আপনি কি নিশ্চিতভাবে লগআউট করতে চান?',

      // Settings
      'settings_title': 'সেটিংস',
      'appearance': 'থিম ও প্রদর্শন',
      'theme_mode': 'অ্যাপের থিম মোড',
      'theme_system': 'সিস্টেম ডিফল্ট',
      'theme_light': 'লাইট মোড (রৌদ্রোজ্জ্বল কাগজ)',
      'theme_dark': 'ডার্ক মোড (গভীর রাত)',
      'language_section': 'ভাষা নির্বাচন',
      'language_name': 'ভাষা',
      'language_bn': 'বাংলা (Bengali)',
      'language_en': 'English (ইংরেজি)',
      'account_section': 'অ্যাকাউন্ট ও নিরাপত্তা',
      'logged_in_as': 'লগইন করা আছে: %s',
      'data_management': 'ডাটা ও ক্যাশ ব্যবস্থাপনা',
      'clear_cache': 'সংরক্ষিত ক্যাশ ও হিস্ট্রি মুছুন',
      'cache_cleared': 'ক্যাশ সফলভাবে মুছে ফেলা হয়েছে',
      'about_section': 'বইবিতান সম্পর্কে',
      'app_version': 'ভার্সন ১.০.০ (রিলিজ)',
      'about_desc': 'বইবিতান একটি আধুনিক, উন্মুক্ত বাংলা ও বিশ্বসাহিত্য পাঠক অ্যাপ। সহজে বই পড়া, অফলাইন সংরক্ষণ ও ডিজিটাল বুকমার্কার সমন্বয়ে তৈরি।',
    },
    'en': {
      // General
      'app_title': 'BoiBitan',
      'app_tagline': 'Your Digital Realm of Literature & Wisdom',
      'loading': 'Loading...',
      'search_placeholder': 'Search by book title or author...',
      'cancel': 'Cancel',
      'ok': 'OK',
      'confirm': 'Confirm',
      'error': 'Error occurred',
      'success': 'Success',
      'retry': 'Try Again',
      'back': 'Back',
      'save': 'Save',
      'delete': 'Delete',
      'explore': 'Explore',
      'view_all': 'View All',

      // Navigation
      'nav_home': 'Home',
      'nav_library': 'My Library',
      'nav_settings': 'Settings',

      // Home Screen
      'greeting_guest': 'Welcome, Reader!',
      'greeting_user': 'Welcome back, %s!',
      'featured_title': 'Readers Choice Masterpieces',
      'featured_subtitle': 'Start reading timeless classic literature today',
      'categories': 'Categories',
      'category_all': 'All Books',
      'category_bangla_novel': 'Bengali Novels',
      'category_translated': 'Translated Literature',
      'category_english_classics': 'English Classics',
      'category_poetry_drama': 'Poetry & Drama',
      'category_self_help': 'Self-Help & Career',
      'shelf_trending': 'Trending Now',
      'shelf_new_arrivals': 'New Arrivals',
      'shelf_bengali_classics': 'Bengali Literary Classics',
      'shelf_translated': 'Translated Masterpieces',
      'shelf_english_classics': 'English Classics Collection',
      'no_books_found': 'No books found',
      'no_category_results': 'No results found in this category',
      'reset_category_filter': 'View all results',
      'try_another_search': 'Try searching with another title or author name',

      // Book Details
      'author': 'Author',
      'category': 'Category',
      'pages': 'Pages',
      'file_size': 'Size',
      'published': 'Published',
      'rating': 'Rating',
      'reviews': 'Reviews',
      'synopsis': 'Book Synopsis',
      'read_now': 'Read Online',
      'read_book': 'Read Book',
      'digital_copy_unavailable':
          'Digital copy of this book is currently unavailable',
      'digital_copy_load_failed': 'Failed to load digital copy of this book',
      'tier3_no_copy_info':
          'Note: A digital copy of this book is currently unavailable.',
      'download_pdf': 'Download PDF',
      'downloading': 'Downloading...',
      'download_complete': 'Download Finished!',
      'add_to_saved': 'Add to Wishlist',
      'remove_from_saved': 'Remove from Wishlist',
      'saved_success': 'Book added to your wishlist',
      'removed_success': 'Book removed from wishlist',

      // Amarbooks Captcha Flow
      'captcha_title': 'Security Verification',
      'captcha_subtitle':
          'To initiate high-speed download, solve the math challenge below:',
      'captcha_input_hint': 'Enter calculation result',
      'captcha_verify': 'Verify & Download',
      'captcha_error': 'Incorrect answer! Please solve the updated challenge.',
      'captcha_correct': 'Correct answer! Starting your download...',
      'captcha_refresh': 'New challenge',

      // Download Progress
      'download_progress_title': 'Downloading PDF',
      'download_speed': 'Speed',
      'open_file': 'Read Inside App',
      'open_external': 'Open in Device Viewer',
      'file_saved_at': 'Saved at: %s',

      // In-app Reader
      'reader_page': 'Page %s of %s',
      'reader_resumed_toast': 'Resumed reading from page %s',
      'reader_bookmark_saved': 'Page %s marked as your bookmark',
      'reader_toggle_theme': 'Night Mode',
      'reader_jump_to_page': 'Jump to Page',
      'reader_enter_page': 'Enter page number',
      'reader_go': 'Go',

      // My Library
      'library_title': 'My Library',
      'tab_continue_reading': 'Continue Reading',
      'tab_saved_books': 'Saved Books',
      'tab_downloaded_files': 'Downloaded Files',
      'empty_continue': 'No books in reading progress yet',
      'empty_continue_hint':
          'Explore the catalog on Home to begin reading any book.',
      'empty_saved': 'No saved books in your wishlist',
      'empty_saved_hint':
          'Tap the heart icon on any book page to save it for later.',
      'empty_downloaded': 'No offline books downloaded yet',
      'empty_downloaded_hint':
          'Download books to enjoy reading without an internet connection.',
      'reading_progress_label': '%s% Completed',
      'last_read_label': 'Last read: %s',
      'read_offline': 'Read Offline',
      'delete_download_confirm': 'Do you wish to delete this downloaded book?',

      // Auth
      'login_title': 'Welcome to BoiBitan',
      'login_subtitle':
          'Sign in to access your curated library and reading sync',
      'email': 'Email Address',
      'email_hint': 'name@example.com',
      'password': 'Password',
      'password_hint': 'At least 6 characters',
      'remember_me': 'Remember Me',
      'forgot_password': 'Forgot password?',
      'login_btn': 'Sign In',
      'google_signin': 'Continue with Google',
      'guest_signin': 'Explore as Guest',
      'no_account': "Don't have an account?",
      'signup_link': 'Create Account',
      'signup_title': 'Create Your Account',
      'signup_subtitle': 'Join BoiBitan and immerse yourself in timeless books',
      'full_name': 'Full Name',
      'full_name_hint': 'e.g. John Doe',
      'confirm_password': 'Confirm Password',
      'confirm_password_hint': 'Re-enter your password',
      'signup_btn': 'Complete Registration',
      'have_account': 'Already registered?',
      'login_link': 'Sign in here',
      'password_mismatch': 'Passwords do not match',
      'auth_invalid': 'Invalid email or password',
      'auth_user_not_found': 'No account found with this email',
      'auth_invalid_email': 'Enter a valid email address',
      'auth_invalid_email_hint':
          'Enter a valid email address (e.g. name@example.com)',
      'auth_invalid_credentials':
          'Invalid email or password, or account does not exist',
      'auth_wrong_password': 'Incorrect password. Please try again.',
      'auth_email_in_use':
          'An account already exists with this email. Please sign in.',
      'google_account_picker_title': 'Choose a Google Account',
      'google_account_picker_subtitle': 'to continue to BoiBitan',
      'add_google_account': 'Add another account',
      'reading_loading_pdf': 'Loading complete book edition...',
      'reading_preparing_book': 'Preparing book...',
      'reader_open_in_browser': 'Read in Browser',
      'offline_ready': 'Offline Ready',
      'browse_books': 'Browse Books',
      'read_google_preview': 'Read Google Preview',
      'search_openlibrary_loading': 'Searching books globally...',
      'search_results_global': 'Global Results',
      'suggestions_title': 'Suggested Books & Authors',
      'category_islamic_selfhelp': 'Islamic & Self-Help',
      'category_scifi': 'Science & Sci-Fi',
      'shelf_islamic_selfhelp': 'Islamic & Self-Help',
      'shelf_scifi': 'Science & Sci-Fi',
      'otp_title': 'Verify Email OTP',
      'otp_subtitle':
          'A 6-digit verification code has been dispatched to your email',
      'otp_enter_code': 'Enter 6-digit OTP code',
      'otp_verify_btn': 'Verify Code',
      'otp_resend_in': 'Resend code in (%ss)',
      'otp_resend_now': 'Resend Code',
      'otp_invalid_code':
          'Invalid OTP code! Please check your email inbox or spam folder',
      'otp_welcome_msg':
          'Welcome! Your account has been verified successfully.',
      'auth_invalid_credentials_or_unverified':
          'Incorrect email or password, or account is unverified',
      'auth_verification_link_sent': 'A verification link has been sent to your email. Please verify before logging in.',
      'auth_verify_email_first': 'Please verify your email address first.',
      'auth_invalid_email_short': 'Invalid email.',
      'auth_please_signup_first': 'Please sign up first.',
      'reset_password_title': 'Reset Password',
      'enter_new_password': 'Enter new password',
      'reenter_new_password': 'Re-enter new password',
      'reset_password_btn': 'Reset Password',
      'reset_password_success':
          'Password reset successfully! Please log in with your new password.',
      'forgot_password_prompt_title': 'Reset Your Password',
      'forgot_password_prompt_desc':
          'Enter your registered email address to receive a verification code.',
      'send_reset_code': 'Send Reset Code',
      'email_verification_title': 'Email Verification',
      'google_signin_failed': 'Google Sign-In was cancelled or failed',
      'logout': 'Log Out',
      'logout_confirm': 'Are you sure you want to log out?',

      // Settings
      'settings_title': 'Settings',
      'appearance': 'Theme & Appearance',
      'theme_mode': 'Color Scheme',
      'theme_system': 'System Default',
      'theme_light': 'Parchment Light',
      'theme_dark': 'Obsidian Dark',
      'language_section': 'Language Selection',
      'language_name': 'Language',
      'language_bn': 'বাংলা (Bengali)',
      'language_en': 'English',
      'account_section': 'Account & Profile',
      'logged_in_as': 'Logged in as: %s',
      'data_management': 'Storage & Cache',
      'clear_cache': 'Clear App Cache & History',
      'cache_cleared': 'Cache successfully cleared',
      'about_section': 'About BoiBitan',
      'app_version': 'Version 1.0.0 (Release)',
      'about_desc': 'BoiBitan is an open literary reader offering timeless Bengali classics and translated world literature with seamless bookmarking and offline downloads.',
    },
  };

  String text(String key, [List<dynamic>? args]) {
    final langCode = locale.languageCode;
    String value =
        _localizedValues[langCode]?[key] ?? _localizedValues['bn']?[key] ?? key;

    if (args != null && args.isNotEmpty) {
      for (final arg in args) {
        String rep = arg.toString();
        if (langCode == 'bn') {
          rep = toBengaliDigits(rep);
        }
        value = value.replaceFirst('%s', rep);
      }
    }
    return value;
  }

  static String translate(String key, String langCode, [List<dynamic>? args]) {
    return AppTranslations(Locale(langCode)).text(key, args);
  }

  static String toBengaliDigits(String input) {
    const enDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    var result = input;
    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(enDigits[i], bnDigits[i]);
    }
    return result;
  }

  static String toEnglishDigits(String input) {
    const enDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    var result = input;
    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(bnDigits[i], enDigits[i]);
    }
    return result;
  }
}

class _AppTranslationsDelegate extends LocalizationsDelegate<AppTranslations> {
  const _AppTranslationsDelegate();

  @override
  bool isSupported(Locale locale) => ['bn', 'en'].contains(locale.languageCode);

  @override
  Future<AppTranslations> load(Locale locale) async {
    return AppTranslations(locale);
  }

  @override
  bool shouldReload(_AppTranslationsDelegate old) => false;
}

extension TranslationExtension on BuildContext {
  String tr(String key, [List<dynamic>? args]) {
    return AppTranslations.of(this).text(key, args);
  }

  bool get isBengali => Localizations.localeOf(this).languageCode == 'bn';

  String formatNum(dynamic n) {
    final str = n.toString();
    return isBengali ? AppTranslations.toBengaliDigits(str) : str;
  }
}
