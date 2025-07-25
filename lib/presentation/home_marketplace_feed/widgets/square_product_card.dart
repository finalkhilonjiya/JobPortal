import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SquareProductCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onTap;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;

  const SquareProductCard({
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
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: InkWell(
        onTap: onTap,
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            height: 42.h, // Total height
            child: Column(
              children: [
                // Image Section - 60%
                Container(
                  height: 25.2.h,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          data['image'],
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[300],
                            child: Center(
                              child: Icon(Icons.image, color: Colors.grey[600], size: 10.w),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: isFavorite ? Colors.red : Colors.white,
                              size: 6.w,
                            ),
                            onPressed: onFavoriteToggle,
                            padding: EdgeInsets.all(0),
                            constraints: BoxConstraints(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Details Section - 40%
                Container(
                  height: 16.8.h,
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        data['title'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11.sp,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 0.3.h),

                      // Category
                      if (data['category_name'] != null || data['category'] != null)
                        Text(
                          data['category_name'] ?? data['category'] ?? '',
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                      // Subcategory
                      if (data['subcategory_name'] != null || data['subcategory'] != null)
                        Text(
                          data['subcategory_name'] ?? data['subcategory'] ?? '',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 8.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                      Spacer(),

                      // Price, Location, Buttons
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Price + Location
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${data['price']}',
                                  style: TextStyle(
                                    color: Color(0xFF2563EB),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.sp,
                                  ),
                                ),
                                SizedBox(height: 0.3.h),
                                Row(
                                  children: [
                                    Icon(Icons.location_on_outlined, size: 3.5.w, color: Colors.grey[600]),
                                    SizedBox(width: 1.w),
                                    Expanded(
                                      child: Text(
                                        data['location'],
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 8.sp,
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

                          // Distance, Call & WhatsApp buttons
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Distance display
                              if (data['distance'] != null)
                                Container(
                                  margin: EdgeInsets.only(bottom: 0.5.h),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.directions_walk,
                                        size: 3.5.w,
                                        color: Color(0xFF2563EB),
                                      ),
                                      SizedBox(width: 0.5.w),
                                      Text(
                                        '${data['distance'] < 1 ? (data['distance'] * 1000).toStringAsFixed(0) + ' m' : data['distance'].toStringAsFixed(1) + ' km'} away',
                                        style: TextStyle(
                                          color: Color(0xFF2563EB),
                                          fontSize: 8.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              // Call & WhatsApp buttons
                              Row(
                                children: [
                                  InkWell(
                                    onTap: onCall,
                                    child: Container(
                                      padding: EdgeInsets.all(2.w),
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.green),
                                      ),
                                      child: Icon(Icons.call, color: Colors.green, size: 5.w),
                                    ),
                                  ),
                                  SizedBox(width: 2.w),
                                  InkWell(
                                    onTap: onWhatsApp,
                                    child: Container(
                                      padding: EdgeInsets.all(2.w),
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.green),
                                      ),
                                      child: FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green, size: 5.w),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
      ),
    );
  }
}