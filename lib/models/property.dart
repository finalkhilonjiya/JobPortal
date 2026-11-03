import '../core/constants.dart';
import '../core/format.dart';

num? _n(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  return num.tryParse(v.toString());
}

int? _i(dynamic v) => _n(v)?.toInt();
double? _d(dynamic v) => _n(v)?.toDouble();
List<String> _sl(dynamic v) =>
    v is List ? v.map((e) => e.toString()).toList() : <String>[];

class Property {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final String purpose;
  final String category;
  final num price;
  final String priceUnit;
  final num? securityDeposit;
  final num? maintenance;
  final String city;
  final String locality;
  final String address;
  final String pincode;
  final String landmark;
  final double? latitude;
  final double? longitude;
  final int? bedrooms;
  final int? bathrooms;
  final int? balconies;
  final num? areaSqft;
  final num? carpetArea;
  final num? builtupArea;
  final num? superBuiltupArea;
  final int? floorNo;
  final int? totalFloors;
  final int? ageYears;
  final String constructionStatus;
  final String possessionDate;
  final String facing;
  final String parking;
  final bool hasLift;
  final String ownership;
  final String reraNumber;
  final String listedBy;
  final bool noBrokerage;
  final String projectName;
  final String builderName;
  final String furnishing;
  final List<String> amenities;
  final List<String> nearby;
  final List<String> images;
  final List<String> floorPlans;
  final String videoUrl;
  final String tourUrl;
  final String pgGender;
  final String food;
  final String sharing;
  final num? previousPrice;
  final String status;
  final bool isVerified;
  final bool isFeatured;
  final int views;
  final int listingCode;
  final String rejectReason;
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
    this.securityDeposit,
    this.maintenance,
    required this.city,
    required this.locality,
    required this.address,
    required this.pincode,
    required this.landmark,
    this.latitude,
    this.longitude,
    this.bedrooms,
    this.bathrooms,
    this.balconies,
    this.areaSqft,
    this.carpetArea,
    this.builtupArea,
    this.superBuiltupArea,
    this.floorNo,
    this.totalFloors,
    this.ageYears,
    required this.constructionStatus,
    required this.possessionDate,
    required this.facing,
    required this.parking,
    required this.hasLift,
    required this.ownership,
    required this.reraNumber,
    required this.listedBy,
    required this.noBrokerage,
    required this.projectName,
    required this.builderName,
    required this.furnishing,
    required this.amenities,
    required this.nearby,
    required this.images,
    required this.floorPlans,
    required this.videoUrl,
    required this.tourUrl,
    required this.pgGender,
    required this.food,
    required this.sharing,
    this.previousPrice,
    required this.status,
    required this.isVerified,
    required this.isFeatured,
    required this.views,
    required this.listingCode,
    required this.rejectReason,
    required this.createdAt,
  });

  factory Property.fromMap(Map<String, dynamic> m) {
    String s(String k) => (m[k] ?? '').toString();
    return Property(
      id: s('id'),
      ownerId: s('owner_id'),
      title: s('title'),
      description: s('description'),
      purpose: s('purpose').isEmpty ? 'rent' : s('purpose'),
      category: s('category').isEmpty ? 'flat' : s('category'),
      price: _n(m['price']) ?? 0,
      priceUnit: s('price_unit').isEmpty ? 'month' : s('price_unit'),
      securityDeposit: _n(m['security_deposit']),
      maintenance: _n(m['maintenance']),
      city: s('city'),
      locality: s('locality'),
      address: s('address'),
      pincode: s('pincode'),
      landmark: s('landmark'),
      latitude: _d(m['latitude']),
      longitude: _d(m['longitude']),
      bedrooms: _i(m['bedrooms']),
      bathrooms: _i(m['bathrooms']),
      balconies: _i(m['balconies']),
      areaSqft: _n(m['area_sqft']),
      carpetArea: _n(m['carpet_area']),
      builtupArea: _n(m['builtup_area']),
      superBuiltupArea: _n(m['super_builtup_area']),
      floorNo: _i(m['floor_no']),
      totalFloors: _i(m['total_floors']),
      ageYears: _i(m['age_years']),
      constructionStatus: s('construction_status'),
      possessionDate: s('possession_date'),
      facing: s('facing'),
      parking: s('parking'),
      hasLift: m['has_lift'] == true,
      ownership: s('ownership'),
      reraNumber: s('rera_number'),
      listedBy: s('listed_by').isEmpty ? 'owner' : s('listed_by'),
      noBrokerage: m['no_brokerage'] == true,
      projectName: s('project_name'),
      builderName: s('builder_name'),
      furnishing: s('furnishing'),
      amenities: _sl(m['amenities']),
      nearby: _sl(m['nearby']),
      images: _sl(m['images']),
      floorPlans: _sl(m['floor_plans']),
      videoUrl: s('video_url'),
      tourUrl: s('tour_url'),
      pgGender: s('pg_gender'),
      food: s('food'),
      sharing: s('sharing'),
      previousPrice: _n(m['previous_price']),
      status: s('status').isEmpty ? 'active' : s('status'),
      isVerified: m['is_verified'] == true,
      isFeatured: m['is_featured'] == true,
      views: _i(m['views']) ?? 0,
      listingCode: _i(m['listing_code']) ?? 0,
      rejectReason: s('reject_reason'),
      createdAt: DateTime.tryParse(s('created_at'))?.toLocal() ?? DateTime.now(),
    );
  }

  num? get bestArea => areaSqft ?? superBuiltupArea ?? builtupArea ?? carpetArea;
  String get priceLabel => formatPrice(price, purpose: purpose, unit: priceUnit);
  bool get isRent => purpose != 'sale';
  bool get isStay => kStayCats.contains(category);
  bool get isLand => kLandCats.contains(category);
  bool get hasBedrooms => !kNoBedroomCats.contains(category);
  bool get priceDropped =>
      previousPrice != null && previousPrice! > price;
  String get catLabel => catOf(category).label;
  String get cover => images.isNotEmpty ? images.first : '';
  String get place => locality.isEmpty ? city : '$locality, $city';
  String get code => listingCode > 0 ? 'HSG$listingCode' : '';

  num? get pricePerSqft {
    final a = bestArea;
    if (a == null || a <= 0 || purpose != 'sale') return null;
    return price / a;
  }

  String get bhkLabel {
    if (!hasBedrooms) return catLabel;
    if (bedrooms == null || bedrooms == 0) return catLabel;
    return '$bedrooms BHK $catLabel';
  }
}

class PropertyContact {
  final String phone;
  const PropertyContact(this.phone);
}
