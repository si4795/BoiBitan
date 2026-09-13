import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/book_catalog.dart';
import '../l10n/app_translations.dart';
import '../l10n/locale_notifier.dart';
import '../models/book.dart';
import '../services/auth_service.dart';
import '../services/book_api_service.dart';
import '../services/storage_service.dart';
import '../theme/theme_notifier.dart';
import '../widgets/book_card.dart';
import '../widgets/typography_cover.dart';
import 'book_details_screen.dart';
import 'category_books_screen.dart';
import 'my_library_screen.dart';
import 'settings_screen.dart';

export '../widgets/consumer_locale_button.dart';

class HomeScreen extends StatefulWidget {
  final AuthService authService;
  final StorageService storageService;

  const HomeScreen({
    super.key,
    required this.authService,
    required this.storageService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  late final FocusNode _searchFocusNode;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _suggestionsOverlay;
  List<Map<String, String>> _suggestions = [];

  final BookApiService _bookApiService = BookApiService();
  String _searchQuery = '';
  String _selectedCategoryKey = 'category_all';
  Timer? _debounceTimer;
  bool _isSearchingApi = false;
  List<Book> _apiSearchResults = [];

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        _removeSuggestionsOverlay();
      }
    });
  }

  @override
  void dispose() {
    _removeSuggestionsOverlay();
    _debounceTimer?.cancel();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _removeSuggestionsOverlay() {
    _suggestionsOverlay?.remove();
    _suggestionsOverlay = null;
  }

  void _showSuggestionsOverlay() {
    _removeSuggestionsOverlay();
    if (!mounted || _suggestions.isEmpty || !_searchFocusNode.hasFocus) return;

    final overlay = Overlay.of(context);
    _suggestionsOverlay = OverlayEntry(
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return Positioned(
          width: MediaQuery.of(context).size.width - 32,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 56),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(14),
              color: isDark ? const Color(0xFF22272E) : Colors.white,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 250),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.dividerTheme.color ?? Colors.black12,
                  ),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  shrinkWrap: true,
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _suggestions[index];
                    final text = item['text'] ?? '';
                    final type = item['type'] ?? 'book';
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        type == 'author'
                            ? Icons.person_outline_rounded
                            : Icons.menu_book_outlined,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(
                        text,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.north_west_rounded,
                        size: 16,
                        color: Colors.grey,
                      ),
                      onTap: () => _applySuggestion(text),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_suggestionsOverlay!);
  }

  void _applySuggestion(String text) {
    _searchController.text = text;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
    _removeSuggestionsOverlay();
    _searchFocusNode.unfocus();
    _performSearch(text);
  }

  void _onSearchChanged(String val) {
    final query = val.trim();
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      _removeSuggestionsOverlay();
      setState(() {
        _searchQuery = '';
        _isSearchingApi = false;
        _apiSearchResults = [];
        _suggestions = [];
      });
      return;
    }

    // Global search decouples from category lock
    if (_selectedCategoryKey != 'category_all') {
      setState(() {
        _selectedCategoryKey = 'category_all';
      });
    }

    // Dynamic suggestions when 2 or more characters
    if (query.length >= 2) {
      _bookApiService.getSuggestions(query).then((suggs) {
        if (!mounted || _searchController.text.trim() != query) return;
        _suggestions = suggs;
        if (_suggestions.isNotEmpty && _searchFocusNode.hasFocus) {
          _showSuggestionsOverlay();
        } else {
          _removeSuggestionsOverlay();
        }
      });
    } else {
      _removeSuggestionsOverlay();
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) async {
    _debounceTimer?.cancel();
    if (query.isEmpty) return;

    setState(() {
      _searchQuery = query;
      _isSearchingApi = true;
    });

    final apiBooks = await _bookApiService.searchBooks(query);
    if (!mounted) return;
    if (_searchController.text.trim() == query) {
      setState(() {
        _apiSearchResults = apiBooks;
        _isSearchingApi = false;
      });
    }
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _removeSuggestionsOverlay();
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _isSearchingApi = false;
      _apiSearchResults = [];
      _suggestions = [];
    });
  }

  // Shelf Section Builder
  Widget _buildShelfSection({
    required String title,
    required List<Book> books,
    required BuildContext context,
  }) {
    if (books.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryBooksScreen(
                        title: title,
                        books: books,
                        storageService: widget.storageService,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  child: Text(
                    context.tr('view_all'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 275,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return BookCard(
                book: book,
                type: BookCardType.shelf,
                storageService: widget.storageService,
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // Category Filter Chips
  Widget _buildCategoryChips(BuildContext context) {
    final theme = Theme.of(context);
    final categories = BookCatalog.categories;

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final catKey = categories[index];
          final isSelected = _selectedCategoryKey == catKey;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(context.tr(catKey)),
              selected: isSelected,
              selectedColor: theme.colorScheme.primaryContainer,
              checkmarkColor: theme.colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.textTheme.bodyMedium?.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
              side: BorderSide(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.dividerTheme.color ?? Colors.black12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onSelected: (selected) {
                _removeSuggestionsOverlay();
                _searchFocusNode.unfocus();
                setState(() {
                  _selectedCategoryKey = catKey;
                });
              },
            ),
          );
        },
      ),
    );
  }

  // Hero Featured Banner
  Widget _buildHeroBanner(BuildContext context) {
    final theme = Theme.of(context);
    final isBn = context.isBengali;
    final featuredBook = BookCatalog.books.first;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorative book icon
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.menu_book_rounded,
              size: 140,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // Book thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: featuredBook.coverUrl.trim().isEmpty
                      ? TypographyCover(
                          title: featuredBook.getLocalizedTitle(isBn),
                          author: featuredBook.getLocalizedAuthor(isBn),
                          width: 80,
                          height: 115,
                          borderRadius: 12,
                        )
                      : CachedNetworkImage(
                          imageUrl: featuredBook.coverUrl,
                          width: 80,
                          height: 115,
                          fit: BoxFit.cover,
                          placeholder: (_, _) =>
                              Container(color: Colors.black26),
                          errorWidget: (_, _, _) => TypographyCover(
                            title: featuredBook.getLocalizedTitle(isBn),
                            author: featuredBook.getLocalizedAuthor(isBn),
                            width: 80,
                            height: 115,
                            borderRadius: 12,
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                // Text details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          context.tr('featured_title'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        featuredBook.getLocalizedTitle(isBn),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        featuredBook.getLocalizedAuthor(isBn),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  BookDetailsScreen(book: featuredBook),
                            ),
                          );
                        },
                        child: Text(context.tr('read_now')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Shimmer placeholder grid during live API search
  Widget _buildShimmerGrid(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E242C) : const Color(0xFFF0EBE3);
    final elementBg = isDark
        ? const Color(0xFF282E38)
        : const Color(0xFFDED8CE);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.62,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: elementBg,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14),
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.auto_stories_rounded,
                        color: Colors.black12,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 12,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: elementBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 10,
                        width: 70,
                        decoration: BoxDecoration(
                          color: elementBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          childCount: 4,
        ),
      ),
    );
  }

  String _getCategoryEnglishName(String catKey) {
    switch (catKey) {
      case 'category_bangla_novel':
        return 'Bengali Novels';
      case 'category_translated':
        return 'Translated Literature';
      case 'category_islamic_selfhelp':
        return 'Islamic & Self-Help';
      case 'category_scifi':
        return 'Science & Sci-Fi';
      case 'category_english_classics':
        return 'English Classics';
      case 'category_poetry_drama':
        return 'Poetry & Drama';
      case 'category_self_help':
        return 'Self-Help & Career';
      default:
        return '';
    }
  }

  // Home Feed Body
  Widget _buildHomeFeed(BuildContext context) {
    final theme = Theme.of(context);
    final isSearching = _searchQuery.isNotEmpty;
    final isCategoryFiltered = _selectedCategoryKey != 'category_all';

    List<Widget> slivers = [
      SliverToBoxAdapter(child: _buildSearchBar(context)),
      SliverToBoxAdapter(child: _buildCategoryChips(context)),
    ];

    if (isSearching || isCategoryFiltered) {
      List<Book> searchResults;
      if (isSearching) {
        // Global search: author/title searches list all matching books
        final localMatches = BookCatalog.search(_searchQuery);
        final seenIds = localMatches.map((b) => b.id).toSet();
        final seenTitles = localMatches
            .map((b) => b.title.toLowerCase().trim())
            .toSet();

        final uniqueApiBooks = _apiSearchResults.where((b) {
          final lower = b.title.toLowerCase().trim();
          return !seenIds.contains(b.id) && !seenTitles.contains(lower);
        }).toList();

        searchResults = [...localMatches, ...uniqueApiBooks];

        // Dynamic category chip reactivity: filter current search results by that genre
        if (isCategoryFiltered) {
          final matchCat = _getCategoryEnglishName(_selectedCategoryKey);
          if (matchCat.isNotEmpty) {
            searchResults = searchResults.where((b) {
              final cat = b.category.toLowerCase();
              final catBn = b.categoryBn.toLowerCase();
              final mCat = matchCat.toLowerCase();
              if (cat == mCat || cat.contains(mCat) || catBn.contains(mCat)) {
                return true;
              }
              if (matchCat == 'Science & Sci-Fi' &&
                  (cat.contains('sci-fi') ||
                      cat.contains('science') ||
                      b.description.toLowerCase().contains('science fiction') ||
                      b.descriptionBn.contains('বিজ্ঞান'))) {
                return true;
              }
              if (matchCat == 'Bengali Novels' &&
                  (cat.contains('bengali') ||
                      catBn.contains('বাংলা') ||
                      cat.contains('novel'))) {
                return true;
              }
              if (matchCat == 'Translated Literature' &&
                  (cat.contains('translated') || catBn.contains('অনূদিত'))) {
                return true;
              }
              if (matchCat == 'Islamic & Self-Help' &&
                  (cat.contains('islamic') ||
                      cat.contains('self-help') ||
                      catBn.contains('ইসলামিক') ||
                      catBn.contains('আত্মউন্নয়ন'))) {
                return true;
              }
              return false;
            }).toList();
          }
        }
      } else {
        // Category filtering only applies when browsing categories without a search query
        searchResults = BookCatalog.books;
        if (isCategoryFiltered) {
          final matchCat = _getCategoryEnglishName(_selectedCategoryKey);
          if (matchCat.isNotEmpty) {
            searchResults = searchResults
                .where((b) => b.category == matchCat)
                .toList();
          }
        }
      }

      if (_isSearchingApi) {
        slivers.add(
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.tr('search_openlibrary_loading'),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      final headerTitle = isSearching
          ? (isCategoryFiltered
                ? '${context.tr(_selectedCategoryKey)} (${context.formatNum(searchResults.length)})'
                : '${context.tr('search_results_global')} (${context.formatNum(searchResults.length)})')
          : '${context.tr(_selectedCategoryKey)} (${context.formatNum(searchResults.length)})';

      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  headerTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (isCategoryFiltered)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: Text(
                      context.tr('category_all'),
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedCategoryKey = 'category_all';
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
      );

      if (searchResults.isEmpty && _isSearchingApi) {
        slivers.add(_buildShimmerGrid(context));
      } else if (searchResults.isEmpty) {
        slivers.add(
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isSearching && isCategoryFiltered
                          ? Icons.filter_list_off_rounded
                          : Icons.search_off_rounded,
                      size: 54,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isSearching && isCategoryFiltered
                          ? context.tr('no_category_results')
                          : context.tr('no_books_found'),
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    if (isSearching && isCategoryFiltered)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: Text(context.tr('reset_category_filter')),
                        onPressed: () {
                          setState(() {
                            _selectedCategoryKey = 'category_all';
                          });
                        },
                      )
                    else
                      Text(
                        context.tr('try_another_search'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      } else {
        slivers.add(
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.62,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final book = searchResults[index];
                return BookCard(
                  book: book,
                  type: BookCardType.grid,
                  storageService: widget.storageService,
                );
              }, childCount: searchResults.length),
            ),
          ),
        );
      }
    } else {
      // Default Feed with Hero Banner & Curated Shelves
      slivers.addAll([
        SliverToBoxAdapter(child: _buildHeroBanner(context)),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        SliverToBoxAdapter(
          child: _buildShelfSection(
            title: context.tr('shelf_trending'),
            books: BookCatalog.getTrending(),
            context: context,
          ),
        ),
        SliverToBoxAdapter(
          child: _buildShelfSection(
            title: context.tr('shelf_bengali_classics'),
            books: BookCatalog.getBengaliClassics(),
            context: context,
          ),
        ),
        SliverToBoxAdapter(
          child: _buildShelfSection(
            title: context.tr('shelf_islamic_selfhelp'),
            books: BookCatalog.getIslamicAndSelfHelp(),
            context: context,
          ),
        ),
        SliverToBoxAdapter(
          child: _buildShelfSection(
            title: context.tr('shelf_scifi'),
            books: BookCatalog.getSciFi(),
            context: context,
          ),
        ),
        SliverToBoxAdapter(
          child: _buildShelfSection(
            title: context.tr('shelf_translated'),
            books: BookCatalog.getTranslated(),
            context: context,
          ),
        ),
        SliverToBoxAdapter(
          child: _buildShelfSection(
            title: context.tr('shelf_english_classics'),
            books: BookCatalog.getEnglishClassics(),
            context: context,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ]);
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: CustomScrollView(slivers: slivers),
    );
  }

  // Search Bar
  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: CompositedTransformTarget(
        link: _layerLink,
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: _onSearchChanged,
          onSubmitted: (val) {
            _removeSuggestionsOverlay();
            _performSearch(val.trim());
          },
          decoration: InputDecoration(
            hintText: context.tr('search_placeholder'),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: theme.colorScheme.primary,
            ),
            suffixIcon: ListenableBuilder(
              listenable: _searchController,
              builder: (context, _) {
                if (_searchController.text.isNotEmpty) {
                  return IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: _clearSearch,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E242C) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.dividerTheme.color ?? Colors.black12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Get Notifiers from widget ancestors if available or passed
    return Scaffold(
      appBar: _currentNavIndex == 0
          ? AppBar(
              leading: Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Image.asset(
                  'assets/icon/app_icon.png',
                  width: 32,
                  height: 32,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.auto_stories_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              title: Text(
                context.tr('app_title'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          _buildHomeFeed(context),
          MyLibraryScreen(
            storageService: widget.storageService,
            onExploreTap: () {
              setState(() {
                _currentNavIndex = 0;
              });
            },
          ),
          ConsumerSettingsView(
            authService: widget.authService,
            storageService: widget.storageService,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() {
            _currentNavIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.storefront_outlined),
            activeIcon: const Icon(Icons.storefront_rounded),
            label: context.tr('nav_home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bookmarks_outlined),
            activeIcon: const Icon(Icons.bookmarks_rounded),
            label: context.tr('nav_library'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings_rounded),
            label: context.tr('nav_settings'),
          ),
        ],
      ),
    );
  }
}

class ConsumerSettingsView extends StatelessWidget {
  final AuthService authService;
  final StorageService storageService;

  const ConsumerSettingsView({
    super.key,
    required this.authService,
    required this.storageService,
  });

  @override
  Widget build(BuildContext context) {
    final inherited = RootAppInherited.of(context);
    if (inherited == null) {
      return const SizedBox.shrink();
    }
    return SettingsScreen(
      authService: authService,
      storageService: storageService,
      themeNotifier: inherited.themeNotifier,
      localeNotifier: inherited.localeNotifier,
    );
  }
}

class RootAppInherited extends InheritedWidget {
  final ThemeNotifier themeNotifier;
  final LocaleNotifier localeNotifier;
  final StorageService storageService;
  final AuthService authService;

  const RootAppInherited({
    super.key,
    required this.themeNotifier,
    required this.localeNotifier,
    required this.storageService,
    required this.authService,
    required super.child,
  });

  static RootAppInherited? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<RootAppInherited>();
  }

  @override
  bool updateShouldNotify(RootAppInherited oldWidget) {
    return themeNotifier != oldWidget.themeNotifier ||
        localeNotifier != oldWidget.localeNotifier ||
        storageService != oldWidget.storageService ||
        authService != oldWidget.authService;
  }
}

extension AppServicesExtension on BuildContext {
  StorageService? get storage => RootAppInherited.of(this)?.storageService;
  AuthService? get auth => RootAppInherited.of(this)?.authService;
}
