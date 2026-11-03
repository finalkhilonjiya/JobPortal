import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/format.dart';
import '../core/prefs.dart';
import '../models/models.dart';
import '../models/property.dart';

SupabaseClient get sb => Supabase.instance.client;

String errText(Object e) {
  if (e is PostgrestException) {
    final m = e.message;
    if (m.contains('row-level security')) return 'You are not allowed to do that.';
    return m;
  }
  if (e is AuthException) return e.message;
  final s = e.toString();
  if (s.contains('SocketException') || s.contains('ClientException')) {
    return 'No internet connection. Please try again.';
  }
  return s.replaceFirst('Exception: ', '');
}

typedef Json = Map<String, dynamic>;

List<Json> _rows(dynamic d) =>
    (d as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();

/// Central data layer. All Supabase calls live here.
class Api {
  // ------------------------------------------------------------------ session
  static String? get uid => sb.auth.currentUser?.id;
  static bool get loggedIn => sb.auth.currentUser != null;

  static final ValueNotifier<Profile?> profile = ValueNotifier<Profile?>(null);
  static final ValueNotifier<Set<String>> favorites = ValueNotifier<Set<String>>(<String>{});
  static final ValueNotifier<int> unreadNotifs = ValueNotifier<int>(0);
  static final ValueNotifier<int> unreadChats = ValueNotifier<int>(0);
  static Timer? _badgeTimer;

  static Future<void> sendOtp(String phone) async {
    await sb.auth.signInWithOtp(phone: phone);
  }

  static Future<void> verifyOtp(String phone, String code) async {
    await sb.auth.verifyOTP(phone: phone, token: code, type: OtpType.sms);
  }

  /// Loads (or creates) the profile of the signed-in user and warms caches.
  static Future<Profile?> bootstrap() async {
    final u = sb.auth.currentUser;
    if (u == null) {
      profile.value = null;
      favorites.value = <String>{};
      unreadNotifs.value = 0;
      unreadChats.value = 0;
      _badgeTimer?.cancel();
      return null;
    }
    Json? row;
    try {
      row = await sb.from('profiles').select().eq('id', u.id).maybeSingle();
    } catch (_) {}
    if (row == null) {
      try {
        await sb.from('profiles').upsert({
          'id': u.id,
          'phone': u.phone == null || u.phone!.isEmpty ? null : '+${u.phone!.replaceAll('+', '')}',
          'role': 'tenant',
          'onboarded': false,
        });
        row = await sb.from('profiles').select().eq('id', u.id).maybeSingle();
      } catch (_) {}
    }
    if (row != null) profile.value = Profile.fromMap(row);
    await loadFavorites();
    await refreshBadges();
    _badgeTimer?.cancel();
    _badgeTimer = Timer.periodic(const Duration(seconds: 45), (_) => refreshBadges());
    return profile.value;
  }

  static Future<void> signOut() async {
    await sb.auth.signOut();
    await bootstrap();
  }

  static Future<void> deleteAccount() async {
    await sb.rpc('delete_my_account');
    await sb.auth.signOut();
    await bootstrap();
  }

  static Future<void> refreshBadges() async {
    final id = uid;
    if (id == null) return;
    try {
      final n = await sb.from('notifications').select('id').eq('user_id', id).eq('is_read', false);
      unreadNotifs.value = (n as List).length;
    } catch (_) {}
    try {
      final c = await sb
          .from('conversations')
          .select('buyer_id, owner_id, buyer_unread, owner_unread')
          .or('buyer_id.eq.$id,owner_id.eq.$id');
      int total = 0;
      for (final r in (c as List)) {
        total += ((r['buyer_id'] == id ? r['buyer_unread'] : r['owner_unread']) as num?)?.toInt() ?? 0;
      }
      unreadChats.value = total;
    } catch (_) {}
  }

  // ------------------------------------------------------------------ profile
  static Future<void> saveProfile(Json data) async {
    final id = uid;
    if (id == null) return;
    await sb.from('profiles').update(data).eq('id', id);
    final row = await sb.from('profiles').select().eq('id', id).maybeSingle();
    if (row != null) profile.value = Profile.fromMap(row);
  }

  static Future<Json?> publicProfile(String id) async {
    try {
      return await sb.from('public_profiles').select().eq('id', id).maybeSingle();
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, String>> namesFor(List<String> ids) async {
    if (ids.isEmpty) return {};
    try {
      final r = await sb.from('public_profiles').select('id, full_name').inFilter('id', ids.toSet().toList());
      return {for (final x in _rows(r)) x['id'].toString(): (x['full_name'] ?? 'User').toString()};
    } catch (_) {
      return {};
    }
  }

  // --------------------------------------------------------------- properties
  static const int pageSize = 12;

  static Future<List<Property>> search(Filters f, {int page = 0, int size = pageSize}) async {
    var q = sb.from('properties').select().eq('status', 'active');

    final text = f.query.trim().replaceAll(RegExp(r'[,()%]'), ' ').trim();
    if (text.isNotEmpty) {
      final code = RegExp(r'^(?:hsg)?\s*(\d{4,})$', caseSensitive: false).firstMatch(text);
      if (code != null) {
        q = q.eq('listing_code', int.parse(code.group(1)!));
      } else {
        q = q.or('title.ilike.%$text%,locality.ilike.%$text%,city.ilike.%$text%,'
            'landmark.ilike.%$text%,project_name.ilike.%$text%,address.ilike.%$text%');
      }
    }
    if (f.purpose.isNotEmpty) q = q.eq('purpose', f.purpose);
    if (f.categories.isNotEmpty) q = q.inFilter('category', f.categories.toList());
    if (f.city.isNotEmpty) q = q.ilike('city', f.city);
    if (f.locality.isNotEmpty) q = q.ilike('locality', '%${f.locality}%');
    if (f.minPrice != null) q = q.gte('price', f.minPrice!);
    if (f.maxPrice != null) q = q.lte('price', f.maxPrice!);
    if (f.bedrooms.isNotEmpty) {
      final has4 = f.bedrooms.contains(4);
      final exact = f.bedrooms.where((e) => e < 4).toList();
      if (has4 && exact.isEmpty) {
        q = q.gte('bedrooms', 4);
      } else if (has4) {
        q = q.or('bedrooms.in.(${exact.join(',')}),bedrooms.gte.4');
      } else {
        q = q.inFilter('bedrooms', exact);
      }
    }
    if (f.minArea != null) q = q.gte('area_sqft', f.minArea!);
    if (f.maxArea != null) q = q.lte('area_sqft', f.maxArea!);
    if (f.furnishing.isNotEmpty) q = q.inFilter('furnishing', f.furnishing.toList());
    if (f.amenities.isNotEmpty) q = q.contains('amenities', f.amenities.toList());
    if (f.listedBy.isNotEmpty) q = q.eq('listed_by', f.listedBy);
    if (f.noBrokerage) q = q.eq('no_brokerage', true);
    if (f.verifiedOnly) q = q.eq('is_verified', true);
    if (f.construction.isNotEmpty) q = q.eq('construction_status', f.construction);
    if (f.facing.isNotEmpty) q = q.eq('facing', f.facing);
    if (f.parking.isNotEmpty) {
      if (f.parking == 'both') {
        q = q.eq('parking', 'both');
      } else {
        q = q.inFilter('parking', [f.parking, 'both']);
      }
    }
    if (f.pgGender.isNotEmpty) q = q.eq('pg_gender', f.pgGender);
    if (f.food.isNotEmpty) q = q.eq('food', f.food);
    if (f.sharing.isNotEmpty) q = q.eq('sharing', f.sharing);
    if (f.nearLat != null && f.nearLng != null) {
      final dLat = f.nearKm / 111.0;
      final dLng = f.nearKm / 100.0;
      q = q
          .gte('latitude', f.nearLat! - dLat)
          .lte('latitude', f.nearLat! + dLat)
          .gte('longitude', f.nearLng! - dLng)
          .lte('longitude', f.nearLng! + dLng);
    }

    PostgrestTransformBuilder<List<Map<String, dynamic>>> t;
    switch (f.sort) {
      case 'price_low':
        t = q.order('price', ascending: true);
        break;
      case 'price_high':
        t = q.order('price', ascending: false);
        break;
      case 'area_high':
        t = q.order('area_sqft', ascending: false, nullsFirst: false);
        break;
      default:
        t = q.order('is_featured', ascending: false).order('created_at', ascending: false);
    }
    final from = page * size;
    final res = await t.range(from, from + size - 1);
    return _rows(res).map(Property.fromMap).toList();
  }

  static Future<Property?> getProperty(String id) async {
    final r = await sb.from('properties').select().eq('id', id).maybeSingle();
    return r == null ? null : Property.fromMap(r);
  }

  static Future<List<Property>> getByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final r = await sb.from('properties').select().inFilter('id', ids);
    final list = _rows(r).map(Property.fromMap).toList();
    list.sort((a, b) => ids.indexOf(a.id).compareTo(ids.indexOf(b.id)));
    return list;
  }

  static Future<List<Property>> featured({String city = '', int limit = 10}) async {
    var q = sb.from('properties').select().eq('status', 'active').eq('is_featured', true);
    if (city.isNotEmpty) q = q.ilike('city', city);
    final r = await q.order('created_at', ascending: false).limit(limit);
    return _rows(r).map(Property.fromMap).toList();
  }

  static Future<List<Property>> latest({String city = '', String purpose = '', String category = '', int limit = 10}) async {
    var q = sb.from('properties').select().eq('status', 'active');
    if (city.isNotEmpty) q = q.ilike('city', city);
    if (purpose.isNotEmpty) q = q.eq('purpose', purpose);
    if (category.isNotEmpty) q = q.eq('category', category);
    final r = await q.order('created_at', ascending: false).limit(limit);
    return _rows(r).map(Property.fromMap).toList();
  }

  static Future<List<Property>> byCategories(List<String> cats, {String city = '', int limit = 10}) async {
    var q = sb.from('properties').select().eq('status', 'active').inFilter('category', cats);
    if (city.isNotEmpty) q = q.ilike('city', city);
    final r = await q.order('created_at', ascending: false).limit(limit);
    return _rows(r).map(Property.fromMap).toList();
  }

  static Future<List<Property>> noBrokerage({String city = '', int limit = 10}) async {
    var q = sb.from('properties').select().eq('status', 'active').eq('no_brokerage', true);
    if (city.isNotEmpty) q = q.ilike('city', city);
    final r = await q.order('created_at', ascending: false).limit(limit);
    return _rows(r).map(Property.fromMap).toList();
  }

  static Future<List<Property>> similar(Property p, {int limit = 8}) async {
    var q = sb
        .from('properties')
        .select()
        .eq('status', 'active')
        .eq('purpose', p.purpose)
        .eq('category', p.category)
        .neq('id', p.id);
    if (p.city.isNotEmpty) q = q.ilike('city', p.city);
    final r = await q.order('created_at', ascending: false).limit(limit);
    return _rows(r).map(Property.fromMap).toList();
  }

  static Future<List<Property>> byOwner(String ownerId, {int limit = 30}) async {
    final r = await sb
        .from('properties')
        .select()
        .eq('owner_id', ownerId)
        .eq('status', 'active')
        .order('created_at', ascending: false)
        .limit(limit);
    return _rows(r).map(Property.fromMap).toList();
  }

  static Future<List<Property>> myListings() async {
    final id = uid;
    if (id == null) return [];
    final r = await sb.from('properties').select().eq('owner_id', id).order('created_at', ascending: false);
    return _rows(r).map(Property.fromMap).toList();
  }

  static Future<Property> createProperty(Json data) async {
    data['owner_id'] = uid;
    final r = await sb.from('properties').insert(data).select().single();
    return Property.fromMap(r);
  }

  static Future<void> updateProperty(String id, Json data) async {
    await sb.from('properties').update(data).eq('id', id);
  }

  static Future<void> setPropertyStatus(String id, String status) => updateProperty(id, {'status': status});

  static Future<void> deleteProperty(String id) async {
    await sb.from('properties').delete().eq('id', id);
  }

  static Future<String?> contactPhone(String propertyId) async {
    final r = await sb.from('property_contacts').select('phone').eq('property_id', propertyId).maybeSingle();
    return r == null ? null : r['phone']?.toString();
  }

  static Future<void> setContactPhone(String propertyId, String phone) async {
    await sb.from('property_contacts').upsert({'property_id': propertyId, 'phone': phone});
  }

  static Future<void> view(String id) async {
    try {
      await sb.rpc('increment_views', params: {'p_id': id});
    } catch (_) {}
    await Prefs.addRecent(id);
  }

  static Future<Map<String, Json>> listingStats() async {
    try {
      final r = await sb.rpc('my_listing_stats');
      return {for (final x in _rows(r)) x['property_id'].toString(): x};
    } catch (_) {
      return {};
    }
  }

  static Future<Json> ownerOverview() async {
    try {
      final r = await sb.rpc('owner_overview');
      return Map<String, dynamic>.from(r as Map);
    } catch (_) {
      return {};
    }
  }

  // ------------------------------------------------------------------ storage
  static Future<String> uploadBytes(Uint8List bytes, String ext, {String contentType = 'image/jpeg'}) async {
    final id = uid;
    if (id == null) throw Exception('Please log in first.');
    final path = '$id/${DateTime.now().microsecondsSinceEpoch}.$ext';
    await sb.storage.from('property-images').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    return sb.storage.from('property-images').getPublicUrl(path);
  }

  // ---------------------------------------------------------------- favorites
  static Future<void> loadFavorites() async {
    final id = uid;
    if (id == null) return;
    try {
      final r = await sb.from('favorites').select('property_id').eq('user_id', id);
      favorites.value = _rows(r).map((e) => e['property_id'].toString()).toSet();
    } catch (_) {}
  }

  static Future<bool> toggleFavorite(String propertyId) async {
    final id = uid;
    if (id == null) return false;
    final set = Set<String>.from(favorites.value);
    if (set.contains(propertyId)) {
      set.remove(propertyId);
      favorites.value = set;
      try {
        await sb.from('favorites').delete().eq('user_id', id).eq('property_id', propertyId);
      } catch (_) {}
    } else {
      set.add(propertyId);
      favorites.value = set;
      try {
        await sb.from('favorites').insert({'user_id': id, 'property_id': propertyId});
      } catch (_) {}
    }
    return true;
  }

  static Future<List<Property>> shortlist() async {
    final id = uid;
    if (id == null) return [];
    final r = await sb
        .from('favorites')
        .select('created_at, properties(*)')
        .eq('user_id', id)
        .order('created_at', ascending: false);
    final out = <Property>[];
    for (final x in _rows(r)) {
      final p = x['properties'];
      if (p is Map) out.add(Property.fromMap(Map<String, dynamic>.from(p)));
    }
    return out;
  }

  // -------------------------------------------------------------------- leads
  static Future<void> createLead({
    required String propertyId,
    required String kind,
    String? message,
    DateTime? visitAt,
  }) async {
    final id = uid;
    if (id == null) throw Exception('Please log in first.');
    final p = profile.value;
    await sb.from('enquiries').insert({
      'property_id': propertyId,
      'user_id': id,
      'kind': kind,
      'message': message,
      'requester_name': p?.fullName,
      'requester_phone': p?.phone,
      if (visitAt != null) 'visit_at': visitAt.toUtc().toIso8601String(),
    });
  }

  static Future<List<Lead>> myLeads() async {
    final id = uid;
    if (id == null) return [];
    final r = await sb
        .from('enquiries')
        .select('*, properties(title)')
        .eq('owner_id', id)
        .order('created_at', ascending: false);
    return _rows(r).map(Lead.fromMap).toList();
  }

  static Future<List<Lead>> myEnquiries() async {
    final id = uid;
    if (id == null) return [];
    final r = await sb
        .from('enquiries')
        .select('*, properties(title)')
        .eq('user_id', id)
        .order('created_at', ascending: false);
    return _rows(r).map(Lead.fromMap).toList();
  }

  static Future<void> updateLead(String id, Json data) async {
    data['updated_at'] = DateTime.now().toUtc().toIso8601String();
    await sb.from('enquiries').update(data).eq('id', id);
  }

  // -------------------------------------------------------------------- chat
  static Future<String> openConversation(String propertyId, String ownerId) async {
    final r = await sb.rpc('get_or_create_conversation', params: {'p_property': propertyId, 'p_owner': ownerId});
    return r.toString();
  }

  static Future<List<Conversation>> conversations() async {
    final id = uid;
    if (id == null) return [];
    final r = await sb
        .from('conversations')
        .select('*, properties(title, images)')
        .or('buyer_id.eq.$id,owner_id.eq.$id')
        .order('last_message_at', ascending: false);
    return _rows(r).map(Conversation.fromMap).toList();
  }

  static Stream<List<Message>> messageStream(String conversationId) {
    return sb
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((rows) => rows.map((e) => Message.fromMap(Map<String, dynamic>.from(e))).toList());
  }

  static Future<void> sendMessage(String conversationId, {String body = '', String? imageUrl}) async {
    final id = uid;
    if (id == null) return;
    await sb.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': id,
      'body': body,
      if (imageUrl != null) 'image_url': imageUrl,
    });
  }

  static Future<void> markRead(String conversationId) async {
    try {
      await sb.rpc('mark_conversation_read', params: {'p_id': conversationId});
    } catch (_) {}
    refreshBadges();
  }

  static Future<void> blockUser(String userId) async {
    await sb.from('blocks').upsert({'blocker_id': uid, 'blocked_id': userId});
  }

  static Future<void> unblockUser(String userId) async {
    await sb.from('blocks').delete().eq('blocker_id', uid!).eq('blocked_id', userId);
  }

  static Future<bool> isBlockedByMe(String userId) async {
    final id = uid;
    if (id == null) return false;
    final r = await sb.from('blocks').select('blocked_id').eq('blocker_id', id).eq('blocked_id', userId);
    return (r as List).isNotEmpty;
  }

  // ---------------------------------------------------------- notifications
  static Future<List<AppNotification>> notifications() async {
    final id = uid;
    if (id == null) return [];
    final r = await sb
        .from('notifications')
        .select()
        .eq('user_id', id)
        .order('created_at', ascending: false)
        .limit(60);
    return _rows(r).map(AppNotification.fromMap).toList();
  }

  static Future<void> markNotifRead(String id) async {
    await sb.from('notifications').update({'is_read': true}).eq('id', id);
    refreshBadges();
  }

  static Future<void> markAllNotifsRead() async {
    final id = uid;
    if (id == null) return;
    await sb.from('notifications').update({'is_read': true}).eq('user_id', id).eq('is_read', false);
    unreadNotifs.value = 0;
  }

  // ------------------------------------------------------------ saved searches
  static Future<List<SavedSearch>> savedSearches() async {
    final id = uid;
    if (id == null) return [];
    final r = await sb.from('saved_searches').select().eq('user_id', id).order('created_at', ascending: false);
    return _rows(r).map(SavedSearch.fromMap).toList();
  }

  static Future<void> saveSearch(String name, Filters f) async {
    final id = uid;
    if (id == null) throw Exception('Please log in first.');
    final j = f.toJson();
    final out = <String, dynamic>{};
    j.forEach((k, v) {
      if (v == null) return;
      if (v is String && v.isEmpty) return;
      if (v is List && v.isEmpty) return;
      if (v == false) return;
      out[k] = v;
    });
    // keys understood by the alert trigger in the database
    if (f.categories.length == 1) out['category'] = f.categories.first;
    if (f.maxPrice != null) out['max_price'] = f.maxPrice;
    await sb.from('saved_searches').insert({'user_id': id, 'name': name, 'filters': out, 'alerts': true});
  }

  static Future<void> setSearchAlerts(String id, bool on) async {
    await sb.from('saved_searches').update({'alerts': on}).eq('id', id);
  }

  static Future<void> deleteSearch(String id) async {
    await sb.from('saved_searches').delete().eq('id', id);
  }

  // ------------------------------------------------------------------ reviews
  static Future<List<Review>> reviews(String type, String targetId) async {
    final r = await sb
        .from('reviews')
        .select()
        .eq('target_type', type)
        .eq('target_id', targetId)
        .order('created_at', ascending: false)
        .limit(50);
    final rows = _rows(r);
    final names = await namesFor(rows.map((e) => e['user_id'].toString()).toList());
    return rows.map((m) => Review.fromMap(m, authorName: names[m['user_id'].toString()] ?? 'User')).toList();
  }

  static Future<void> addReview(String type, String targetId, int rating, String comment) async {
    final id = uid;
    if (id == null) throw Exception('Please log in first.');
    await sb.from('reviews').upsert({
      'user_id': id,
      'target_type': type,
      'target_id': targetId,
      'rating': rating,
      'comment': comment,
    }, onConflict: 'user_id,target_type,target_id');
  }

  static Future<void> deleteReview(String id) async {
    await sb.from('reviews').delete().eq('id', id);
  }

  // ------------------------------------------------------------------ reports
  static Future<void> report({String? propertyId, String? reviewId, String? userId, required String reason, String? details}) async {
    final id = uid;
    if (id == null) throw Exception('Please log in first.');
    await sb.from('reports').insert({
      'user_id': id,
      if (propertyId != null) 'property_id': propertyId,
      if (reviewId != null) 'review_id': reviewId,
      if (userId != null) 'reported_user_id': userId,
      'reason': reason,
      'details': details,
    });
  }

  // ----------------------------------------------------------------- articles
  static Future<List<Article>> articles({int limit = 40}) async {
    final r = await sb.from('articles').select().eq('published', true).order('created_at', ascending: false).limit(limit);
    return _rows(r).map(Article.fromMap).toList();
  }

  // ------------------------------------------------------------- promotions
  static Future<void> requestPromotion(String propertyId, String plan, String note) async {
    final id = uid;
    if (id == null) throw Exception('Please log in first.');
    await sb.from('promotion_requests').insert({
      'property_id': propertyId,
      'user_id': id,
      'plan': plan,
      'note': note,
    });
  }

  static Future<List<PromoRequest>> myPromotions() async {
    final id = uid;
    if (id == null) return [];
    final r = await sb
        .from('promotion_requests')
        .select('*, properties(title)')
        .eq('user_id', id)
        .order('created_at', ascending: false);
    return _rows(r).map(PromoRequest.fromMap).toList();
  }

  // -------------------------------------------------------------- locality / city
  static Future<List<Json>> popularCities() async {
    try {
      final r = await sb.rpc('popular_cities', params: {'p_limit': 10});
      return _rows(r);
    } catch (_) {
      return [];
    }
  }

  static Future<List<Json>> popularLocalities(String city) async {
    try {
      final r = await sb.rpc('popular_localities', params: {'p_city': city, 'p_limit': 10});
      return _rows(r);
    } catch (_) {
      return [];
    }
  }

  static Future<Json> localityStats(String city, String locality) async {
    try {
      final r = await sb.rpc('locality_stats', params: {'p_city': city, 'p_locality': locality});
      return Map<String, dynamic>.from(r as Map);
    } catch (_) {
      return {};
    }
  }

  static Future<List<Json>> localityTrend(String city, String locality, String purpose) async {
    try {
      final r = await sb.rpc('locality_trend', params: {'p_city': city, 'p_locality': locality, 'p_purpose': purpose});
      return _rows(r);
    } catch (_) {
      return [];
    }
  }

  static Future<Json> estimatePrice(String city, String locality, String purpose, num area) async {
    try {
      final r = await sb.rpc('estimate_price',
          params: {'p_city': city, 'p_locality': locality, 'p_purpose': purpose, 'p_area': area});
      return Map<String, dynamic>.from(r as Map);
    } catch (_) {
      return {'scope': 'none', 'samples': 0};
    }
  }

  // -------------------------------------------------------------------- admin
  static Future<Json> adminStats() async {
    final r = await sb.rpc('admin_stats');
    return Map<String, dynamic>.from(r as Map);
  }

  static Future<List<Property>> adminListings(String status, {String q = ''}) async {
    var b = sb.from('properties').select();
    if (status.isNotEmpty) b = b.eq('status', status);
    final text = q.trim().replaceAll(RegExp(r'[,()%]'), ' ').trim();
    if (text.isNotEmpty) b = b.or('title.ilike.%$text%,city.ilike.%$text%,locality.ilike.%$text%');
    final r = await b.order('created_at', ascending: false).limit(80);
    return _rows(r).map(Property.fromMap).toList();
  }

  static Future<List<ReportItem>> adminReports(String status) async {
    final r = await sb.from('reports').select().eq('status', status).order('created_at', ascending: false).limit(80);
    return _rows(r).map(ReportItem.fromMap).toList();
  }

  static Future<void> adminResolveReport(String id, String status) async {
    await sb.from('reports').update({'status': status}).eq('id', id);
  }

  static Future<List<Profile>> adminUsers({String q = ''}) async {
    var b = sb.from('profiles').select();
    final text = q.trim().replaceAll(RegExp(r'[,()%]'), ' ').trim();
    if (text.isNotEmpty) b = b.or('full_name.ilike.%$text%,phone.ilike.%$text%');
    final r = await b.order('created_at', ascending: false).limit(80);
    return _rows(r).map(Profile.fromMap).toList();
  }

  static Future<void> adminUpdateProfile(String id, Json data) async {
    await sb.from('profiles').update(data).eq('id', id);
  }

  static Future<List<PromoRequest>> adminPromotions() async {
    final r = await sb
        .from('promotion_requests')
        .select('*, properties(title)')
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return _rows(r).map(PromoRequest.fromMap).toList();
  }

  static Future<void> adminReviewPromotion(String id, bool approve) async {
    await sb.rpc('admin_review_promotion', params: {'p_id': id, 'p_approve': approve});
  }

  static Future<bool> autoApprove() async {
    try {
      final r = await sb.from('app_settings').select('value').eq('key', 'auto_approve').maybeSingle();
      if (r == null) return true;
      return r['value'] == true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> setAutoApprove(bool v) async {
    await sb.from('app_settings').upsert({'key': 'auto_approve', 'value': v});
  }

  static Future<void> adminSaveArticle({String? id, required String title, required String category, required String summary, required String body}) async {
    final data = {
      'title': title,
      'category': category,
      'summary': summary,
      'body': body,
      'slug': 'a-${slugify(title)}',
    };
    if (id == null) {
      await sb.from('articles').insert(data);
    } else {
      await sb.from('articles').update(data).eq('id', id);
    }
  }

  static Future<void> adminDeleteArticle(String id) async {
    await sb.from('articles').delete().eq('id', id);
  }

  static String slugify(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');

  static String localityId(String city, String locality) => localityKey(city, locality);
}
