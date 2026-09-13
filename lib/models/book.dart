class Book {
  final String id;
  final String title;
  final String titleBn;
  final String author;
  final String authorBn;
  final String category;
  final String categoryBn;
  final String description;
  final String descriptionBn;
  final String coverUrl;
  final double rating;
  final int reviewCount;
  final int pageCount;
  final String fileSize;
  final int publicationYear;
  final String downloadUrl;
  final String? previewUrl;
  final String? assetPdfPath;
  final bool isFeatured;
  final bool isTrending;

  const Book({
    required this.id,
    required this.title,
    required this.titleBn,
    required this.author,
    required this.authorBn,
    required this.category,
    required this.categoryBn,
    required this.description,
    required this.descriptionBn,
    required this.coverUrl,
    required this.rating,
    required this.reviewCount,
    required this.pageCount,
    required this.fileSize,
    required this.publicationYear,
    required this.downloadUrl,
    this.previewUrl,
    this.assetPdfPath,
    this.isFeatured = false,
    this.isTrending = false,
  });

  String getLocalizedTitle(bool isBn) => isBn ? titleBn : title;
  String getLocalizedAuthor(bool isBn) => isBn ? authorBn : author;
  String getLocalizedCategory(bool isBn) => isBn ? categoryBn : category;
  String getLocalizedDescription(bool isBn) =>
      isBn ? descriptionBn : description;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'titleBn': titleBn,
      'author': author,
      'authorBn': authorBn,
      'category': category,
      'categoryBn': categoryBn,
      'description': description,
      'descriptionBn': descriptionBn,
      'coverUrl': coverUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'pageCount': pageCount,
      'fileSize': fileSize,
      'publicationYear': publicationYear,
      'downloadUrl': downloadUrl,
      'previewUrl': previewUrl,
      'assetPdfPath': assetPdfPath,
      'isFeatured': isFeatured,
      'isTrending': isTrending,
    };
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] as String,
      title: map['title'] as String,
      titleBn: map['titleBn'] as String? ?? map['title'] as String,
      author: map['author'] as String,
      authorBn: map['authorBn'] as String? ?? map['author'] as String,
      category: map['category'] as String,
      categoryBn: map['categoryBn'] as String? ?? map['category'] as String,
      description: map['description'] as String,
      descriptionBn:
          map['descriptionBn'] as String? ?? map['description'] as String,
      coverUrl: map['coverUrl'] as String,
      rating: (map['rating'] as num).toDouble(),
      reviewCount: map['reviewCount'] as int,
      pageCount: map['pageCount'] as int,
      fileSize: map['fileSize'] as String,
      publicationYear: map['publicationYear'] as int,
      downloadUrl: map['downloadUrl'] as String,
      previewUrl: map['previewUrl'] as String?,
      assetPdfPath: map['assetPdfPath'] as String?,
      isFeatured: map['isFeatured'] as bool? ?? false,
      isTrending: map['isTrending'] as bool? ?? false,
    );
  }
}
