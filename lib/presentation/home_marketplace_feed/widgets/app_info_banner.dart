// ===== File 1: widgets/app_info_banner.dart =====
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AppInfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      height: 22.h, // Increased height for bigger banner
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
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.5.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.verified, color: Color(0xFF2563EB), size: 6.w),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Welcome to',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 11.sp,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'khilonjiya.com',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'আমাৰ সংস্কৃতি, আমাৰ গৌৰৱ',
            style: TextStyle(
              color: Colors.white.withOpacity(0.95),
              fontSize: 10.sp,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            'Our Culture, Our Pride',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 8.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ===== File 2: widgets/product_card.dart =====
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onTap;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;
  
  const ProductCard({
    required this.data,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onTap,
    required this.onCall,
    required this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
      height: 15.h, // Fixed height to prevent overflow
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(2.w),
            child: Row(
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    data['image'],
                    width: 25.w,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 25.w,
                      height: double.infinity,
                      color: Colors.grey[300],
                      child: Icon(Icons.image, color: Colors.grey[600]),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Title and Price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  data['title'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11.sp,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (data['is_verified'] == true)
                                Icon(Icons.verified, color: Color(0xFF2563EB), size: 4.w),
                            ],
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            '₹${data['price']}',
                            style: TextStyle(
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.bold,
                              fontSize: 13.sp,
                            ),
                          ),
                        ],
                      ),
                      // Location and Time
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['location'],
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 9.sp,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            data['time_ago'],
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 8.sp,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: Color(0xFF2563EB),
                        size: 5.w,
                      ),
                      onPressed: onFavoriteToggle,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.call, color: Colors.green, size: 5.w),
                          onPressed: onCall,
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(
                            minWidth: 8.w,
                            minHeight: 8.w,
                          ),
                        ),
                        SizedBox(width: 1.w),
                        IconButton(
                          icon: Icon(Icons.message, color: Colors.green, size: 5.w),
                          onPressed: onWhatsApp,
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(
                            minWidth: 8.w,
                            minHeight: 8.w,
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
      ),
    );
  }
}

// ===== File 3: widgets/premium_section.dart =====
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PremiumSection extends StatelessWidget {
  final List<Map<String, dynamic>> listings;
  final Function(Map<String, dynamic>) onTap;
  final Set<String> favoriteIds;
  final Function(String) onFavoriteToggle;
  
  const PremiumSection({
    required this.listings,
    required this.onTap,
    required this.favoriteIds,
    required this.onFavoriteToggle,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28.h,
      margin: EdgeInsets.only(bottom: 1.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 3.w),
        itemCount: listings.length,
        itemBuilder: (_, index) => Container(
          width: 85.w,
          margin: EdgeInsets.only(right: 3.w),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onTap(listings[index]),
              child: Column(
                children: [
                  // Premium Badge
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 1.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF0EA5E9)],
                      ),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star, color: Colors.white, size: 4.w),
                        SizedBox(width: 1.w),
                        Text(
                          'PREMIUM',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(3.w),
                      child: Row(
                        children: [
                          // Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              listings[index]['image'],
                              width: 30.w,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 30.w,
                                height: double.infinity,
                                color: Colors.grey[300],
                                child: Icon(Icons.image, color: Colors.grey[600], size: 8.w),
                              ),
                            ),
                          ),
                          SizedBox(width: 3.w),
                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            listings[index]['title'],
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12.sp,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (listings[index]['is_verified'] == true)
                                          Icon(Icons.verified, color: Color(0xFF2563EB), size: 4.w),
                                      ],
                                    ),
                                    SizedBox(height: 0.5.h),
                                    Text(
                                      listings[index]['description'] ?? '',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 9.sp,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '₹${listings[index]['price']}',
                                      style: TextStyle(
                                        color: Color(0xFF2563EB),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on_outlined, size: 3.w, color: Colors.grey[600]),
                                        SizedBox(width: 1.w),
                                        Expanded(
                                          child: Text(
                                            listings[index]['location'],
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 9.sp,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Actions
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(
                                  favoriteIds.contains(listings[index]['id']) 
                                      ? Icons.favorite 
                                      : Icons.favorite_border,
                                  color: Color(0xFF2563EB),
                                  size: 5.w,
                                ),
                                onPressed: () => onFavoriteToggle(listings[index]['id']),
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                              ),
                              Column(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.call, color: Colors.green, size: 5.w),
                                    onPressed: () {},
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(
                                      minWidth: 8.w,
                                      minHeight: 8.w,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.message, color: Colors.green, size: 5.w),
                                    onPressed: () {},
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(
                                      minWidth: 8.w,
                                      minHeight: 8.w,
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
            ),
          ),
        ),
      ),
    );
  }
}