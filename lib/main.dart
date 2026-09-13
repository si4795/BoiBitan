import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'config/supabase_config.dart';
import 'firebase_options.dart';
import 'l10n/app_translations.dart';
import 'l10n/locale_notifier.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await SupabaseConfig.init();

  final themeNotifier = ThemeNotifier();
  final localeNotifier = LocaleNotifier();
  final authService = AuthService();
  final storageService = StorageService();

  runApp(
    BoiBitanApp(
      themeNotifier: themeNotifier,
      localeNotifier: localeNotifier,
      authService: authService,
      storageService: storageService,
    ),
  );
}

class BoiBitanApp extends StatelessWidget {
  final ThemeNotifier themeNotifier;
  final LocaleNotifier localeNotifier;
  final AuthService authService;
  final StorageService storageService;

  const BoiBitanApp({
    super.key,
    required this.themeNotifier,
    required this.localeNotifier,
    required this.authService,
    required this.storageService,
  });

  @override
  Widget build(BuildContext context) {
    authService.setStorageService(storageService);
    return RootAppInherited(
      themeNotifier: themeNotifier,
      localeNotifier: localeNotifier,
      storageService: storageService,
      authService: authService,
      child: ListenableBuilder(
        listenable: Listenable.merge([
          themeNotifier,
          localeNotifier,
          storageService,
          authService,
        ]),
        builder: (context, _) {
          return MaterialApp(
            title: 'BoiBitan',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeNotifier.themeMode,
            locale: localeNotifier.currentLocale,
            supportedLocales: const [Locale('bn'), Locale('en')],
            localizationsDelegates: const [
              AppTranslations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: SplashScreen(
              authService: authService,
              storageService: storageService,
            ),
          );
        },
      ),
    );
  }
}
