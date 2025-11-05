import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'square_product_card.dart';
import 'all_premium_listings_page.dart';

class PremiumSection extends StatefulWidget {
  final List<Map<String, dynamic>> listings;
  final Function(Map<String, dynamic>) onTap;
  final Set<String> favoriteIds;
  final Function(String) onFavoriteToggle;
  final Function(String) onCall;
  final Function(String) onWhatsApp;

  const PremiumSection({
    required this.listings,
    required this.onTap,
    required this.favoriteIds,
    required this.onFavoriteToggle,
    required this.onCall,
    required this.onWhatsApp,
  });

  @override
  State<PremiumSection> createState() => _PremiumSectionState();
}

class _PremiumSectionState extends State<PremiumSection> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    if (widget.listings.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
    }
  }

  void _startAutoScroll() {
    if (!mounted || widget.listings.isEmpty) return;

    Future.delayed(Duration(seconds: 3), () {
      if (!mounted) return;

      double cardWidth = 92.w + 8.w; // width + horizontal margin

      _scrollController.animateTo(
        _scrollController.offset + cardWidth,
        duration: Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      ).then((_) {
        if (!mounted) return;

        if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent - cardWidth) {
          _scrollController.jumpTo(0);
        }
        _startAutoScroll();
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.listings.isEmpty) {
      return SizedBox.shrink();
    }

    // Triple listings for infinite scroll illusion
    final infiniteListings = [
      ...widget.listings,
      ...widget.listings,
      ...widget.listings,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF0EA5E9)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF2563EB).withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.white, size: 11.sp),
                    SizedBox(width: 1.w),
                    Text(
                      'PREMIUM LISTINGS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Spacer(),
              if (widget.listings.length > 2)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AllPremiumListingsPage(
                          onFavoriteToggle: widget.onFavoriteToggle,
                          favoriteIds: widget.favoriteIds,
                          onCall: widget.onCall,
                          onWhatsApp: widget.onWhatsApp,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Horizontal Premium Cards
        SizedBox(
          height: 42.h, // Same height as SquareProductCard
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: infiniteListings.length,
            itemBuilder: (context, index) {
              final listing = infiniteListings[index];
              final isFavorite = widget.favoriteIds.contains(listing['id']);

              return Container(
                width: 92.w, // ✅ same width ratio as full listings
                margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                child: Stack(
                  children: [
                    SquareProductCard(
                      data: listing,
                      isFavorite: isFavorite,
                      onFavoriteToggle: () =>
                          widget.onFavoriteToggle(listing['id']),
                      onTap: () => widget.onTap(listing),
                      onCall: () => widget.onCall(listing['phone'] ?? ''),
                      onWhatsApp: () =>
                          widget.onWhatsApp(listing['phone'] ?? ''),
                    ),

                    // Premium Badge Overlay
                    Positioned(
                      top: 2.h,
                      left: 6.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 3.w, vertical: 0.8.h),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.workspace_premium,
                                color: Colors.white, size: 10.sp),
                            SizedBox(width: 1.w),
                            Text(
                              'PREMIUM',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}