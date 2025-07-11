import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/image_gallery_widget.dart';
import './widgets/item_details_widget.dart';
import './widgets/location_info_widget.dart';
import './widgets/related_items_widget.dart';
import './widgets/safety_tips_widget.dart';
import './widgets/seller_profile_widget.dart';

class ListingDetail extends StatefulWidget {
  const ListingDetail({Key? key}) : super(key: key);

  @override
  State<ListingDetail> createState() => _ListingDetailState();
}

class _ListingDetailState extends State<ListingDetail> {
  bool isFavorite = false;
  bool isLoading = false;

  // Mock listing data
  final Map<String, dynamic> listingData = {
    "id": 1,
    "title": "iPhone 14 Pro Max - 256GB Space Black",
    "price": "\$899",
    "originalPrice": "\$1099",
    "condition": "Like New",
    "category": "Electronics",
    "description":
        """Selling my iPhone 14 Pro Max in excellent condition. Used for only 6 months with screen protector and case from day one. No scratches, dents, or damage. Battery health is 98%. Includes original box, charger, and unused EarPods. Perfect for someone looking for a premium phone at a great price. Reason for selling: upgrading to iPhone 15 Pro Max.""",
    "location": "Downtown, San Francisco",
    "distance": "2.3 km away",
    "postedDate": "2 days ago",
    "views": 156,
    "images": [
      "https://images.unsplash.com/photo-1592750475338-74b7b21085ab?w=800&h=600&fit=crop",
      "https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=800&h=600&fit=crop",
      "https://images.unsplash.com/photo-1580910051074-3eb694886505?w=800&h=600&fit=crop",
      "https://images.unsplash.com/photo-1556656793-08538906a9f8?w=800&h=600&fit=crop"
    ],
    "seller": {
      "id": 101,
      "name": "Sarah Johnson",
      "avatar":
          "https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150&h=150&fit=crop",
      "rating": 4.8,
      "reviewCount": 24,
      "isVerified": true,
      "memberSince": "Member since 2021",
      "responseTime": "Usually responds within 2 hours"
    },
    "isOwnListing": false,
    "specifications": {
      "Brand": "Apple",
      "Model": "iPhone 14 Pro Max",
      "Storage": "256GB",
      "Color": "Space Black",
      "Condition": "Like New",
      "Warranty": "6 months remaining"
    }
  };

  final List<Map<String, dynamic>> relatedItems = [
    {
      "id": 2,
      "title": "iPhone 13 Pro - 128GB",
      "price": "\$699",
      "image":
          "https://images.unsplash.com/photo-1592750475338-74b7b21085ab?w=400&h=300&fit=crop",
      "location": "1.5 km away",
      "condition": "Good"
    },
    {
      "id": 3,
      "title": "Samsung Galaxy S23 Ultra",
      "price": "\$849",
      "image":
          "https://images.unsplash.com/photo-1610945265064-0e34e5519bbf?w=400&h=300&fit=crop",
      "location": "3.2 km away",
      "condition": "Excellent"
    },
    {
      "id": 4,
      "title": "iPhone 14 - 128GB Blue",
      "price": "\$749",
      "image":
          "https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=400&h=300&fit=crop",
      "location": "2.8 km away",
      "condition": "Like New"
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildCustomAppBar(),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ImageGalleryWidget(
                      images: (listingData["images"] as List).cast<String>(),
                    ),
                    SizedBox(height: 2.h),
                    SellerProfileWidget(
                      seller: listingData["seller"] as Map<String, dynamic>,
                      onViewProfile: () => _navigateToProfile(),
                    ),
                    SizedBox(height: 2.h),
                    ItemDetailsWidget(
                      title: listingData["title"] as String,
                      price: listingData["price"] as String,
                      originalPrice: listingData["originalPrice"] as String,
                      condition: listingData["condition"] as String,
                      category: listingData["category"] as String,
                      description: listingData["description"] as String,
                      postedDate: listingData["postedDate"] as String,
                      views: listingData["views"] as int,
                      specifications:
                          listingData["specifications"] as Map<String, dynamic>,
                    ),
                    SizedBox(height: 2.h),
                    LocationInfoWidget(
                      location: listingData["location"] as String,
                      distance: listingData["distance"] as String,
                      onViewMap: () => _showMapModal(),
                    ),
                    SizedBox(height: 2.h),
                    const SafetyTipsWidget(),
                    SizedBox(height: 2.h),
                    RelatedItemsWidget(
                      items: relatedItems,
                      onItemTap: (item) => _navigateToListing(item),
                    ),
                    SizedBox(height: 12.h), // Space for bottom buttons
                  ],
                ),
              ),
            ],
          ),
          _buildBottomActionButtons(),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return SliverAppBar(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      elevation: 0,
      pinned: true,
      floating: false,
      leading: Container(
        margin: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.9 * 255),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1 * 255),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 20,
          ),
        ),
      ),
      actions: [
        Container(
          margin: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color:
                AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.9 * 255),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1 * 255),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () => _shareListing(),
            icon: CustomIconWidget(
              iconName: 'share',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 20,
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.only(right: 4.w, top: 2.w, bottom: 2.w),
          decoration: BoxDecoration(
            color:
                AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.9 * 255),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1 * 255),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () => _toggleFavorite(),
            icon: CustomIconWidget(
              iconName: isFavorite ? 'favorite' : 'favorite_border',
              color: isFavorite
                  ? AppTheme.lightTheme.colorScheme.error
                  : AppTheme.lightTheme.colorScheme.onSurface,
              size: 20,
            ),
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(Icons.flag_outlined, size: 20),
                  SizedBox(width: 8),
                  Text('Report Listing'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'block',
              child: Row(
                children: [
                  Icon(Icons.block_outlined, size: 20),
                  SizedBox(width: 8),
                  Text('Block Seller'),
                ],
              ),
            ),
          ],
                      child: Container(
              margin: EdgeInsets.only(right: 4.w, top: 2.w, bottom: 2.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface
                    .withValues(alpha: 0.9 * 255),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1 * 255),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: CustomIconWidget(
                iconName: 'more_vert',
                color: AppTheme.lightTheme.colorScheme.onSurface,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionButtons() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1 * 255),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: listingData["isOwnListing"] == true
              ? _buildOwnerActions()
              : _buildBuyerActions(),
        ),
      ),
    );
  }

  Widget _buildBuyerActions() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : () => _chatWithSeller(),
            icon: isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.lightTheme.colorScheme.onPrimary,
                      ),
                    ),
                  )
                : CustomIconWidget(
                    iconName: 'chat',
                    color: AppTheme.lightTheme.colorScheme.onPrimary,
                    size: 20,
                  ),
            label: Text(
              isLoading ? 'Loading...' : 'Chat with Seller',
              style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onPrimary,
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 3.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          flex: 1,
          child: OutlinedButton(
            onPressed: () => _callSeller(),
            child: CustomIconWidget(
              iconName: 'phone',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 20,
            ),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 3.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _editListing(),
            icon: CustomIconWidget(
              iconName: 'edit',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 20,
            ),
            label: Text('Edit Listing'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 3.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _viewAnalytics(),
            icon: CustomIconWidget(
              iconName: 'analytics',
              color: AppTheme.lightTheme.colorScheme.onPrimary,
              size: 20,
            ),
            label: Text('Analytics'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 3.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFavorite ? 'Added to favorites' : 'Removed from favorites',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareListing() {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality will be implemented'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _chatWithSeller() {
    setState(() {
      isLoading = true;
    });

    // Simulate loading
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        isLoading = false;
      });
      Navigator.pushNamed(context, '/chat-messaging');
    });
  }

  void _callSeller() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Call Seller'),
        content: const Text('Would you like to call Sarah Johnson?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Calling functionality will be implemented'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Call'),
          ),
        ],
      ),
    );
  }

  void _navigateToProfile() {
    Navigator.pushNamed(context, '/user-profile');
  }

  void _showMapModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 70.h,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              margin: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Item Location',
                    style: AppTheme.lightTheme.textTheme.titleLarge,
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: CustomIconWidget(
                      iconName: 'close',
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color:
                      AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'location_on',
                        color: AppTheme.lightTheme.colorScheme.primary,
                        size: 48,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Map View',
                        style: AppTheme.lightTheme.textTheme.titleMedium,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Interactive map will be implemented',
                        style: AppTheme.lightTheme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToListing(Map<String, dynamic> item) {
    Navigator.pushNamed(context, '/listing-detail');
  }

  void _editListing() {
    Navigator.pushNamed(context, '/create-listing');
  }

  void _viewAnalytics() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Analytics view will be implemented'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'report':
        _showReportDialog();
        break;
      case 'block':
        _showBlockDialog();
        break;
    }
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Listing'),
        content: const Text('Why are you reporting this listing?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report submitted successfully'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block Seller'),
        content: const Text(
            'Are you sure you want to block this seller? You won\'t see their listings anymore.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Seller blocked successfully'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }
}
