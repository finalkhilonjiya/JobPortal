import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationService {
  static const int refreshHours = 6;

  static Future<void> ensureFreshLocation() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    // Get existing stored location
    final profile = await client
        .from('user_profiles')
        .select('current_latitude, current_longitude, location_updated_at')
        .eq('id', user.id)
        .maybeSingle();

    bool needsRefresh = true;

    if (profile != null) {
      final updatedAtRaw = profile['location_updated_at']?.toString();

      if (updatedAtRaw != null && updatedAtRaw.isNotEmpty) {
        final updatedAt = DateTime.tryParse(updatedAtRaw);

        if (updatedAt != null) {
          final diff = DateTime.now().difference(updatedAt);
          if (diff.inHours < refreshHours) {
            needsRefresh = false;
          }
        }
      }
    }

    if (!needsRefresh) return;

    // Request permission
    final permission = await Permission.location.request();
    if (!permission.isGranted) return;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    await client.from('user_profiles').update({
      'current_latitude': position.latitude,
      'current_longitude': position.longitude,
      'location_updated_at': DateTime.now().toIso8601String(),
    }).eq('id', user.id);
  }
}