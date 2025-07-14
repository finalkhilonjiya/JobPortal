import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

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

enum ViewMode { grid, list, card }

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
  late AnimationController _floatingButtonController;
  late AnimationController _searchBarController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _listSlideAnimation;
  late Animation<double> _floatingButtonAnimation;
  late Animation<double> _searchBarAnimation;
  
  // Advanced Animation Controllers
  late AnimationController _refreshAnimationController;
  late Animation<double> _refreshRotationAnimation;
  
  // Scroll and Loading States
  late ScrollController _scrollController;
  double _scrollOffset = 0.0;
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isLoadingCategories = false;
  bool _isLoadingLocation = false;
  bool _showBackToTop = false;
  bool _showSearch = false;
  bool _hasMoreListings = true;
  String _searchQuery = '';
  Map<String, dynamic> _activeFilters = {};
  bool _useGpsLocation = false;
  Position? _currentPosition;
  double _selectedDistance = 5.0;
  
  // View Mode
  ViewMode _viewMode = ViewMode.list;
  
  // Navigation and Selection States
  int _currentIndex = 0;
  String _selectedCategory = 'All';
  String _selectedLocation = 'Detect Location';
  Set<String> _favoriteListings = {};
  
  // Data Collections
  List<Map<String, dynamic>> _listings = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _trendingListings = [];
  List<Map<String, dynamic>> _recentlyViewed = [];
  List<Map<String, dynamic>> _recommendedListings = [];
  
  // Services
  final CategoryService _categoryService = CategoryService();
  final ListingService _listingService = ListingService();
  final FavoriteService _favoriteService = FavoriteService();
  final AuthService _authService = AuthService();
  
  // Enhanced Categories with gradient colors
  final List<Map<String, dynamic>> _defaultCategories = [
    {
      'id': 'all', 
      'name': 'All', 
      'icon': 'apps', 
      'color': '0xFF6366F1',
      'gradientColors': ['0xFF6366F1', '0xFF8B5CF6']
    },
    {
      'id': 'electronics', 
      'name': 'Electronics', 
      'icon': 'devices', 
      'color': '0xFF3B82F6',
      'gradientColors': ['0xFF3B82F6', '0xFF1D4ED8']
    },
    {
      'id': 'fashion', 
      'name': 'Fashion', 
      'icon': 'checkroom', 
      'color': '0xFFEC4899',
      'gradientColors': ['0xFFEC4899', '0xFFDB2777']
    },
    {
      'id': 'jobs', 
      'name': 'Jobs', 
      'icon': 'work', 
      'color': '0xFF10B981',
      'gradientColors': ['0xFF10B981', '0xFF059669']
    },
    {
      'id': 'automotive', 
      'name': 'Vehicles', 
      'icon': 'directions_car', 
      'color': '0xFFF59E0B',
      'gradientColors': ['0xFFF59E0B', '0xFFD97706']
    },
    {
      'id': 'furniture', 
      'name': 'Furniture', 
      'icon': 'chair', 
      'color': '0xFF8B5CF6',
      'gradientColors': ['0xFF8B5CF6', '0xFF7C3AED']
    },
    {
      'id': 'books', 
      'name': 'Books', 
      'icon': 'menu_book', 
      'color': '0xFF06B6D4',
      'gradientColors': ['0xFF06B6D4', '0xFF0891B2']
    },
    {
      'id': 'sports', 
      'name': 'Sports', 
      'icon': 'sports_soccer', 
      'color': '0xFFF97316',
      'gradientColors': ['0xFFF97316', '0xFFEA580C']
    },
    {
      'id': 'food', 
      'name': 'Food', 
      'icon': 'restaurant', 
      'color': '0xFFEF4444',
      'gradientColors': ['0xFFEF4444', '0xFFDC2626']
    },
    {
      'id': 'services', 
      'name': 'Services', 
      'icon': 'handyman', 
      'color': '0xFF84CC16',
      'gradientColors': ['0xFF84CC16', '0xFF65A30D']
    },
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
    // Header Animation
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _floatingButtonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _searchBarController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _refreshAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
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
    
    _floatingButtonAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _floatingButtonController,
      curve: Curves.elasticOut,
    ));
    
    _searchBarAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _searchBarController,
      curve: Curves.easeInOutCubic,
    ));
    
    _refreshRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _refreshAnimationController,
      curve: Curves.linear,
    ));
    
    // Start animations
    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _listAnimationController.forward();
        _floatingButtonController.forward();
      }
    });
  }

  void _setupScrollController() {
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
        _showBackToTop = _scrollController.offset > 500;
      });
      
      // Load more when reaching the end
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreListings();
      }
    });
  }

  Future<void> _requestLocationPermission() async {
    try {
      setState(() => _isLoadingLocation = true);

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
          _selectedLocation = 'Guwahati, Assam';
        });
      }
    } catch (e) {
      debugPrint('❌ Location permission error: $e');
      setState(() {
        _useGpsLocation = false;
        _selectedLocation = 'Guwahati, Assam';
      });
    } finally {
      setState(() => _isLoadingLocation = false);
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
      _loadRecommendedListings(),
    ]);
  }

  Future<void> _loadCategories() async {
    try {
      setState(() => _isLoadingCategories = true);

      final categories = await _categoryService.getMainCategories();
      
      setState(() {
        _categories = _defaultCategories.map((defaultCat) {
          final serverCat = categories.firstWhere(
            (cat) => cat['name'].toString().toLowerCase() == 
                     defaultCat['name'].toString().toLowerCase(),
            orElse: () => <String, dynamic>{},
          );
          
          return {
            ...defaultCat,
            'id': serverCat?['id'] ?? defaultCat['id'],
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
      final trending = await _listingService.getTrendingListings(limit: 8);
      setState(() {
        _trendingListings = trending.map((listing) => _formatListing(listing)).toList();
      });
    } catch (error) {
      debugPrint('❌ Failed to load trending listings: $error');
      setState(() => _trendingListings = []);
    }
  }

  Future<void> _loadRecommendedListings() async {
    try {
      // This would ideally use user preferences and history
      final recommended = await _listingService.getActiveListings(limit: 6);
      setState(() {
        _recommendedListings = recommended.map((listing) => _formatListing(listing)).toList();
      });
    } catch (error) {
      debugPrint('❌ Failed to load recommended listings: $error');
    }
  }

  Future<void> _loadListings() async {
    if (_isLoading) return;
    
    try {
      setState(() => _isLoading = true);

      List<Map<String, dynamic>> listings;
      
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
        final categoryId = _categories.firstWhere(
          (cat) => cat['name'] == _selectedCategory,
          orElse: () => {'id': null},
        )['id'];
        
        if (categoryId != null && categoryId != 'all') {
          listings = await _listingService.getListingsByCategory(categoryId, limit: 20);
        } else {
          listings = await _listingService.getActiveListings(limit: 20);
        }
      }

      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        listings = listings.where((listing) {
          final title = listing['title'].toString().toLowerCase();
          final description = listing['description']?.toString().toLowerCase() ?? '';
          final query = _searchQuery.toLowerCase();
          return title.contains(query) || description.contains(query);
        }).toList();
      }

      // Apply advanced filters
      listings = _applyAdvancedFilters(listings);

      setState(() {
        _listings = listings.map((listing) => _formatListing(listing)).toList();
        _hasMoreListings = listings.length >= 20;
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

  List<Map<String, dynamic>> _applyAdvancedFilters(List<Map<String, dynamic>> listings) {
    if (_activeFilters.isEmpty) return listings;
    
    return listings.where((listing) {
      // Price filter
      if (_activeFilters['minPrice'] != null || _activeFilters['maxPrice'] != null) {
        final price = double.tryParse(listing['price'].toString()) ?? 0;
        final minPrice = _activeFilters['minPrice'] ?? 0;
        final maxPrice = _activeFilters['maxPrice'] ?? double.infinity;
        if (price < minPrice || price > maxPrice) return false;
      }
      
      // Condition filter
      if (_activeFilters['condition'] != null && 
          listing['condition'] != _activeFilters['condition']) {
        return false;
      }
      
      // Sort by filter (applied after filtering)
      
      return true;
    }).toList();
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
      ) / 1000;
    }

    return {
      'id': listing['id'],
      'title': listing['title'],
      'price': '₹${listing['price']}',
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
      'rating': listing['rating'] ?? 4.5,
      'isVerified': listing['is_verified'] ?? false,
    };
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
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

  Future<void> _refreshListings() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    _refreshAnimationController.repeat();

    HapticFeedback.lightImpact();
    
    await Future.wait([
      _loadCategories(),
      _loadTrendingListings(),
      _loadListings(),
      _loadFavorites(),
      _loadRecommendedListings(),
    ]);

    _refreshAnimationController.stop();
    _refreshAnimationController.reset();
    setState(() => _isRefreshing = false);
  }

  Future<void> _loadMoreListings() async {
    if (_isLoading || !_hasMoreListings) return;

    setState(() => _isLoading = true);

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
        _hasMoreListings = moreListings.length >= 10;
        _isLoading = false;
      });
    } catch (error) {
      setState(() => _isLoading = false);
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

      setState(() {
        if (_favoriteListings.contains(listingId.toString())) {
          _favoriteListings.remove(listingId.toString());
        } else {
          _favoriteListings.add(listingId.toString());
        }
      });

      // Update the listing's favorite status
      _updateListingFavoriteStatus(listingId);

      // Make API call
      if (_favoriteListings.contains(listingId.toString())) {
        await _favoriteService.addFavorite(listingId);
        _showAnimatedSnackBar('Added to favorites', Icons.favorite, isSuccess: true);
      } else {
        await _favoriteService.removeFavorite(listingId);
        _showAnimatedSnackBar('Removed from favorites', Icons.favorite_border);
      }
    } catch (error) {
      // Revert on error
      setState(() {
        if (_favoriteListings.contains(listingId.toString())) {
          _favoriteListings.remove(listingId.toString());
        } else {
          _favoriteListings.add(listingId.toString());
        }
      });
      _updateListingFavoriteStatus(listingId);
      
      debugPrint('❌ Failed to toggle favorite: $error');
      _showAnimatedSnackBar('Failed to update favorite', Icons.error, isError: true);
    }
  }

  void _updateListingFavoriteStatus(String listingId) {
    setState(() {
      final updateListing = (List<Map<String, dynamic>> list) {
        final index = list.indexWhere((listing) => listing['id'] == listingId);
        if (index != -1) {
          list[index]['isFavorite'] = _favoriteListings.contains(listingId.toString());
        }
      };
      
      updateListing(_listings);
      updateListing(_trendingListings);
      updateListing(_recommendedListings);
    });
  }

  void _onCategorySelected(String category) {
    if (_selectedCategory == category) return;
    
    setState(() => _selectedCategory = category);
    
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
    setState(() => _selectedDistance = distance);
    
    if (_useGpsLocation) {
      _loadListings();
    }
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    
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
        _searchBarController.reverse();
        _loadListings();
      } else {
        _searchBarController.forward();
      }
    });
    
    HapticFeedback.lightImpact();
  }

  void _toggleViewMode() {
    HapticFeedback.lightImpact();
    setState(() {
      switch (_viewMode) {
        case ViewMode.list:
          _viewMode = ViewMode.grid;
          break;
        case ViewMode.grid:
          _viewMode = ViewMode.card;
          break;
        case ViewMode.card:
          _viewMode = ViewMode.list;
          break;
      }
    });
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
    
    // Add to recently viewed
    setState(() {
      _recentlyViewed.removeWhere((item) => item['id'] == listing['id']);
      _recentlyViewed.insert(0, listing);
      if (_recentlyViewed.length > 10) {
        _recentlyViewed = _recentlyViewed.take(10).toList();
      }
    });
    
    Navigator.pushNamed(context, AppRoutes.listingDetail, arguments: listing);
  }

  void _scrollToTop() {
    HapticFeedback.lightImpact();
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  void _showAnimatedSnackBar(String message, IconData icon, {bool isSuccess = false, bool isError = false}) {
    if (!mounted) return;
    
    Color backgroundColor;
    if (isSuccess) {
      backgroundColor = Colors.green.shade600;
    } else if (isError) {
      backgroundColor = Colors.red.shade600;
    } else {
      backgroundColor = AppTheme.lightTheme.colorScheme.primary;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            SizedBox(width: 2.w),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(4.w),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
        animation: CurvedAnimation(
          parent: ModalRoute.of(context)!.animation!,
          curve: Curves.elasticOut,
        ),
      ),
    );
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
        "rating": 4.8,
        "isVerified": true,
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
        "rating": 4.5,
        "isVerified": false,
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
        "rating": 5.0,
        "isVerified": true,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Stack(
          children: [
            // Background gradient
            Container(
              height: 30.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 26),
                    AppTheme.lightTheme.colorScheme.secondary.withValues(alpha: 26),
                  ],
                ),
              ),
            ),
            
            RefreshIndicator(
              onRefresh: _refreshListings,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Enhanced App Bar
                  SliverAppBar(
                    expandedHeight: _showSearch ? 22.h : 18.h,
                    floating: true,
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      background: _buildEnhancedHeader(),
                    ),
                  ),
                  
                  // Categories Section
                  SliverToBoxAdapter(
                    child: _buildCategoriesSection(),
                  ),
                  
                  // Trending Section
                  if (_trendingListings.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildTrendingSection(),
                    ),
                  
                  // Recommended For You Section
                  if (_recommendedListings.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildRecommendedSection(),
                    ),
                  
                  // Listings Header
                  SliverToBoxAdapter(
                    child: _buildListingsHeader(),
                  ),
                  
                  // Listings Grid/List
                  _buildListingsSection(),
                  
                  // Bottom padding
                  SliverToBoxAdapter(
                    child: SizedBox(height: 12.h),
                  ),
                ],
              ),
            ),
            
            // Back to Top Button
            if (_showBackToTop)
              Positioned(
                right: 4.w,
                bottom: 12.h,
                child: AnimatedScale(
                  scale: _showBackToTop ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: FloatingActionButton.small(
                    heroTag: "backToTop",
                    onPressed: _scrollToTop,
                    backgroundColor: Colors.white,
                    elevation: 8,
                    child: Icon(
                      Icons.keyboard_arrow_up,
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _buildModernBottomNav(),
      floatingActionButton: AnimatedBuilder(
        animation: _floatingButtonAnimation,
        builder: (context, child) => Transform.scale(
          scale: _floatingButtonAnimation.value,
          child: FloatingActionButton.extended(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, AppRoutes.createListing);
            },
            backgroundColor: AppTheme.lightTheme.colorScheme.primary,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Sell',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildEnhancedHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
      child: Column(
        children: [
          // Logo and Actions Row
          Row(
            children: [
              // Logo
              Text(
                'khilonjiya',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              
              // View Mode Toggle
              _buildAnimatedIconButton(
                icon: _viewMode == ViewMode.list 
                    ? Icons.view_list 
                    : _viewMode == ViewMode.grid 
                    ? Icons.grid_view 
                    : Icons.view_agenda,
                onTap: _toggleViewMode,
              ),
              
              SizedBox(width: 2.w),
              
              // Search Toggle
              _buildAnimatedIconButton(
                icon: _showSearch ? Icons.close : Icons.search,
                onTap: _toggleSearch,
                isActive: _showSearch,
              ),
              
              SizedBox(width: 2.w),
              
              // Notifications
              _buildNotificationButton(),
            ],
          ),
          
          SizedBox(height: 2.h),
          
          // Location Selector
          _buildLocationSelector(),
          
          // Animated Search Bar
          if (_showSearch)
            AnimatedBuilder(
              animation: _searchBarAnimation,
              builder: (context, child) => Transform.scale(
                scaleY: _searchBarAnimation.value,
                alignment: Alignment.topCenter,
                child: Opacity(
                  opacity: _searchBarAnimation.value,
                  child: Container(
                    margin: EdgeInsets.only(top: 2.h),
                    child: _buildSearchBar(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnimatedIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(2.5.w),
        decoration: BoxDecoration(
          color: isActive 
              ? AppTheme.lightTheme.colorScheme.primary
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 26),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isActive 
              ? Colors.white
              : AppTheme.lightTheme.colorScheme.primary,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildNotificationButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // Navigate to notifications
      },
      child: Container(
        padding: EdgeInsets.all(2.5.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 26),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Icon(
              Icons.notifications_outlined,
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 20,
            ),
            // Notification badge with animation
            Positioned(
              right: 0,
              top: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 102),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 20,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              _selectedLocation,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
            ),
          ),
          if (_isLoadingLocation)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
            )
          else
            Icon(
              Icons.keyboard_arrow_down,
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
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
                hintText: 'Search products, services, jobs...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 1.5.h),
              ),
              style: TextStyle(fontSize: 14.sp),
              autofocus: true,
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                setState(() => _searchQuery = '');
                _loadListings();
              },
              child: Icon(
                Icons.clear,
                color: Colors.grey,
                size: 20,
              ),
            ),
          SizedBox(width: 2.w),
          GestureDetector(
            onTap: _showAdvancedFilters,
            child: Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tune,
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 16,
                  ),
                  if (_activeFilters.isNotEmpty) ...[
                    SizedBox(width: 1.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.2.h),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_activeFilters.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to all categories
                  },
                  child: Text(
                    'See All',
                    style: TextStyle(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 14.h,
            child: _isLoadingCategories
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category['name'];
                      
                      return Padding(
                        padding: EdgeInsets.only(right: 3.w),
                        child: _buildModernCategoryChip(category, isSelected),
                      );
                    },
                  ),
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildModernCategoryChip(Map<String, dynamic> category, bool isSelected) {
    final gradientColors = category['gradientColors'] as List<String>;
    
    return GestureDetector(
      onTap: () => _onCategorySelected(category['name']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 25.w,
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: gradientColors.map((c) => Color(int.parse(c))).toList(),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? Colors.transparent 
                : Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(int.parse(gradientColors.first)).withValues(alpha: 102),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(2.5.w),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.white.withValues(alpha: 51)
                    : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                IconData(
                  _getIconCode(category['icon']),
                  fontFamily: 'MaterialIcons',
                ),
                color: isSelected 
                    ? Colors.white 
                    : Color(int.parse(category['color'])),
                size: 24,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              category['name'],
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 11.sp,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (category['count'] != null && category['count'] > 0)
              Text(
                '${category['count']}',
                style: TextStyle(
                  color: isSelected 
                      ? Colors.white.withValues(alpha: 204)
                      : Colors.grey,
                  fontSize: 9.sp,
                ),
              ),
          ],
        ),
      ),
    );
  }

  int _getIconCode(String iconName) {
    const iconMap = {
      'apps': 0xe01b,
      'devices': 0xe1b1,
      'checkroom': 0xf19e,
      'work': 0xe8f9,
      'directions_car': 0xe1d7,
      'chair': 0xf1f3,
      'menu_book': 0xe86e,
      'sports_soccer': 0xea27,
      'restaurant': 0xe56c,
      'handyman': 0xf10b,
    };
    return iconMap[iconName] ?? 0xe01b;
  }

  Widget _buildTrendingSection() {
    return Container(
      margin: EdgeInsets.only(top: 2.h),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(1.5.w),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.trending_up,
                    color: Colors.orange,
                    size: 16,
                  ),
                ),
                SizedBox(width: 2.w),
                Text(
                  'Trending Now',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 28.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              itemCount: _trendingListings.length,
              itemBuilder: (context, index) {
                final listing = _trendingListings[index];
                return _buildTrendingCard(listing);
              },
            ),
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildTrendingCard(Map<String, dynamic> listing) {
    return GestureDetector(
      onTap: () => _onListingTap(listing),
      child: Container(
        width: 50.w,
        margin: EdgeInsets.only(right: 3.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 13),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with gradient overlay
            Stack(
              children: [
                Container(
                  height: 18.h,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    image: DecorationImage(
                      image: NetworkImage(listing['imageUrl']),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 2.w,
                  right: 2.w,
                  child: GestureDetector(
                    onTap: () => _toggleFavorite(listing['id'].toString()),
                    child: Container(
                      padding: EdgeInsets.all(1.5.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 51),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        listing['isFavorite'] ? Icons.favorite : Icons.favorite_border,
                        color: listing['isFavorite'] ? Colors.red : Colors.grey,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                if (listing['isSponsored'])
                  Positioned(
                    top: 2.w,
                    left: 2.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.orange, Colors.deepOrange],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'FEATURED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing['title'],
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12.sp,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                      SizedBox(width: 1.w),
                      Expanded(
                        child: Text(
                          listing['location'],
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 10.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        listing['price'],
                        style: TextStyle(
                          color: AppTheme.lightTheme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                      if (listing['rating'] != null)
                        Row(
                          children: [
                            Icon(Icons.star, size: 12, color: Colors.orange),
                            SizedBox(width: 0.5.w),
                            Text(
                              listing['rating'].toString(),
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedSection() {
    return Container(
      margin: EdgeInsets.only(top: 2.h),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(1.5.w),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: Colors.purple,
                    size: 16,
                  ),
                ),
                SizedBox(width: 2.w),
                Text(
                  'Recommended For You',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 15.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              itemCount: _recommendedListings.length,
              itemBuilder: (context, index) {
                final listing = _recommendedListings[index];
                return _buildRecommendedCard(listing);
              },
            ),
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildRecommendedCard(Map<String, dynamic> listing) {
    return GestureDetector(
      onTap: () => _onListingTap(listing),
      child: Container(
        width: 70.w,
        margin: EdgeInsets.only(right: 3.w),
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purple.shade50,
              Colors.purple.shade100,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.purple.shade200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(listing['imageUrl']),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    listing['title'],
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12.sp,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    listing['price'],
                    style: TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                      SizedBox(width: 1.w),
                      Expanded(
                        child: Text(
                          listing['location'],
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 10.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingsHeader() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'All Listings',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              if (_activeFilters.isNotEmpty)
                Container(
                  margin: EdgeInsets.only(right: 2.w),
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_alt,
                        size: 14,
                        color: AppTheme.lightTheme.colorScheme.primary,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        '${_activeFilters.length} Active',
                        style: TextStyle(
                          color: AppTheme.lightTheme.colorScheme.primary,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                '${_listings.length} Results',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListingsSection() {
    if (_listings.isEmpty && !_isLoading) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyState(),
      );
    }

    switch (_viewMode) {
      case ViewMode.grid:
        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 3.w,
              mainAxisSpacing: 3.w,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= _listings.length) {
                  return _isLoading ? _buildLoadingCard() : null;
                }
                return _buildGridListingCard(_listings[index]);
              },
              childCount: _listings.length + (_isLoading ? 2 : 0),
            ),
          ),
        );
      
      case ViewMode.card:
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index >= _listings.length) {
                return _isLoading ? _buildLoadingIndicator() : null;
              }
              return _buildEnhancedListingCard(_listings[index]);
            },
            childCount: _listings.length + (_isLoading ? 1 : 0),
          ),
        );
      
      case ViewMode.list:
      default:
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index >= _listings.length) {
                return _isLoading ? _buildLoadingIndicator() : null;
              }
              return _buildModernListingCard(_listings[index]);
            },
            childCount: _listings.length + (_isLoading ? 1 : 0),
          ),
        );
    }
  }

  Widget _buildGridListingCard(Map<String, dynamic> listing) {
    return GestureDetector(
      onTap: () => _onListingTap(listing),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 13),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 20.h,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    image: DecorationImage(
                      image: NetworkImage(listing['imageUrl']),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 2.w,
                  right: 2.w,
                  child: GestureDetector(
                    onTap: () => _toggleFavorite(listing['id'].toString()),
                    child: Container(
                      padding: EdgeInsets.all(1.5.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        listing['isFavorite'] ? Icons.favorite : Icons.favorite_border,
                        color: listing['isFavorite'] ? Colors.red : Colors.grey,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing['title'],
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11.sp,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    listing['price'],
                    style: TextStyle(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                      SizedBox(width: 1.w),
                      Expanded(
                        child: Text(
                          listing['location'],
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 9.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernListingCard(Map<String, dynamic> listing) {
    return GestureDetector(
      onTap: () => _onListingTap(listing),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 13),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 30.w,
                  height: 30.w,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                    image: DecorationImage(
                      image: NetworkImage(listing['imageUrl']),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (listing['isVerified'])
                  Positioned(
                    bottom: 1.w,
                    left: 1.w,
                    child: Container(
                      padding: EdgeInsets.all(1.w),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            listing['title'],
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.sp,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _toggleFavorite(listing['id'].toString()),
                          child: Icon(
                            listing['isFavorite'] ? Icons.favorite : Icons.favorite_border,
                            color: listing['isFavorite'] ? Colors.red : Colors.grey,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      listing['price'],
                      style: TextStyle(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                        SizedBox(width: 1.w),
                        Expanded(
                          child: Text(
                            listing['location'],
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 11.sp,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_useGpsLocation && listing['distance'] != null)
                          Text(
                            '${listing['distance'].toStringAsFixed(1)} km',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 11.sp,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          listing['timePosted'],
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 10.sp,
                          ),
                        ),
                        if (listing['views_count'] != null)
                          Row(
                            children: [
                              Icon(Icons.remove_red_eye_outlined, size: 12, color: Colors.grey),
                              SizedBox(width: 0.5.w),
                              Text(
                                '${listing['views_count']}',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10.sp,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedListingCard(Map<String, dynamic> listing) {
    return GestureDetector(
      onTap: () => _onListingTap(listing),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 13),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 25.h,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    image: DecorationImage(
                      image: NetworkImage(listing['imageUrl']),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 3.w,
                  left: 3.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 153),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      listing['category'],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 3.w,
                  right: 3.w,
                  child: GestureDetector(
                    onTap: () => _toggleFavorite(listing['id'].toString()),
                    child: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 51),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        listing['isFavorite'] ? Icons.favorite : Icons.favorite_border,
                        color: listing['isFavorite'] ? Colors.red : Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing['title'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        listing['price'],
                        style: TextStyle(
                          color: AppTheme.lightTheme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
                        ),
                      ),
                      if (listing['condition'] != null)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                          decoration: BoxDecoration(
                            color: _getConditionColor(listing['condition']).withValues(alpha: 51),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            listing['condition'].toString().toUpperCase(),
                            style: TextStyle(
                              color: _getConditionColor(listing['condition']),
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                      SizedBox(width: 1.w),
                      Expanded(
                        child: Text(
                          listing['location'],
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                      if (_useGpsLocation && listing['distance'] != null)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.near_me, size: 12, color: Colors.blue),
                              SizedBox(width: 0.5.w),
                              Text(
                                '${listing['distance'].toStringAsFixed(1)} km',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey),
                          SizedBox(width: 1.w),
                          Text(
                            listing['timePosted'],
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (listing['views_count'] != null) ...[
                            Icon(Icons.remove_red_eye_outlined, size: 14, color: Colors.grey),
                            SizedBox(width: 0.5.w),
                            Text(
                              '${listing['views_count']} views',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 11.sp,
                              ),
                            ),
                          ],
                          if (listing['rating'] != null) ...[
                            SizedBox(width: 3.w),
                            Icon(Icons.star, size: 14, color: Colors.orange),
                            SizedBox(width: 0.5.w),
                            Text(
                              listing['rating'].toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 11.sp,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'new':
        return Colors.green;
      case 'excellent':
        return Colors.blue;
      case 'good':
        return Colors.orange;
      case 'fair':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Widget _buildModernBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 13),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: BottomAppBar(
          color: Colors.transparent,
          elevation: 0,
          notchMargin: 8.0,
          shape: const CircularNotchedRectangle(),
          child: Container(
            height: 8.h,
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(0, Icons.home, 'Home'),
                _buildNavItem(1, Icons.search, 'Search'),
                const SizedBox(width: 56), // Space for FAB
                _buildNavItem(3, Icons.chat_bubble_outline, 'Messages', hasNotification: true),
                _buildNavItem(4, Icons.person_outline, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, {bool hasNotification = false}) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _currentIndex = index);
        
        switch (index) {
          case 1:
            Navigator.pushNamed(context, AppRoutes.searchAndFilters);
            break;
          case 3:
            Navigator.pushNamed(context, AppRoutes.chatMessaging);
            break;
          case 4:
            Navigator.pushNamed(context, AppRoutes.userProfile);
            break;
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 26)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  Icon(
                    isSelected ? icon : icon,
                    color: isSelected 
                        ? AppTheme.lightTheme.colorScheme.primary 
                        : Colors.grey,
                    size: 24,
                  ),
                  if (hasNotification)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              label,
              style: TextStyle(
                color: isSelected 
                    ? AppTheme.lightTheme.colorScheme.primary 
                    : Colors.grey,
                fontSize: 10.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.lightTheme.colorScheme.primaryContainer,
                    AppTheme.lightTheme.colorScheme.secondaryContainer,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 60,
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'No listings found',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No results found for "$_searchQuery"'
                  : 'Try adjusting your filters or search in a different category',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
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
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.createListing);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Listing'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
      child: Center(
        child: CircularProgressIndicator(
          color: AppTheme.lightTheme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            height: 20.h,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 2.h,
                  width: double.infinity,
                  color: Colors.grey.shade300,
                ),
                SizedBox(height: 1.h),
                Container(
                  height: 2.h,
                  width: 20.w,
                  color: Colors.grey.shade300,
                ),
              ],
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
    _floatingButtonController.dispose();
    _searchBarController.dispose();
    _refreshAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
