import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Small local store: onboarding flag, recently viewed, compare list, recent searches, city.
class Prefs {
  static SharedPreferences? _p;

  static Future<void> init() async {
    try {
      _p = await SharedPreferences.getInstance();
    } catch (_) {
      _p = null;
    }
    compare.value = List<String>.from(_list('compare'));
  }

  static List<String> _list(String k) => _p?.getStringList(k) ?? <String>[];
  static Future<void> _save(String k, List<String> v) async {
    try {
      await _p?.setStringList(k, v);
    } catch (_) {}
  }

  static bool get onboardingSeen => _p?.getBool('onboarding_seen') ?? false;
  static Future<void> setOnboardingSeen() async {
    try {
      await _p?.setBool('onboarding_seen', true);
    } catch (_) {}
  }

  static String get city => _p?.getString('city') ?? '';
  static Future<void> setCity(String v) async {
    try {
      await _p?.setString('city', v);
    } catch (_) {}
  }

  // recently viewed (ids, newest first)
  static List<String> get recent => _list('recent');
  static Future<void> addRecent(String id) async {
    final l = _list('recent')..remove(id);
    l.insert(0, id);
    await _save('recent', l.take(20).toList());
  }

  // recent search terms
  static List<String> get searches => _list('searches');
  static Future<void> addSearch(String q) async {
    final t = q.trim();
    if (t.isEmpty) return;
    final l = _list('searches')..remove(t);
    l.insert(0, t);
    await _save('searches', l.take(8).toList());
  }

  static Future<void> clearSearches() => _save('searches', <String>[]);

  // compare list (max 3) - listenable so the bar updates
  static final ValueNotifier<List<String>> compare = ValueNotifier<List<String>>(<String>[]);
  static bool inCompare(String id) => compare.value.contains(id);

  /// returns false if list is full
  static bool toggleCompare(String id) {
    final l = List<String>.from(compare.value);
    if (l.contains(id)) {
      l.remove(id);
    } else {
      if (l.length >= 3) return false;
      l.add(id);
    }
    compare.value = l;
    _save('compare', l);
    return true;
  }

  static void clearCompare() {
    compare.value = <String>[];
    _save('compare', <String>[]);
  }
}
