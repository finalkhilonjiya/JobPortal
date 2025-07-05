import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/account_settings_section_widget.dart';
import './widgets/favorites_section_widget.dart';
import './widgets/my_listings_section_widget.dart';
import './widgets/profile_header_widget.dart';
import './widgets/recent_views_section_widget.dart';
import './widgets/statistics_cards_widget.dart';
import './widgets/verification_center_widget.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({Key? key}) : super(key: key);

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  // Mock user data
  final Map<String, dynamic> userData = {
    "id": 1,
    "name": "Sarah Johnson",
    "email": "sarah.johnson@email.com",
    "phone": "+1 (555) 123-4567",
    "avatar":
        "https://images.unsplash.com/photo-1494790108755-2616b612b786?fm=jpg&q=60&w=400&ixlib=rb-4.0.3",
    "isVerified": true,
    "rating": 4.8,
    "reviewCount": 127,
    "memberSince": "March 2022",
    "activeListings": 12,
    "soldItems": 45,
    "bio":
        "Passionate about sustainable living and finding great deals on quality items.",
    "location": "San Francisco, CA",
    "isBusinessAccount": false,
    "kycStatus": "verified",
    "phoneVerified": true,
    "emailVerified": true
  };

  final List<Map<String, dynamic>> myListings = [
    {
      "id": 1,
      "title": "Vintage Leather Jacket",
      "price": "\$85.00",
      "image":
          "https://images.unsplash.com/photo-1551028719-00167b16eac5?fm=jpg&q=60&w=400&ixlib=rb-4.0.3",
      "status": "active",
      "views": 24,
      "favorites": 8,
      "postedDate": "2 days ago"
    },
    {
      "id": 2,
      "title": "iPhone 13 Pro Max",
      "price": "\$750.00",
      "image":
          "https://images.unsplash.com/photo-1592750475338-74b7b21085ab?fm=jpg&q=60&w=400&ixlib=rb-4.0.3",
      "status": "sold",
      "views": 156,
      "favorites": 23,
      "postedDate": "1 week ago"
    },
    {
      "id": 3,
      "title": "Gaming Chair",
      "price": "\$120.00",
      "image":
          "https://images.unsplash.com/photo-1586023492125-27b2c045efd7?fm=jpg&q=60&w=400&ixlib=rb-4.0.3",
      "status": "expired",
      "views": 67,
      "favorites": 12,
      "postedDate": "3 weeks ago"
    },
    {
      "id": 4,
      "title": "MacBook Air M2",
      "price": "\$950.00",
      "image":
          "https://images.unsplash.com/photo-1517336714731-489689fd1ca8?fm=jpg&q=60&w=400&ixlib=rb-4.0.3",
      "status": "active",
      "views": 89,
      "favorites": 31,
      "postedDate": "5 days ago"
    }
  ];

  final List<Map<String, dynamic>> favoriteItems = [
    {
      "id": 1,
      "title": "Vintage Camera",
      "price": "\$200.00",
      "image":
          "https://images.unsplash.com/photo-1606983340126-99ab4feaa64a?fm=jpg&q=60&w=400&ixlib=rb-4.0.3",
      "seller": "Mike Chen",
      "location": "Oakland, CA"
    },
    {
      "id": 2,
      "title": "Designer Handbag",
      "price": "\$150.00",
      "image":
          "https://images.unsplash.com/photo-1584917865442-de89df76afd3?fm=jpg&q=60&w=400&ixlib=rb-4.0.3",
      "seller": "Emma Davis",
      "location": "Berkeley, CA"
    }
  ];

  final List<Map<String, dynamic>> recentViews = [
    {
      "id": 1,
      "title": "Wireless Headphones",
      "price": "\$45.00",
      "image":
          "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?fm=jpg&q=60&w=400&ixlib=rb-4.0.3",
      "viewedDate": "Today"
    },
    {
      "id": 2,
      "title": "Coffee Table",
      "price": "\$80.00",
      "image":
          "https://images.unsplash.com/photo-1586023492125-27b2c045efd7?fm=jpg&q=60&w=400&ixlib=rb-4.0.3",
      "viewedDate": "Yesterday"
    }
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.index = 4; // Profile tab active
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Logout',
            style: AppTheme.lightTheme.textTheme.titleLarge,
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login-screen',
                  (route) => false,
                );
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Tab Bar
            Container(
              color: AppTheme.lightTheme.colorScheme.surface,
              child: TabBar(
                controller: _tabController,
                onTap: (index) {
                  switch (index) {
                    case 0:
                      Navigator.pushNamed(context, '/home-marketplace-feed');
                      break;
                    case 1:
                      Navigator.pushNamed(context, '/search-and-filters');
                      break;
                    case 2:
                      Navigator.pushNamed(
                          context, '/favorites-and-saved-items');
                      break;
                    case 3:
                      Navigator.pushNamed(context, '/chat-messaging');
                      break;
                    case 4:
                      // Current screen - Profile
                      break;
                  }
                },
                tabs: [
                  Tab(
                    icon: CustomIconWidget(
                      iconName: 'home',
                      color: _tabController.index == 0
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                    text: 'Home',
                  ),
                  Tab(
                    icon: CustomIconWidget(
                      iconName: 'search',
                      color: _tabController.index == 1
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                    text: 'Search',
                  ),
                  Tab(
                    icon: CustomIconWidget(
                      iconName: 'favorite',
                      color: _tabController.index == 2
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                    text: 'Favorites',
                  ),
                  Tab(
                    icon: CustomIconWidget(
                      iconName: 'chat',
                      color: _tabController.index == 3
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                    text: 'Chat',
                  ),
                  Tab(
                    icon: CustomIconWidget(
                      iconName: 'person',
                      color: _tabController.index == 4
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                    text: 'Profile',
                  ),
                ],
              ),
            ),

            // Profile Content
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    // Profile Header
                    ProfileHeaderWidget(
                      userData: userData,
                      onEditProfile: () {
                        // Navigate to edit profile screen
                      },
                    ),

                    SizedBox(height: 2.h),

                    // Statistics Cards
                    StatisticsCardsWidget(
                      activeListings: userData["activeListings"] as int,
                      soldItems: userData["soldItems"] as int,
                      memberSince: userData["memberSince"] as String,
                    ),

                    SizedBox(height: 3.h),

                    // Verification Center
                    VerificationCenterWidget(
                      kycStatus: userData["kycStatus"] as String,
                      phoneVerified: userData["phoneVerified"] as bool,
                      emailVerified: userData["emailVerified"] as bool,
                    ),

                    SizedBox(height: 3.h),

                    // My Listings Section
                    MyListingsSectionWidget(
                      listings: myListings,
                      onViewAllListings: () {
                        // Navigate to all listings screen
                      },
                    ),

                    SizedBox(height: 3.h),

                    // Favorites Section
                    FavoritesSectionWidget(
                      favoriteItems: favoriteItems,
                      onViewAllFavorites: () {
                        Navigator.pushNamed(
                            context, '/favorites-and-saved-items');
                      },
                    ),

                    SizedBox(height: 3.h),

                    // Recent Views Section
                    RecentViewsSectionWidget(
                      recentViews: recentViews,
                      onViewAllRecent: () {
                        // Navigate to recent views screen
                      },
                    ),

                    SizedBox(height: 3.h),

                    // Account Settings Section
                    AccountSettingsSectionWidget(
                      userData: userData,
                      onLogout: _showLogoutDialog,
                    ),

                    SizedBox(height: 4.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/create-listing');
        },
        child: CustomIconWidget(
          iconName: 'add',
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
