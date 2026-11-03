import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForceUpdateService {
  // These are read after check() completes
  static bool _updateRequired = false;
  static String _storeUrl = '';

  static bool get updateRequired => _updateRequired;
  static String get storeUrl => _storeUrl;

  static Future<void> check() async {
    try {
      // 1. Get current app build number from device
      final info = await PackageInfo.fromPlatform();
      final currentBuildNumber = int.tryParse(info.buildNumber) ?? 0;

      print('📦 Current build number: $currentBuildNumber');

      // 2. Fetch min required version and store URL from Supabase
      final response = await Supabase.instance.client
          .from('app_config')
          .select('key, value')
          .inFilter('key', ['min_version_code', 'play_store_url']);

      // 3. Convert list of rows into a simple key->value map
      final map = <String, String>{};
      for (final row in response) {
        map[row['key'] as String] = row['value'] as String;
      }

      print('🔧 app_config from Supabase: $map');

      // 4. Parse minimum version from Supabase
      final minVersion = int.tryParse(map['min_version_code'] ?? '0') ?? 0;
      _storeUrl = map['play_store_url'] ?? '';

      print('🔢 Min required build: $minVersion');
      print('🔗 Store URL: $_storeUrl');

      // 5. Compare — if current is less than required, flag for update
      if (currentBuildNumber < minVersion) {
        _updateRequired = true;
        print('🔴 Force update required!');
      } else {
        _updateRequired = false;
        print('✅ App is up to date.');
      }
    } catch (e) {
      // On any error (no internet, Supabase down etc),
      // allow app to proceed — never block user due to our own server error
      _updateRequired = false;
      print('⚠️ ForceUpdateService error (allowing app to proceed): $e');
    }
  }
}