import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/listing_service.dart';
import 'square_product_card.dart';
import 'listing_details_fullscreen.dart';
import 'marketplace_helpers.dart';

class AllPremiumListingsPage extends StatefulWidget {
  final Set<String> favoriteIds;
  final Function(String) onFavoriteToggle;
  final Function(String) onCall;
  final Function(String) onWhatsApp;

  const AllPremiumListingsPage({
    Key? key,
    required this.favoriteIds,
    required this.onFavoriteToggle,
    required this.onCall,
    required this.onWhatsApp,
  }) : super(key: key);

  @override
  State<AllPremiumListingsPage> createState() => _AllPremiumListingsPageState();
}

class _AllPremiumListingsPageState extends State<AllPremiumListingsPage> {
  final ListingService _listingService = ListingService();
  List<Map<String, dynamic>> _premiumListings = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchAllPremiumListings();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllPremiumListings() async {
    setState(() => _isLoading = true);
    
    try {
      final listings = await _listingService.fetchPremiumListings(
        limit: 100, // Fetch more premium listings
      );
      
      setState(() {
        _premiumListings = listings;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching premium listings: $e');
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading premium listings'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showListingDetails(Map<String, dynamic> listing) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListingDetailsFullscreen(
          listing: listing,
          isFavorite: widget.favoriteIds.contains(listing['id']),
          onFavoriteToggle: () => widget.onFavoriteToggle(listing['id']),
          onCall: () => widget.onCall(listing['phone'] ?? ''),
          onWhatsApp: () => widget.onWhatsApp(listing['phone'] ?? ''),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF0EA5E9)],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Colors.white, size: 10.sp),
                  SizedBox(width: 0.5.w),
                  Text(
                    'PREMIUM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 2.w),
            Text(
              'All Premium Listings',
              style: TextStyle(
                color: Colors.black,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2563EB),
              ),
            )
          : _premiumListings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.star_border,
                        size: 20.w,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'No premium listings available',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchAllPremiumListings,
                  color: Color(0xFF2563EB),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.only(top: 1.h, bottom: 2.h),
                    itemCount: _premiumListings.length,
                    itemBuilder: (context, index) {
                      final listing = _premiumListings[index];
                      final isFavorite = widget.favoriteIds.contains(listing['id']);
                      
                      return Stack(
                        children: [
                          // The regular square product card
                          SquareProductCard(
                            data: listing,
                            isFavorite: isFavorite,
                            onFavoriteToggle: () => widget.onFavoriteToggle(listing['id']),
                            onTap: () => _showListingDetails(listing),
                            onCall: () => widget.onCall(listing['phone'] ?? ''),
                            onWhatsApp: () => widget.onWhatsApp(listing['phone'] ?? ''),
                          ),
                          // Premium Badge Overlay
                          Positioned(
                            top: 1.5.h,
                            left: 5.w,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF2563EB), Color(0xFF0EA5E9)],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star, color: Colors.white, size: 9.sp),
                                  SizedBox(width: 0.5.w),
                                  Text(
                                    'PREMIUM',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8.sp,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
    );
  }
}