import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../widgets/bottom_nav_bar_widget.dart';
import '../../theme/app_theme.dart';
import 'package:shimmer/shimmer.dart';
import '../../utils/supabase_service.dart';
import 'dart:async';
import '../../routes/app_routes.dart';

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
      _categories = [
        {'name': 'All', 'icon': Icons.grid_view_rounded, 'color': Color(0xFF2563EB)},
        {'name': 'Electronics', 'icon': Icons.devices_other_rounded, 'color': Color(0xFF2563EB)},
        {'name': 'Vehicles', 'icon': Icons.directions_car_filled_rounded, 'color': Color(0xFF2563EB)},
        {'name': 'Jobs', 'icon': Icons.work_outline_rounded, 'color': Color(0xFF2563EB)},
        {'name': 'Properties', 'icon': Icons.apartment_rounded, 'color': Color(0xFF2563EB)},
      ];
      
      _listings = List.generate(10, (i) => {
        'id': '$i',
        'title': 'Product Title $i',
        'price': (i + 1) * 5000,
        'location': 'Guwahati, Assam',
        'category': i % 2 == 0 ? 'Electronics' : 'Vehicles',
        'image': 'https://picsum.photos/400/300?random=$i',
        'is_featured': i < 3,
        'time_ago': '2 hours ago',
      });
      
      _isLoadingPremium = false;
      _isLoadingFeed = false;
    });
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

  void _openSearchPage() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SearchBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _AppInfoBanner()),
            SliverToBoxAdapter(child: _ThreeOptionSection()),
            SliverToBoxAdapter(child: _SearchBarSection(onTap: _openSearchPage)),
            if (_listings.where((l) => l['is_featured'] == true).isNotEmpty)
              SliverToBoxAdapter(
                child: _isLoadingPremium
                    ? _buildShimmerSection()
                    : _PremiumSection(listings: _listings.where((l) => l['is_featured'] == true).toList()),
              ),
            SliverToBoxAdapter(child: _CategoriesSection(
              categories: _categories,
              selected: _selectedCategory,
              onSelect: _onCategorySelected,
            )),
            _isLoadingFeed
                ? SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, __) => _buildShimmerCard(),
                      childCount: 5,
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, index) => _ProductCard(data: _filteredListings[index]),
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
          if (index == 1) _openSearchPage();
        },
        onFabPressed: () {},
        hasMessageNotification: false,
      ),
    );
  }

  Widget _buildShimmerSection() {
    return Container(
      height: 18.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: 3,
        itemBuilder: (_, __) => Container(
          width: 70.w,
          margin: EdgeInsets.only(right: 3.w),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(height: 10.h, color: Colors.white),
        ),
      ),
    );
  }
}

class _AppInfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF0EA5E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF2563EB).withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.verified, color: Color(0xFF2563EB), size: 24),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome to\nkhilonjiya.com',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'আমাৰ সংস্কৃতি, আমাৰ গৌৰৱ',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11.sp),
                ),
                Text(
                  'Our Culture, Our Pride',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 9.sp),
                ),
              ],
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
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Apply for Job'),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('List Jobs'),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('Assamese Traditional Marketplace', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBarSection extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchBarSection({required this.onTap});
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey[600], size: 20),
                    SizedBox(width: 8),
                    Text('Search items...', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.grey[600], size: 20),
                    SizedBox(width: 8),
                    Flexible(child: Text('Location', style: TextStyle(color: Colors.grey[600]), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumSection extends StatelessWidget {
  final List<Map<String, dynamic>> listings;
  const _PremiumSection({required this.listings});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18.h,
      margin: EdgeInsets.only(bottom: 2.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: listings.length,
        itemBuilder: (_, index) => Container(
          width: 70.w,
          margin: EdgeInsets.only(right: 3.w),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {},
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        listings[index]['image'],
                        width: 80,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 80,
                          color: Colors.grey[300],
                          child: Icon(Icons.image, color: Colors.grey[600]),
                        ),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Color(0xFF2563EB).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Premium', style: TextStyle(color: Color(0xFF2563EB), fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          SizedBox(height: 4),
                          Text(listings[index]['title'], style: TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                          Text('₹${listings[index]['price']}', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                          Text(listings[index]['location'], style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoriesSection extends StatelessWidget {
  final List<Map<String, Object>> categories;
  final String selected;
  final void Function(String) onSelect;
  const _CategoriesSection({required this.categories, required this.selected, required this.onSelect});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 10.h,
      margin: EdgeInsets.symmetric(vertical: 1.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: categories.length,
        itemBuilder: (_, index) {
          final cat = categories[index];
          final isSelected = cat['name'] == selected;
          return GestureDetector(
            onTap: () => onSelect(cat['name'] as String),
            child: Container(
              margin: EdgeInsets.only(right: 3.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected ? Color(0xFF2563EB) : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: isSelected ? Color(0xFF2563EB) : Colors.grey[300]!, width: 2),
                    ),
                    child: Icon(cat['icon'] as IconData, color: isSelected ? Colors.white : Color(0xFF2563EB), size: 24),
                  ),
                  SizedBox(height: 4),
                  Text(cat['name'] as String, style: TextStyle(fontSize: 10, color: isSelected ? Color(0xFF2563EB) : Colors.grey[700], fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ProductCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    data['image'],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: Icon(Icons.image, color: Colors.grey[600]),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text('₹${data['price']}', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(width: 8),
                          if (data['is_featured'] == true) Icon(Icons.verified, color: Color(0xFF2563EB), size: 16),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(data['title'], style: TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(data['location'], style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      Text(data['time_ago'], style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.favorite_border, color: Color(0xFF2563EB)),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SearchBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Text('Search', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'What are you looking for?',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Location',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2563EB),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Search', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}