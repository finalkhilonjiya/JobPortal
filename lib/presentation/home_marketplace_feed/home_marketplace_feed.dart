// File: screens/marketplace/home_marketplace_feed.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import './widgets/top_bar_widget.dart';
import './widgets/search_bar_full_width.dart';
import './widgets/app_info_banner_new.dart';
import './widgets/three_option_section.dart';
import './widgets/premium_carousel.dart';
import './widgets/categories_with_filter.dart';
import './widgets/square_product_card.dart';
import './widgets/listing_details_fullscreen.dart';
import './widgets/shimmer_widgets.dart';
import './widgets/marketplace_helpers.dart';
import './widgets/advanced_filter_sheet.dart';
import './widgets/create_listing_page.dart';
import './widgets/profile_page.dart';
import './widgets/bottom_nav_bar_widget.dart';
import 'dart:async';

class HomeMarketplaceFeed extends StatefulWidget {
  const HomeMarketplaceFeed({Key? key}) : super(key: key);

  @override
  State<HomeMarketplaceFeed> createState() => _HomeMarketplaceFeedState();
}

class _HomeMarketplaceFeedState extends State<HomeMarketplaceFeed> {
  int _currentIndex = 0;
  bool _isLoadingPremium = true;
  bool _isLoadingFeed = true;
  List<Map<String, Object>> _categories = [];
  List<Map<String, dynamic>> _listings = [];
  List<Map<String, dynamic>> _premiumListings = [];
  String _selectedCategory = 'All';
  Set<String> _favoriteIds = {};
  String _currentLocation = 'Guwahati, Assam';
  final ScrollController _scrollController = ScrollController();
  
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
    if (!_isLoadingFeed) {
      setState(() => _isLoadingFeed = true);
      await Future.delayed(Duration(seconds: 1));
      setState(() {
        _listings.addAll(MarketplaceHelpers.getMockListings());
        _isLoadingFeed = false;
      });
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoadingPremium = true;
      _isLoadingFeed = true;
    });
    
    await Future.delayed(Duration(milliseconds: 800));
    
    setState(() {
      _categories = MarketplaceHelpers.getMainCategoriesOnly();
      _listings = MarketplaceHelpers.getMockListings();
      _premiumListings = _listings.where((l) => l['is_featured'] == true).toList();
      _isLoadingPremium = false;
      _isLoadingFeed = false;
    });
  }

  void _onCategorySelected(String name) {
    setState(() {
      _selectedCategory = name;
      _selectedSubcategory = 'All';
    });
  }

  void _toggleFavorite(String id) {
    setState(() {
      if (_favoriteIds.contains(id)) {
        _favoriteIds.remove(id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed from favorites'), duration: Duration(seconds: 1)),
        );
      } else {
        _favoriteIds.add(id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added to favorites'), duration: Duration(seconds: 1)),
        );
      }
    });
  }

  List<Map<String, dynamic>> get _filteredListings {
    var filtered = _listings;
    
    if (_selectedCategory != 'All') {
      filtered = filtered.where((l) => l['category'] == _selectedCategory).toList();
    }
    
    // Apply sorting
    if (_sortBy == 'Price (Low to High)') {
      filtered.sort((a, b) => a['price'].compareTo(b['price']));
    } else if (_sortBy == 'Price (High to Low)') {
      filtered.sort((a, b) => b['price'].compareTo(a['price']));
    }
    
    return filtered;
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
    );
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
                    // Open search functionality
                  },
                ),
              ),
              
              // New App Info Banner
              SliverToBoxAdapter(child: AppInfoBannerNew()),
              
              // Three Option Section
              SliverToBoxAdapter(child: ThreeOptionSection()),
              
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
              
              // Categories with Filter
              SliverToBoxAdapter(
                child: CategoriesWithFilter(
                  categories: _categories,
                  selected: _selectedCategory,
                  onSelect: _onCategorySelected,
                  onFilterTap: _openAdvancedFilter,
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
          if (index == 4) _navigateToProfile();
        },
        onFabPressed: _openCreateListing,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateListing,
        backgroundColor: Color(0xFF2563EB),
        child: Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}