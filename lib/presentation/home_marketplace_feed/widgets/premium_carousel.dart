import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:carousel_slider/carousel_slider.dart';

class PremiumCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> listings;
  final Function(Map<String, dynamic>) onTap;
  final Set<String> favoriteIds;
  final Function(String) onFavoriteToggle;

  const PremiumCarousel({
    required this.listings,
    required this.onTap,
    required this.favoriteIds,
    required this.onFavoriteToggle,
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
            autoPlayInterval: Duration(seconds: 4),
            autoPlayAnimationDuration: Duration(milliseconds: 800),
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
                      child: Column(
                        children: [
                          // Premium Badge
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 0.8.h),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                              ),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            child: Center(
                              child: Text(
                                'PREMIUM',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          // Image Section
                          Expanded(
                            flex: 3,
                            child: Stack(
                              children: [
                                Container(
                                  width: double.infinity,
                                  child: Image.network(
                                    listing['image'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Colors.grey[300],
                                      child: Icon(Icons.image, size: 10.w),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: Icon(
                                      widget.favoriteIds.contains(listing['id']) 
                                          ? Icons.favorite 
                                          : Icons.favorite_border,
                                      color: widget.favoriteIds.contains(listing['id']) 
                                          ? Colors.red 
                                          : Colors.white,
                                    ),
                                    onPressed: () => widget.onFavoriteToggle(listing['id']),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.black.withOpacity(0.5),
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
                              padding: EdgeInsets.all(2.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        listing['title'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.sp,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (listing['subcategory'] != null)
                                        Text(
                                          listing['subcategory'],
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 9.sp,
                                          ),
                                        ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '₹${listing['price']}',
                                        style: TextStyle(
                                          color: Color(0xFF2563EB),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14.sp,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            height: 4.h,
                                            width: 4.h,
                                            decoration: BoxDecoration(
                                              color: Colors.green[50],
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.green),
                                            ),
                                            child: Icon(Icons.call, color: Colors.green, size: 4.w),
                                          ),
                                          SizedBox(width: 1.w),
                                          Container(
                                            height: 4.h,
                                            width: 4.h,
                                            decoration: BoxDecoration(
                                              color: Colors.green[50],
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.green),
                                            ),
                                            child: Icon(Icons.chat, color: Colors.green, size: 4.w),
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
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
        // Dots Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: widget.listings.asMap().entries.map((entry) {
            return Container(
              width: _currentIndex == entry.key ? 8.w : 2.w,
              height: 2.w,
              margin: EdgeInsets.symmetric(vertical: 1.h, horizontal: 1.w),
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(1.w),
                color: _currentIndex == entry.key
                    ? Color(0xFF2563EB)
                    : Colors.grey[400],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}