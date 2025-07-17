// ===== File 3: widgets/marketplace/listing_details_sheet.dart =====
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ListingDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> listing;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;
  final VoidCallback? onReport;
  
  const ListingDetailsSheet({
    required this.listing,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onCall,
    required this.onWhatsApp,
    this.onReport,
  });
  
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
            width: 40,
            height: 4,
            margin: EdgeInsets.symmetric(vertical: 12),
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
                    height: 300,
                    width: double.infinity,
                    child: Image.network(
                      listing['image'],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.image, color: Colors.grey[600], size: 60),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₹${listing['price']}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: Color(0xFF2563EB),
                                size: 28,
                              ),
                              onPressed: onFavoriteToggle,
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          listing['title'],
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.grey[600], size: 16),
                            SizedBox(width: 4),
                            Text(
                              listing['location'],
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            SizedBox(width: 16),
                            Icon(Icons.access_time, color: Colors.grey[600], size: 16),
                            SizedBox(width: 4),
                            Text(
                              listing['time_ago'],
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Description',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          listing['description'] ?? 'No description available',
                          style: TextStyle(fontSize: 16, height: 1.5),
                        ),
                        SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: onCall,
                                icon: Icon(Icons.call),
                                label: Text('Call'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: onWhatsApp,
                                icon: Icon(Icons.message),
                                label: Text('WhatsApp'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        if (onReport != null)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: onReport,
                              icon: Icon(Icons.flag, color: Colors.red),
                              label: Text('Report', style: TextStyle(color: Colors.red)),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
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
    );
  }
}
