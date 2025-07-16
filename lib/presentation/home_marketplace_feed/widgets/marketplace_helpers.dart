import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MarketplaceHelpers {
  static List<Map<String, Object>> getMockCategories() {
    return [
      {'name': 'All', 'icon': Icons.grid_view_rounded, 'color': Color(0xFF2563EB)},
      {'name': 'Electronics', 'icon': Icons.devices_other_rounded, 'color': Color(0xFF2563EB)},
      {'name': 'Vehicles', 'icon': Icons.directions_car_filled_rounded, 'color': Color(0xFF2563EB)},
      {'name': 'Jobs', 'icon': Icons.work_outline_rounded, 'color': Color(0xFF2563EB)},
      {'name': 'Properties', 'icon': Icons.apartment_rounded, 'color': Color(0xFF2563EB)},
      {'name': 'Fashion', 'icon': Icons.checkroom_rounded, 'color': Color(0xFF2563EB)},
      {'name': 'Home', 'icon': Icons.home_rounded, 'color': Color(0xFF2563EB)},
    ];
  }
  
  static List<Map<String, dynamic>> getMockListings() {
    return [
      {
        'id': '1',
        'title': 'iPhone 14 Pro Max 256GB',
        'price': 89999,
        'location': 'Guwahati, Assam',
        'category': 'Electronics',
        'image': 'https://picsum.photos/400/300?random=1',
        'is_featured': true,
        'is_verified': true,
        'time_ago': '2 hours ago',
        'phone': '+919876543210',
        'description': 'Brand new condition, with warranty. Original box and all accessories included.',
      },
      {
        'id': '2',
        'title': 'Honda City 2020 Model',
        'price': 850000,
        'location': 'Dibrugarh, Assam',
        'category': 'Vehicles',
        'image': 'https://picsum.photos/400/300?random=2',
        'is_featured': true,
        'is_verified': true,
        'time_ago': '4 hours ago',
        'phone': '+919876543211',
        'description': 'Single owner, excellent condition. Full service history available.',
      },
      {
        'id': '3',
        'title': 'Web Developer Position',
        'price': 45000,
        'location': 'Remote, India',
        'category': 'Jobs',
        'image': 'https://picsum.photos/400/300?random=3',
        'is_featured': true,
        'is_verified': false,
        'time_ago': '1 day ago',
        'phone': '+919876543212',
        'description': 'Full-time position, 2+ years experience required. Good growth opportunities.',
      },
      {
        'id': '4',
        'title': '2BHK Apartment for Rent',
        'price': 15000,
        'location': 'Jorhat, Assam',
        'category': 'Properties',
        'image': 'https://picsum.photos/400/300?random=4',
        'is_featured': false,
        'is_verified': true,
        'time_ago': '3 hours ago',
        'phone': '+919876543213',
        'description': 'Fully furnished, parking available. Near schools and markets.',
      },
      {
        'id': '5',
        'title': 'Samsung Galaxy S23 Ultra',
        'price': 124999,
        'location': 'Tezpur, Assam',
        'category': 'Electronics',
        'image': 'https://picsum.photos/400/300?random=5',
        'is_featured': false,
        'is_verified': false,
        'time_ago': '5 hours ago',
        'phone': '+919876543214',
        'description': 'Sealed pack, all colors available. Bill and warranty included.',
      },
      {
        'id': '6',
        'title': 'Traditional Assamese Mekhela',
        'price': 3500,
        'location': 'Guwahati, Assam',
        'category': 'Fashion',
        'image': 'https://picsum.photos/400/300?random=6',
        'is_featured': false,
        'is_verified': true,
        'time_ago': '6 hours ago',
        'phone': '+919876543215',
        'description': 'Pure silk, handwoven design. Perfect for occasions.',
      },
      {
        'id': '7',
        'title': 'Wooden Dining Table Set',
        'price': 25000,
        'location': 'Silchar, Assam',
        'category': 'Home',
        'image': 'https://picsum.photos/400/300?random=7',
        'is_featured': false,
        'is_verified': false,
        'time_ago': '1 day ago',
        'phone': '+919876543216',
        'description': '6-seater, solid wood construction. Excellent condition.',
      },
      {
        'id': '8',
        'title': 'MacBook Air M2',
        'price': 119900,
        'location': 'Guwahati, Assam',
        'category': 'Electronics',
        'image': 'https://picsum.photos/400/300?random=8',
        'is_featured': false,
        'is_verified': true,
        'time_ago': '2 days ago',
        'phone': '+919876543217',
        'description': '8GB RAM, 256GB SSD, Space Grey. AppleCare+ available.',
      },
    ];
  }
  
  static List<Map<String, dynamic>> getRecentlyViewed() {
    return getMockListings().take(5).toList();
  }
  
  static List<String> getTrendingSearches() {
    return [
      'iPhone',
      'Scooty',
      'PG in Guwahati',
      'Part time jobs',
      'Used cars',
      'Laptop',
      'Furniture',
      'Books',
    ];
  }
  
  static Future<void> makePhoneCall(BuildContext context, String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch phone call')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error making phone call')),
        );
      }
    }
  }

  static Future<void> openWhatsApp(BuildContext context, String phoneNumber) async {
    final whatsappUrl = "https://wa.me/${phoneNumber.replaceAll(RegExp(r'[^\d]'), '')}";
    try {
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('WhatsApp not installed')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening WhatsApp')),
        );
      }
    }
  }
}

// ===== File 2: widgets/search_bottom_sheet.dart (Updated) =====
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SearchBottomSheet extends StatefulWidget {
  final List<String> trendingSearches;
  final Function(String, String) onSearch;
  
  const SearchBottomSheet({
    Key? key,
    required this.trendingSearches,
    required this.onSearch,
  }) : super(key: key);
  
  @override
  _SearchBottomSheetState createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends State<SearchBottomSheet> {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  List<String> _locationSuggestions = [
    'Guwahati, Assam',
    'Dibrugarh, Assam',
    'Jorhat, Assam',
    'Tezpur, Assam',
    'Silchar, Assam',
  ];
  
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
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search',
                      style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 2.h),
                    
                    // Search Input
                    TextField(
                      controller: _itemController,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'What are you looking for?',
                        hintText: 'e.g., iPhone, Car, Apartment',
                        prefixIcon: Icon(Icons.search, color: Color(0xFF2563EB)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xFF2563EB), width: 2),
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    
                    // Location Input with Autocomplete
                    TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'Location',
                        hintText: 'e.g., Guwahati, Assam',
                        prefixIcon: Icon(Icons.location_on, color: Color(0xFF2563EB)),
                        suffixIcon: Icon(Icons.my_location, color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xFF2563EB), width: 2),
                        ),
                      ),
                    ),
                    
                    // Location Suggestions
                    SizedBox(height: 1.h),
                    Wrap(
                      spacing: 2.w,
                      children: _locationSuggestions.map((location) => InkWell(
                        onTap: () {
                          _locationController.text = location;
                        },
                        child: Chip(
                          label: Text(
                            location,
                            style: TextStyle(fontSize: 9.sp),
                          ),
                          backgroundColor: Colors.grey[100],
                        ),
                      )).toList(),
                    ),
                    
                    SizedBox(height: 3.h),
                    
                    // Advanced Filters Button
                    OutlinedButton.icon(
                      onPressed: () {
                        // Show advanced filters
                      },
                      icon: Icon(Icons.filter_list),
                      label: Text('Advanced Filters'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Color(0xFF2563EB),
                        side: BorderSide(color: Color(0xFF2563EB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 3.h),
                    
                    // Trending Searches
                    Text(
                      'Trending Searches',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Wrap(
                      spacing: 2.w,
                      runSpacing: 1.h,
                      children: widget.trendingSearches.map((search) => InkWell(
                        onTap: () {
                          _itemController.text = search;
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                          decoration: BoxDecoration(
                            color: Color(0xFF2563EB).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Color(0xFF2563EB).withOpacity(0.3)),
                          ),
                          child: Text(
                            search,
                            style: TextStyle(
                              color: Color(0xFF2563EB),
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )).toList(),
                    ),
                    
                    SizedBox(height: 4.h),
                    
                    // Search Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onSearch(_itemController.text, _locationController.text);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2563EB),
                          padding: EdgeInsets.symmetric(vertical: 1.8.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Search',
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _itemController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}