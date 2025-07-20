// File: screens/marketplace/home_marketplace_feed.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import './widgets/top_bar_widget.dart';
import './widgets/search_bar_full_width.dart';
import './widgets/app_info_banner_new.dart';
import './widgets/three_option_section.dart';
import './widgets/premium_carousel.dart';
import './widgets/square_product_card.dart';
import './widgets/listing_details_fullscreen.dart';
import './widgets/shimmer_widgets.dart';
import './widgets/marketplace_helpers.dart';
import './widgets/advanced_filter_sheet.dart';
import './widgets/create_listing_page.dart';
import './widgets/profile_page.dart';
import './widgets/bottom_nav_bar_widget.dart';
import './search_page.dart'; // Add this import
import '../../services/listing_service.dart'; // Add this import
import '../jobs/jobs_home_page.dart'; // Add this import
import '../traditional_market/traditional_market_home_page.dart'; // Add this import
import 'dart:async';
import './premium_package_page.dart';
// Add the following import for CategoriesSection
import 'widgets/categories_section.dart';
import 'widgets/category_data.dart';

class HomeMarketplaceFeed extends StatefulWidget {
  const HomeMarketplaceFeed({Key? key}) : super(key: key);

  @override
  State<HomeMarketplaceFeed> createState() => _HomeMarketplaceFeedState();
}

class _HomeMarketplaceFeedState extends State<HomeMarketplaceFeed> {
  final ListingService _listingService = ListingService(); // Add this
  
  int _currentIndex = 0;
  bool _isLoadingPremium = true;
  bool _isLoadingFeed = true;
  bool _isLoadingMore = false; // Add this
  List<Map<String, Object>> _categories = [];
  List<Map<String, dynamic>> _listings = [];
  List<Map<String, dynamic>> _premiumListings = [];
  String _selectedCategory = 'All';
  String _selectedCategoryId = 'All'; // Add this
  Set<String> _favoriteIds = {};
  String _currentLocation = 'Guwahati, Assam';
  final ScrollController _scrollController = ScrollController();
  
  // Pagination
  int _currentOffset = 0;
  final int _pageSize = 20;

  // Add this field for pagination state
  bool _hasMoreData = true;
  
  // Filter states
  String _priceRange = 'All';
  String _selectedSubcategory = 'All';
  String _sortBy = 'Newest';
  double _maxDistance = 50.0;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _scrollController.addListener(_onScroll);
    _detectLocation();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _detectLocation() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _currentLocation = 'Guwahati, Assam';
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreListings();
    }
  }

  Future<void> _loadMoreListings() async {
    if (!_isLoadingMore && !_isLoadingFeed) {
      setState(() => _isLoadingMore = true);
      
      try {
        final newListings = await _listingService.fetchListings(
          categoryId: _selectedCategoryId == 'All' ? null : _selectedCategoryId,
          sortBy: _sortBy,
          offset: _currentOffset + _pageSize,
          limit: _pageSize,
        );
        
        setState(() {
          if (newListings.isEmpty) {
            // If no more data, repeat from beginning (infinite scroll)
            _currentOffset = 0;
            _fetchListingsOnly();
          } else {
            _listings.addAll(newListings);
            _currentOffset += _pageSize;
          }
          _isLoadingMore = false;
        });
      } catch (e) {
        print('Error loading more listings: $e');
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<void> _fetchListingsOnly() async {
    try {
      final listings = await _listingService.fetchListings(
        categoryId: _selectedCategoryId == 'All' ? null : _selectedCategoryId,
        sortBy: _sortBy,
        offset: 0,
        limit: _pageSize,
      );
      
      if (listings.isNotEmpty) {
        setState(() {
          _listings.addAll(listings);
        });
      }
    } catch (e) {
      print('Error fetching listings: $e');
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoadingPremium = true;
      _isLoadingFeed = true;
      _currentOffset = 0;
      _listings = []; // Clear existing listings
    });
    
    try {
      // Fetch categories from Supabase
      List<Map<String, dynamic>> categoriesData = [];
      try {
        categoriesData = await _listingService.getCategories();
      } catch (e) {
        print('Error fetching categories: $e');
      }
      
      final mainCategories = CategoryData.mainCategories.map((cat) => {
  'name': cat['name'] as Object,
  'id': cat['name'] as Object,  // Using name as ID for now
  'icon': cat['icon'] as Object,
  'image': cat['image'] as Object,  // Include the image!
}).toList();
      
      // Fetch favorites if user is logged in
      Set<String> favorites = {};
      try {
        favorites = await _listingService.getUserFavorites();
      } catch (e) {
        print('Error fetching favorites: $e');
      }
      
      // Fetch listings from Supabase
      List<Map<String, dynamic>> listings = [];
      try {
        listings = await _listingService.fetchListings(
          sortBy: _sortBy,
          offset: 0,
          limit: _pageSize,
        );
      } catch (e) {
        print('Error fetching listings: $e');
      }
      
      // Use mock data for premium listings for now
      final premiumListings = MarketplaceHelpers.getMockListings()
          .where((l) => l['is_featured'] == true)
          .toList();
      
      setState(() {
        _categories = mainCategories;
        _favoriteIds = favorites;
        _listings = listings.isNotEmpty ? listings : MarketplaceHelpers.getMockListings();
        _premiumListings = premiumListings;
        _isLoadingPremium = false;
        _isLoadingFeed = false;
      });
    } catch (e) {
      print('Error in _fetchData: $e');
      // Fallback to all mock data on error
      setState(() {
        _categories = MarketplaceHelpers.getMainCategoriesOnly();
        _listings = MarketplaceHelpers.getMockListings();
        _premiumListings = _listings.where((l) => l['is_featured'] == true).toList();
        _isLoadingPremium = false;
        _isLoadingFeed = false;
      });
    }
  }

  IconData _getCategoryIcon(String categoryName) {
    // Map category names to icons
    switch (categoryName) {
      case 'Electronics':
        return Icons.devices_other_rounded;
      case 'Vehicles':
        return Icons.directions_car_filled_rounded;
      case 'Furniture':
        return Icons.chair_rounded;
      case 'Properties for Sale':
        return Icons.home_rounded;
      case 'Room for Rent':
        return Icons.meeting_room_rounded;
      case 'PG Accommodation':
        return Icons.apartment_rounded;
      case 'Homestays':
        return Icons.cottage_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  void _onCategorySelected(String name) {
    // Find the category ID
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
    
    // Refetch listings with new category
    _fetchFilteredListings();
  }

  Future<void> _fetchFilteredListings() async {
    setState(() {
      _isLoadingFeed = true;
      _listings = []; // Clear existing listings
      _currentOffset = 0;
    });
    
    try {
      final listings = await _listingService.fetchListings(
        categoryId: _selectedCategoryId == 'All' ? null : _selectedCategoryId,
        sortBy: _sortBy,
        offset: 0,
        limit: _pageSize,
      );
      
      setState(() {
        _listings = listings.isNotEmpty ? listings : [];
        _currentOffset = 0;
        _isLoadingFeed = false;
      });
    } catch (e) {
      print('Error fetching filtered listings: $e');
      setState(() {
        _listings = [];
        _isLoadingFeed = false;
      });
    }
  }

  void _toggleFavorite(String id) async {
    try {
      final isFavorited = await _listingService.toggleFavorite(id);
      
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please login to add favorites'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredListings {
    // Listings are already filtered from the API
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
          _fetchFilteredListings(); // Refetch with new filters
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateListingPage(),
        fullscreenDialog: true,
      ),
    ).then((_) {
      // Refresh listings after creating a new one
      _fetchData();
    });
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfilePage()),
    );
  }

  Widget _buildListingWithPremium(int index) {
    // Insert premium carousel after every 12 items
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
                PremiumCarousel(
                  listings: _premiumListings,
                  onTap: _showListingDetails,
                  favoriteIds: _favoriteIds,
                  onFavoriteToggle: _toggleFavorite,
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchData,
          color: Color(0xFF2563EB),
          child: CustomScrollView(
            controller: _scrollController,
            physics: AlwaysScrollableScrollPhysics(),
            slivers: [
              // Top Bar with Logo and Location
              SliverToBoxAdapter(
                child: TopBarWidget(
                  currentLocation: _currentLocation,
                  onLocationTap: _detectLocation,
                ),
              ),
              
              // Full Width Search Bar
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
              
              // New App Info Banner
              SliverToBoxAdapter(child: AppInfoBannerNew()),
              
              // Three Option Section
              SliverToBoxAdapter(
                child: ThreeOptionSection(
                  onJobsTap: () {
                    // Navigate to Jobs Homepage
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JobsHomePage(), // You'll create this
                      ),
                    );
                  },
                  onTraditionalTap: () {
                    // Navigate to Traditional Market Homepage
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TraditionalMarketHomePage(), // You'll create this
                      ),
                    );
                  },
                ),
              ),
              
              // Premium Section at top
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
                      _isLoadingPremium
                          ? ShimmerPremiumSection()
                          : PremiumCarousel(
                              listings: _premiumListings,
                              onTap: _showListingDetails,
                              favoriteIds: _favoriteIds,
                              onFavoriteToggle: _toggleFavorite,
                            ),
                    ],
                  ),
                ),
              
              // Categories
              SliverToBoxAdapter(
                child: CategoriesSection(
                  categories: _categories,
                  selected: _selectedCategory,
                  onSelect: _onCategorySelected,
                ),
              ),
              
              // Filter Bar - Below Categories, Above Feed
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'All Listings',
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
              
              // Product Feed with Premium insertions
              _isLoadingFeed && _filteredListings.isEmpty
                  ? SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, __) => ShimmerProductCard(),
                        childCount: 6,
                      ),
                    )
                  : SliverList(
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
      // Search tab
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SearchPage()),
      );
    } else if (index == 2) {
      // Package tab - ADD THIS
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PremiumPackagePage()),
      );
    } else if (index == 4) {
      // Profile tab
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
          SizedBox(height: 0.5.h),
          Text(
            'Sell',
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2563EB),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
   }
}
