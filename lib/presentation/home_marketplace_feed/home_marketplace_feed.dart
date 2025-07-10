import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../utils/category_service.dart';
import '../../utils/listing_service.dart';
import '../../utils/favorite_service.dart';
import '../../utils/auth_service.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/enhanced_category_chip_widget.dart';
import './widgets/compact_listing_card_widget.dart';
import './widgets/enhanced_location_selector_widget.dart';
import './widgets/trending_section_widget.dart';
import './widgets/quick_action_widget.dart';
import './widgets/advanced_filter_widget.dart';

class HomeMarketplaceFeed extends StatefulWidget {
  const HomeMarketplaceFeed({Key? key}) : super(key: key);

  @override
  State<HomeMarketplaceFeed> createState() => _HomeMarketplaceFeedState();
}

class _HomeMarketplaceFeedState extends State<HomeMarketplaceFeed>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _headerAnimationController;
  late AnimationController _listAnimationController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _listSlideAnimation;
  // Scroll and Loading States
  late ScrollController _scrollController;
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isLoadingCategories = false;
  bool _isLoadingLocation = false;
  bool _showBackToTop = false;
  bool _showSearch = false;
  String _searchQuery = '';
  Map<String, dynamic> _activeFilters = {};
  bool _useGpsLocation = false;
  Position? _currentPosition;
  double _selectedDistance = 5.0;
  // Navigation and Selection States
  int _currentIndex = 0;
  String _selectedCategory = 'All';
  String _selectedLocation = 'Detect Location';
  Set<String> _favoriteListings = {};
  // Data Collections
  List<Map<String, dynamic>> _listings = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _trendingListings = [];
  // Services
  final CategoryService _categoryService = CategoryService();
  final ListingService _listingService = ListingService();
  final FavoriteService _favoriteService = FavoriteService();
  final AuthService _authService = AuthService();
  // Enhanced Categories for khilonjiya.com marketplace
  final List<Map<String, dynamic>> _defaultCategories = [
    {'id': 'all', 'name': 'All', 'icon': 'apps', 'color': '0xFF6366F1'},
    {'id': 'electronics', 'name': 'Electronics', 'icon': 'devices', 'color': '0xFF3B82F6'},
    {'id': 'fashion', 'name': 'Fashion', 'icon': 'checkroom', 'color': '0xFFEC4899'},
    {'id': 'jobs', 'name': 'Jobs', 'icon': 'work', 'color': '0xFF10B981'},
    {'id': 'automotive', 'name': 'Vehicles', 'icon': 'directions_car', 'color': '0xFFF59E0B'},
    {'id': 'furniture', 'name': 'Furniture', 'icon': 'chair', 'color': '0xFF8B5CF6'},
    {'id': 'books', 'name': 'Books', 'icon': 'menu_book', 'color': '0xFF06B6D4'},
    {'id': 'sports', 'name': 'Sports', 'icon': 'sports_soccer', 'color': '0xFFF97316'},
    {'id': 'food', 'name': 'Food', 'icon': 'restaurant', 'color': '0xFFEF4444'},
    {'id': 'services', 'name': 'Services', 'icon': 'handyman', 'color': '0xFF84CC16'},
  ];
  final List<String> _defaultLocations = [
    'Detect Location',
    'Guwahati, Assam',
    'Dibrugarh, Assam',
    'Jorhat, Assam',
    'Silchar, Assam',
    'Tezpur, Assam',
    'Nagaon, Assam',
    'Bongaigaon, Assam',
    'Sivasagar, Assam',
  ];
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupScrollController();
    _requestLocationPermission();
    _loadInitialData();
  }

  void _setupAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _headerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOut,
    ));
    
    _listSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _listAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animations
    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _listAnimationController.forward();
    });
  }

  void _setupScrollController() {
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _scrollController.addListener(() {
      setState(() {
        _showBackToTop = _scrollController.offset > 500;
      });
    });
  }

  Future<void> _requestLocationPermission() async {
    try {
      setState(() {
        _isLoadingLocation = true;
      });

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        await _getCurrentLocation();
      } else {
        setState(() {
          _useGpsLocation = false;
          _selectedLocation = 'Guwahati, Assam'; // Default to Guwahati
        });
      }
    } catch (e) {
      debugPrint('❌ Location permission error: $e');
      setState(() {
        _useGpsLocation = false;
        _selectedLocation = 'Guwahati, Assam';
      });
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      if (_currentPosition != null) {
        setState(() {
          _selectedLocation = 'Current Location';
          _useGpsLocation = true;
        });
      }
    } catch (e) {
      debugPrint('❌ Get location error: $e');
      setState(() {
        _useGpsLocation = false;
        _selectedLocation = 'Guwahati, Assam';
      });
    }
  }


Future<void> _loadInitialData() async {
    await Future.wait([
      _loadCategories(),
      _loadTrendingListings(),
      _loadListings(),
      _loadFavorites(),
    ]);
  }

  Future<void> _loadCategories() async {
    try {
      setState(() {
        _isLoadingCategories = true;
      });

      final categories = await _categoryService.getMainCategories();
      
      setState(() {
        _categories = _defaultCategories.map((defaultCat) {
          // Try to find matching category from service
          final serverCat = categories.firstWhere(
            (cat) => cat['name'].toString().toLowerCase() == 
                     defaultCat['name'].toString().toLowerCase(),
            orElse: () => <String, dynamic>{},
          );
          
          return {
            'id': serverCat?['id'] ?? defaultCat['id'],
            'name': defaultCat['name'],
            'icon': defaultCat['icon'],
            'color': defaultCat['color'],
            'count': serverCat?['listing_count'] ?? 0,
          };
        }).toList();
        _isLoadingCategories = false;
      });
    } catch (error) {
      setState(() {
        _isLoadingCategories = false;
        _categories = _defaultCategories.map((cat) => {
          ...cat,
          'count': 0,
        }).toList();
      });
      debugPrint('❌ Failed to load categories: $error');
    }
  }

  Future<void> _loadTrendingListings() async {
    try {
      final trending = await _listingService.getTrendingListings(limit: 5);
      setState(() {
        _trendingListings = trending.map((listing) => _formatListing(listing)).toList();
      });
    } catch (error) {
      debugPrint('❌ Failed to load trending listings: $error');
      setState(() {
        _trendingListings = [];
      });
    }
  }

  Future<void> _loadListings() async {
    try {
      setState(() {
        _isLoading = true;
      });

      List<Map<String, dynamic>> listings;
      
      // Apply distance filter if GPS location is available
      if (_useGpsLocation && _currentPosition != null) {
        listings = await _listingService.getNearbyListings(
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          radiusKm: _selectedDistance,
          categoryId: _selectedCategory == 'All' ? null : _selectedCategory,
          limit: 20,
        );
      } else if (_selectedCategory == 'All') {
        listings = await _listingService.getActiveListings(limit: 20);
      } else {
        final category = _categories.firstWhere(
          (cat) => cat['name'] == _selectedCategory,
          orElse: () => <String, dynamic>{},
        );
        final categoryId = category['id'];
        
        if (categoryId != null && categoryId != 'all') {
          listings = await _listingService.getListingsByCategory(categoryId, limit: 20);
        } else {
          listings = await _listingService.getActiveListings(limit: 20);
        }
      }

      // Apply search filter if active
      if (_searchQuery.isNotEmpty) {
        listings = listings.where((listing) {
          final title = listing['title'].toString().toLowerCase();
          final description = listing['description']?.toString().toLowerCase() ?? '';
          final query = _searchQuery.toLowerCase();
          return title.contains(query) || description.contains(query);
        }).toList();
      }

      setState(() {
        _listings = listings.map((listing) => _formatListing(listing)).toList();
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _listings = _getMockListings();
      });
      debugPrint('❌ Failed to load listings: $error');
    }
  }

  Map<String, dynamic> _formatListing(Map<String, dynamic> listing) {
    final images = listing['images'] as List<dynamic>?;
    final firstImage = images?.isNotEmpty == true
        ? images!.first as String
        : 'https://images.unsplash.com/photo-1560472355-536de3962603?w=400&h=300&fit=crop';

    double? distance;
    if (_currentPosition != null && listing['latitude'] != null && listing['longitude'] != null) {
      distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        listing['latitude'].toDouble(),
        listing['longitude'].toDouble(),
      ) / 1000; // Convert to kilometers
    }

    return {
      'id': listing['id'],
      'title': listing['title'],
      'price': '\$${listing['price']}',
      'location': listing['location'] ?? 'Unknown Location',
      'timePosted': _formatTimeAgo(DateTime.parse(listing['created_at'])),
      'imageUrl': firstImage,
      'category': listing['category']?['name'] ?? 'General',
      'isSponsored': listing['is_featured'] ?? false,
      'isFavorite': _favoriteListings.contains(listing['id'].toString()),
      'views_count': listing['views_count'] ?? 0,
      'condition': listing['condition'] ?? 'good',
      'seller': listing['seller'],
      'distance': distance,
      'description': listing['description'],
      'latitude': listing['latitude'],
      'longitude': listing['longitude'],
    };
  }

  Future<void> _loadFavorites() async {
    try {
      if (_authService.isAuthenticated()) {
        final favorites = await _favoriteService.getUserFavorites();
        final Set<String> ids = favorites
            .map<String>((fav) => fav['listing_id'].toString())
            .toSet();

        setState(() {
          _favoriteListings = ids;
        });
      }
    } catch (error) {
      debugPrint('❌ Failed to load favorites: $error');
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  List<Map<String, dynamic>> _getMockListings() {
    return [
      {
        "id": "1",
        "title": "iPhone 14 Pro Max - Excellent Condition",
        "price": "₹89,999",
        "location": "Fancy Bazar, Guwahati",
        "timePosted": "2 hours ago",
        "imageUrl": "https://images.unsplash.com/photo-1592750475338-74b7b21085ab?w=400&h=300&fit=crop",
        "category": "Electronics",
        "isSponsored": true,
        "isFavorite": false,
        "distance": 2.5,
        "condition": "excellent",
        "seller": {"phone_number": "+918638527410"},
      },
      {
        "id": "2",
        "title": "Assamese Traditional Mekhela Chador",
        "price": "₹12,500",
        "location": "Paltan Bazar, Guwahati",
        "timePosted": "4 hours ago",
        "imageUrl": "https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=400&h=300&fit=crop",
        "category": "Fashion",
        "isSponsored": false,
        "isFavorite": false,
        "distance": 1.8,
        "condition": "new",
        "seller": {"phone_number": null},
      },
      {
        "id": "3",
        "title": "Software Developer - Remote Work",
        "price": "₹8,50,000/year",
        "location": "Guwahati, Assam",
        "timePosted": "6 hours ago",
        "imageUrl": "https://images.unsplash.com/photo-1517077304055-6e89abbf09b0?w=400&h=300&fit=crop",
        "category": "Jobs",
        "isSponsored": false,
        "isFavorite": true,
        "distance": 0.5,
        "condition": "new",
        "seller": {"phone_number": "+919876543210"},
      },
    ];
  }


void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreListings();
    }
  }

  Future<void> _refreshListings() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    HapticFeedback.lightImpact();
    
    await Future.wait([
      _loadCategories(),
      _loadTrendingListings(),
      _loadListings(),
      _loadFavorites(),
    ]);

    setState(() {
      _isRefreshing = false;
    });
  }

  Future<void> _loadMoreListings() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> moreListings;
      final offset = _listings.length;

      if (_useGpsLocation && _currentPosition != null) {
        moreListings = await _listingService.getNearbyListings(
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          radiusKm: _selectedDistance,
          categoryId: _selectedCategory == 'All' ? null : _selectedCategory,
          limit: 10,
          offset: offset,
        );
      } else if (_selectedCategory == 'All') {
        moreListings = await _listingService.getActiveListings(
          limit: 10, 
          offset: offset,
        );
      } else {
        final categoryId = _categories.firstWhere(
          (cat) => cat['name'] == _selectedCategory,
          orElse: () => {'id': null},
        )['id'];
        
        if (categoryId != null && categoryId != 'all') {
          moreListings = await _listingService.getListingsByCategory(
            categoryId,
            limit: 10,
            offset: offset,
          );
        } else {
          moreListings = await _listingService.getActiveListings(
            limit: 10,
            offset: offset,
          );
        }
      }

      setState(() {
        _listings.addAll(moreListings.map((listing) => _formatListing(listing)));
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('❌ Failed to load more listings: $error');
    }
  }

  Future<void> _toggleFavorite(String listingId) async {
    HapticFeedback.lightImpact();

    try {
      if (!_authService.isAuthenticated()) {
        Navigator.pushNamed(context, AppRoutes.loginScreen);
        return;
      }

      if (_favoriteListings.contains(listingId.toString())) {
        await _favoriteService.removeFavorite(listingId);
        setState(() {
          _favoriteListings.remove(listingId.toString());
        });
        _showSnackBar('Removed from favorites', Icons.favorite_border);
      } else {
        await _favoriteService.addFavorite(listingId);
        setState(() {
          _favoriteListings.add(listingId.toString());
        });
        _showSnackBar('Added to favorites', Icons.favorite, isSuccess: true);
      }

      // Update the listing's favorite status in the lists
      setState(() {
        final index = _listings.indexWhere((listing) => listing['id'] == listingId);
        if (index != -1) {
          _listings[index]['isFavorite'] = _favoriteListings.contains(listingId.toString());
        }
        
        final trendingIndex = _trendingListings.indexWhere((listing) => listing['id'] == listingId);
        if (trendingIndex != -1) {
          _trendingListings[trendingIndex]['isFavorite'] = _favoriteListings.contains(listingId.toString());
        }
      });
    } catch (error) {
      debugPrint('❌ Failed to toggle favorite: $error');
      _showSnackBar('Failed to update favorite', Icons.error, isError: true);
    }
  }

  void _onCategorySelected(String category) {
    if (_selectedCategory == category) return;
    
    setState(() {
      _selectedCategory = category;
    });
    
    HapticFeedback.lightImpact();
    _loadListings();
  }

  void _onLocationChanged(String location) {
    setState(() {
      _selectedLocation = location;
      if (location == 'Detect Location') {
        _useGpsLocation = true;
        _getCurrentLocation();
      } else {
        _useGpsLocation = false;
      }
    });
    
    HapticFeedback.lightImpact();
    _loadListings();
  }

  void _onDistanceChanged(double distance) {
    setState(() {
      _selectedDistance = distance;
    });
    
    if (_useGpsLocation) {
      _loadListings();
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    
    // Debounce search
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchQuery == query) {
        _loadListings();
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchQuery = '';
        _loadListings();
      }
    });
    
    HapticFeedback.lightImpact();
  }

  void _showAdvancedFilters() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdvancedFilterWidget(
        currentFilters: _activeFilters,
        currentDistance: _selectedDistance,
        useGpsLocation: _useGpsLocation,
        onFiltersApplied: (filters, distance) {
          setState(() {
            _activeFilters = filters;
            _selectedDistance = distance;
          });
          _loadListings();
        },
      ),
    );
  }

  void _onListingTap(Map<String, dynamic> listing) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, AppRoutes.listingDetail, arguments: listing);
  }

  void _onListingLongPress(Map<String, dynamic> listing) {
    HapticFeedback.mediumImpact();
    _showQuickActions(listing);
  }

  void _showQuickActions(Map<String, dynamic> listing) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickActionWidget(
        listing: listing,
        onShare: () => _shareListing(listing),
        onReport: () => _reportListing(listing),
        onHide: () => _hideListing(listing),
      ),
    );
  }

  void _shareListing(Map<String, dynamic> listing) {
    // Implement share functionality
    _showSnackBar('Share functionality coming soon!', Icons.share);
  }

  void _reportListing(Map<String, dynamic> listing) {
    // Implement report functionality
    _showSnackBar('Listing reported', Icons.flag, isSuccess: true);
  }

  void _hideListing(Map<String, dynamic> listing) {
    setState(() {
      _listings.removeWhere((item) => item['id'] == listing['id']);
    });
    _showSnackBar('Listing hidden', Icons.visibility_off);
  }

  void _scrollToTop() {
    HapticFeedback.lightImpact();
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _showSnackBar(String message, IconData icon, {bool isSuccess = false, bool isError = false}) {
    if (!mounted) return;
    
    Color backgroundColor;
    if (isSuccess) {
      backgroundColor = AppTheme.getSuccessColor(true);
    } else if (isError) {
      backgroundColor = AppTheme.lightTheme.colorScheme.error;
    } else {
      backgroundColor = AppTheme.lightTheme.colorScheme.primary;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            SizedBox(width: 2.w),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(4.w),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredListings {
    return _listings;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshListings,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: _buildEnhancedHeader(),
              ),
              // Trending Section
              if (_trendingListings.isNotEmpty)
                SliverToBoxAdapter(
                  child: TrendingSectionWidget(
                    trendingListings: _trendingListings,
                    onListingTap: _onListingTap,
                    onFavoriteTap: _toggleFavorite,
                  ),
                ),
              // Listings
              _filteredListings.isEmpty && !_isLoading
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index >= _filteredListings.length) {
                            return _isLoading ? _buildLoadingIndicator() : null;
                          }
                          final listing = _filteredListings[index];
                          final isFavorite = _favoriteListings.contains(listing['id'].toString());
                          return CompactListingCardWidget(
                            listing: listing,
                            isFavorite: isFavorite,
                            onTap: () => _onListingTap(listing),
                            onLongPress: () => _onListingLongPress(listing),
                            onFavoriteTap: () => _toggleFavorite(listing['id'].toString()),
                            showDistance: _useGpsLocation,
                          );
                        },
                        childCount: _filteredListings.length + (_isLoading ? 1 : 0),
                      ),
                    ),
              // Bottom padding
              SliverToBoxAdapter(
                child: SizedBox(height: 10.h),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildEnhancedBottomNav(),
      floatingActionButton: _showBackToTop
          ? FloatingActionButton.small(
              onPressed: _scrollToTop,
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
              child: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
            )
          : FloatingActionButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pushNamed(context, AppRoutes.createListing);
              },
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
    );
  }

  Widget _buildEnhancedHeader() {
    return Container(
      color: AppTheme.lightTheme.colorScheme.surface,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Column(
        children: [
          // Top Row - Location, Search, Notifications
          Row(
            children: [
              Expanded(
                child: EnhancedLocationSelectorWidget(
                  selectedLocation: _selectedLocation,
                  locations: _defaultLocations,
                  isLoading: _isLoadingLocation,
                  useGpsLocation: _useGpsLocation,
                  onLocationChanged: _onLocationChanged,
                ),
              ),
              SizedBox(width: 3.w),
              
              // Search Toggle Button
              GestureDetector(
                onTap: _toggleSearch,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(2.5.w),
                  decoration: BoxDecoration(
                    color: _showSearch 
                        ? AppTheme.lightTheme.colorScheme.primary
                        : AppTheme.lightTheme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _showSearch ? Icons.close : Icons.search,
                    color: _showSearch 
                        ? Colors.white
                        : AppTheme.lightTheme.colorScheme.primary,
                    size: 24,
                  ),
                ),
              ),
              
              SizedBox(width: 2.w),
              
              // Notifications Button
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pushNamed(context, AppRoutes.notificationsScreen);
                },
                child: Container(
                  padding: EdgeInsets.all(2.5.w),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        color: AppTheme.lightTheme.colorScheme.primary,
                        size: 24,
                      ),
                      // Notification badge
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppTheme.lightTheme.colorScheme.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Search Bar (when active)
          if (_showSearch) ...[
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primaryContainer.withAlpha(77),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.primary.withAlpha(77),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 20,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: TextField(
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search in khilonjiya.com...',
                        border: InputBorder.none,
                        hintStyle: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      style: AppTheme.lightTheme.textTheme.bodyMedium,
                      autofocus: true,
                    ),
                  ),
                  if (_activeFilters.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_activeFilters.length}',
                        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          
          SizedBox(height: 2.h),
          
          // Enhanced Categories Section
          SizedBox(
            height: 12.h, // Increased height for prominent look
            child: _isLoadingCategories
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(right: 3.w),
                        child: EnhancedCategoryChipWidget(
                          category: _categories[index],
                          isSelected: _selectedCategory == _categories[index]['name'],
                          onTap: () => _onCategorySelected(_categories[index]['name']),
                        ),
                      );
                    },
                  ),
          ),
          
          // Distance Filter (when GPS is active)
          if (_useGpsLocation && _currentPosition != null) ...[
            SizedBox(height: 1.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.secondaryContainer.withAlpha(77),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 16,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Within ${_selectedDistance.toInt()} km',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _showAdvancedFilters,
                    child: Text(
                      'Change',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }


Widget _buildEnhancedBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow.withAlpha(26),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          selectedItemColor: AppTheme.lightTheme.colorScheme.primary,
          unselectedItemColor: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          selectedLabelStyle: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w400,
          ),
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });

            HapticFeedback.lightImpact();

            switch (index) {
              case 0:
                // Already on Home
                break;
              case 1:
                Navigator.pushNamed(context, AppRoutes.searchAndFilters);
                break;
              case 2:
                Navigator.pushNamed(context, AppRoutes.createListing);
                break;
              case 3:
                Navigator.pushNamed(context, AppRoutes.chatMessaging);
                break;
              case 4:
                Navigator.pushNamed(context, AppRoutes.userProfile);
                break;
            }
          },
          items: [
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(1.w),
                decoration: BoxDecoration(
                  color: _currentIndex == 0
                      ? AppTheme.lightTheme.colorScheme.primary.withAlpha(26)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _currentIndex == 0 ? Icons.home : Icons.home_outlined,
                  size: 24,
                ),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(1.w),
                decoration: BoxDecoration(
                  color: _currentIndex == 1
                      ? AppTheme.lightTheme.colorScheme.primary.withAlpha(26)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _currentIndex == 1 ? Icons.search : Icons.search_outlined,
                  size: 24,
                ),
              ),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(1.w),
                decoration: BoxDecoration(
                  color: _currentIndex == 2
                      ? AppTheme.lightTheme.colorScheme.primary.withAlpha(26)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _currentIndex == 2 ? Icons.add_circle : Icons.add_circle_outline,
                  size: 24,
                ),
              ),
              label: 'Sell',
            ),
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(1.w),
                decoration: BoxDecoration(
                  color: _currentIndex == 3
                      ? AppTheme.lightTheme.colorScheme.primary.withAlpha(26)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    Icon(
                      _currentIndex == 3 ? Icons.chat : Icons.chat_outlined,
                      size: 24,
                    ),
                    // Unread message badge
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(1.w),
                decoration: BoxDecoration(
                  color: _currentIndex == 4
                      ? AppTheme.lightTheme.colorScheme.primary.withAlpha(26)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _currentIndex == 4 ? Icons.person : Icons.person_outlined,
                  size: 24,
                ),
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 40,
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'No listings found',
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No results found for "$_searchQuery"'
                  : 'Try adjusting your location or category filters',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedCategory = 'All';
                      _searchQuery = '';
                      _activeFilters.clear();
                      _showSearch = false;
                    });
                    _loadListings();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset Filters'),
                ),
                SizedBox(width: 3.w),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.createListing);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Listing'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppTheme.lightTheme.colorScheme.primary,
          ),
          SizedBox(height: 2.h),
          Text(
            'Loading more listings...',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _listAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}