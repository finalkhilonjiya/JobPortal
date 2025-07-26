// File: screens/marketplace/home_marketplace_feed.dart
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
import '../jobs/jobs_home_page.dart';
import '../traditional_market/traditional_market_home_page.dart';
import 'dart:async';
import './premium_package_page.dart';
import 'widgets/categories_section.dart';
import 'widgets/category_data.dart';

class HomeMarketplaceFeed extends StatefulWidget {
  const HomeMarketplaceFeed({Key? key}) : super(key: key);

  @override
  State<HomeMarketplaceFeed> createState() => _HomeMarketplaceFeedState();
}

class _HomeMarketplaceFeedState extends State<HomeMarketplaceFeed> {
  final ListingService _listingService = ListingService();
  
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
    _scrollController.addListener(_onScroll);
    // Delay initial fetch to ensure auth is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
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
    if (!_isLoadingMore && !_isLoadingFeed && _hasMoreData) {
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
            // If no more data, repeat from beginning
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
      _listings = [];
      _hasInitialLoadError = false;
    });
    
    try {
      // Fetch categories - use hardcoded if API fails
      List<Map<String, dynamic>> categoriesData = [];
      try {
        categoriesData = await _listingService.getCategories();
      } catch (e) {
        print('Error fetching categories from API: $e');
        // Continue with empty categories, will use hardcoded
      }
      
      // Build category list with All option
      final List<Map<String, dynamic>> mainCategories = [
        {
          'name': 'All',
          'id': 'All',
          'icon': Icons.apps,
          'image': null,
        },
      ];
      
      // Add fetched categories or use hardcoded
      if (categoriesData.isNotEmpty) {
        mainCategories.addAll(
          categoriesData.where((cat) => cat['parent_category_id'] == null).map((cat) => {
            'name': cat['name'],
            'id': cat['id'],
            'icon': _getCategoryIcon(cat['name']),
            'image': cat['icon_url'],
          }).toList()
        );
      } else {
        // Use hardcoded categories if API failed
                mainCategories.addAll(
          CategoryData.mainCategories.map((cat) => {
            'name': cat['name'],
            'id': cat['name'],
            'icon': cat['icon'],
            'image': cat['image'] ?? '',
          }).toList()
        );

      }
      
      // Fetch favorites - don't fail if user not logged in
      Set<String> favorites = {};
      try {
        favorites = await _listingService.getUserFavorites();
      } catch (e) {
        print('Error fetching favorites: $e');
        // Continue without favorites
      }
      
      // Fetch listings
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
      
      // Fetch premium listings
      List<Map<String, dynamic>> premiumListings = [];
      try {
        premiumListings = await _listingService.fetchPremiumListings(
          limit: 10,
        );
        print('Fetched ${premiumListings.length} premium listings');
      } catch (e) {
        print('Error fetching premium listings: $e');
      }
      
      setState(() {
        _categories = mainCategories;
        _favoriteIds = favorites;
        _listings = listings;
        _premiumListings = premiumListings;
        _isLoadingPremium = false;
        _isLoadingFeed = false;
        
        // Only show error if both listings and premium failed
        if (listings.isEmpty && premiumListings.isEmpty && categoriesData.isEmpty) {
          _hasInitialLoadError = true;
        }
      });
    } catch (e) {
      print('Unexpected error in _fetchData: $e');
      setState(() {
        // Use hardcoded categories on error
        _categories = [
          {
            'name': 'All',
            'id': 'All',
            'icon': Icons.apps,
            'image': null,
          },
          ...CategoryData.mainCategories.map((cat) => {
            'name': cat['name'],
            'id': cat['name'],
            'icon': cat['icon'],
            'image': cat['image'],
          }).toList()
        ];
        _listings = [];
        _premiumListings = [];
        _isLoadingPremium = false;
        _isLoadingFeed = false;
        _hasInitialLoadError = true;
      });
    }
  }

  IconData _getCategoryIcon(String categoryName) {
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
    setState(() {
      _isLoadingFeed = true;
      _listings = [];
      _currentOffset = 0;
    });
    
    try {
      final listings = await _listingService.fetchListings(
        categoryId: _selectedCategoryId == 'All' ? null : _selectedCategoryId,
        sortBy: _sortBy,
        offset: 0,
        limit: _pageSize,
      );
      
      // Also fetch filtered premium listings
      List<Map<String, dynamic>> premiumListings = [];
      try {
        premiumListings = await _listingService.fetchPremiumListings(
          categoryId: _selectedCategoryId == 'All' ? null : _selectedCategoryId,
          limit: 10,
        );
      } catch (e) {
        print('Error fetching filtered premium listings: $e');
        // Keep existing premium listings if fetch fails
        premiumListings = _premiumListings;
      }
      
      setState(() {
        _listings = listings;
        _premiumListings = premiumListings;
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfilePage()),
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
              // Top Bar
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
              
              // Three Options
              SliverToBoxAdapter(
                child: ThreeOptionSection(
                  onJobsTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JobsHomePage(),
                      ),
                    );
                  },
                  onTraditionalTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TraditionalMarketHomePage(),
                      ),
                    );
                  },
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
                      _isLoadingPremium
                          ? ShimmerPremiumSection()
                          : PremiumSection(
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
              
              // Categories
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