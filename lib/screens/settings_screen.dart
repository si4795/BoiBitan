import 'package:flutter/material.dart';

import '../l10n/app_translations.dart';
import '../l10n/locale_notifier.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../theme/theme_notifier.dart';
import 'auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  final AuthService authService;
  final StorageService storageService;
  final ThemeNotifier themeNotifier;
  final LocaleNotifier localeNotifier;

  const SettingsScreen({
    super.key,
    required this.authService,
    required this.storageService,
    required this.themeNotifier,
    required this.localeNotifier,
  });

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('logout')),
        content: Text(context.tr('logout_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await authService.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LoginScreen(
                      authService: authService,
                      storageService: storageService,
                    ),
                  ),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(context.tr('logout')),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('clear_cache')),
        content: const Text(
          'আপনার সংরক্ষিত বুকমার্ক ও পড়ার অগ্রগতি মুছে যাবে। আপনি কি নিশ্চিত?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await storageService.clearAll();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.tr('cache_cleared')),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(context.tr('confirm')),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('settings_title'))),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        children: [
          // User Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person_rounded,
                      size: 32,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authService.displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          authService.userEmail ?? 'reader@boibitan.app',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: context.tr('logout'),
                    icon: const Icon(Icons.logout_rounded, color: Colors.red),
                    onPressed: () => _showLogoutDialog(context),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Theme Settings Section
          _buildSectionHeader(context, context.tr('appearance')),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_auto_rounded),
                  title: Text(context.tr('theme_system')),
                  trailing: Icon(
                    themeNotifier.themeMode == ThemeMode.system
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: themeNotifier.themeMode == ThemeMode.system
                        ? theme.colorScheme.primary
                        : Colors.grey,
                  ),
                  onTap: () => themeNotifier.setThemeMode(ThemeMode.system),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.light_mode_rounded),
                  title: Text(context.tr('theme_light')),
                  trailing: Icon(
                    themeNotifier.themeMode == ThemeMode.light
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: themeNotifier.themeMode == ThemeMode.light
                        ? theme.colorScheme.primary
                        : Colors.grey,
                  ),
                  onTap: () => themeNotifier.setThemeMode(ThemeMode.light),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.dark_mode_rounded),
                  title: Text(context.tr('theme_dark')),
                  trailing: Icon(
                    themeNotifier.themeMode == ThemeMode.dark
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: themeNotifier.themeMode == ThemeMode.dark
                        ? theme.colorScheme.primary
                        : Colors.grey,
                  ),
                  onTap: () => themeNotifier.setThemeMode(ThemeMode.dark),
                ),
              ],
            ),
          ),

          // Language Settings Section
          _buildSectionHeader(context, context.tr('language_section')),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Text('🇧🇩', style: TextStyle(fontSize: 22)),
                  title: Text(context.tr('language_bn')),
                  trailing: Icon(
                    localeNotifier.currentLocale.languageCode == 'bn'
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: localeNotifier.currentLocale.languageCode == 'bn'
                        ? theme.colorScheme.primary
                        : Colors.grey,
                  ),
                  onTap: () => localeNotifier.setLocale(const Locale('bn')),
                ),
                const Divider(),
                ListTile(
                  leading: const Text('🇺🇸', style: TextStyle(fontSize: 22)),
                  title: Text(context.tr('language_en')),
                  trailing: Icon(
                    localeNotifier.currentLocale.languageCode == 'en'
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: localeNotifier.currentLocale.languageCode == 'en'
                        ? theme.colorScheme.primary
                        : Colors.grey,
                  ),
                  onTap: () => localeNotifier.setLocale(const Locale('en')),
                ),
              ],
            ),
          ),

          // Storage Management Section
          _buildSectionHeader(context, context.tr('data_management')),
          Card(
            child: ListTile(
              leading: const Icon(Icons.cleaning_services_rounded),
              title: Text(context.tr('clear_cache')),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showClearCacheDialog(context),
            ),
          ),

          // About Section
          _buildSectionHeader(context, context.tr('about_section')),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/icon/app_icon.png',
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Icon(
                            Icons.auto_stories_rounded,
                            size: 40,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('app_title'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            context.tr('app_version'),
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr('about_desc'),
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
