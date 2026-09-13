class ReadingProgress {
  final String bookId;
  final int lastReadPage;
  final int totalPages;
  final DateTime lastReadAt;

  const ReadingProgress({
    required this.bookId,
    required this.lastReadPage,
    required this.totalPages,
    required this.lastReadAt,
  });

  int get percentage {
    if (totalPages <= 0) return 0;
    final pct = ((lastReadPage + 1) / totalPages * 100).round();
    return pct > 100 ? 100 : (pct < 0 ? 0 : pct);
  }

  Map<String, dynamic> toMap() {
    return {
      'bookId': bookId,
      'lastReadPage': lastReadPage,
      'totalPages': totalPages,
      'lastReadAt': lastReadAt.toIso8601String(),
    };
  }

  factory ReadingProgress.fromMap(Map<String, dynamic> map) {
    return ReadingProgress(
      bookId: map['bookId'] as String,
      lastReadPage: map['lastReadPage'] as int? ?? 0,
      totalPages: map['totalPages'] as int? ?? 1,
      lastReadAt: map['lastReadAt'] != null
          ? DateTime.parse(map['lastReadAt'] as String)
          : DateTime.now(),
    );
  }
}
