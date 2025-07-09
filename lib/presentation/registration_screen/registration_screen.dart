import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../utils/auth_service.dart';
import '../../utils/supabase_service.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/category_chip_widget.dart';
import './widgets/listing_card_widget.dart';
import './widgets/location_selector_widget.dart';

// Service classes
class CategoryService {
  Future<List<Map<String, dynamic>>> getMainCategories() async {
    try {
      final client = SupabaseService().safeClient;
      if (client == null) return [];
      
      final response = await client
          .from('categories')
          .select('*')
          .eq('is_active', true)
          .is_('parent_category_id', null)
          .order('sort_order');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Failed to get main categories: $e');
      return [];
    }
  }
}

class ListingService {
  Future<List<Map<String, dynamic>>> getActiveListings({int limit = 20, int offset = 0}) async {
    try {
      final client = SupabaseService().safeClient;
      if (client == null) return [];
      
      final response = await client
          .from('listings')
          .select('''
            *,
            category:categories(name),
            seller:user_profiles(full_name, avatar_url)
          ''')
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Failed to get active listings: $e');
      return [];
    }
  }
  
  Future<List<Map<String, dynamic>>> getListingsByCategory(String categoryId, {int limit = 20}) async {
    try {
      final client = SupabaseService().safeClient;
      if (client == null) return [];
      
      final response = await client
          .from('listings')
          .select('''
            *,
            category:categories(name),
            seller:user_profiles(full_name, avatar_url)
          ''')
          .eq('status', 'active')
          .eq('category_id', categoryId)
          .order('created_at', ascending: false)
          .limit(limit);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Failed to get listings by category: $e');
      return [];
    }
  }
  
  Future<List<Map<String, dynamic>>> searchListings({
    required String query,
    String? categoryId,
    String? location,
    int limit = 20,
  }) async {
    try {
      final client = SupabaseService().safeClient;
      if (client == null) return [];

      var queryBuilder = client
          .from('listings')
          .select('''
            *,
            category:categories(name),
            seller:user_profiles(full_name, avatar_url)
          ''')
          .eq('status', 'active')
          .or('title.ilike.%$query%,description.ilike.%$query%');

      if (categoryId != null && categoryId != 'All') {
        queryBuilder = queryBuilder.eq('category_id', categoryId);
      }

      if (location != null && location.isNotEmpty) {
        queryBuilder = queryBuilder.ilike('location', '%$location%');
      }

      final response = await queryBuilder
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Failed to search listings: $e');
      return [];
    }
  }
}

class FavoriteService {
  Future<List<Map<String, dynamic>>> getUserFavorites() async {
    try {
      final client = SupabaseService().safeClient;
      if (client == null) return [];

      final userId = client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await client
          .from('favorites')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Failed to get user favorites: $e');
      return [];
    }
  }

  Future<void> addFavorite(String listingId) async {
    try {
      final client = SupabaseService().safeClient;
      if (client == null) return;

      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      await client.from('favorites').insert({
        'user_id': userId,
        'listing_id': listingId,
      });
    } catch (e) {
      debugPrint('❌ Failed to add favorite: $e');
      rethrow;
    }
  }

  Future<void> removeFavorite(String listingId) async {
    try {
      final client = SupabaseService().safeClient;
      if (client == null) return;

      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      await client
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('listing_id', listingId);
    } catch (e) {
      debugPrint('❌ Failed to remove favorite: $e');
      rethrow;
    }
  }
}

class HomeMarketplaceFeed extends StatefulWidget {
  const HomeMarketplaceFeed({Key? key}) : super(key: key);

  @override
  State<HomeMarketplaceFeed> createState() => _HomeMarketplaceFeedState();
}

class _HomeMarketplaceFeedState extends State<HomeMarketplaceFeed>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  
  // All required variables
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isLoadingCategories = false;
  bool _isLoadingLocation = false;
  bool _showSearch = false;
  bool _showBackToTop = false;
  bool _useGpsLocation = false;
  int _currentIndex = 0;
  String _selectedCategory = 'All';
  String _selectedLocation = 'New York, NY';
  String _searchQuery = '';
  Set<String> _favoriteListings = {};
  Set<String> _activeFilters = {};
  Position? _currentPosition;
  double _selectedDistance = 25.0;

  // Data lists
  List<Map<String, dynamic>> _listings = [];
  List<Map<String, dynamic>> _categories = [];

  // Animation controllers
  late AnimationController _headerAnimationController;
  late AnimationController _listAnimationController;

  // Services
  final CategoryService _categoryService = CategoryService();
  final ListingService _listingService = ListingService();
  final FavoriteService _favoriteService = FavoriteService();

  final List<String> _defaultLocations = [
    'New York, NY',
    'Los Angeles, CA',
    'Chicago, IL',
    'Houston, TX',
    'Phoenix, AZ',
    'Philadelphia, PA'
  ];


   @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    
    // Initialize animation controllers
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadCategories(),
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
        _categories = [
          {'id': 'all', 'name': 'All'},
          ...categories
              .map((cat) => {
                    'id': cat['id'],
                    'name': cat['name'],
                  })
              .toList(),
        ];
        _isLoadingCategories = false;
      });
    } catch (error) {
      setState(() {
        _isLoadingCategories = false;
        _categories = [
          {'id': 'all', 'name': 'All'},
          {'id': '1', 'name': 'Electronics'},
          {'id': '2', 'name': 'Furniture'},
          {'id': '3', 'name': 'Fashion'},
          {'id': '4', 'name': 'Sports'},
          {'id': '5', 'name': 'Automotive'},
          {'id': '6', 'name': 'Books'},
          {'id': '7', 'name': 'Home & Garden'},
        ];
      });
      debugPrint('❌ Failed to load categories: $error');
    }
  }

  Future<void> _loadListings() async {
    try {
      setState(() {
        _isLoading = true;
      });

      List<Map<String, dynamic>> listings;
      if (_selectedCategory == 'All') {
        listings = await _listingService.getActiveListings(limit: 20);
      } else {
        final categoryId = _categories.firstWhere(
            (cat) => cat['name'] == _selectedCategory,
            orElse: () => {'id': 'all'})['id'];
        if (categoryId != null && categoryId != 'all') {
          listings = await _listingService.getListingsByCategory(categoryId, limit: 20);
        } else {
          listings = await _listingService.getActiveListings(limit: 20);
        }
      }

      setState(() {
        _listings = listings.map((listing) {
          final images = listing['images'] as List<dynamic>?;
          final firstImage = images?.isNotEmpty == true
              ? images!.first as String
              : 'https://images.unsplash.com/photo-1560472355-536de3962603?w=400&h=300&fit=crop';

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
          };
        }).toList();
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

  Future<void> _loadFavorites() async {
    try {
      final authService = AuthService();
      if (authService.isAuthenticated()) {
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
        "price": "\$899",
        "location": "Manhattan, NY",
        "timePosted": "2 hours ago",
        "imageUrl": "https://images.unsplash.com/photo-1592750475338-74b7b21085ab?w=400&h=300&fit=crop",
        "category": "Electronics",
        "isSponsored": true,
        "isFavorite": false,
      },
      {
        "id": "2",
        "title": "MacBook Air M2 - Brand New Sealed",
        "price": "\$1199",
        "location": "Brooklyn, NY",
        "timePosted": "4 hours ago",
        "imageUrl": "https://images.unsplash.com/photo-1541807084-5c52b6b3adef?w=400&h=300&fit=crop",
        "category": "Electronics",
        "isSponsored": false,
        "isFavorite": false,
      },
      {
        "id": "3",
        "title": "Modern Dining Table Set",
        "price": "\$450",
        "location": "Queens, NY",
        "timePosted": "6 hours ago",
        "imageUrl": "https://images.unsplash.com/photo-1581539250439-c96689b516dd?w=400&h=300&fit=crop",
        "category": "Furniture",
        "isSponsored": false,
        "isFavorite": true,
      },
      {
        "id": "4",
        "title": "2020 Honda Civic - Low Mileage",
        "price": "\$18500",
        "location": "Bronx, NY",
        "timePosted": "1 day ago",
        "imageUrl": "https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=400&h=300&fit=crop",
        "category": "Automotive",
        "isSponsored": false,
        "isFavorite": false,
      },
    ];
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreListings();
    }
    
    // Show/hide back to top button
    setState(() {
      _showBackToTop = _scrollController.position.pixels > 500;
    });
  }

  Future<void> _refreshListings() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    await Future.wait([
      _loadCategories(),
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

      if (_selectedCategory == 'All') {
        moreListings = await _listingService.getActiveListings(limit: 10, offset: offset);
      } else {
        final categoryId = _categories.firstWhere(
            (cat) => cat['name'] == _selectedCategory,
            orElse: () => {'id': 'all'})['id'];
        if (categoryId != null && categoryId != 'all') {
          moreListings = await _listingService.getListingsByCategory(categoryId, limit: 10);
        } else {
          moreListings = await _listingService.getActiveListings(limit: 10, offset: offset);
        }
      }

      setState(() {
        _listings.addAll(moreListings.map((listing) {
          final images = listing['images'] as List<dynamic>?;
          final firstImage = images?.isNotEmpty == true
              ? images!.first as String
              : 'https://images.unsplash.com/photo-1560472355-536de3962603?w=400&h=300&fit=crop';

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
          };
        }));
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
      final authService = AuthService();
      if (!authService.isAuthenticated()) {
        Navigator.pushNamed(context, AppRoutes.loginScreen);
        return;
      }

      if (_favoriteListings.contains(listingId.toString())) {
        await _favoriteService.removeFavorite(listingId);
        setState(() {
          _favoriteListings.remove(listingId.toString());
        });
      } else {
        await _favoriteService.addFavorite(listingId);
        setState(() {
          _favoriteListings.add(listingId.toString());
        });
      }

      setState(() {
        final index = _listings.indexWhere((listing) => listing['id'] == listingId);
        if (index != -1) {
          _listings[index]['isFavorite'] = _favoriteListings.contains(listingId.toString());
        }
      });
    } catch (error) {
      debugPrint('❌ Failed to toggle favorite: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update favorite'),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
        ),
      );
    }
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadListings();
  }

  void _onLocationChanged(String location) {
    setState(() {
      _selectedLocation = location;
    });
    _loadListings();
  }

  void _onListingTap(Map<String, dynamic> listing) {
    Navigator.pushNamed(context, AppRoutes.listingDetail, arguments: listing);
  }

  void _onListingLongPress(Map<String, dynamic> listing) {
    HapticFeedback.mediumImpact();
    _showQuickActions(listing);
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    
    if (query.isEmpty) {
      _loadListings();
    } else {
      _searchListings(query);
    }
  }

  void _showAdvancedFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Advanced Filters',
                style: AppTheme.lightTheme.textTheme.headlineSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _searchListings(String query) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final results = await _listingService.searchListings(
        query: query,
        categoryId: _selectedCategory != 'All' ? _selectedCategory : null,
        location: _selectedLocation,
        limit: 20,
      );

      setState(() {
        _listings = results.map((listing) {
          final images = listing['images'] as List<dynamic>?;
          final firstImage = images?.isNotEmpty == true
              ? images!.first as String
              : 'https://images.unsplash.com/photo-1560472355-536de3962603?w=400&h=300&fit=crop';

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
          };
        }).toList();
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('❌ Failed to search listings: $error');
    }
  }

  void _showQuickActions(Map<String, dynamic> listing) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  ListTile(
                    leading: CustomIconWidget(
                      iconName: 'share',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 24,
                    ),
                    title: Text(
                      'Share',
                      style: AppTheme.lightTheme.textTheme.bodyLarge,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: CustomIconWidget(
                      iconName: 'report',
                      color: AppTheme.lightTheme.colorScheme.error,
                      size: 24,
                    ),
                    title: Text(
                      'Report',
                      style: AppTheme.lightTheme.textTheme.bodyLarge,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredListings {
    if (_selectedCategory == 'All') {
      return _listings;
    }
    return _listings.where((listing) => (listing['category'] as String) == _selectedCategory).toList();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildEnhancedHeader(),
            _buildCategoriesSection(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshListings,
                color: AppTheme.lightTheme.colorScheme.primary,
                child: _filteredListings.isEmpty && !_isLoading
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                        itemCount: _filteredListings.length + (_isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _filteredListings.length) {
                            return _buildLoadingIndicator();
                          }

                          final listing = _filteredListings[index];
                          final isFavorite = _favoriteListings.contains(listing['id'].toString());

                          return Padding(
                            padding: EdgeInsets.only(bottom: 2.h),
                            child: ListingCardWidget(
                              listing: listing,
                              isFavorite: isFavorite,
                              onTap: () => _onListingTap(listing),
                              onLongPress: () => _onListingLongPress(listing),
                              onFavoriteTap: () => _toggleFavorite(listing['id'].toString()),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
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
          Row(
            children: [
              Expanded(
                child: LocationSelectorWidget(
                  selectedLocation: _selectedLocation,
                  locations: _defaultLocations,
                  isLoading: _isLoadingLocation,
                  useGpsLocation: _useGpsLocation,
                  onLocationChanged: _onLocationChanged,
                ),
              ),
              SizedBox(width: 3.w),
              GestureDetector(
                onTap: _toggleSearch,
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: _showSearch 
                        ? AppTheme.lightTheme.colorScheme.primary.withOpacity(0.1)
                        : AppTheme.lightTheme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _showSearch ? Icons.close : Icons.search,
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 24,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              GestureDetector(
                onTap: () {
                  // Handle notifications
                },
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.notifications_outlined,
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          if (_showSearch) ...[
            SizedBox(height: 1.h),
            Container(
              height: 6.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.outline,
                  width: 1,
                ),
              ),
              child: TextField(
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search listings...',
                  prefixIcon: Icon(Icons.search, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Container(
      color: AppTheme.lightTheme.colorScheme.surface,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: SizedBox(
        height: 5.h,
        child: _isLoadingCategories
            ? Center(
                child: CircularProgressIndicator(
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
              )
            : ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(right: 2.w),
                    child: CategoryChipWidget(
                      category: _categories[index],
                      isSelected: _selectedCategory == _categories[index]['name'],
                      onTap: () => _onCategorySelected(_categories[index]['name']),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildEnhancedBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      selectedItemColor: AppTheme.lightTheme.colorScheme.primary,
      unselectedItemColor: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });

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
          icon: Icon(
            _currentIndex == 0 ? Icons.home : Icons.home_outlined,
            color: _currentIndex == 0
                ? AppTheme.lightTheme.colorScheme.primary
                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            _currentIndex == 1 ? Icons.search : Icons.search_outlined,
            color: _currentIndex == 1
                ? AppTheme.lightTheme.colorScheme.primary
                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            _currentIndex == 2 ? Icons.add_circle : Icons.add_circle_outline,
            color: _currentIndex == 2
                ? AppTheme.lightTheme.colorScheme.primary
                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          label: 'Sell',
        ),
        BottomNavigationBarItem(
          icon: Stack(
            children: [
              Icon(
                _currentIndex == 3 ? Icons.chat : Icons.chat_outlined,
                color: _currentIndex == 3
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            _currentIndex == 4 ? Icons.person : Icons.person_outlined,
            color: _currentIndex == 4
                ? AppTheme.lightTheme.colorScheme.primary
                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          label: 'Profile',
        ),
      ],
    );
  }


  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty
                  ? Icons.search_off
                  : Icons.inventory_2_outlined,
              size: 80,
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 3.h),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No results found for "$_searchQuery"'
                  : 'No listings found',
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search terms'
                  : 'Try adjusting your location or category filters',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = 'All';
                  _searchQuery = '';
                  _activeFilters.clear();
                  _showSearch = false;
                });
                _loadListings();
              },
              child: const Text('Reset Filters'),
            ),
            SizedBox(height: 2.h),
            OutlinedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.createListing);
              },
              child: const Text('Create Listing'),
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

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _listAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}