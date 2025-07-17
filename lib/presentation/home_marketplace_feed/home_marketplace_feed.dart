// File: screens/marketplace/home_marketplace_feed.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import './widgets/bottom_nav_bar_widget.dart';
import './widgets/app_info_banner.dart';
import './widgets/three_option_section.dart';
import './widgets/search_bar_widget.dart';
import './widgets/premium_section.dart';
import './widgets/categories_section.dart';
import './widgets/product_card.dart';
import './widgets/search_bottom_sheet.dart';
import './widgets/listing_details_fullscreen.dart';
import './widgets/shimmer_widgets.dart';
import './widgets/marketplace_helpers.dart';
import './widgets/notification_strip.dart';
import './widgets/create_listing_page.dart';
import './widgets/profile_page.dart';
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
  String _selectedCategory = 'All';
  Set<String> _favoriteIds = {};
  bool _hasNotifications = true;
  String _currentLocation = 'Guwahati, Assam';
  final ScrollController _scrollController = ScrollController();

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
    // Simulate location detection
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _currentLocation = 'Guwahati, Assam';
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
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
      _isLoadingPremium = false;
      _isLoadingFeed = false;
    });
  }

  void _onCategorySelected(String name) {
    setState(() {
      _selectedCategory = name;
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
    if (_selectedCategory == 'All') return _listings;
    return _listings.where((l) => l['category'] == _selectedCategory).toList();
  }

  List<Map<String, dynamic>> get _featuredListings {
    return _listings.where((l) => l['is_featured'] == true).toList();
  }

  void _openSearchPage() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SearchBottomSheet(
        currentLocation: _currentLocation,
        onSearch: (query, location) {
          Navigator.pop(context);
          // Handle search
        },
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

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(),
      ),
    );
  }

  Future<void> _refreshData() async {
    await _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: Color(0xFF2563EB),
          child: CustomScrollView(
            controller: _scrollController,
            physics: AlwaysScrollableScrollPhysics(),
            slivers: [
              // Search Bar with Location
              SliverToBoxAdapter(
                child: SearchBarWidget(
                  onTap: _openSearchPage,
                  currentLocation: _currentLocation,
                ),
              ),
              
              // Notification Strip
              if (_hasNotifications)
                SliverToBoxAdapter(
                  child: NotificationStrip(
                    message: "🎉 Get 20% off on premium listings today!",
                    onClose: () => setState(() => _hasNotifications = false),
                  ),
                ),
              
              // App Info Banner
              SliverToBoxAdapter(child: AppInfoBanner()),
              
              // Three Option Section
              SliverToBoxAdapter(child: ThreeOptionSection()),
              
              // Premium Section
              if (_featuredListings.isNotEmpty)
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
                              listings: _featuredListings,
                              onTap: _showListingDetails,
                              favoriteIds: _favoriteIds,
                              onFavoriteToggle: _toggleFavorite,
                            ),
                    ],
                  ),
                ),
              
              // Categories - Main only
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                      child: Text(
                        'Categories',
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
                    CategoriesSection(
                      categories: _categories,
                      selected: _selectedCategory,
                      onSelect: _onCategorySelected,
                    ),
                  ],
                ),
              ),
              
              // Listings Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedCategory == 'All' ? 'All Listings' : '$_selectedCategory',
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_filteredListings.length} items',
                        style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Product Feed
              _isLoadingFeed && _filteredListings.isEmpty
                  ? SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, __) => ShimmerProductCard(),
                        childCount: 5,
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, index) {
                          if (index == _filteredListings.length) {
                            return _isLoadingFeed
                                ? Padding(
                                    padding: EdgeInsets.all(2.h),
                                    child: Center(child: CircularProgressIndicator()),
                                  )
                                : SizedBox.shrink();
                          }
                          return ProductCard(
                            data: _filteredListings[index],
                            isFavorite: _favoriteIds.contains(_filteredListings[index]['id']),
                            onFavoriteToggle: () => _toggleFavorite(_filteredListings[index]['id']),
                            onTap: () => _showListingDetails(_filteredListings[index]),
                            onCall: () => MarketplaceHelpers.makePhoneCall(
                              context, 
                              _filteredListings[index]['phone']
                            ),
                            onWhatsApp: () => MarketplaceHelpers.openWhatsApp(
                              context, 
                              _filteredListings[index]['phone']
                            ),
                          );
                        },
                        childCount: _filteredListings.length + (_isLoadingFeed ? 1 : 0),
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
          switch (index) {
            case 1:
              _openSearchPage();
              break;
            case 3:
              // Packages - handled in profile
              _navigateToProfile();
              break;
            case 4:
              _navigateToProfile();
              break;
          }
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