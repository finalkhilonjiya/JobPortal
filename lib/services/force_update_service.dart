import 'package:in_app_update/in_app_update.dart';

class ForceUpdateService {
  static Future<void> check() async {
    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        // 🔴 FORCE UPDATE
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      // Ignore errors (Play Store only works on real device)
    }
  }
}