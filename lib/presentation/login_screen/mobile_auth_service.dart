import 'package:supabase_flutter/supabase_flutter.dart';

class MobileAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Request OTP (fixed 12345)
  Future<bool> sendOtp(String mobileNumber) async {
    try {
      await _supabase.functions.invoke(
        'smart-function',
        body: {'action': 'request-otp', 'mobile_number': mobileNumber},
      );
      return true;
    } catch (e) {
      print("Error sending OTP: $e");
      return false;
    }
  }

  // Verify OTP
  Future<bool> verifyOtp(String mobileNumber, String otp) async {
    try {
      final response = await _supabase.functions.invoke(
        'smart-function',
        body: {'action': 'verify-otp', 'mobile_number': mobileNumber, 'otp': otp},
      );
      return response.data['success'] == true;
    } catch (e) {
      print("Error verifying OTP: $e");
      return false;
    }
  }

  // ✅ Added back required methods
  Future<bool> checkConnection() async {
    try {
      await _supabase.from('user_profiles').select().limit(1);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> refreshSession() async {
    final session = _supabase.auth.currentSession;
    return session != null;
  }

  static bool isValidMobileNumber(String mobile) {
    return mobile.isNotEmpty && mobile.length == 10;
  }
}