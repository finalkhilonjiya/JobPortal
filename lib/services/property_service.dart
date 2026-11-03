import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/property.dart';
import 'auth_service.dart';

class PropertyService {
  static SupabaseClient get _c => Supabase.instance.client;

  static List<Property> _list(List<Map<String, dynamic>> rows) =>
      rows.map((e) => Property.fromMap(e)).toList();

  /// sort: new | price_low | price_high
  static Future<List<Property>> search({
    String? purpose,
    String? category,
    String? city,
    String? query,
    bool featuredOnly = false,
    String sort = 'new',
    int limit = 30,
  }) async {
    var q = _c.from('properties').select().eq('status', 'active');

    if (purpose != null && purpose.isNotEmpty) q = q.eq('purpose', purpose);
    if (category != null && category.isNotEmpty) {
      q = q.eq('category', category);
    }
    if (city != null && city.isNotEmpty) q = q.ilike('city', city);
    if (featuredOnly) q = q.eq('is_featured', true);

    final text = (query ?? '').trim().replaceAll(RegExp(r'[,()%*]'), ' ');
    if (text.isNotEmpty) {
      q = q.or(
          'title.ilike.%$text%,locality.ilike.%$text%,city.ilike.%$text%,address.ilike.%$text%');
    }

    final ordered = sort == 'price_low'
        ? q.order('price', ascending: true)
        : sort == 'price_high'
            ? q.order('price', ascending: false)
            : q.order('created_at', ascending: false);

    final rows = await ordered.limit(limit);
    return _list(rows);
  }

  static Future<List<Property>> myListings() async {
    final uid = AuthService.userId;
    if (uid == null) return [];
    final rows = await _c
        .from('properties')
        .select()
        .eq('owner_id', uid)
        .order('created_at', ascending: false);
    return _list(rows);
  }

  static Future<List<Property>> favorites() async {
    if (!AuthService.isLoggedIn) return [];
    final rows = await _c
        .from('favorites')
        .select('properties(*)')
        .order('created_at', ascending: false);
    final out = <Property>[];
    for (final r in rows) {
      final p = r['properties'];
      if (p is Map<String, dynamic>) out.add(Property.fromMap(p));
    }
    return out;
  }

  static Future<List<String>> uploadImages(List<XFile> files) async {
    final uid = AuthService.userId;
    if (uid == null) throw Exception('Please log in first');
    final urls = <String>[];
    final stamp = DateTime.now().microsecondsSinceEpoch;
    for (var i = 0; i < files.length; i++) {
      final bytes = await files[i].readAsBytes();
      final path = '$uid/${stamp}_$i.jpg';
      await _c.storage.from('property-images').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
      urls.add(_c.storage.from('property-images').getPublicUrl(path));
    }
    return urls;
  }

  static Future<String> create(
      Map<String, dynamic> data, String contactPhone) async {
    final uid = AuthService.userId;
    if (uid == null) throw Exception('Please log in first');
    final row = await _c
        .from('properties')
        .insert({...data, 'owner_id': uid})
        .select('id')
        .single();
    final id = row['id'].toString();
    await _c.from('property_contacts').upsert({
      'property_id': id,
      'phone': contactPhone,
    });
    return id;
  }

  static Future<void> delete(String id) async {
    await _c.from('properties').delete().eq('id', id);
  }

  /// Owner phone. RLS only lets logged-in users read it.
  static Future<String?> contactPhone(String propertyId) async {
    final row = await _c
        .from('property_contacts')
        .select('phone')
        .eq('property_id', propertyId)
        .maybeSingle();
    return row?['phone']?.toString();
  }

  static Future<void> recordEnquiry(String propertyId) async {
    final uid = AuthService.userId;
    if (uid == null) return;
    try {
      await _c.from('enquiries').insert({
        'property_id': propertyId,
        'user_id': uid,
      });
    } catch (_) {}
  }

  static Future<void> report(String propertyId, String reason) async {
    final uid = AuthService.userId;
    if (uid == null) return;
    await _c.from('reports').insert({
      'property_id': propertyId,
      'user_id': uid,
      'reason': reason,
    });
  }
}
