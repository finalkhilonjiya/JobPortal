import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../widgets/bottom_nav_bar_widget.dart';
import '../../theme/app_theme.dart';
import 'package:shimmer/shimmer.dart';
import '../../utils/supabase_service.dart';

class HomeMarketplaceFeed extends StatefulWidget {
  const HomeMarketplaceFeed({Key? key}) : super(key: key);

  @override
  State<HomeMarketplaceFeed> createState() => _HomeMarketplaceFeedState();
}

class _HomeMarketplaceFeedState extends State<HomeMarketplaceFeed> {
  int _currentIndex = 0;
  bool _isLoadingPremium = true;
  bool _isLoadingFeed = true;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _listings = [];
  String _selectedCategory = 'All';

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
    try {
      final supabase = SupabaseService();
      // Fetch categories
      final catRes = await supabase.client.from('categories').select();
      final categories = List<Map<String, dynamic>>.from(catRes);
      // Fetch listings
      final listRes = await supabase.client.from('listings').select('*, categories(name)');
      final listings = List<Map<String, dynamic>>.from(listRes);
      setState(() {
        _categories = [{'name': 'All', 'icon': Icons.apps, 'color': Colors.green}] + List<Map<String, dynamic>>.from(categories.map((c) => {
          'name': c['name'],
          'icon': Icons.category,
          'color': Colors.green
        }).toList());
        _listings = listings;
        _isLoadingPremium = false;
        _isLoadingFeed = false;
      });
    } catch (e) {
      // Use mock data if error
      setState(() {
        _categories = [
          {'name': 'All', 'icon': Icons.apps, 'color': Colors.green},
          {'name': 'Electronics', 'icon': Icons.devices, 'color': Colors.green},
          {'name': 'Vehicles', 'icon': Icons.directions_car, 'color': Colors.green},
          {'name': 'Jobs', 'icon': Icons.work, 'color': Colors.green},
          {'name': 'Properties', 'icon': Icons.home, 'color': Colors.green},
        ];
        _listings = List.generate(20, (i) => {
          'title': 'Product Title $i',
          'price': (i + 1) * 5000,
          'location': 'Guwahati, Assam',
          'category': i % 2 == 0 ? 'Electronics' : 'Vehicles',
          'image': 'https://source.unsplash.com/random/400x300?sig=$i',
          'is_featured': i < 3,
        });
        _isLoadingPremium = false;
        _isLoadingFeed = false;
      });
    }
  }

  void _onCategorySelected(String name) {
    setState(() {
      _selectedCategory = name;
    });
  }

  List<Map<String, dynamic>> get _filteredListings {
    if (_selectedCategory == 'All') return _listings;
    return _listings.where((l) => l['category'] == _selectedCategory).toList();
  }

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
            SliverToBoxAdapter(
              child: _isLoadingPremium
                  ? _ShimmerPremiumCardsSection()
                  : _PremiumCardsSection(listings: _listings.where((l) => l['is_featured'] == true).toList()),
            ),
            SliverToBoxAdapter(child: _CategoriesSection(
              categories: _categories,
              selected: _selectedCategory,
              onSelect: _onCategorySelected,
            )),
            _isLoadingFeed
                ? SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _ShimmerProductFeedCard(),
                      childCount: 8,
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _ProductFeedCard(data: _filteredListings[index]),
                      childCount: _filteredListings.length,
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
        hasMessageNotification: false,
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
        gradient: LinearGradient(
          colors: [AppTheme.primaryLight, AppTheme.successLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryLight.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Your trusted Assamese marketplace for buying, selling, and more.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12.sp,
              fontFamily: 'Poppins',
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
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
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
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
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
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  elevation: 2,
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 6.h,
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.outlineLight, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryLight.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
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
                  style: TextStyle(color: AppTheme.textSecondaryLight, fontSize: 12.sp, fontFamily: 'Poppins'),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 3.w),
                child: Icon(Icons.location_on, color: AppTheme.primaryLight, size: 20),
              ),
              Text('Guwahati, Assam', style: TextStyle(color: AppTheme.primaryLight, fontSize: 11.sp, fontFamily: 'Poppins')),
              SizedBox(width: 2.w),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShimmerPremiumCardsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22.h,
      child: ListView.builder(
        key: const Key('shimmer_premium_cards_list'),
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        itemCount: 3,
        itemBuilder: (context, index) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: 60.w,
            margin: EdgeInsets.only(right: 4.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumCardsSection extends StatelessWidget {
  final List<Map<String, dynamic>> listings;
  const _PremiumCardsSection({required this.listings});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22.h,
      child: ListView.builder(
        key: const Key('premium_cards_list'),
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        itemCount: listings.length,
        itemBuilder: (context, index) => _PremiumCard(data: listings[index]),
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _PremiumCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 60.w,
      margin: EdgeInsets.only(right: 4.w),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.06),
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
                image: NetworkImage(data['image'] ?? 'https://source.unsplash.com/random/800x600'),
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
                    Text('Premium', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11.sp, fontFamily: 'Poppins')),
                    const SizedBox(width: 8),
                    Icon(Icons.verified, color: Colors.green, size: 16),
                  ],
                ),
                SizedBox(height: 0.5.h),
                Text(data['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp, fontFamily: 'Poppins')),
                SizedBox(height: 0.5.h),
                Text('₹${data['price']}', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12.sp, fontFamily: 'Poppins')),
                SizedBox(height: 0.5.h),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.green, size: 14),
                    SizedBox(width: 4),
                    Text(data['location'] ?? '', style: TextStyle(color: Colors.green, fontSize: 10.sp, fontFamily: 'Poppins')),
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
  final List<Map<String, dynamic>> categories;
  final String selected;
  final void Function(String) onSelect;
  const _CategoriesSection({required this.categories, required this.selected, required this.onSelect});
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
          final isSelected = cat['name'] == selected;
          return GestureDetector(
            onTap: () => onSelect(cat['name']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: isSelected ? Colors.green : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 26,
                    child: Icon(cat['icon'] as IconData, color: Colors.green, size: 24),
                  ),
                  SizedBox(height: 0.8.h),
                  Text(cat['name'] as String, style: TextStyle(fontSize: 10.sp, color: isSelected ? Colors.white : Colors.green, fontFamily: 'Poppins')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ShimmerProductFeedCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
          child: SizedBox(height: 90, width: double.infinity),
        ),
      ),
    );
  }
}

class _ProductFeedCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ProductFeedCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Card(
        key: Key('product_feed_card_${data['title']}'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  data['image'] ?? 'https://source.unsplash.com/random/400x300',
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
                        Text('₹${data['price']}', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13.sp, fontFamily: 'Poppins')),
                        SizedBox(width: 8),
                        Icon(Icons.verified, color: Colors.green, size: 16),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Text(data['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp, fontFamily: 'Poppins')),
                    SizedBox(height: 0.5.h),
                    Text(data['location'] ?? '', style: TextStyle(color: Colors.green, fontSize: 10.sp, fontFamily: 'Poppins')),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 12, color: Colors.green),
                        SizedBox(width: 4),
                        Text('2 hours ago', style: TextStyle(color: Colors.green, fontSize: 9.sp, fontFamily: 'Poppins')),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                key: Key('favorite_icon_${data['title']}'),
                icon: Icon(Icons.favorite_border, color: Colors.green),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}