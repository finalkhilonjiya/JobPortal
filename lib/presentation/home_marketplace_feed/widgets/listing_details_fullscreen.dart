import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ListingDetailsFullscreen extends StatefulWidget {
  final Map<String, dynamic> listing;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;

  const ListingDetailsFullscreen({
    required this.listing,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onCall,
    required this.onWhatsApp,
  });

  @override
  State<ListingDetailsFullscreen> createState() => _ListingDetailsFullscreenState();
}

class _ListingDetailsFullscreenState extends State<ListingDetailsFullscreen> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final images = [widget.listing['image'], widget.listing['image'], widget.listing['image']];
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Image Carousel
          SliverAppBar(
            expandedHeight: 35.h,
            pinned: true,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.5),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: widget.isFavorite ? Colors.red : Colors.white,
                ),
                onPressed: widget.onFavoriteToggle,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.5),
                ),
              ),
              SizedBox(width: 2.w),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  CarouselSlider(
                    options: CarouselOptions(
                      height: double.infinity,
                      viewportFraction: 1.0,
                      onPageChanged: (index, reason) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                    ),
                    items: images.map((image) {
                      return Image.network(
                        image,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          child: Icon(Icons.image, size: 50),
                        ),
                      );
                    }).toList(),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: images.asMap().entries.map((entry) {
                        return Container(
                          width: 8,
                          height: 8,
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentImageIndex == entry.key
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.listing['title'],
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (widget.listing['is_verified'] == true)
                        Icon(Icons.verified, color: Color(0xFF2563EB)),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    '₹${widget.listing['price']}',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  
                  // Category Tags
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.listing['category'],
                          style: TextStyle(color: Color(0xFF2563EB)),
                        ),
                      ),
                      if (widget.listing['subcategory'] != null) ...[
                        SizedBox(width: 2.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(widget.listing['subcategory']),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 2.h),

                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.grey[600]),
                      SizedBox(width: 1.w),
                      Text(
                        widget.listing['location'],
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  
                  // Posted Date
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.grey[600], size: 5.w),
                      SizedBox(width: 1.w),
                      Text(
                        'Posted ${widget.listing['time_ago']}',
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),

                  // Condition
                  if (widget.listing['condition'] != null) ...[
                    _buildDetailRow('Condition', widget.listing['condition']),
                  ],
                  
                  // Additional Details based on category
                  if (widget.listing['brand'] != null)
                    _buildDetailRow('Brand', widget.listing['brand']),
                  if (widget.listing['model'] != null)
                    _buildDetailRow('Model', widget.listing['model']),
                  if (widget.listing['yearOfPurchase'] != null)
                    _buildDetailRow('Year', widget.listing['yearOfPurchase']),
                  if (widget.listing['kilometresDriven'] != null)
                    _buildDetailRow('KM Driven', widget.listing['kilometresDriven']),
                  if (widget.listing['fuelType'] != null)
                    _buildDetailRow('Fuel Type', widget.listing['fuelType']),
                  if (widget.listing['bedrooms'] != null)
                    _buildDetailRow('Bedrooms', widget.listing['bedrooms']),
                  if (widget.listing['bathrooms'] != null)
                    _buildDetailRow('Bathrooms', widget.listing['bathrooms']),
                  
                  SizedBox(height: 3.h),
                  
                  // Description
                  Text(
                    'Description',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    widget.listing['description'] ?? 'No description available',
                    style: TextStyle(fontSize: 12.sp, height: 1.5),
                  ),
                  
                  // Seller Info (if available)
                  if (widget.listing['sellerName'] != null) ...[
                    SizedBox(height: 3.h),
                    Text(
                      'Seller Information',
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 1.h),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Color(0xFF2563EB),
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(widget.listing['sellerName']),
                      subtitle: Text('Member since 2023'),
                    ),
                  ],
                  
                  SizedBox(height: 10.h), // Space for bottom buttons
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: widget.onCall,
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
                onPressed: widget.onWhatsApp,
                icon: Icon(Icons.chat),
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
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }
}