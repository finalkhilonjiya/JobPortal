import '../core/constants.dart';
import '../core/format.dart';

num _num(dynamic v, [num fallback = 0]) {
  if (v == null) return fallback;
  if (v is num) return v;
  return num.tryParse(v.toString()) ?? fallback;
}

int? _intOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

class Property {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final String purpose; // rent | sale
  final String category; // room | pg | homestay | flat | house | plot | commercial
  final num price;
  final String priceUnit; // month | night | total
  final String city;
  final String locality;
  final String address;
  final int? bedrooms;
  final int? bathrooms;
  final num? areaSqft;
  final String? furnishing;
  final List<String> amenities;
  final List<String> images;
  final String status;
  final bool isVerified;
  final bool isFeatured;
  final DateTime createdAt;

  const Property({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.purpose,
    required this.category,
    required this.price,
    required this.priceUnit,
    required this.city,
    required this.locality,
    required this.address,
    this.bedrooms,
    this.bathrooms,
    this.areaSqft,
    this.furnishing,
    this.amenities = const [],
    this.images = const [],
    this.status = 'active',
    this.isVerified = false,
    this.isFeatured = false,
    required this.createdAt,
  });

  factory Property.fromMap(Map<String, dynamic> m) {
    return Property(
      id: m['id'].toString(),
      ownerId: (m['owner_id'] ?? '').toString(),
      title: (m['title'] ?? '').toString(),
      description: (m['description'] ?? '').toString(),
      purpose: (m['purpose'] ?? 'rent').toString(),
      category: (m['category'] ?? 'flat').toString(),
      price: _num(m['price']),
      priceUnit: (m['price_unit'] ?? 'month').toString(),
      city: (m['city'] ?? '').toString(),
      locality: (m['locality'] ?? '').toString(),
      address: (m['address'] ?? '').toString(),
      bedrooms: _intOrNull(m['bedrooms']),
      bathrooms: _intOrNull(m['bathrooms']),
      areaSqft: m['area_sqft'] == null ? null : _num(m['area_sqft']),
      furnishing: m['furnishing']?.toString(),
      amenities: m['amenities'] == null
          ? const []
          : List<String>.from(m['amenities'] as List),
      images: m['images'] == null
          ? const []
          : List<String>.from(m['images'] as List),
      status: (m['status'] ?? 'active').toString(),
      isVerified: m['is_verified'] == true,
      isFeatured: m['is_featured'] == true,
      createdAt:
          DateTime.tryParse((m['created_at'] ?? '').toString()) ?? DateTime.now(),
    );
  }

  String get priceLabel =>
      formatPrice(price, purpose: purpose, unit: priceUnit);

  String get categoryLabel => kCategories[category] ?? category;

  String get purposeLabel => purpose == 'sale' ? 'For sale' : 'For rent';

  String get place {
    if (locality.isNotEmpty && city.isNotEmpty) return '$locality, $city';
    return locality.isNotEmpty ? locality : city;
  }

  String? get coverImage => images.isEmpty ? null : images.first;
}
