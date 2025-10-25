import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/listing_service.dart';
import './listing_details_fullscreen.dart';
import './marketplace_helpers.dart';

class MyListingsPage extends StatefulWidget {
  @override
  State<MyListingsPage> createState() => _MyListingsPageState();
}

class _MyListingsPageState extends State<MyListingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ListingService _listingService = ListingService();
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _activeListings = [];
  List<Map<String, dynamic>> _soldListings = [];
  List<Map<String, dynamic>> _expiredListings = [];
  Set<String> _favoriteIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserListings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserListings() async {
    setState(() => _isLoading = true);

    try {
      // Fetch user's listings
      final listings = await _listingService.getUserListings();
      
      // Fetch favorites
      final favorites = await _listingService.getUserFavorites();

      // Separate listings by status
      final active = <Map<String, dynamic>>[];
      final sold = <Map<String, dynamic>>[];
      final expired = <Map<String, dynamic>>[];

      for (var listing in listings) {
        final status = listing['status']?.toString().toLowerCase() ?? 'active';
        
        if (status == 'sold' || status == 'rented') {
          sold.add(listing);
        } else if (status == 'expired' || status == 'suspended') {
          expired.add(listing);
        } else {
          active.add(listing);
        }
      }

      setState(() {
        _activeListings = active;
        _soldListings = sold;
        _expiredListings = expired;
        _favoriteIds = favorites;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading user listings: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load listings'),
            backgroundColor: Colors.red,
          ),
        );
      }

      // If auth error, go back
      if (e.toString().contains('auth') || e.toString().contains('401')) {
        if (mounted) {
          Navigator.pop(context);
        }
      }
    }
  }

  Future<void> _deleteListing(String listingId) async {
    try {
      await _listingService.deleteListing(listingId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Listing deleted successfully')),
        );
        _loadUserListings(); // Reload listings
      }
    } catch (e) {
      debugPrint('Error deleting listing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete listing'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAsSold(String listingId) async {
    try {
      await _listingService.updateListingStatus(listingId, 'sold');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Listing marked as sold')),
        );
        _loadUserListings(); // Reload listings
      }
    } catch (e) {
      debugPrint('Error updating listing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update listing'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showListingDetails(Map<String, dynamic> listing) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListingDetailsFullscreen(
          listing: listing,
          isFavorite: _favoriteIds.contains(listing['id']),
          onFavoriteToggle: () {
            // Toggle favorite logic if needed
          },
          onCall: () => MarketplaceHelpers.makePhoneCall(context, listing['phone']),
          onWhatsApp: () => MarketplaceHelpers.openWhatsApp(context, listing['phone']),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Color(0xFF2563EB),
        title: Text('My Listings', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: [
            Tab(text: 'Active (${_activeListings.length})'),
            Tab(text: 'Sold (${_soldListings.length})'),
            Tab(text: 'Expired (${_expiredListings.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2563EB),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadUserListings,
              color: Color(0xFF2563EB),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildListingsList(_activeListings, 'active'),
                  _buildListingsList(_soldListings, 'sold'),
                  _buildListingsList(_expiredListings, 'expired'),
                ],
              ),
            ),
    );
  }

  Widget _buildListingsList(List<Map<String, dynamic>> listings, String status) {
    if (listings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 20.w,
              color: Colors.grey[400],
            ),
            SizedBox(height: 2.h),
            Text(
              'No ${status} listings',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Your ${status} listings will appear here',
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: listings.length,
      itemBuilder: (context, index) {
        final listing = listings[index];
        return _buildListingCard(listing, status);
      },
    );
  }

  Widget _buildListingCard(Map<String, dynamic> listing, String status) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () => _showListingDetails(listing),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  listing['image'] ?? 'https://via.placeholder.com/200',
                  width: 20.w,
                  height: 20.w,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 20.w,
                      height: 20.w,
                      color: Colors.grey[300],
                      child: Icon(Icons.image, color: Colors.grey[600]),
                    );
                  },
                ),
              ),
              SizedBox(width: 3.w),
              
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing['title'] ?? 'Untitled',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      '₹${listing['price'] ?? 0}',
                      style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      listing['location'] ?? 'Location not specified',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 1.h),
                    Row(
                      children: [
                        Icon(Icons.visibility, size: 4.w, color: Colors.grey),
                        SizedBox(width: 1.w),
                        Text(
                          '${listing['views'] ?? 0}',
                          style: TextStyle(fontSize: 10.sp, color: Colors.grey[700]),
                        ),
                        SizedBox(width: 4.w),
                        Icon(Icons.access_time, size: 4.w, color: Colors.grey),
                        SizedBox(width: 1.w),
                        Text(
                          _formatDate(listing['created_at']),
                          style: TextStyle(fontSize: 10.sp, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Actions menu
              PopupMenuButton(
                icon: Icon(Icons.more_vert, color: Colors.grey[700]),
                itemBuilder: (context) {
                  final items = <PopupMenuEntry<String>>[];
                  
                  items.add(PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(Icons.visibility, size: 4.w, color: Colors.grey[700]),
                        SizedBox(width: 2.w),
                        Text('View'),
                      ],
                    ),
                    value: 'view',
                  ));
                  
                  items.add(PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 4.w, color: Colors.grey[700]),
                        SizedBox(width: 2.w),
                        Text('Edit'),
                      ],
                    ),
                    value: 'edit',
                  ));
                  
                  if (status == 'active') {
                    items.add(PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 4.w, color: Colors.green),
                          SizedBox(width: 2.w),
                          Text('Mark as Sold'),
                        ],
                      ),
                      value: 'sold',
                    ));
                  }
                  
                  items.add(PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 4.w, color: Colors.red),
                        SizedBox(width: 2.w),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                    value: 'delete',
                  ));
                  
                  return items;
                },
                onSelected: (value) {
                  switch (value) {
                    case 'view':
                      _showListingDetails(listing);
                      break;
                    case 'edit':
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Edit feature coming soon')),
                      );
                      break;
                    case 'sold':
                      _showConfirmDialog(
                        'Mark as Sold',
                        'Are you sure you want to mark this listing as sold?',
                        () => _markAsSold(listing['id']),
                      );
                      break;
                    case 'delete':
                      _showConfirmDialog(
                        'Delete Listing',
                        'Are you sure you want to delete this listing? This action cannot be undone.',
                        () => _deleteListing(listing['id']),
                      );
                      break;
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConfirmDialog(String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: Text(
              title.contains('Delete') ? 'Delete' : 'Confirm',
              style: TextStyle(
                color: title.contains('Delete') ? Colors.red : Color(0xFF2563EB),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateString) {
    if (dateString == null) return 'Unknown';
    
    try {
      final date = DateTime.parse(dateString.toString());
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return '1 day ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '$weeks ${weeks == 1 ? "week" : "weeks"} ago';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '$months ${months == 1 ? "month" : "months"} ago';
      } else {
        final years = (difference.inDays / 365).floor();
        return '$years ${years == 1 ? "year" : "years"} ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}