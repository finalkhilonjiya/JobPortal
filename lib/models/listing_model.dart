// File: lib/models/listing_model.dart
class ListingModel {
  final String? id;
  final String sellerId;
  final String categoryId;
  final String title;
  final String description;
  final double price;
  final String condition;
  final String status;
  final String location;
  final List<String> images;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ListingModel({
    this.id,
    required this.sellerId,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.price,
    required this.condition,
    required this.status,
    required this.location,
    required this.images,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'seller_id': sellerId,
      'category_id': categoryId,
      'title': title,
      'description': description,
      'price': price,
      'condition': condition,
      'status': status,
      'location': location,
      'images': images,
    };
  }

  factory ListingModel.fromJson(Map<String, dynamic> json) {
    return ListingModel(
      id: json['id'],
      sellerId: json['seller_id'],
      categoryId: json['category_id'],
      title: json['title'],
      description: json['description'],
      price: json['price'].toDouble(),
      condition: json['condition'],
      status: json['status'],
      location: json['location'],
      images: List<String>.from(json['images'] ?? []),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }
}