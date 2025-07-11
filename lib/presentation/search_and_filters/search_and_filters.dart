import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../utils/search_service.dart';
import '../../utils/category_service.dart';
import './widgets/filter_chips_widget.dart';
import './widgets/filter_modal_widget.dart';
import './widgets/recent_searches_widget.dart';
import './widgets/search_bar_widget.dart';
import './widgets/search_results_widget.dart';
import './widgets/trending_keywords_widget.dart';

class SearchAndFilters extends StatefulWidget {
  const SearchAndFilters({Key? key}) : super(key: key);

  @override
  State<SearchAndFilters> createState() => _SearchAndFiltersState();
}

class _SearchAndFiltersState extends State<SearchAndFilters>
    with TickerProviderStateMixin {
  late TextEditingController _searchController;
  late ScrollController _scrollController;
  late AnimationController _filterAnimationController;

  // Services
  final SearchService _searchService = SearchService();
  final CategoryService _categoryService = CategoryService();

  // State variables
  bool _isSearching = false;
  bool _isLoadingResults = false;
  bool _hasSearched = false;
  String _currentQuery = '';

  // Search results and suggestions
  List<Map<String, dynamic>> _searchResults = [];
  List<String> _searchSuggestions = [];
  List<String> _trendingKeywords = [];
  List<Map<String, dynamic>> _recentSearches = [];
  List<Map<String, dynamic>> _categories = [];

  // Filter state
  Map<String, dynamic> _activeFilters = {
    'category': null,
    'minPrice': null,
    'maxPrice': null,
    'location': null,
    'condition': null,
    'sortBy': 'newest',
  };

  bool _hasActiveFilters = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController();
    _filterAnimationController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);

    _searchController.addListener(_onSearchTextChanged);
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _filterAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadTrendingKeywords(),
      _loadRecentSearches(),
      _loadCategories(),
    ]);
  }

  Future<void> _loadTrendingKeywords() async {
    try {
      final keywords = await _searchService.getTrendingKeywords();
      setState(() {
        _trendingKeywords = keywords;
      });
    } catch (error) {
      debugPrint('❌ Failed to load trending keywords: $error');
      // Use fallback keywords
      setState(() {
        _trendingKeywords = [
          'iPhone',
          'MacBook',
          'furniture',
          'car',
          'laptop',
          'phone',
          'bicycle',
          'camera',
          'watch',
          'clothes'
        ];
      });
    }
  }

  Future<void> _loadRecentSearches() async {
    try {
      final searches = await _searchService.getSearchHistory();
      setState(() {
        _recentSearches = searches;
      });
    } catch (error) {
      debugPrint('❌ Failed to load recent searches: $error');
      // Recent searches are optional, so don't show error
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryService.getMainCategories();
      setState(() {
        _categories = categories;
      });
    } catch (error) {
      debugPrint('❌ Failed to load categories: $error');
      // Use fallback categories
      setState(() {
        _categories = [
          {'id': '1', 'name': 'Electronics'},
          {'id': '2', 'name': 'Furniture'},
          {'id': '3', 'name': 'Fashion'},
          {'id': '4', 'name': 'Sports'},
          {'id': '5', 'name': 'Automotive'},
        ];
      });
    }
  }

  void _onSearchTextChanged() {
    final query = _searchController.text;

    if (query.isEmpty) {
      setState(() {
        _searchSuggestions = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // Debounce search suggestions
    Future.delayed(const Duration(milliseconds: 300), () async {
      if (_searchController.text == query && query.isNotEmpty) {
        try {
          final suggestions = await _searchService.getSearchSuggestions(query);
          if (mounted && _searchController.text == query) {
            setState(() {
              _searchSuggestions = suggestions;
            });
          }
        } catch (error) {
          debugPrint('❌ Failed to get search suggestions: $error');
        }
      }
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoadingResults = true;
      _hasSearched = true;
      _currentQuery = query.trim();
    });

    try {
      // Save search to history
      await _searchService.saveSearchHistory(
          query: _currentQuery, filters: _activeFilters);

      // Perform search with filters
      final results = await _searchService.searchListings(
          query: _currentQuery,
          categoryId: _activeFilters['category'],
          location: _activeFilters['location'],
          minPrice: _activeFilters['minPrice']?.toDouble(),
          maxPrice: _activeFilters['maxPrice']?.toDouble());

      setState(() {
        _searchResults = results;
        _isLoadingResults = false;
        _searchSuggestions = [];
      });

      // Trigger haptic feedback
      HapticFeedback.lightImpact();
    } catch (error) {
      setState(() {
        _isLoadingResults = false;
        _searchResults = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Search failed. Please try again.'),
          backgroundColor: AppTheme.lightTheme.colorScheme.error));
    }
  }

  void _onSuggestionTap(String suggestion) {
    _searchController.text = suggestion;
    _performSearch(suggestion);
  }

  void _onTrendingKeywordTap(String keyword) {
    _searchController.text = keyword;
    _performSearch(keyword);
  }

  void _onRecentSearchTap(String query) {
    _searchController.text = query;
    _performSearch(query);
  }

  void _onFilterChanged(Map<String, dynamic> newFilters) {
    setState(() {
      _activeFilters = newFilters;
      _hasActiveFilters =
          newFilters.values.any((value) => value != null && value != 'newest');
    });

    if (_hasActiveFilters) {
      _filterAnimationController.forward();
    } else {
      _filterAnimationController.reverse();
    }

    // Re-run search if there's an active query
    if (_currentQuery.isNotEmpty) {
      _performSearch(_currentQuery);
    }
  }

  void _clearFilters() {
    setState(() {
      _activeFilters = {
        'category': null,
        'minPrice': null,
        'maxPrice': null,
        'location': null,
        'condition': null,
        'sortBy': 'newest',
      };
      _hasActiveFilters = false;
    });

    _filterAnimationController.reverse();

    // Re-run search if there's an active query
    if (_currentQuery.isNotEmpty) {
      _performSearch(_currentQuery);
    }
  }

  void _showFilterModal() {
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => FilterModalWidget(
              activeFilters: _activeFilters,
              onFiltersApplied: _onFilterChanged,
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: SafeArea(
            child: Column(children: [
          // Search Header
          Container(
              padding: EdgeInsets.all(4.w),
              color: AppTheme.lightTheme.colorScheme.surface,
              child: Column(children: [
                // Search Bar and Filter Button
                Row(children: [
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: CustomIconWidget(
                          iconName: 'arrow_back',
                          color: AppTheme.lightTheme.colorScheme.onSurface,
                          size: 24)),
                  Expanded(
                      child: SearchBarWidget(
                    controller: _searchController,
                    focusNode: FocusNode(),
                    onChanged: (_) => _onSearchTextChanged(),
                    onFilterPressed: _showFilterModal,
                  )),
                  SizedBox(width: 2.w),
                  AnimatedBuilder(
                      animation: _filterAnimationController,
                      builder: (context, child) {
                        return Container(
                            decoration: BoxDecoration(
                                color: _hasActiveFilters
                                    ? AppTheme.lightTheme.colorScheme.primary
                                    : AppTheme.lightTheme.colorScheme
                                        .surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(2.w),
                                border: _hasActiveFilters
                                    ? null
                                    : Border.all(
                                        color: AppTheme
                                            .lightTheme.colorScheme.outline)),
                            child: IconButton(
                                onPressed: _showFilterModal,
                                icon: CustomIconWidget(
                                    iconName: 'tune',
                                    color: _hasActiveFilters
                                        ? Colors.white
                                        : AppTheme.lightTheme.colorScheme
                                            .onSurfaceVariant,
                                    size: 24)));
                      }),
                ]),

                // Active Filter Chips
                if (_hasActiveFilters) ...[
                  SizedBox(height: 2.h),
                  FilterChipsWidget(
                    activeFilters: _activeFilters,
                    onClearAll: _clearFilters,
                    onRemoveFilter: (key) {
                      setState(() {
                        _activeFilters[key] = null;
                        _hasActiveFilters = _activeFilters.values
                            .any((value) => value != null && value != 'newest');
                      });
                      if (_currentQuery.isNotEmpty) {
                        _performSearch(_currentQuery);
                      }
                    },
                  ),
                ],
              ])),

          // Main Content
          Expanded(child: _buildMainContent()),
        ])));
  }

  Widget _buildMainContent() {
    if (_isLoadingResults) {
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircularProgressIndicator(
            color: AppTheme.lightTheme.colorScheme.primary),
        SizedBox(height: 2.h),
        Text('Searching...', style: AppTheme.lightTheme.textTheme.bodyLarge),
      ]));
    }

    if (_hasSearched && _searchResults.isNotEmpty) {
      return SearchResultsWidget(
        results: _searchResults,
        isGridView: true,
      );
    }

    if (_hasSearched && _searchResults.isEmpty) {
      return _buildNoResultsState();
    }

    // Default state - show trending and recent searches
    return SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (_trendingKeywords.isNotEmpty) ...[
            TrendingKeywordsWidget(
              onKeywordTap: _onTrendingKeywordTap,
              trendingKeywords: _trendingKeywords,
            ),
            SizedBox(height: 3.h),
          ],
          if (_recentSearches.isNotEmpty) ...[
            RecentSearchesWidget(
              onSearchTap: _onRecentSearchTap,
              recentSearches: _recentSearches.map((search) => search['query'].toString()).toList(),
            ),
          ],
        ]));
  }

  Widget _buildNoResultsState() {
    return Center(
        child: Padding(
            padding: EdgeInsets.all(8.w),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              CustomIconWidget(
                  iconName: 'search_off',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 80),
              SizedBox(height: 3.h),
              Text('No results found',
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant)),
              SizedBox(height: 1.h),
              Text('Try different keywords or adjust your filters',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center),
              SizedBox(height: 3.h),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (_hasActiveFilters) ...[
                  OutlinedButton(
                      onPressed: _clearFilters,
                      child: const Text('Clear Filters')),
                  SizedBox(width: 3.w),
                ],
                ElevatedButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _hasSearched = false;
                        _currentQuery = '';
                        _searchResults = [];
                      });
                    },
                    child: const Text('New Search')),
              ]),
            ])));
  }
}