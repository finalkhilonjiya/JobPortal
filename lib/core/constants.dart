import 'package:flutter/material.dart';

class Cat {
  final String key;
  final String label;
  final IconData icon;
  final String group; // residential | commercial | land | stay
  const Cat(this.key, this.label, this.icon, this.group);
}

const List<Cat> kCategories = [
  Cat('flat', 'Flat / Apartment', Icons.apartment_rounded, 'residential'),
  Cat('house', 'House', Icons.home_rounded, 'residential'),
  Cat('villa', 'Villa', Icons.villa_rounded, 'residential'),
  Cat('room', 'Room', Icons.meeting_room_rounded, 'residential'),
  Cat('pg', 'PG', Icons.bed_rounded, 'stay'),
  Cat('hostel', 'Hostel', Icons.night_shelter_rounded, 'stay'),
  Cat('coliving', 'Co-living', Icons.groups_rounded, 'stay'),
  Cat('homestay', 'Homestay', Icons.holiday_village_rounded, 'stay'),
  Cat('plot', 'Plot', Icons.landscape_rounded, 'land'),
  Cat('agri_land', 'Agri land', Icons.grass_rounded, 'land'),
  Cat('shop', 'Shop', Icons.storefront_rounded, 'commercial'),
  Cat('office', 'Office', Icons.business_center_rounded, 'commercial'),
  Cat('commercial_building', 'Commercial building', Icons.domain_rounded, 'commercial'),
  Cat('warehouse', 'Warehouse', Icons.warehouse_rounded, 'commercial'),
  Cat('project', 'New project', Icons.construction_rounded, 'residential'),
];

Cat catOf(String key) =>
    kCategories.firstWhere((c) => c.key == key, orElse: () => kCategories.first);

const Set<String> kStayCats = {'pg', 'hostel', 'coliving', 'homestay', 'room'};
const Set<String> kLandCats = {'plot', 'agri_land'};
const Set<String> kNoBedroomCats = {'plot', 'agri_land', 'shop', 'office', 'commercial_building', 'warehouse'};

const Map<String, String> kPurposeLabels = {'rent': 'Rent', 'sale': 'Buy', 'lease': 'Lease'};

const List<String> kAmenities = [
  'Lift', 'Parking', 'Power backup', 'Security', 'CCTV', 'Wi-Fi', 'Air conditioning',
  'Geyser', 'Water supply', 'Balcony', 'Kitchen', 'Meals included', 'Laundry',
  'Attached bathroom', 'Gym', 'Swimming pool', 'Garden', 'Clubhouse', 'Play area',
];

const List<String> kFurnishing = ['unfurnished', 'semi', 'furnished'];
const Map<String, String> kFurnishingLabel = {
  'unfurnished': 'Unfurnished',
  'semi': 'Semi-furnished',
  'furnished': 'Fully furnished',
};

const List<String> kFacing = ['North', 'South', 'East', 'West', 'North-East', 'North-West', 'South-East', 'South-West'];

const List<String> kRoles = ['tenant', 'buyer', 'owner', 'seller', 'landlord', 'agent', 'broker', 'builder'];
const Map<String, String> kRoleLabel = {
  'tenant': 'Tenant',
  'buyer': 'Buyer',
  'owner': 'Owner',
  'seller': 'Seller',
  'landlord': 'Landlord',
  'agent': 'Agent',
  'broker': 'Broker',
  'builder': 'Builder / Developer',
  'admin': 'Admin',
};
const Set<String> kProRoles = {'agent', 'broker', 'builder'};

const List<String> kLeadStatuses = [
  'new', 'contacted', 'interested', 'visit_scheduled', 'negotiation', 'converted', 'rejected'
];
const Map<String, String> kLeadLabel = {
  'new': 'New',
  'contacted': 'Contacted',
  'interested': 'Interested',
  'visit_scheduled': 'Visit scheduled',
  'negotiation': 'Negotiation',
  'converted': 'Converted',
  'rejected': 'Rejected',
};

const Map<String, String> kPromoPlans = {
  'featured_7': 'Featured - 7 days',
  'featured_30': 'Featured - 30 days',
  'top_30': 'Top of search - 30 days',
};

const List<String> kPopularCities = [
  'Guwahati', 'Bongaigaon', 'Goalpara', 'Dhubri', 'Kokrajhar', 'Jorhat', 'Dibrugarh', 'Silchar',
  'Delhi', 'Mumbai', 'Bengaluru', 'Hyderabad', 'Chennai', 'Kolkata', 'Pune',
];

const List<String> kReportReasons = [
  'Fake or misleading listing', 'Wrong price', 'Already rented / sold', 'Wrong photos',
  'Broker posing as owner', 'Abusive behaviour', 'Other',
];

const List<String> kSortKeys = ['newest', 'price_low', 'price_high', 'area_high'];
const Map<String, String> kSortLabel = {
  'newest': 'Newest first',
  'price_low': 'Price: low to high',
  'price_high': 'Price: high to low',
  'area_high': 'Largest area',
};
