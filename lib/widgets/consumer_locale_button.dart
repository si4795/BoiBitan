import 'package:flutter/material.dart';

import '../l10n/app_translations.dart';
import '../screens/home_screen.dart';

/// Prominent bilingual language switcher toggle button.
/// Toggles the application between Bengali (🇧🇩 বাংলা) and English (🇺🇸 English).
class ConsumerLocaleButton extends StatelessWidget {
  final bool isProminent;

  const ConsumerLocaleButton({super.key, this.isProminent = false});

  @override
  Widget build(BuildContext context) {
    final isBn = context.isBengali;
    final theme = Theme.of(context);

    return TextButton(
      style: TextButton.styleFrom(
        padding: isProminent
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () {
        final toggle = RootAppInherited.of(context)
            ?.localeNotifier
            .toggleLocale;
        toggle?.call();
      },
      child: Container(
        padding: isProminent
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
            : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isBn ? '🇧🇩 বাংলা' : '🇺🇸 English',
              style: TextStyle(
                fontSize: isProminent ? 13 : 12,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.swap_horiz_rounded,
              size: isProminent ? 16 : 14,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
