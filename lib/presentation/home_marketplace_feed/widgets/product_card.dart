// ===== File 2: widgets/product_card.dart (1.5x bigger, icons only) =====
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
      margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      height: 22.h, // 1.5x bigger (was 15.h)
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Row(
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    data['image'],
                    width: 35.w,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 35.w,
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
                      // Title and Verified Badge
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  data['title'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11.sp, // reduced
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (data['is_verified'] == true)
                                Padding(
                                  padding: EdgeInsets.only(left: 1.w),
                                  child: Icon(Icons.verified, color: Color(0xFF2563EB), size: 5.w),
                                ),
                            ],
                          ),
                          SizedBox(height: 0.5.h),
                          if (data['subcategory'] != null && data['subcategory'].toString().isNotEmpty)
                            Text(
                              data['subcategory'],
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          Text(
                            '₹${data['price']}',
                            style: TextStyle(
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.bold,
                              fontSize: 13.sp, // reduced
                            ),
                          ),
                        ],
                      ),
                      // Location and Time
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 4.w, color: Colors.grey[600]),
                              SizedBox(width: 1.w),
                              Expanded(
                                child: Text(
                                  data['location'],
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 10.sp,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            data['time_ago'],
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 9.sp,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions Column
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey[600],
                        size: 6.w,
                      ),
                      onPressed: onFavoriteToggle,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        minWidth: 10.w,
                        minHeight: 10.w,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.call, color: Colors.green, size: 5.w),
                            onPressed: onCall,
                            padding: EdgeInsets.all(2.w),
                            constraints: BoxConstraints(
                              minWidth: 10.w,
                              minHeight: 10.w,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 5.w,
                            color: Colors.green.withOpacity(0.3),
                          ),
                          IconButton(
                            icon: Icon(FontAwesomeIcons.whatsapp, color: Colors.green, size: 5.w),
                            onPressed: onWhatsApp,
                            padding: EdgeInsets.all(2.w),
                            constraints: BoxConstraints(
                              minWidth: 10.w,
                              minHeight: 10.w,
                            ),
                          ),
                        ],
                      ),
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