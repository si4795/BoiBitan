import 'package:flutter/material.dart';

/// An elegant typography-based book cover widget rendered when a book
/// does not have remote cover artwork available. Mimics a physical hardcover book
/// with a vertical spine accent, foil-embossed icon, title, and author typography.
class TypographyCover extends StatelessWidget {
  final String title;
  final String author;
  final double? width;
  final double? height;
  final double borderRadius;

  const TypographyCover({
    super.key,
    required this.title,
    required this.author,
    this.width,
    this.height,
    this.borderRadius = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gradientColors = isDark
        ? const [Color(0xFF1E293B), Color(0xFF0F172A)]
        : const [Color(0xFF2C3E50), Color(0xFF1A252F)];

    final isCompact =
        (height != null && height! < 140) || (width != null && width! < 110);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
        ),
        child: Stack(
          children: [
            // Vertical spine accent on left edge
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: isCompact ? 7 : 12,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.5),
                      Colors.white.withValues(alpha: 0.08),
                      Colors.black.withValues(alpha: 0.3),
                    ],
                  ),
                ),
              ),
            ),
            // Title and author typography
            Padding(
              padding: EdgeInsets.fromLTRB(isCompact ? 10 : 16, 8, 8, 8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.auto_stories_rounded,
                      color: const Color(0xFFE5A93C).withValues(alpha: 0.9),
                      size: isCompact ? 20 : 28,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title.isNotEmpty ? title : 'বইবিতান',
                      textAlign: TextAlign.center,
                      maxLines: isCompact ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isCompact ? 11 : 13,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    if (author.isNotEmpty && !isCompact) ...[
                      const SizedBox(height: 6),
                      Container(
                        width: 24,
                        height: 1.5,
                        color: const Color(0xFFE5A93C).withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        author,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
