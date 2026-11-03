import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';

/// Keeps the user's shortlisted property ids in memory so hearts update instantly.
class FavoritesStore extends ChangeNotifier {
  FavoritesStore._();
  static final FavoritesStore instance = FavoritesStore._();

  final Set<String> _ids = <String>{};

  bool contains(String id) => _ids.contains(id);

  Future<void> load() async {
    if (!AuthService.isLoggedIn) {
      _ids.clear();
      notifyListeners();
      return;
    }
    try {
      final rows = await Supabase.instance.client
          .from('favorites')
          .select('property_id');
      _ids
        ..clear()
        ..addAll(rows.map((r) => r['property_id'].toString()));
      notifyListeners();
    } catch (_) {}
  }

  /// Returns the new state (true = shortlisted).
  Future<bool> toggle(String propertyId) async {
    final uid = AuthService.userId;
    if (uid == null) return false;
    final client = Supabase.instance.client;
    final wasIn = _ids.contains(propertyId);

    // optimistic update
    if (wasIn) {
      _ids.remove(propertyId);
    } else {
      _ids.add(propertyId);
    }
    notifyListeners();

    try {
      if (wasIn) {
        await client
            .from('favorites')
            .delete()
            .eq('user_id', uid)
            .eq('property_id', propertyId);
      } else {
        await client
            .from('favorites')
            .insert({'user_id': uid, 'property_id': propertyId});
      }
    } catch (_) {
      // roll back
      if (wasIn) {
        _ids.add(propertyId);
      } else {
        _ids.remove(propertyId);
      }
      notifyListeners();
    }
    return !wasIn;
  }
}
