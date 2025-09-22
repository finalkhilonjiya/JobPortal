// File: lib/presentation/home_marketplace_feed/home_marketplace_feed.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import './widgets/top_bar_widget.dart';
import './widgets/search_bar_full_width.dart';
import './widgets/app_info_banner_new.dart';
import './widgets/three_option_section.dart';
import './widgets/premium_section.dart';
import './widgets/square_product_card.dart';
import './widgets/listing_details_fullscreen.dart';
import './widgets/shimmer_widgets.dart';
import './widgets/marketplace_helpers.dart';
import './widgets/advanced_filter_sheet.dart';
import './widgets/create_listing_page.dart';
import './widgets/profile_page.dart';
import './widgets/bottom_nav_bar_widget.dart';
import './search_page.dart';
import '../../services/listing_service.dart';
import './construction_services_home_page.dart';
import './jobs_portal_home_page.dart';
import 'dart:async';
import './premium_package_page.dart';
import 'widgets/categories_section.dart';
import 'widgets/category_data.dart';
import '../login_screen/mobile_auth_service.dart';
import '../../core/app_export.dart';

class HomeMarketplaceFeed extends StatefulWidget {
  const HomeMarketplaceFeed({Key? key}) : super(key: key);

  @override
  State<HomeMarketplaceFeed> createState() => _HomeMarketplaceFeedState();
}

class _HomeMarketplaceFeedState extends State<HomeMarketplaceFeed> with WidgetsBindingObserver {
  final ListingService _listingService = ListingService();
  final MobileAuthService _authService = MobileAuthService();

  // Auth related state
  bool _isCheckingAuth = true;
  bool _isAuthenticatedUser = false;
  String? _currentUserId;

  int _currentIndex = 0;
  bool _isLoadingPremium = true;
  bool _isLoadingFeed = true;
  bool _isLoadingMore = false;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _listings = [];
  List<Map<String, dynamic>> _premiumListings = [];
  String _selectedCategory = 'All';
  String _selectedCategoryId = 'All';
  Set<String> _favoriteIds = {};
  String _currentLocation = 'Guwahati, Assam';
  final ScrollController _scrollController = ScrollController();

  // Category mapping - maps CategoryData names to database IDs
  Map<String, String> _categoryMapping = {};

  // Pagination
  int _currentOffset = 0;
  final int _pageSize = 20;
  bool _hasMoreData = true;
  bool _hasInitialLoadError = false;

  // Filter states
  String _priceRange = 'All';
  String _selectedSubcategory = 'All';
  String _sortBy = 'Newest';
  double _maxDistance = 50.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);

    // Initialize authentication first, then fetch data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWithAuth();
    });
    _detectLocation();

    // Keep session alive every 10 minutes
    Timer.periodic(Duration(minutes: 10), (timer) {
      if (mounted && _isAuthenticatedUser) {
        _authService.keepSessionAlive();
      } else if (!mounted) {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Check auth when app becomes active
    if (state == AppLifecycleState.resumed) {
      _verifyAuthState();
    }
  }

  /// Initialize authentication and then fetch data
  Future<void> _initializeWithAuth() async {
    setState(() {
      _isCheckingAuth = true;
    });

    try {
      // Initialize auth service
      await _authService.initialize();

      // Check if user is authenticated
      final isAuthenticated = _authService.isAuthenticated;
      final userId = _authService.userId;

      debugPrint('Auth Check - Authenticated: $isAuthenticated, User ID: $userId');

      if (isAuthenticated && userId != null) {
        setState(() {
          _isAuthenticatedUser = true;
          _currentUserId = userId;
          _isCheckingAuth = false;
        });

        // Try to refresh session to ensure it's valid
        final sessionValid = await _authService.refreshSession();
        if (!sessionValid) {
          debugPrint('Session refresh failed, redirecting to login');
          _redirectToLogin();
          return;
        }

        // Auth is valid, fetch data
        await _fetchData();

      } else {
        debugPrint('User not authenticated, redirecting to login');
        _redirectToLogin();
      }

    } catch (e) {
      debugPrint('Auth initialization error: $e');
      _redirectToLogin();
    }
  }

  /// Verify auth state without full initialization
  Future<void> _verifyAuthState() async {
    if (!_authService.isAuthenticated) {
      debugPrint('Auth verification failed, redirecting to login');
      _redirectToLogin();
      return;
    }

    // Try to refresh session
    final sessionValid = await _authService.refreshSession();
    if (!sessionValid) {
      debugPrint('Session verification failed, redirecting to login');
      _redirectToLogin();
    }
  }

  /// Redirect to login screen
  void _redirectToLogin() {
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/mobile_login', // Update this to match your actual route name
        (route) => false,
      );
    }
  }

  void _detectLocation() async {
    await Future.delayed(Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _currentLocation = 'Guwahati, Assam';
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreListings();
    }
  }

  Future<void> _loadMoreListings() async {
    if (!_isLoadingMore && !_isLoadingFeed && _hasMoreData && _isAuthenticatedUser) {
      setState(() => _isLoadingMore = true);

      try {
        // Verify auth before API call
        if (!_authService.isSupabaseAuthenticated) {
          debugPrint('Not authenticated for API call, refreshing session');
          final refreshed = await _authService.refreshSession();
          if (!refreshed) {
            _redirectToLogin();
            return;
          }
        }

        // Get the correct category ID for API call
        String? categoryIdForApi = _getCategoryIdForApi(_selectedCategoryId);

        final newListings = await _listingService.fetchListings(
          categoryId: categoryIdForApi,
          sortBy: _sortBy,
          offset: _currentOffset + _pageSize,
          limit: _pageSize,
        );

        if (mounted) {
          setState(() {
            if (newListings.isEmpty) {
              // If no more data, repeat from beginning
              _currentOffset = 0;
              _fetchListingsOnly();
            } else {
              _listings.addAll(newListings);
              _currentOffset += _pageSize;
            }
            _isLoadingMore = false;
          });
        }
      } catch (e) {
        debugPrint('Error loading more listings: $e');
        if (mounted) {
          setState(() => _isLoadingMore = false);
        }

        // Check if error is auth-related
        if (e.toString().contains('auth') || e.toString().contains('401')) {
          _verifyAuthState();
        }
      }
    }
  }

  Future<void> _fetchListingsOnly() async {
    if (!_isAuthenticatedUser) return;

    try {
      // Verify auth before API call
      if (!_authService.isSupabaseAuthenticated) {
        final refreshed = await _authService.refreshSession();
        if (!refreshed) {
          _redirectToLogin();
          return;
        }
      }

      // Get the correct category ID for API call
      String? categoryIdForApi = _getCategoryIdForApi(_selectedCategoryId);

      final listings = await _listingService.fetchListings(
        categoryId: categoryIdForApi,
        sortBy: _sortBy,
        offset: 0,
        limit: _pageSize,
      );

      if (listings.isNotEmpty && mounted) {
        setState(() {
          _listings.addAll(listings);
        });
      }
    } catch (e) {
      debugPrint('Error fetching listings: $e');
      if (e.toString().contains('auth') || e.toString().contains('401')) {
        _verifyAuthState();
      }
    }
  }

  /// Get the correct category ID for API calls
  String? _getCategoryIdForApi(String selectedCategoryId) {
    if (selectedCategoryId == 'All') return null;
    
    // If it's already a database ID (from mapping), use it
    if (_categoryMapping.containsValue(selectedCategoryId)) {
      return selectedCategoryId;
    }
    
    // If it's a CategoryData name, get the mapped database ID
    return _categoryMapping[selectedCategoryId];
  }

  Future<void> _fetchData() async {
    if (!_isAuthenticatedUser) return;

    setState(() {
      _isLoadingPremium = true;
      _isLoadingFeed = true;
      _currentOffset = 0;
      _listings = [];
      _hasInitialLoadError = false;
    });

    try {
      // Verify Supabase auth state before making API calls
      if (!_authService.isSupabaseAuthenticated) {
        debugPrint('Supabase not authenticated, attempting refresh');
        final refreshed = await _authService.refreshSession();
        if (!refreshed) {
          debugPrint('Session refresh failed during data fetch');
          _redirectToLogin();
          return;
        }
      }

      debugPrint('Fetching data for authenticated user: $_currentUserId');

      // Fetch categories from database and create mapping
      List<Map<String, dynamic>> databaseCategories = [];
      Map<String, String> categoryMapping = {};
      
      try {
        databaseCategories = await _listingService.getCategories();
        debugPrint('Fetched ${databaseCategories.length} categories from API');
        
        // Create mapping between CategoryData names and database IDs
        categoryMapping = _createCategoryMapping(databaseCategories);
      } catch (e) {
        debugPrint('Error fetching categories from API: $e');
        // Continue with empty mapping, will use CategoryData only
      }

      // Build category list - always use CategoryData for consistency
      final List<Map<String, dynamic>> processedCategories = _buildCategoryList(categoryMapping);

      // Fetch user favorites
      Set<String> favorites = {};
      try {
        favorites = await _listingService.getUserFavorites();
        debugPrint('Fetched ${favorites.length} user favorites');
      } catch (e) {
        debugPrint('Error fetching favorites: $e');
        // Check if error is auth-related
        if (e.toString().contains('auth') || e.toString().contains('401')) {
          _verifyAuthState();
          return;
        }
      }

      // Fetch listings
      List<Map<String, dynamic>> listings = [];
      try {
        listings = await _listingService.fetchListings(
          sortBy: _sortBy,
          offset: 0,
          limit: _pageSize,
        );
        debugPrint('Fetched ${listings.length} listings');
      } catch (e) {
        debugPrint('Error fetching listings: $e');
        if (e.toString().contains('auth') || e.toString().contains('401')) {
          _verifyAuthState();
          return;
        }
      }

      // Fetch premium listings
      List<Map<String, dynamic>> premiumListings = [];
      try {
        premiumListings = await _listingService.fetchPremiumListings(
          limit: 10,
        );
        debugPrint('Fetched ${premiumListings.length} premium listings');
      } catch (e) {
        debugPrint('Error fetching premium listings: $e');
        if (e.toString().contains('auth') || e.toString().contains('401')) {
          _verifyAuthState();
          return;
        }
      }

      if (mounted) {
        setState(() {
          _categories = processedCategories;
          _categoryMapping = categoryMapping;
          _favoriteIds = favorites;
          _listings = listings;
          _premiumListings = premiumListings;
          _isLoadingPremium = false;
          _isLoadingFeed = false;

          // Only show error if both listings and premium failed
          if (listings.isEmpty && premiumListings.isEmpty && databaseCategories.isEmpty) {
            _hasInitialLoadError = true;
          }
        });
      }
    } catch (e) {
      debugPrint('Unexpected error in _fetchData: $e');
      if (mounted) {
        setState(() {
          // Use CategoryData only on error
          _categories = _buildCategoryList({});
          _categoryMapping = {};
          _listings = [];
          _premiumListings = [];
          _isLoadingPremium = false;
          _isLoadingFeed = false;
          _hasInitialLoadError = true;
        });
      }

      // Check if error is auth-related
      if (e.toString().contains('auth') || e.toString().contains('401')) {
        _verifyAuthState();
      }
    }
  }

  /// Create mapping between CategoryData names and database category IDs
  Map<String, String> _createCategoryMapping(List<Map<String, dynamic>> databaseCategories) {
    Map<String, String> mapping = {};
    
    // Define the rental categories we want to show
    final targetCategories = [
      'Room for Rent',
      'PG Accommodation', 
      'Homestays',
      'Properties for Rent'
    ];

    for (String categoryName in targetCategories) {
      // Try to find matching database category
      final dbCategory = databaseCategories.firstWhere(
        (cat) => cat['name'] == categoryName || 
                 cat['name'].toLowerCase() == categoryName.toLowerCase() ||
                 _isSimilarCategory(cat['name'], categoryName),
        orElse: () => {},
      );
      
      if (dbCategory.isNotEmpty && dbCategory['id'] != null) {
        mapping[categoryName] = dbCategory['id'].toString();
        debugPrint('Mapped "$categoryName" to database ID: ${dbCategory['id']}');
      } else {
        debugPrint('No database category found for: $categoryName');
      }
    }
    
    return mapping;
  }

  /// Check if two category names are similar (for mapping flexibility)
  bool _isSimilarCategory(String dbName, String localName) {
    // Add custom mapping logic for similar category names
    final similarityMap = {
      'Properties for Rent': ['Property for Rent', 'Properties', 'Real Estate'],
      'Room for Rent': ['Room Rental', 'Rooms', 'Single Room'],
      'PG Accommodation': ['PG', 'Paying Guest', 'PG Hostel'],
      'Homestays': ['Homestay', 'Home Stay', 'Guest House'],
    };

    return similarityMap[localName]?.any((similar) => 
      dbName.toLowerCase().contains(similar.toLowerCase())) ?? false;
  }

  /// Build the category list using CategoryData with database ID mapping
  List<Map<String, dynamic>> _buildCategoryList(Map<String, String> categoryMapping) {
    final List<Map<String, dynamic>> processedCategories = [];
    
    // Always add "All" category first
    processedCategories.add({
      'name': 'All',
      'id': 'All',
      'icon': Icons.apps_rounded,
      'image': 'https://cdn-icons-png.flaticon.com/512/8058/8058572.png',
    });

    // Add only the rental categories from CategoryData
    final rentalCategories = CategoryData.mainCategories.where(
      (cat) => cat['name'] != 'All' // Exclude "All" as we already added it
    );

    for (final cat in rentalCategories) {
      final categoryName = cat['name'] as String;
      final databaseId = categoryMapping[categoryName] ?? categoryName;
      
      processedCategories.add({
        'name': categoryName,
        'id': databaseId, // Use database ID if available, otherwise use name
        'icon': cat['icon'],
        'image': cat['image'],
      });
    }

    debugPrint('Built ${processedCategories.length} categories for display');
    return processedCategories;
  }

  void _onCategorySelected(String name) {
    final category = _categories.firstWhere(
      (cat) => cat['name'] == name,
      orElse: () => {'name': 'All', 'id': 'All', 'icon': Icons.category},
    );

    setState(() {
      _selectedCategory = name;
      _selectedCategoryId = category['id'] as String;
      _selectedSubcategory = 'All';
      _currentOffset = 0;
      _hasMoreData = true;
    });

    _fetchFilteredListings();
  }

  Future<void> _fetchFilteredListings() async {
    if (!_isAuthenticatedUser) return;

    setState(() {
      _isLoadingFeed = true;
      _listings = [];
      _currentOffset = 0;
    });

    try {
      // Verify auth before API call
      if (!_authService.isSupabaseAuthenticated) {
        final refreshed = await _authService.refreshSession();
        if (!refreshed) {
          _redirectToLogin();
          return;
        }
      }

      // Get the correct category ID for API call
      String? categoryIdForApi = _getCategoryIdForApi(_selectedCategoryId);

      final listings = await _listingService.fetchListings(
        categoryId: categoryIdForApi,
        sortBy: _sortBy,
        offset: 0,
        limit: _pageSize,
      );

      // Also fetch filtered premium listings
      List<Map<String, dynamic>> premiumListings = [];
      try {
        premiumListings = await _listingService.fetchPremiumListings(
          categoryId: categoryIdForApi,
          limit: 10,
        );
      } catch (e) {
        debugPrint('Error fetching filtered premium listings: $e');
        // Keep existing premium listings if fetch fails
        premiumListings = _premiumListings;
      }

      if (mounted) {
        setState(() {
          _listings = listings;
          _premiumListings = premiumListings;
          _currentOffset = 0;
          _isLoadingFeed = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching filtered listings: $e');
      if (mounted) {
        setState(() {
          _listings = [];
          _isLoadingFeed = false;
        });
      }

      if (e.toString().contains('auth') || e.toString().contains('401')) {
        _verifyAuthState();
      }
    }
  }

  void _toggleFavorite(String id) async {
    if (!_isAuthenticatedUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please login to add favorites'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Verify auth before API call
      if (!_authService.isSupabaseAuthenticated) {
        final refreshed = await _authService.refreshSession();
        if (!refreshed) {
          _redirectToLogin();
          return;
        }
      }

      final isFavorited = await _listingService.toggleFavorite(id);

      if (mounted) {
        setState(() {
          if (isFavorited) {
            _favoriteIds.add(id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Added to favorites'), duration: Duration(seconds: 1)),
            );
          } else {
            _favoriteIds.remove(id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Removed from favorites'), duration: Duration(seconds: 1)),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Toggle favorite error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update favorites'),
            backgroundColor: Colors.red,
          ),
        );
      }

      if (e.toString().contains('auth') || e.toString().contains('401')) {
        _verifyAuthState();
      }
    }
  }

  List<Map<String, dynamic>> get _filteredListings {
    return _listings;
  }

  void _openAdvancedFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdvancedFilterSheet(
        selectedCategory: _selectedCategory,
        priceRange: _priceRange,
        selectedSubcategory: _selectedSubcategory,
        sortBy: _sortBy,
        maxDistance: _maxDistance,
        onApplyFilter: (filters) {
          setState(() {
            _priceRange = filters['priceRange'];
            _selectedSubcategory = filters['subcategory'];
            _sortBy = filters['sortBy'];
            _maxDistance = filters['maxDistance'];
          });
          Navigator.pop(context);
          _fetchFilteredListings();
        },
      ),
    );
  }

  void _showListingDetails(Map<String, dynamic> listing) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListingDetailsFullscreen(
          listing: listing,
          isFavorite: _favoriteIds.contains(listing['id']),
          onFavoriteToggle: () => _toggleFavorite(listing['id']),
          onCall: () => MarketplaceHelpers.makePhoneCall(context, listing['phone']),
          onWhatsApp: () => MarketplaceHelpers.openWhatsApp(context, listing['phone']),
        ),
      ),
    );
  }

  void _openCreateListing() {
    if (!_isAuthenticatedUser) {
      _redirectToLogin();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateListingPage(),
        fullscreenDialog: true,
      ),
    ).then((_) {
      _fetchData();
    });
  }

  void _navigateToProfile() {
    if (!_isAuthenticatedUser) {
      _redirectToLogin();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfilePage()),
    );
  }

  void _navigateToJobs() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobsPortalHomePage(),
      ),
    );
  }

  void _navigateToConstructionServices() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConstructionServicesHomePage(),
      ),
    );
  }

  Widget _buildListingWithPremium(int index) {
    if ((index + 1) % 13 == 0 && _premiumListings.isNotEmpty) {
      final premiumIndex = ((index + 1) ~/ 13) - 1;
      return Column(
        children: [
          SquareProductCard(
            data: _filteredListings[index - (premiumIndex + 1)],
            isFavorite: _favoriteIds.contains(_filteredListings[index - (premiumIndex + 1)]['id']),
            onFavoriteToggle: () => _toggleFavorite(_filteredListings[index - (premiumIndex + 1)]['id']),
            onTap: () => _showListingDetails(_filteredListings[index - (premiumIndex + 1)]),
            onCall: () => MarketplaceHelpers.makePhoneCall(
              context, 
              _filteredListings[index - (premiumIndex + 1)]['phone']
            ),
            onWhatsApp: () => MarketplaceHelpers.openWhatsApp(
              context, 
              _filteredListings[index - (premiumIndex + 1)]['phone']
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(vertical: 2.h),
            padding: EdgeInsets.only(bottom: 2.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  child: Text(
                    'Sponsored',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                PremiumSection(
                  listings: _premiumListings,
                  onTap: _showListingDetails,
                  favoriteIds: _favoriteIds,
                  onFavoriteToggle: _toggleFavorite,
                  onCall: (phone) => MarketplaceHelpers.makePhoneCall(context, phone),
                  onWhatsApp: (phone) => MarketplaceHelpers.openWhatsApp(context, phone),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final actualIndex = index - ((index ~/ 13));
    if (actualIndex >= _filteredListings.length) return SizedBox.shrink();

    return SquareProductCard(
      data: _filteredListings[actualIndex],
      isFavorite: _favoriteIds.contains(_filteredListings[actualIndex]['id']),
      onFavoriteToggle: () => _toggleFavorite(_filteredListings[actualIndex]['id']),
      onTap: () => _showListingDetails(_filteredListings[actualIndex]),
      onCall: () => MarketplaceHelpers.makePhoneCall(
        context, 
        _filteredListings[actualIndex]['phone']
      ),
      onWhatsApp: () => MarketplaceHelpers.openWhatsApp(
        context, 
        _filteredListings[actualIndex]['phone']
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while checking authentication
    if (_isCheckingAuth) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF2563EB)),
              SizedBox(height: 2.h),
              Text(
                'Verifying authentication...',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Main authenticated UI
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _verifyAuthState();
            if (_isAuthenticatedUser) {
              await _fetchData();
            }
          },
          color: Color(0xFF2563EB),
          child: CustomScrollView(
            controller: _scrollController,
            physics: AlwaysScrollableScrollPhysics(),
            slivers: [
              // Top Bar - Updated to use company logo
              SliverToBoxAdapter(
                child: TopBarWidget(
                  currentLocation: _currentLocation,
                  onLocationTap: _detectLocation,
                ),
              ),

              // Search Bar
              SliverToBoxAdapter(
                child: SearchBarFullWidth(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SearchPage(),
                      ),
                    );
                  },
                ),
              ),

              // App Info Banner
              SliverToBoxAdapter(child: AppInfoBannerNew()),

              // Three Options - Updated for Jobs and Construction Services
              SliverToBoxAdapter(
                child: ThreeOptionSection(
                  onJobsTap: _navigateToJobs,
                  onConstructionTap: _navigateToConstructionServices,
                ),
              ),

              // Premium Section
              if (_premiumListings.isNotEmpty)
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                        child: Text(
                          'Premium Listings',
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.only(bottom: 2.h),
                        child: _isLoadingPremium
                            ? ShimmerPremiumSection()
                            : PremiumSection(
                                listings: _premiumListings,
                                onTap: _showListingDetails,
                                favoriteIds: _favoriteIds,
                                onFavoriteToggle: _toggleFavorite,
                                onCall: (phone) => MarketplaceHelpers.makePhoneCall(context, phone),
                                onWhatsApp: (phone) => MarketplaceHelpers.openWhatsApp(context, phone),
                              ),
                      ),
                    ],
                  ),
                ),

              // Categories - Now only shows 4 rental categories
              SliverToBoxAdapter(
                child: CategoriesSection(
                  categories: _categories.map((cat) => cat.cast<String, Object>()).toList(),
                  selected: _selectedCategory,
                  onSelect: _onCategorySelected,
                ),
              ),

              // Filter Bar
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedCategory == 'All' ? 'All Listings' : _selectedCategory,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      InkWell(
                        onTap: _openAdvancedFilter,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                          decoration: BoxDecoration(
                            border: Border.all(color: Color(0xFF2563EB)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.filter_list,
                                color: Color(0xFF2563EB),
                                size: 4.5.w,
                              ),
                              SizedBox(width: 1.w),
                              Text(
                                'Filter',
                                style: TextStyle(
                                  color: Color(0xFF2563EB),
                                  fontSize: 11.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Main Feed
              if (_hasInitialLoadError && _listings.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    height: 50.h,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_off, size: 15.w, color: Colors.grey),
                          SizedBox(height: 2.h),
                          Text(
                            'Unable to load listings',
                            style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
                          ),
                          SizedBox(height: 2.h),
                          ElevatedButton(
                            onPressed: _fetchData,
                            child: Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (_isLoadingFeed && _filteredListings.isEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => ShimmerProductCard(),
                    childCount: 6,
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, index) => _buildListingWithPremium(index),
                    childCount: _filteredListings.length + 
                               (_filteredListings.length ~/ 12),
                  ),
                ),

              // Loading more indicator
              if (_isLoadingMore)
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.all(2.h),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ),

              SliverPadding(padding: EdgeInsets.only(bottom: 10.h)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBarWidget(
        currentIndex: _currentIndex,
        hasMessageNotification: true,
        onTabSelected: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SearchPage()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PremiumPackagePage()),
            );
          } else if (index == 4) {
            _navigateToProfile();
          }
        },
        onFabPressed: _openCreateListing,
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: _openCreateListing,
            backgroundColor: Color(0xFF2563EB),
            child: Icon(Icons.add, color: Colors.white),
            heroTag: 'sell_fab',
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}