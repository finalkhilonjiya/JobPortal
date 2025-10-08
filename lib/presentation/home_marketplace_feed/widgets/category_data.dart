import 'package:flutter/material.dart';

class CategoryData {
  static final List<Map<String, dynamic>> mainCategories = [
    {
      'name': 'All',
      'icon': Icons.apps_rounded,
      'image': 'https://cdn-icons-png.flaticon.com/512/8058/8058572.png',
      'subcategories': [],
    },
    {
      'name': 'Room for Rent',
      'icon': Icons.meeting_room_rounded,
      'image':
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQioUo2QBlK9Llqz7YSQcbLS6Jm7_6IEjGy8VLRyRtA7A&s',
      'subcategories': [
        'Single Room',
        'Shared Room',
        '1 BHK for Rent',
        '2 BHK for Rent',
        '3 BHK for Rent',
        '4 BHK for Rent',
        'Room in Apartment',
        'Room in Independent House',
      ],
    },
    {
      'name': 'PG Accommodation',
      'icon': Icons.apartment_rounded,
      'image':
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTevvagKhA9s9jkz9oLOu0HYE1SdXL5B09b4w&s',
      'subcategories': [
        'PG for Male',
        'PG for Female',
        'PG with Food',
        'PG without Food',
        'AC PG',
        'Non-AC PG',
        'Single Occupancy',
        'Shared Occupancy',
      ],
    },
    {
      'name': 'Homestays',
      'icon': Icons.cottage_rounded,
      'image':
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTMZCkXg9qb1XjGEiR2kDXZoPHY2xWXAnk_9w&s',
      'subcategories': [
        'Entire Home',
        'Private Room',
        'Shared Room',
        'Farm Stay',
        'Hill Station Stay',
        'Beach Stay',
        'Heritage Stay',
      ],
    },
    {
      'name': 'Properties for Sale',
      'icon': Icons.home_work_rounded,
      'image':
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQpfW240Q3lGejPKThC36IFQtecjL4Yi2Ml-dzErxh4MYC2O69dnH4BXZ_D&s=10',
      'subcategories': [
        'Flats / Apartments for Sale',
        'Houses / Villas for Sale',
        'Commercial Properties for Sale',
        'Office Space for Sale',
        'Shop / Showroom for Sale',
        'Land / Plots for Sale',
      ],
    },
  ];

  static List<String> getSubcategories(String category) {
    final categoryData = mainCategories.firstWhere(
      (cat) => cat['name'] == category,
      orElse: () => {'subcategories': []},
    );
    return List<String>.from(categoryData['subcategories'] ?? []);
  }

  static bool shouldShowField(String category, String field) {
    final fieldCategories = {
      'bedrooms': ['Properties for Sale', 'Room for Rent', 'Homestays'],
      'bathrooms': ['Properties for Sale', 'Room for Rent', 'Homestays'],
      'furnishingStatus': [
        'Properties for Sale',
        'Room for Rent', 
        'PG Accommodation',
        'Homestays'
      ],
      'rentAmount': ['Properties for Sale', 'Room for Rent', 'PG Accommodation', 'Homestays'],
      'deposit': ['Properties for Sale', 'Room for Rent', 'PG Accommodation'],
      'amenities': ['Properties for Sale', 'Room for Rent', 'PG Accommodation', 'Homestays'],
      'preferredTenant': ['Properties for Sale', 'Room for Rent', 'PG Accommodation'],
      'foodIncluded': ['PG Accommodation', 'Homestays'],
      'occupancyType': ['PG Accommodation'],
    };

    return fieldCategories[field]?.contains(category) ?? false;
  }
}