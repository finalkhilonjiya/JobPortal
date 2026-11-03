class Profile {
  final String id;
  final String fullName;
  final String phone;
  final String email;
  final String avatarUrl;
  final String role;
  final String agencyName;
  final String agencyAddress;
  final String bio;
  final List<String> extraPhones;
  final bool isVerified;
  final bool isSuspended;
  final bool onboarded;
  final Map<String, dynamic> notifPrefs;
  final DateTime? createdAt;

  const Profile({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.avatarUrl,
    required this.role,
    required this.agencyName,
    required this.agencyAddress,
    required this.bio,
    required this.extraPhones,
    required this.isVerified,
    required this.isSuspended,
    required this.onboarded,
    required this.notifPrefs,
    this.createdAt,
  });

  factory Profile.fromMap(Map<String, dynamic> m) {
    String s(String k) => (m[k] ?? '').toString();
    final ep = m['extra_phones'];
    final np = m['notif_prefs'];
    return Profile(
      id: s('id'),
      fullName: s('full_name'),
      phone: s('phone'),
      email: s('email'),
      avatarUrl: s('avatar_url'),
      role: s('role').isEmpty ? 'tenant' : s('role'),
      agencyName: s('agency_name'),
      agencyAddress: s('agency_address'),
      bio: s('bio'),
      extraPhones: ep is List ? ep.map((e) => e.toString()).toList() : <String>[],
      isVerified: m['is_verified'] == true,
      isSuspended: m['is_suspended'] == true,
      onboarded: m['onboarded'] == true,
      notifPrefs: np is Map ? Map<String, dynamic>.from(np) : <String, dynamic>{},
      createdAt: DateTime.tryParse(s('created_at'))?.toLocal(),
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isPro => role == 'agent' || role == 'broker' || role == 'builder';
  String get displayName => fullName.isNotEmpty ? fullName : 'User';
}

class Lead {
  final String id;
  final String propertyId;
  final String userId;
  final String ownerId;
  final String kind;
  final String message;
  final String requesterName;
  final String requesterPhone;
  final String status;
  final String note;
  final DateTime? followUpAt;
  final DateTime? visitAt;
  final DateTime createdAt;
  final String propertyTitle;

  const Lead({
    required this.id,
    required this.propertyId,
    required this.userId,
    required this.ownerId,
    required this.kind,
    required this.message,
    required this.requesterName,
    required this.requesterPhone,
    required this.status,
    required this.note,
    this.followUpAt,
    this.visitAt,
    required this.createdAt,
    required this.propertyTitle,
  });

  factory Lead.fromMap(Map<String, dynamic> m) {
    String s(String k) => (m[k] ?? '').toString();
    final prop = m['properties'];
    return Lead(
      id: s('id'),
      propertyId: s('property_id'),
      userId: s('user_id'),
      ownerId: s('owner_id'),
      kind: s('kind').isEmpty ? 'enquiry' : s('kind'),
      message: s('message'),
      requesterName: s('requester_name'),
      requesterPhone: s('requester_phone'),
      status: s('status').isEmpty ? 'new' : s('status'),
      note: s('note'),
      followUpAt: DateTime.tryParse(s('follow_up_at'))?.toLocal(),
      visitAt: DateTime.tryParse(s('visit_at'))?.toLocal(),
      createdAt: DateTime.tryParse(s('created_at'))?.toLocal() ?? DateTime.now(),
      propertyTitle: prop is Map ? (prop['title'] ?? '').toString() : '',
    );
  }
}

class Conversation {
  final String id;
  final String? propertyId;
  final String buyerId;
  final String ownerId;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int buyerUnread;
  final int ownerUnread;
  final String propertyTitle;
  final String propertyImage;

  const Conversation({
    required this.id,
    this.propertyId,
    required this.buyerId,
    required this.ownerId,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.buyerUnread,
    required this.ownerUnread,
    required this.propertyTitle,
    required this.propertyImage,
  });

  factory Conversation.fromMap(Map<String, dynamic> m) {
    String s(String k) => (m[k] ?? '').toString();
    final prop = m['properties'];
    String img = '';
    String title = '';
    if (prop is Map) {
      title = (prop['title'] ?? '').toString();
      final imgs = prop['images'];
      if (imgs is List && imgs.isNotEmpty) img = imgs.first.toString();
    }
    return Conversation(
      id: s('id'),
      propertyId: m['property_id']?.toString(),
      buyerId: s('buyer_id'),
      ownerId: s('owner_id'),
      lastMessage: s('last_message'),
      lastMessageAt: DateTime.tryParse(s('last_message_at'))?.toLocal() ?? DateTime.now(),
      buyerUnread: (m['buyer_unread'] as num?)?.toInt() ?? 0,
      ownerUnread: (m['owner_unread'] as num?)?.toInt() ?? 0,
      propertyTitle: title,
      propertyImage: img,
    );
  }

  String otherId(String me) => me == buyerId ? ownerId : buyerId;
  int unreadFor(String me) => me == buyerId ? buyerUnread : ownerUnread;
}

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final String imageUrl;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.imageUrl,
    required this.createdAt,
  });

  factory Message.fromMap(Map<String, dynamic> m) {
    String s(String k) => (m[k] ?? '').toString();
    return Message(
      id: s('id'),
      conversationId: s('conversation_id'),
      senderId: s('sender_id'),
      body: s('body'),
      imageUrl: s('image_url'),
      createdAt: DateTime.tryParse(s('created_at'))?.toLocal() ?? DateTime.now(),
    );
  }
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String kind;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.kind,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> m) {
    String s(String k) => (m[k] ?? '').toString();
    final d = m['data'];
    return AppNotification(
      id: s('id'),
      title: s('title'),
      body: s('body'),
      kind: s('kind'),
      data: d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{},
      isRead: m['is_read'] == true,
      createdAt: DateTime.tryParse(s('created_at'))?.toLocal() ?? DateTime.now(),
    );
  }
}

class Review {
  final String id;
  final String userId;
  final String targetType;
  final String targetId;
  final int rating;
  final String comment;
  final bool verifiedVisit;
  final DateTime createdAt;
  final String authorName;

  const Review({
    required this.id,
    required this.userId,
    required this.targetType,
    required this.targetId,
    required this.rating,
    required this.comment,
    required this.verifiedVisit,
    required this.createdAt,
    required this.authorName,
  });

  factory Review.fromMap(Map<String, dynamic> m, {String authorName = ''}) {
    String s(String k) => (m[k] ?? '').toString();
    return Review(
      id: s('id'),
      userId: s('user_id'),
      targetType: s('target_type'),
      targetId: s('target_id'),
      rating: (m['rating'] as num?)?.toInt() ?? 0,
      comment: s('comment'),
      verifiedVisit: m['is_verified_visit'] == true,
      createdAt: DateTime.tryParse(s('created_at'))?.toLocal() ?? DateTime.now(),
      authorName: authorName,
    );
  }
}

class Article {
  final String id;
  final String slug;
  final String title;
  final String category;
  final String summary;
  final String body;
  final bool published;

  const Article({
    required this.id,
    required this.slug,
    required this.title,
    required this.category,
    required this.summary,
    required this.body,
    required this.published,
  });

  factory Article.fromMap(Map<String, dynamic> m) {
    String s(String k) => (m[k] ?? '').toString();
    return Article(
      id: s('id'),
      slug: s('slug'),
      title: s('title'),
      category: s('category'),
      summary: s('summary'),
      body: s('body'),
      published: m['published'] != false,
    );
  }
}

class SavedSearch {
  final String id;
  final String name;
  final Map<String, dynamic> filters;
  final bool alerts;

  const SavedSearch({required this.id, required this.name, required this.filters, required this.alerts});

  factory SavedSearch.fromMap(Map<String, dynamic> m) {
    final f = m['filters'];
    return SavedSearch(
      id: (m['id'] ?? '').toString(),
      name: (m['name'] ?? '').toString(),
      filters: f is Map ? Map<String, dynamic>.from(f) : <String, dynamic>{},
      alerts: m['alerts'] != false,
    );
  }
}

class PromoRequest {
  final String id;
  final String propertyId;
  final String userId;
  final String plan;
  final String note;
  final String status;
  final DateTime createdAt;
  final String propertyTitle;

  const PromoRequest({
    required this.id,
    required this.propertyId,
    required this.userId,
    required this.plan,
    required this.note,
    required this.status,
    required this.createdAt,
    required this.propertyTitle,
  });

  factory PromoRequest.fromMap(Map<String, dynamic> m) {
    String s(String k) => (m[k] ?? '').toString();
    final prop = m['properties'];
    return PromoRequest(
      id: s('id'),
      propertyId: s('property_id'),
      userId: s('user_id'),
      plan: s('plan'),
      note: s('note'),
      status: s('status'),
      createdAt: DateTime.tryParse(s('created_at'))?.toLocal() ?? DateTime.now(),
      propertyTitle: prop is Map ? (prop['title'] ?? '').toString() : '',
    );
  }
}

class ReportItem {
  final String id;
  final String? propertyId;
  final String? reviewId;
  final String? reportedUserId;
  final String userId;
  final String reason;
  final String details;
  final String status;
  final DateTime createdAt;

  const ReportItem({
    required this.id,
    this.propertyId,
    this.reviewId,
    this.reportedUserId,
    required this.userId,
    required this.reason,
    required this.details,
    required this.status,
    required this.createdAt,
  });

  factory ReportItem.fromMap(Map<String, dynamic> m) {
    String s(String k) => (m[k] ?? '').toString();
    return ReportItem(
      id: s('id'),
      propertyId: m['property_id']?.toString(),
      reviewId: m['review_id']?.toString(),
      reportedUserId: m['reported_user_id']?.toString(),
      userId: s('user_id'),
      reason: s('reason'),
      details: s('details'),
      status: s('status'),
      createdAt: DateTime.tryParse(s('created_at'))?.toLocal() ?? DateTime.now(),
    );
  }
}

/// Search / filter state, serialisable to jsonb for saved searches.
class Filters {
  String query;
  String purpose; // '' | rent | sale | lease
  Set<String> categories;
  String city;
  String locality;
  num? minPrice;
  num? maxPrice;
  Set<int> bedrooms; // 1,2,3,4 (4 = 4+)
  num? minArea;
  num? maxArea;
  Set<String> furnishing;
  Set<String> amenities;
  String listedBy; // '' | owner | broker | builder
  bool noBrokerage;
  bool verifiedOnly;
  String construction; // '' | ready | under_construction
  String facing;
  String parking; // '' | car | bike | both
  String pgGender;
  String food;
  String sharing;
  String sort;
  double? nearLat;
  double? nearLng;
  double nearKm;

  Filters({
    this.query = '',
    this.purpose = '',
    Set<String>? categories,
    this.city = '',
    this.locality = '',
    this.minPrice,
    this.maxPrice,
    Set<int>? bedrooms,
    this.minArea,
    this.maxArea,
    Set<String>? furnishing,
    Set<String>? amenities,
    this.listedBy = '',
    this.noBrokerage = false,
    this.verifiedOnly = false,
    this.construction = '',
    this.facing = '',
    this.parking = '',
    this.pgGender = '',
    this.food = '',
    this.sharing = '',
    this.sort = 'newest',
    this.nearLat,
    this.nearLng,
    this.nearKm = 10,
  })  : categories = categories ?? <String>{},
        bedrooms = bedrooms ?? <int>{},
        furnishing = furnishing ?? <String>{},
        amenities = amenities ?? <String>{};

  Filters copy() => Filters.fromJson(toJson());

  int get activeCount {
    int n = 0;
    if (purpose.isNotEmpty) n++;
    if (categories.isNotEmpty) n++;
    if (city.isNotEmpty) n++;
    if (locality.isNotEmpty) n++;
    if (minPrice != null || maxPrice != null) n++;
    if (bedrooms.isNotEmpty) n++;
    if (minArea != null || maxArea != null) n++;
    if (furnishing.isNotEmpty) n++;
    if (amenities.isNotEmpty) n++;
    if (listedBy.isNotEmpty) n++;
    if (noBrokerage) n++;
    if (verifiedOnly) n++;
    if (construction.isNotEmpty) n++;
    if (facing.isNotEmpty) n++;
    if (parking.isNotEmpty) n++;
    if (pgGender.isNotEmpty) n++;
    if (food.isNotEmpty) n++;
    if (sharing.isNotEmpty) n++;
    if (nearLat != null) n++;
    return n;
  }

  Map<String, dynamic> toJson() => {
        'query': query,
        'purpose': purpose,
        'categories': categories.toList(),
        'city': city,
        'locality': locality,
        'minPrice': minPrice,
        'maxPrice': maxPrice,
        'bedrooms': bedrooms.toList(),
        'minArea': minArea,
        'maxArea': maxArea,
        'furnishing': furnishing.toList(),
        'amenities': amenities.toList(),
        'listedBy': listedBy,
        'noBrokerage': noBrokerage,
        'verifiedOnly': verifiedOnly,
        'construction': construction,
        'facing': facing,
        'parking': parking,
        'pgGender': pgGender,
        'food': food,
        'sharing': sharing,
        'sort': sort,
        'nearLat': nearLat,
        'nearLng': nearLng,
        'nearKm': nearKm,
      };

  factory Filters.fromJson(Map<String, dynamic> j) {
    List<String> sl(dynamic v) => v is List ? v.map((e) => e.toString()).toList() : <String>[];
    num? nn(dynamic v) => v is num ? v : (v == null ? null : num.tryParse(v.toString()));
    String s(String k) => (j[k] ?? '').toString();
    return Filters(
      query: s('query'),
      purpose: s('purpose'),
      categories: sl(j['categories']).toSet(),
      city: s('city'),
      locality: s('locality'),
      minPrice: nn(j['minPrice']),
      maxPrice: nn(j['maxPrice']),
      bedrooms: sl(j['bedrooms']).map((e) => int.tryParse(e) ?? 0).where((e) => e > 0).toSet(),
      minArea: nn(j['minArea']),
      maxArea: nn(j['maxArea']),
      furnishing: sl(j['furnishing']).toSet(),
      amenities: sl(j['amenities']).toSet(),
      listedBy: s('listedBy'),
      noBrokerage: j['noBrokerage'] == true,
      verifiedOnly: j['verifiedOnly'] == true,
      construction: s('construction'),
      facing: s('facing'),
      parking: s('parking'),
      pgGender: s('pgGender'),
      food: s('food'),
      sharing: s('sharing'),
      sort: s('sort').isEmpty ? 'newest' : s('sort'),
      nearLat: nn(j['nearLat'])?.toDouble(),
      nearLng: nn(j['nearLng'])?.toDouble(),
      nearKm: nn(j['nearKm'])?.toDouble() ?? 10,
    );
  }

  String describe() {
    final parts = <String>[];
    if (purpose.isNotEmpty) parts.add(purpose == 'sale' ? 'Buy' : purpose == 'rent' ? 'Rent' : 'Lease');
    if (categories.isNotEmpty) parts.add(categories.length == 1 ? categories.first : '${categories.length} types');
    if (bedrooms.isNotEmpty) parts.add('${(bedrooms.toList()..sort()).join(',')} BHK');
    if (locality.isNotEmpty) parts.add(locality);
    if (city.isNotEmpty) parts.add(city);
    if (query.isNotEmpty) parts.add('"$query"');
    return parts.isEmpty ? 'All properties' : parts.join(' · ');
  }
}
