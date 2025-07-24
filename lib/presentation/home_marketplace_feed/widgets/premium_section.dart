import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'square_product_card.dart';

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
    
    // Auto-scroll for infinite loop effect
    if (widget.listings.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startAutoScroll();
      });
    }
  }
  
  void _startAutoScroll() {
    if (!mounted || widget.listings.isEmpty) return;
    
    Future.delayed(Duration(seconds: 3), () {
      if (!mounted) return;
      
      _scrollController.animateTo(
        _scrollController.offset + 52.w, // Width of one card + spacing
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      ).then((_) {
        if (!mounted) return;
        
        // Check if we've reached the end
        if (_scrollController.offset >= _scrollController.position.maxScrollExtent - 52.w) {
          // Jump back to start for infinite loop
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
    
    // Triple the listings for infinite scroll effect
    final infiniteListings = [
      ...widget.listings,
      ...widget.listings,
      ...widget.listings,
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Premium Section Header
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
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.white, size: 11.sp),
                    SizedBox(width: 1.w),
                    Text(
                      'PREMIUM ADS',
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
                    // Navigate to all premium listings
                  },
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 9.sp,
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // Horizontal Scrollable List of Square Cards
        Container(
          height: 44.h,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only(left: 2.w, right: 2.w, bottom: 1.h),
            itemCount: infiniteListings.length,
            itemBuilder: (context, index) {
              final listing = infiniteListings[index];
              final isFavorite = widget.favoriteIds.contains(listing['id']);
              
              return Container(
                width: 50.w,
                padding: EdgeInsets.only(right: 2.w),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Theme(
                      data: Theme.of(context).copyWith(
                        cardTheme: CardTheme(margin: EdgeInsets.zero),
                      ),
                      child: Container(
                        margin: EdgeInsets.zero,
                        child: SquareProductCard(
                          data: listing,
                          isFavorite: isFavorite,
                          onFavoriteToggle: () => widget.onFavoriteToggle(listing['id']),
                          onTap: () => widget.onTap(listing),
                          onCall: () => widget.onCall(listing['phone'] ?? ''),
                          onWhatsApp: () => widget.onWhatsApp(listing['phone'] ?? ''),
                        ),
                      ),
                    ),
                    
                    // Premium Badge Overlay
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.4.h),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF0EA5E9)],
                          ),
                          borderRadius: BorderRadius.circular(6),
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
                            Icon(Icons.star, color: Colors.white, size: 7.sp),
                            SizedBox(width: 0.3.w),
                            Text(
                              'PREMIUM',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 6.5.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
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