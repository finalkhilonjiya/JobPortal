import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'square_product_card.dart'; // Import the square product card

class PremiumSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (listings.isEmpty) {
      return SizedBox.shrink(); // Don't show section if no premium listings
    }
    
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
              if (listings.length > 2)
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
          height: 44.h, // Slightly increased to accommodate any padding
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only(left: 2.w, right: 2.w, bottom: 1.h),
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final listing = listings[index];
              final isFavorite = favoriteIds.contains(listing['id']);
              
              return Container(
                width: 50.w, // Increased width for better spacing
                padding: EdgeInsets.only(right: index < listings.length - 1 ? 2.w : 0),
                child: Stack(
                  clipBehavior: Clip.none, // Allow badge to overflow if needed
                  children: [
                    // Remove the default margin from SquareProductCard
                    Theme(
                      data: Theme.of(context).copyWith(
                        cardTheme: CardTheme(margin: EdgeInsets.zero),
                      ),
                      child: Container(
                        margin: EdgeInsets.zero, // Override any default margins
                        child: SquareProductCard(
                          data: listing,
                          isFavorite: isFavorite,
                          onFavoriteToggle: () => onFavoriteToggle(listing['id']),
                          onTap: () => onTap(listing),
                          onCall: () => onCall(listing['phone'] ?? ''),
                          onWhatsApp: () => onWhatsApp(listing['phone'] ?? ''),
                        ),
                      ),
                    ),
                    
                    // Premium Badge Overlay - Positioned more carefully
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