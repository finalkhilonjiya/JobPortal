import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../widgets/bottom_nav_bar_widget.dart';
import '../../theme/app_theme.dart';

class HomeMarketplaceFeed extends StatefulWidget {
  const HomeMarketplaceFeed({Key? key}) : super(key: key);

  @override
  State<HomeMarketplaceFeed> createState() => _HomeMarketplaceFeedState();
}

class _HomeMarketplaceFeedState extends State<HomeMarketplaceFeed> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _AppInfoBanner()),
            SliverToBoxAdapter(child: _ThreeOptionSection()),
            SliverToBoxAdapter(child: _SearchBarSection()),
            SliverToBoxAdapter(child: _PremiumCardsSection()),
            SliverToBoxAdapter(child: _CategoriesSection()),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _ProductFeedCard(index: index),
                childCount: 20, // Placeholder for infinite feed
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 12.h)),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBarWidget(
        currentIndex: _currentIndex,
        onTabSelected: (index) {
          setState(() => _currentIndex = index);
          // TODO: Handle navigation
        },
        onFabPressed: () {
          // TODO: Navigate to create listing
        },
        hasMessageNotification: false, // TODO: wire up real notification state
      ),
    );
  }
}

class _AppInfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to khilonjiya.com',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Your trusted Assamese marketplace for buying, selling, and more.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreeOptionSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  key: const Key('btn_apply_job'),
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryLight,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Apply for Job'),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  key: const Key('btn_list_jobs'),
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryLight,
                    side: const BorderSide(color: AppTheme.primaryLight),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('List Jobs'),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Center(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('btn_assamese_marketplace'),
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successLight,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: const Text('Assamese Traditional Marketplace', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBarSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: GestureDetector(
        key: const Key('search_bar'),
        onTap: () {
          // TODO: Open full search screen
        },
        child: Container(
          height: 6.h,
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.outlineLight, width: 1),
          ),
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 3.w),
                child: Icon(Icons.search, color: AppTheme.textSecondaryLight, size: 22),
              ),
              Expanded(
                child: Text(
                  "Search 'Mobiles'",
                  style: TextStyle(color: AppTheme.textSecondaryLight, fontSize: 12.sp),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 3.w),
                child: Icon(Icons.location_on, color: AppTheme.primaryLight, size: 20),
              ),
              Text('Guwahati, Assam', style: TextStyle(color: AppTheme.primaryLight, fontSize: 11.sp)),
              SizedBox(width: 2.w),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumCardsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22.h,
      child: ListView.builder(
        key: const Key('premium_cards_list'),
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        itemCount: 6,
        itemBuilder: (context, index) => _PremiumCard(index: index),
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  final int index;
  const _PremiumCard({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60.w,
      margin: EdgeInsets.only(right: 4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 12.h,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              image: DecorationImage(
                image: NetworkImage('https://source.unsplash.com/random/800x600?sig=$index'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Premium', style: TextStyle(color: AppTheme.successLight, fontWeight: FontWeight.bold, fontSize: 11.sp)),
                    const SizedBox(width: 8),
                    Icon(Icons.verified, color: AppTheme.successLight, size: 16),
                  ],
                ),
                SizedBox(height: 0.5.h),
                Text('Featured Product $index', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp)),
                SizedBox(height: 0.5.h),
                Text('₹${(index + 1) * 10000}', style: TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.bold, fontSize: 12.sp)),
                SizedBox(height: 0.5.h),
                Row(
                  children: [
                    Icon(Icons.location_on, color: AppTheme.textSecondaryLight, size: 14),
                    SizedBox(width: 4),
                    Text('Guwahati', style: TextStyle(color: AppTheme.textSecondaryLight, fontSize: 10.sp)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoriesSection extends StatelessWidget {
  final List<Map<String, dynamic>> categories = const [
    {'name': 'Electronics', 'icon': Icons.devices, 'color': AppTheme.primaryLight},
    {'name': 'Vehicles', 'icon': Icons.directions_car, 'color': AppTheme.secondaryLight},
    {'name': 'Jobs', 'icon': Icons.work, 'color': AppTheme.successLight},
    {'name': 'Properties', 'icon': Icons.home, 'color': AppTheme.warningLight},
    {'name': 'Fashion', 'icon': Icons.checkroom, 'color': AppTheme.errorLight},
    {'name': 'Furniture', 'icon': Icons.chair, 'color': AppTheme.primaryLight},
    {'name': 'Services', 'icon': Icons.handyman, 'color': AppTheme.secondaryLight},
    {'name': 'More', 'icon': Icons.more_horiz, 'color': AppTheme.textSecondaryLight},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 10.h,
      child: ListView.separated(
        key: const Key('categories_list'),
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        itemCount: categories.length,
        separatorBuilder: (_, __) => SizedBox(width: 4.w),
        itemBuilder: (context, index) {
          final cat = categories[index];
          return Column(
            children: [
              CircleAvatar(
                backgroundColor: (cat['color'] as Color).withOpacity(0.1),
                radius: 26,
                child: Icon(cat['icon'] as IconData, color: cat['color'] as Color, size: 24),
              ),
              SizedBox(height: 0.8.h),
              Text(cat['name'] as String, style: TextStyle(fontSize: 10.sp, color: AppTheme.textPrimaryLight)),
            ],
          );
        },
      ),
    );
  }
}

class _ProductFeedCard extends StatelessWidget {
  final int index;
  const _ProductFeedCard({required this.index});

  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key('product_feed_card_$index'),
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                'https://source.unsplash.com/random/400x300?sig=$index',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('₹${(index + 1) * 5000}', style: TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.bold, fontSize: 13.sp)),
                      SizedBox(width: 8),
                      Icon(Icons.verified, color: AppTheme.successLight, size: 16),
                    ],
                  ),
                  SizedBox(height: 0.5.h),
                  Text('Product Title $index', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp)),
                  SizedBox(height: 0.5.h),
                  Text('Guwahati, Assam', style: TextStyle(color: AppTheme.textSecondaryLight, fontSize: 10.sp)),
                  SizedBox(height: 0.5.h),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: AppTheme.textSecondaryLight),
                      SizedBox(width: 4),
                      Text('2 hours ago', style: TextStyle(color: AppTheme.textSecondaryLight, fontSize: 9.sp)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              key: Key('favorite_icon_$index'),
              icon: Icon(Icons.favorite_border, color: AppTheme.primaryLight),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}