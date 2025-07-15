import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
import './widgets/featured_banner_widget.dart';
import './widgets/category_grid_widget.dart';
import './widgets/product_list_widget.dart';
import '../../widgets/bottom_nav_bar_widget.dart';

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
      'id': 'electronics',
      'name': 'Electronics',
      'icon': 'devices',
      'color': '0xFF3B82F6',
      'gradientColors': ['0xFF3B82F6', '0xFF1D4ED8']
    },
    {
      'id': 'properties',
      'name': 'Properties',
      'icon': 'home',
      'color': '0xFF6366F1',
      'gradientColors': ['0xFF6366F1', '0xFF8B5CF6']
    },
    {
      'id': 'room_rent',
      'name': 'Room for Rent',
      'icon': 'meeting_room',
      'color': '0xFF10B981',
      'gradientColors': ['0xFF10B981', '0xFF059669']
    },
    {
      'id': 'room_pg',
      'name': 'Room for PG',
      'icon': 'hotel',
      'color': '0xFFF59E0B',
      'gradientColors': ['0xFFF59E0B', '0xFFD97706']
    },
    {
      'id': 'homestay',
      'name': 'Homestay',
      'icon': 'holiday_village',
      'color': '0xFF8B5CF6',
      'gradientColors': ['0xFF8B5CF6', '0xFF7C3AED']
    },
    {
      'id': 'furniture',
      'name': 'Furniture',
      'icon': 'chair',
      'color': '0xFF06B6D4',
      'gradientColors': ['0xFF06B6D4', '0xFF0891B2']
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

  String _activeMainSection = 'marketplace';

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
        duration: const Duration(milliseconds: 1500),
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // TODO: App info banner (static or carousel)
            SizedBox(height: 16),
            // TODO: Three-option section (Apply for job, List jobs, Assamese marketplace button)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          key: const Key('btn_apply_job'),
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryLight,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Apply for Job'),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          key: const Key('btn_list_jobs'),
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryLight,
                            side: const BorderSide(color: AppTheme.primaryLight),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('List Jobs'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        key: const Key('btn_assamese_marketplace'),
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successLight,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        child: const Text('Assamese Traditional Marketplace', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Main Menu (Main Sections)
            _buildMainSections(),
            // Categories Grid
            Expanded(child: CategoryGridWidget()),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBarWidget(
        currentIndex: _currentIndex,
        onTabSelected: (index) {
          setState(() => _currentIndex = index);
          // TODO: Handle navigation
        },
        onFabPressed: () {
          // TODO: Navigate to create listing
        },
        hasMessageNotification: false, // TODO: wire up real notification state
      ),
    );
  }

  Widget _buildMainSections() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildMainSectionButton(
            icon: Icons.work_outline,
            label: 'Jobs',
            color: Colors.blue.shade100,
            onTap: () => _onMainSectionTap('jobs'),
          ),
          _buildMainSectionButton(
            icon: Icons.storefront_outlined,
            label: 'Marketplace',
            color: Colors.green.shade100,
            onTap: () => _onMainSectionTap('marketplace'),
          ),
          _buildMainSectionButton(
            icon: Icons.emoji_emotions_outlined,
            label: 'Tradition',
            color: Colors.orange.shade100,
            onTap: () => _onMainSectionTap('tradition'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainSectionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: EdgeInsets.symmetric(horizontal: 1.w),
          padding: EdgeInsets.symmetric(vertical: 2.2.h),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.18),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: AppTheme.lightTheme.colorScheme.primary),
              SizedBox(height: 1.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  void _onMainSectionTap(String section) {
    HapticFeedback.lightImpact();
    setState(() {
      _activeMainSection = section;
      // Optionally, you can also reset filters or search here
    });
    _loadListings();
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
