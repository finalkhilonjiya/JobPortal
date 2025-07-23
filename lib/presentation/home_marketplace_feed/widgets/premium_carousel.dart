import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PremiumCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> listings;
  final Function(Map<String, dynamic>) onTap;
  final Set<String> favoriteIds;
  final Function(String) onFavoriteToggle;
  final Function(String) onCall;
  final Function(String) onWhatsApp;

  const PremiumCarousel({
    required this.listings,
    required this.onTap,
    required this.favoriteIds,
    required this.onFavoriteToggle,
    required this.onCall,
    required this.onWhatsApp,
  });

  @override
  State<PremiumCarousel> createState() => _PremiumCarouselState();
}

class _PremiumCarouselState extends State<PremiumCarousel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 28.h,
            autoPlay: true,
            autoPlayInterval: Duration(seconds: 6),
            autoPlayAnimationDuration: Duration(milliseconds: 500),
            enlargeCenterPage: true,
            viewportFraction: 0.85,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          items: widget.listings.map((listing) {
            return Builder(
              builder: (BuildContext context) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  margin: EdgeInsets.symmetric(horizontal: 1.w),
                  child: InkWell(
                    onTap: () => widget.onTap(listing),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        children: [
                          Column(
                            children: [
                              // Image Section
                              Expanded(
                                flex: 3,
                                child: Stack(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                        child: Image.network(
                                          listing['image'] ?? '',
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            color: Colors.grey[300],
                                            child: Icon(Icons.image, size: 10.w, color: Colors.grey[600]),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Favorite button
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            widget.favoriteIds.contains(listing['id']) 
                                                ? Icons.favorite 
                                                : Icons.favorite_border,
                                            color: widget.favoriteIds.contains(listing['id']) 
                                                ? Colors.red 
                                                : Colors.white,
                                            size: 20,
                                          ),
                                          onPressed: () => widget.onFavoriteToggle(listing['id']),
                                          padding: EdgeInsets.all(8),
                                          constraints: BoxConstraints(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Details Section
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: EdgeInsets.all(2.w), // Reduced padding
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Title and Category
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              listing['title'] ?? 'No Title',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11.sp, // Reduced font size
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (listing['category'] != null)
                                              Text(
                                                '${listing['category']} > ${listing['subcategory'] ?? ''}',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 8.sp, // Reduced font size
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                      // Price and Actions Row
                                      Row(
                                        children: [
                                          // Price and Location
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  '₹${listing['price'] ?? '0'}',
                                                  style: TextStyle(
                                                    color: Color(0xFF2563EB),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12.sp, // Reduced font size
                                                  ),
                                                ),
                                                if (listing['location'] != null)
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.location_on_outlined, 
                                                        size: 9.sp, // Reduced icon size
                                                        color: Colors.grey[600]
                                                      ),
                                                      SizedBox(width: 0.5.w),
                                                      Flexible(
                                                        child: Text(
                                                          listing['location'],
                                                          style: TextStyle(
                                                            color: Colors.grey[600],
                                                            fontSize: 8.sp, // Reduced font size
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                          ),
                                          // Action Buttons
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              InkWell(
                                                onTap: () => widget.onCall(listing['phone'] ?? ''),
                                                borderRadius: BorderRadius.circular(20),
                                                child: Container(
                                                  height: 3.5.h, // Reduced size
                                                  width: 3.5.h,
                                                  decoration: BoxDecoration(
                                                    color: Colors.green.withOpacity(0.1),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(Icons.phone, color: Colors.green, size: 3.5.w),
                                                ),
                                              ),
                                              SizedBox(width: 1.5.w),
                                              InkWell(
                                                onTap: () => widget.onWhatsApp(listing['phone'] ?? ''),
                                                borderRadius: BorderRadius.circular(20),
                                                child: Container(
                                                  height: 3.5.h, // Reduced size
                                                  width: 3.5.h,
                                                  decoration: BoxDecoration(
                                                    color: Color(0xFF25D366).withOpacity(0.1),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: FaIcon(
                                                    FontAwesomeIcons.whatsapp, 
                                                    color: Color(0xFF25D366), 
                                                    size: 3.5.w
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Premium Badge - Top Left
                          Positioned(
                            top: 0,
                            left: 0,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.8.h),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF2563EB), Color(0xFF0EA5E9)],
                                ),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star, color: Colors.white, size: 10.sp),
                                  SizedBox(width: 0.5.w),
                                  Text(
                                    'PREMIUM',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8.sp,
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
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
        // Dots Indicator
        Container(
          padding: EdgeInsets.only(top: 1.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: widget.listings.asMap().entries.map((entry) {
              return AnimatedContainer(
                duration: Duration(milliseconds: 300),
                width: _currentIndex == entry.key ? 6.w : 2.w,
                height: 2.w,
                margin: EdgeInsets.symmetric(horizontal: 1.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1.w),
                  color: _currentIndex == entry.key
                      ? Color(0xFF2563EB)
                      : Colors.grey[400],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
