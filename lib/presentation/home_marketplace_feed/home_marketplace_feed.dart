import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../widgets/bottom_nav_bar_widget.dart';
import '../../widgets/marketplace/app_info_banner.dart';
import '../../widgets/marketplace/three_option_section.dart';
import '../../widgets/marketplace/search_bar_section.dart';
import '../../widgets/marketplace/premium_section.dart';
import '../../widgets/marketplace/categories_section.dart';
import '../../widgets/marketplace/product_card.dart';
import '../../widgets/marketplace/search_bottom_sheet.dart';
import '../../widgets/marketplace/listing_details_sheet.dart';
import '../../widgets/marketplace/shimmer_widgets.dart';
import '../../utils/marketplace_helpers.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoadingPremium = true;
      _isLoadingFeed = true;
    });
    
    await Future.delayed(Duration(seconds: 1));
    
    setState(() {
      _categories = MarketplaceHelpers.getMockCategories();
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
          SnackBar(content: Text('Removed from favorites')),
        );
      } else {
        _favoriteIds.add(id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added to favorites')),
        );
      }
    });
  }

  List<Map<String, dynamic>> get _filteredListings {
    if (_selectedCategory == 'All') return _listings;
    return _listings.where((l) => l['category'] == _selectedCategory).toList();
  }

  void _openSearchPage() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SearchBottomSheet(),
    );
  }

  void _showListingDetails(Map<String, dynamic> listing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ListingDetailsSheet(
        listing: listing,
        isFavorite: _favoriteIds.contains(listing['id']),
        onFavoriteToggle: () => _toggleFavorite(listing['id']),
        onCall: () => MarketplaceHelpers.makePhoneCall(context, listing['phone']),
        onWhatsApp: () => MarketplaceHelpers.openWhatsApp(context, listing['phone']),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: AppInfoBanner()),
            SliverToBoxAdapter(child: ThreeOptionSection()),
            SliverToBoxAdapter(child: SearchBarSection(onTap: _openSearchPage)),
            if (_listings.where((l) => l['is_featured'] == true).isNotEmpty)
              SliverToBoxAdapter(
                child: _isLoadingPremium
                    ? ShimmerPremiumSection()
                    : PremiumSection(
                        listings: _listings.where((l) => l['is_featured'] == true).toList(),
                        onTap: _showListingDetails,
                        favoriteIds: _favoriteIds,
                        onFavoriteToggle: _toggleFavorite,
                      ),
              ),
            SliverToBoxAdapter(child: CategoriesSection(
              categories: _categories,
              selected: _selectedCategory,
              onSelect: _onCategorySelected,
            )),
            _isLoadingFeed
                ? SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, __) => ShimmerProductCard(),
                      childCount: 5,
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, index) => ProductCard(
                        data: _filteredListings[index],
                        isFavorite: _favoriteIds.contains(_filteredListings[index]['id']),
                        onFavoriteToggle: () => _toggleFavorite(_filteredListings[index]['id']),
                        onTap: () => _showListingDetails(_filteredListings[index]),
                        onCall: () => MarketplaceHelpers.makePhoneCall(context, _filteredListings[index]['phone']),
                        onWhatsApp: () => MarketplaceHelpers.openWhatsApp(context, _filteredListings[index]['phone']),
                      ),
                      childCount: _filteredListings.length,
                    ),
                  ),
            SliverPadding(padding: EdgeInsets.only(bottom: 10.h)),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBarWidget(
        currentIndex: _currentIndex,
        onTabSelected: (index) {
          setState(() => _currentIndex = index);
          switch (index) {
            case 1:
              _openSearchPage();
              break;
            case 3:
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Packages feature coming soon')),
              );
              break;
            case 4:
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Profile feature coming soon')),
              );
              break;
          }
        },
        onFabPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Create listing feature coming soon')),
          );
        },
        hasMessageNotification: false,
      ),
    );
  }
}