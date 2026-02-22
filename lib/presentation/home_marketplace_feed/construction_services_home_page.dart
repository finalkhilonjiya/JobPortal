import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'rcc_works_form.dart';
import 'assam_type_form.dart';
import 'electrical_works_form.dart';
import 'false_ceiling_form.dart';
import 'plumbing_form.dart';
import 'interior_design_form.dart';

class ConstructionServicesHomePage extends StatefulWidget {
  const ConstructionServicesHomePage({Key? key}) : super(key: key);

  @override
  State<ConstructionServicesHomePage> createState() =>
      _ConstructionServicesHomePageState();
}

class _ConstructionServicesHomePageState
    extends State<ConstructionServicesHomePage> {

  final SupabaseClient _supabase = Supabase.instance.client;
  final ScrollController _scrollController = ScrollController();

  List<String> _sliderImages = [];
  int _currentIndex = 0;

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;

  int _offset = 0;
  final int _limit = 6;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loadingMore || !_hasMore) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
  final res = await _supabase
      .from('slider')
      .select('image_url')
      .eq('slider_type', 'construction')
      .eq('is_active', true)
      .order('display_order', ascending: true)
      .range(_offset, _offset + _limit - 1);

  setState(() {
    _sliderImages =
        List<String>.from(res.map((e) => e['image_url'] ?? ''));
    _offset += _sliderImages.length;
    _hasMore = res.length == _limit;
    _loading = false;
  });
}
  Future<void> _loadMore() async {
  if (!_hasMore) return;

  setState(() => _loadingMore = true);

  final res = await _supabase
      .from('slider')
      .select('image_url')
      .eq('slider_type', 'construction')
      .eq('is_active', true)
      .order('display_order', ascending: true)
      .range(_offset, _offset + _limit - 1);

  setState(() {
    _sliderImages.addAll(
        List<String>.from(res.map((e) => e['image_url'] ?? '')));
    _offset += res.length;
    _hasMore = res.length == _limit;
    _loadingMore = false;
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Khilonjiya Construction Services"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  _buildSliderSection(),
                  _buildWelcomeBanner(),
                  _buildServicesGrid(context),
                  _buildFeaturesSection(),
                  if (_loadingMore)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: const CircularProgressIndicator(),
                    ),
                  SizedBox(height: 10.h),
                ],
              ),
            ),
    );
  }

  // ================= SLIDER =================

  Widget _buildSliderSection() {
    if (_sliderImages.isEmpty) return const SizedBox();

    return Container(
      margin: EdgeInsets.fromLTRB(4.w, 4.h, 4.w, 6.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Ongoing Projects",
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 3.w),
          CarouselSlider(
            options: CarouselOptions(
              height: 25.h,
              autoPlay: true,
              enlargeCenterPage: true,
              viewportFraction: 0.9,
              onPageChanged: (index, reason) {
                setState(() => _currentIndex = index);
              },
            ),
            items: _sliderImages.map((url) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (_, __) =>
                      Container(color: Colors.grey[300]),
                  errorWidget: (_, __, ___) =>
                      Container(color: Colors.grey[300]),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_sliderImages.length, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentIndex == index ? 10 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _currentIndex == index
                      ? Colors.blue
                      : Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ================= ORIGINAL BANNER =================

  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(4.w, 0, 4.w, 6.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 1280 / 636,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            'assets/images/constructionbanner.jpg',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  // ================= ORIGINAL GRID =================

  Widget _buildServicesGrid(BuildContext context) {
    final services = [
      ServiceItem(
        title: 'RCC Works',
        subtitle: 'Reinforced concrete construction',
        icon: Icons.construction,
        colors: [Color(0xFFE8F5E8), Color(0xFFC8E6C9)],
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => RCCWorksForm())),
      ),
      ServiceItem(
        title: 'Assam Type',
        subtitle: 'Traditional Assamese architecture',
        icon: Icons.home,
        colors: [Color(0xFFFFF3E0), Color(0xFFFFCC02)],
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => AssamTypeForm())),
      ),
      ServiceItem(
        title: 'Electrical Works',
        subtitle: 'Complete electrical solutions',
        icon: Icons.electrical_services,
        colors: [Color(0xFFE3F2FD), Color(0xFF90CAF9)],
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => ElectricalWorksForm())),
      ),
      ServiceItem(
        title: 'False Ceiling',
        subtitle: 'Modern ceiling designs',
        icon: Icons.architecture,
        colors: [Color(0xFFF3E5F5), Color(0xFFCE93D8)],
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => FalseCeilingForm())),
      ),
      ServiceItem(
        title: 'Plumbing',
        subtitle: 'Complete plumbing solutions',
        icon: Icons.plumbing,
        colors: [Color(0xFFFFF8E1), Color(0xFFFFCC02)],
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => PlumbingForm())),
      ),
      ServiceItem(
        title: 'Interior Design',
        subtitle: 'Custom interior solutions',
        icon: Icons.design_services,
        colors: [Color(0xFFFCE4EC), Color(0xFFF48FB1)],
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => InteriorDesignForm())),
      ),
    ];

    return Container(
      margin: EdgeInsets.fromLTRB(4.w, 0, 4.w, 6.w),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 4.w,
          mainAxisSpacing: 4.w,
          childAspectRatio: 0.85,
        ),
        itemCount: services.length,
        itemBuilder: (_, index) {
          return _buildServiceCard(services[index]);
        },
      ),
    );
  }

  Widget _buildServiceCard(ServiceItem service) {
    return GestureDetector(
      onTap: service.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(5.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 15.w,
              height: 15.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: service.colors),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                service.icon,
                size: 7.w,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 4.w),
            Text(
              service.title,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.w),
            Text(
              service.subtitle,
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ================= ORIGINAL FEATURES =================

  Widget _buildFeaturesSection() {
    return Container(
      margin: EdgeInsets.fromLTRB(4.w, 0, 4.w, 6.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.all(6.w),
      child: Column(
        children: [
          Text(
            'Why Choose Us?',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4.w),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFeatureItem(Icons.star, '15+ Years\nExperience'),
              _buildFeatureItem(Icons.workspace_premium, 'Local\nExpertise'),
              _buildFeatureItem(Icons.verified, 'Quality\nMaterials'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Column(
      children: [
        Container(
          width: 10.w,
          height: 10.w,
          decoration: const BoxDecoration(
            color: Color(0xFF2563EB),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 5.w),
        ),
        SizedBox(height: 2.w),
        Text(
          text,
          style: TextStyle(
            fontSize: 10.sp,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class ServiceItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  ServiceItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.onTap,
  });
}