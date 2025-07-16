// ===== File 2: widgets/notification_strip.dart (continued) =====
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class NotificationStrip extends StatelessWidget {
  final String message;
  final VoidCallback onClose;
  
  const NotificationStrip({
    Key? key,
    required this.message,
    required this.onClose,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      color: Color(0xFF2563EB),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.white, size: 4.w),
            onPressed: onClose,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ===== File 3: widgets/trending_searches_widget.dart =====
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TrendingSearchesWidget extends StatelessWidget {
  final List<String> searches;
  final Function(String) onSearchTap;
  
  const TrendingSearchesWidget({
    Key? key,
    required this.searches,
    required this.onSearchTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Color(0xFF2563EB), size: 5.w),
              SizedBox(width: 2.w),
              Text(
                'Trending Searches',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: searches.map((search) => InkWell(
              onTap: () => onSearchTap(search),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
                decoration: BoxDecoration(
                  color: Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Color(0xFF2563EB).withOpacity(0.3)),
                ),
                child: Text(
                  search,
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ===== File 4: widgets/recently_viewed_section.dart =====
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class RecentlyViewedSection extends StatelessWidget {
  final List<Map<String, dynamic>> listings;
  final Function(Map<String, dynamic>) onTap;
  
  const RecentlyViewedSection({
    Key? key,
    required this.listings,
    required this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 3.w),
            child: Text(
              'Recently Viewed',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          SizedBox(height: 1.h),
          Container(
            height: 12.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              itemCount: listings.length,
              itemBuilder: (context, index) => Container(
                width: 25.w,
                margin: EdgeInsets.only(right: 2.w),
                child: InkWell(
                  onTap: () => onTap(listings[index]),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            listings[index]['image'],
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[300],
                              child: Icon(Icons.image, color: Colors.grey[600]),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        '₹${listings[index]['price']}',
                        style: TextStyle(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      Text(
                        listings[index]['title'],
                        style: TextStyle(
                          fontSize: 8.sp,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== File 5: widgets/categories_section.dart (Updated) =====
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class CategoriesSection extends StatelessWidget {
  final List<Map<String, Object>> categories;
  final String selected;
  final void Function(String) onSelect;
  
  const CategoriesSection({
    Key? key,
    required this.categories, 
    required this.selected, 
    required this.onSelect
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 10.h,
      margin: EdgeInsets.symmetric(vertical: 0.5.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 3.w),
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
                    width: 12.w,
                    height: 12.w,
                    decoration: BoxDecoration(
                      color: isSelected ? Color(0xFF2563EB) : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Color(0xFF2563EB) : Colors.grey[300]!,
                        width: 2,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: Color(0xFF2563EB).withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ] : [],
                    ),
                    child: Icon(
                      cat['icon'] as IconData,
                      color: isSelected ? Colors.white : Color(0xFF2563EB),
                      size: 5.w,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    cat['name'] as String,
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: isSelected ? Color(0xFF2563EB) : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ===== File 6: widgets/listing_details_sheet.dart (Updated) =====
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ListingDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> listing;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;
  final VoidCallback onReport;
  
  const ListingDetailsSheet({
    Key? key,
    required this.listing,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onCall,
    required this.onWhatsApp,
    required this.onReport,
  }) : super(key: key);
  
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
            width: 10.w,
            height: 0.5.h,
            margin: EdgeInsets.symmetric(vertical: 1.h),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 35.h,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        Image.network(
                          listing['image'],
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[300],
                            child: Icon(Icons.image, color: Colors.grey[600], size: 60),
                          ),
                        ),
                        Positioned(
                          top: 1.h,
                          right: 1.h,
                          child: IconButton(
                            icon: Icon(Icons.flag_outlined, color: Colors.white),
                            onPressed: onReport,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '₹${listing['price']}',
                                        style: TextStyle(
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                      if (listing['is_verified'] == true) ...[
                                        SizedBox(width: 2.w),
                                        Icon(Icons.verified, color: Color(0xFF2563EB), size: 5.w),
                                      ],
                                    ],
                                  ),
                                  SizedBox(height: 1.h),
                                  Text(
                                    listing['title'],
                                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: Color(0xFF2563EB),
                                size: 7.w,
                              ),
                              onPressed: onFavoriteToggle,
                            ),
                          ],
                        ),
                        SizedBox(height: 1.h),
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.grey[600], size: 4.w),
                            SizedBox(width: 1.w),
                            Text(
                              listing['location'],
                              style: TextStyle(color: Colors.grey[600], fontSize: 11.sp),
                            ),
                            SizedBox(width: 4.w),
                            Icon(Icons.access_time, color: Colors.grey[600], size: 4.w),
                            SizedBox(width: 1.w),
                            Text(
                              listing['time_ago'],
                              style: TextStyle(color: Colors.grey[600], fontSize: 11.sp),
                            ),
                          ],
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Description',
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          listing['description'] ?? 'No description available',
                          style: TextStyle(fontSize: 12.sp, height: 1.5),
                        ),
                        SizedBox(height: 3.h),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: onCall,
                                icon: Icon(Icons.call),
                                label: Text('Call'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: onWhatsApp,
                                icon: Icon(Icons.message),
                                label: Text('WhatsApp'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}