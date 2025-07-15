// ===== File 5: utils/marketplace_helpers.dart =====
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
        'time_ago': '2 days ago',
        'phone': '+919876543217',
        'description': '8GB RAM, 256GB SSD, Space Grey. AppleCare+ available.',
      },
    ];
  }
  
  static Future<void> makePhoneCall(BuildContext context, String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch phone call')),
      );
    }
  }

  static Future<void> openWhatsApp(BuildContext context, String phoneNumber) async {
    final whatsappUrl = "https://wa.me/${phoneNumber.replaceAll(RegExp(r'[^\d]'), '')}";
    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('WhatsApp not installed')),
      );
    }
  }
}