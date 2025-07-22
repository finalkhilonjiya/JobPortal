import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
    return Container(
      height: 25.h,
      margin: EdgeInsets.only(bottom: 2.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
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
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.all(3.w),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            listings[index]['image'],
                            width: 120,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 120,
                              height: double.infinity,
                              color: Colors.grey[300],
                              child: Icon(Icons.image, color: Colors.grey[600], size: 40),
                            ),
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title
                                  Text(
                                    listings[index]['title'],
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  // Category > Subcategory
                                  Text(
                                    '${listings[index]['category']} > ${listings[index]['subcategory']}',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  // Condition
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getConditionColor(listings[index]['condition']).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _formatCondition(listings[index]['condition']),
                                      style: TextStyle(
                                        color: _getConditionColor(listings[index]['condition']),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Price
                                  Text(
                                    '₹${listings[index]['price']}',
                                    style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                  // Location
                                  Row(
                                    children: [
                                      Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                                      SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          listings[index]['location'],
                                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Distance if available
                                  if (listings[index]['distance'] != null)
                                    Container(
                                      margin: EdgeInsets.only(top: 4),
                                      child: Row(
                                        children: [
                                          Icon(Icons.directions_walk, size: 12, color: Colors.blue),
                                          SizedBox(width: 4),
                                          Text(
                                            '${listings[index]['distance'].toStringAsFixed(1)} km away',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.blue,
                                              fontWeight: FontWeight.w500,
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
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Favorite button
                            IconButton(
                              icon: Icon(
                                favoriteIds.contains(listings[index]['id']) ? Icons.favorite : Icons.favorite_border,
                                color: Color(0xFF2563EB),
                              ),
                              onPressed: () => onFavoriteToggle(listings[index]['id']),
                            ),
                            // Action buttons
                            Column(
                              children: [
                                // Call button
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.phone, color: Colors.green, size: 20),
                                    onPressed: () => onCall(listings[index]['phone'] ?? ''),
                                    constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                                    padding: EdgeInsets.all(6),
                                  ),
                                ),
                                SizedBox(height: 8),
                                // WhatsApp button
                                Container(
                                  decoration: BoxDecoration(
                                    color: Color(0xFF25D366).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    icon: FaIcon(FontAwesomeIcons.whatsapp, color: Color(0xFF25D366), size: 20),
                                    onPressed: () => onWhatsApp(listings[index]['phone'] ?? ''),
                                    constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                                    padding: EdgeInsets.all(6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Premium tag in top-left corner
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                          Icon(Icons.star, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'PREMIUM',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
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
        ),
      ),
    );
  }

  Color _getConditionColor(String? condition) {
    switch (condition?.toLowerCase()) {
      case 'new':
        return Colors.green;
      case 'like_new':
        return Colors.teal;
      case 'good':
        return Colors.blue;
      case 'fair':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatCondition(String? condition) {
    if (condition == null) return 'Used';
    return condition.replaceAll('_', ' ').split(' ').map((word) => 
      word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : ''
    ).join(' ');
  }
}