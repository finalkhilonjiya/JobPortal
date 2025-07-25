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
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:math' as math;

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
  List<Map<String, Object>> _categories = [];
  List<Map<String, dynamic>> _listings = [];
  List<Map<String, dynamic>> _premiumListings = [];
  String _selectedCategory = 'All';
  String _selectedCategoryId = 'All';
  Set<String> _favoriteIds = {};
  String _currentLocation = 'Detecting...';
  final ScrollController _scrollController = ScrollController();
  
  // Location variables
  double? _userLatitude;
  double? _userLongitude;
  bool _locationDetected = false;
  
  // Pagination
  int _currentOffset = 0;
  final int _pageSize = 20;
  bool _hasMoreData = true;
  
  // Filter states
  String _priceRange = 'All';
  String _selectedSubcategory = 'All';
  String _sortBy = 'Newest';
  double _maxDistance = 50.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _detectLocation();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _detectLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentLocation = 'Location denied';
            _locationDetected = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentLocation = 'Location disabled';
          _locationDetected = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _currentLocation = '${place.locality ?? place.subAdministrativeArea ?? 'Unknown'}, ${place.administrativeArea ?? ''}';
          _userLatitude = position.latitude;
          _userLongitude = position.longitude;
          _locationDetected = true;
        });
        
        _fetchData();
      }
    } catch (e) {
      setState(() {
        _currentLocation = 'Location unavailable';
        _locationDetected = false;
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
    if (!_isLoadingMore && !_isLoadingFeed && _locationDetected) {
      setState(() => _isLoadingMore = true);
      
      try {
        final newListings = await _listingService.searchListings(
          latitude: _userLatitude,
          longitude: _userLongitude,
          keywords: _selectedCategoryId == 'All' ? null : _selectedCategory,
          sortBy: 'distance',
          searchRadius: _maxDistance,
          offset: _currentOffset + _pageSize,
          limit: _pageSize,
        );
        
        setState(() {
          if (newListings.isEmpty) {
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
    if (!_locationDetected) return;
    
    try {
      final listings = await _listingService.searchListings(
        latitude: _userLatitude,
        longitude: _userLongitude,
        keywords: _selectedCategoryId == 'All' ? null : _selectedCategory,
        sortBy: 'distance',
        searchRadius: _maxDistance,
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
    if (!_locationDetected) return;
    
    setState(() {
      _isLoadingPremium = true;
      _isLoadingFeed = true;
      _currentOffset = 0;
      _listings = [];
    });
    
    try {
      List<Map<String, dynamic>> categoriesData = [];
      try {
        categoriesData = await _listingService.getCategories();
      } catch (e) {
        print('Error fetching categories: $e');
      }
      
      final mainCategories = [
        {
          'name': 'All' as Object,
          'id': 'All' as Object,
          'icon': Icons.apps as Object,
          'image': null as Object,
        },
        ...categoriesData.where((cat) => cat['parent_category_id'] == null).map((cat) => {
          'name': cat['name'] as Object,
          'id': cat['id'] as Object,
          'icon': _getCategoryIcon(cat['name']) as Object,
          'image': cat['icon_url'] as Object,
        }).toList(),
      ];
      
      Set<String> favorites = {};
      try {
        favorites = await _listingService.getUserFavorites();
      } catch (e) {
        print('Error fetching favorites: $e');
      }
      
      List<Map<String, dynamic>> listings = [];
      if (_locationDetected && _userLatitude != null && _userLongitude != null) {
        try {
          listings = await _listingService.searchListings(
            latitude: _userLatitude,
            longitude: _userLongitude,
            keywords: null,
            sortBy: 'distance',
            searchRadius: _maxDistance,
            offset: 0,
            limit: _pageSize,
          );
        } catch (e) {
          print('Error fetching listings by distance: $e');
        }
      }
      
      List<Map<String, dynamic>> premiumListings = [];
      if (_locationDetected && _userLatitude != null && _userLongitude != null) {
        try {
          premiumListings = await _listingService.fetchPremiumListings(
            categoryId: _selectedCategoryId == 'All' ? null : _selectedCategoryId,
            limit: 50,
          );
          
          if (premiumListings.isNotEmpty) {
            for (var listing in premiumListings) {
              if (listing['latitude'] != null && listing['longitude'] != null) {
                double distance = _calculateDistance(
                  _userLatitude!,
                  _userLongitude!,
                  listing['latitude'],
                  listing['longitude'],
                );
                listing['distance'] = distance;
              }
            }
            premiumListings.sort((a, b) => 
              (a['distance'] ?? double.infinity).compareTo(b['distance'] ?? double.infinity)
            );
            premiumListings = premiumListings.take(10).toList();
          }
        } catch (e) {
          print('Error fetching premium listings: $e');
        }
      }
      
      setState(() {
        _categories = mainCategories;
        _favoriteIds = favorites;
        _listings = listings;
        _premiumListings = premiumListings;
        _isLoadingPremium = false;
        _isLoadingFeed = false;
      });
    } catch (e) {
      print('Error in _fetchData: $e');
      setState(() {
        _categories = CategoryData.mainCategories.map((cat) => {
          'name': cat['name'] as Object,
          'id': cat['name'] as Object,
          'icon': cat['icon'] as Object,
          'image': cat['image'] as Object,
        }).toList();
        _listings = [];
        _premiumListings = [];
        _isLoadingPremium = false;
        _isLoadingFeed = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data. Please check your connection.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371;
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    
    double a = 
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
      math.sin(dLon / 2) * math.sin(dLon / 2);
    
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * math.pi / 180;
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
    if (!_locationDetected) return;
    
    setState(() {
      _isLoadingFeed = true;
      _listings = [];
      _currentOffset = 0;
    });
    
    try {
      final listings = await _listingService.searchListings(
        latitude: _userLatitude,
        longitude: _userLongitude,
        keywords: _selectedCategoryId == 'All' ? null : _selectedCategory,
        sortBy: 'distance',
        searchRadius: _maxDistance,
        offset: 0,
        limit: _pageSize,
      );
      
      List<Map<String, dynamic>> premiumListings = [];
      try {
        premiumListings = await _listingService.fetchPremiumListings(
          categoryId: _selectedCategoryId == 'All' ? null : _selectedCategoryId,
          limit: 50,
        );
        
        if (premiumListings.isNotEmpty && _userLatitude != null && _userLongitude != null) {
          for (var listing in premiumListings) {
            if (listing['latitude'] != null && listing['longitude'] != null) {
              double distance = _calculateDistance(
                _userLatitude!,
                _userLongitude!,
                listing['latitude'],
                listing['longitude'],
              );
              listing['distance'] = distance;
            }
          }
          premiumListings.sort((a, b) => 
            (a['distance'] ?? double.infinity).compareTo(b['distance'] ?? double.infinity)
          );
          premiumListings = premiumListings.take(10).toList();
        }
      } catch (e) {
        print('Error fetching filtered premium listings: $e');
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
        _premiumListings = [];
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
        child: !_locationDetected 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: 20.w, color: Colors.grey),
                  SizedBox(height: 2.h),
                  Text(
                    'Location Required',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Please enable location to see nearby listings',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 3.h),
                  ElevatedButton(
                    onPressed: _detectLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2563EB),
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
                    ),
                    child: Text(
                      'Enable Location',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchData,
              color: Color(0xFF2563EB),
              child: CustomScrollView(
                controller: _scrollController,
                physics: AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: TopBarWidget(
                      currentLocation: _currentLocation,
                      onLocationTap: _detectLocation,
                    ),
                  ),
                  
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
                  
                  SliverToBoxAdapter(child: AppInfoBannerNew()),
                  
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
                  
                  SliverToBoxAdapter(
                    child: CategoriesSection(
                      categories: _categories,
                      selected: _selectedCategory,
                      onSelect: _onCategorySelected,
                    ),
                  ),
                  
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