import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class DeviceSpot {
  final double lat;
  final double lng;
  final String city;
  final String area;
  const DeviceSpot(this.lat, this.lng, this.city, this.area);
}

class LocationResult {
  final DeviceSpot? spot;
  final String? error;
  const LocationResult({this.spot, this.error});
}

class LocationService {
  static Future<LocationResult> current() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return const LocationResult(error: 'Location is turned off on your phone.');
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied) {
        return const LocationResult(error: 'Location permission was denied.');
      }
      if (perm == LocationPermission.deniedForever) {
        return const LocationResult(error: 'Location permission is blocked. Enable it in phone settings.');
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      String city = '';
      String area = '';
      try {
        final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (marks.isNotEmpty) {
          final m = marks.first;
          city = (m.locality ?? '').isNotEmpty ? m.locality! : (m.subAdministrativeArea ?? '');
          area = m.subLocality ?? '';
        }
      } catch (_) {}
      return LocationResult(spot: DeviceSpot(pos.latitude, pos.longitude, city, area));
    } catch (e) {
      return const LocationResult(error: 'Could not get your location. Try again.');
    }
  }

  /// distance in km
  static double km(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000.0;
  }
}
