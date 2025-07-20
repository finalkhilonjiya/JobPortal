import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

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
            height: 48.h, // Increased from ~40h to 48h (20% increase)
            child: Column(
              children: [
                // Image Section - Top Half
                Container(
                  height: 24.h, // Increased proportionally
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
                            child: Icon(Icons.image, color: Colors.grey[600], size: 10.w),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.white,
                            size: 6.w,
                          ),
                          onPressed: onFavoriteToggle,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withOpacity(0.5),
                            padding: EdgeInsets.all(1.w),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Details Section - Bottom Half
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(3.w),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              data['title'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12.sp,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 1.h),
                            // Category
                            if (data['category'] != null)
                              Text(
                                'Category: ${data['category']}',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 10.sp,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            SizedBox(height: 0.5.h),
                            // Subcategory
                            if (data['subcategory'] != null)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  data['subcategory'],
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 9.sp,
                                  ),
                                ),
                              ),
                            SizedBox(height: 1.h),
                            // Price
                            Text(
                              '₹${data['price']}',
                              style: TextStyle(
                                color: Color(0xFF2563EB),
                                fontWeight: FontWeight.bold,
                                fontSize: 14.sp,
                              ),
                            ),
                            SizedBox(height: 0.5.h),
                            // Location
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined, size: 3.5.w, color: Colors.grey[600]),
                                SizedBox(width: 1.w),
                                Expanded(
                                  child: Text(
                                    data['location'],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 9.sp,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Call and WhatsApp Icons - Bottom Right
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Row(
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
                                  child: Icon(Icons.whatsapp, color: Colors.green, size: 5.w),
                                ),
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
          ),
        ),
      ),
    );
  }
}