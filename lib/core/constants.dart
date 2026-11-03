import 'package:flutter/material.dart';

/// purpose -> label
const Map<String, String> kPurposes = {
  'rent': 'Rent',
  'sale': 'Buy',
};

/// category -> label
const Map<String, String> kCategories = {
  'room': 'Room',
  'pg': 'PG',
  'homestay': 'Homestay',
  'flat': 'Flat',
  'house': 'House',
  'plot': 'Plot',
  'commercial': 'Commercial',
};

const Map<String, IconData> kCategoryIcons = {
  'room': Icons.meeting_room_outlined,
  'pg': Icons.bed_outlined,
  'homestay': Icons.cottage_outlined,
  'flat': Icons.apartment_outlined,
  'house': Icons.home_outlined,
  'plot': Icons.landscape_outlined,
  'commercial': Icons.storefront_outlined,
};

const Map<String, String> kFurnishing = {
  'unfurnished': 'Unfurnished',
  'semi': 'Semi-furnished',
  'furnished': 'Furnished',
};

const List<String> kAmenities = [
  'Wi-Fi',
  'Parking',
  'Power backup',
  'Water supply',
  'Lift',
  'Security',
  'CCTV',
  'Air conditioning',
  'Geyser',
  'Attached bathroom',
  'Kitchen',
  'Meals included',
  'Laundry',
  'Balcony',
];

const List<String> kCities = [
  'Guwahati',
  'Bongaigaon',
  'Goalpara',
  'Dhubri',
  'Kokrajhar',
  'Jorhat',
  'Dibrugarh',
  'Silchar',
  'Delhi',
  'Mumbai',
  'Bengaluru',
  'Kolkata',
  'Hyderabad',
  'Pune',
  'Chennai',
];

const List<String> kReportReasons = [
  'Fake or misleading listing',
  'Wrong price or details',
  'Already rented or sold',
  'Spam or duplicate',
  'Offensive content',
];

String defaultPriceUnit(String purpose, String category) {
  if (purpose == 'sale') return 'total';
  if (category == 'homestay') return 'night';
  return 'month';
}
