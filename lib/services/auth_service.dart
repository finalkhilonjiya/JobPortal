import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/format.dart';

class AuthService {
  static SupabaseClient get _c => Supabase.instance.client;

  static User? get user => _c.auth.currentUser;
  static bool get isLoggedIn => user != null;
  static String? get userId => user?.id;
  static Stream<AuthState> get changes => _c.auth.onAuthStateChange;

  /// Sends an SMS OTP. With Supabase "test phone numbers" no SMS is sent and
  /// the fixed OTP you configured is accepted.
  static Future<String> sendOtp(String rawPhone) async {
    final phone = normalizePhone(rawPhone);
    await _c.auth.signInWithOtp(phone: phone);
    return phone;
  }

  static Future<void> verifyOtp(String phone, String code) async {
    await _c.auth.verifyOTP(phone: phone, token: code, type: OtpType.sms);
    await ensureProfile();
  }

  static Future<void> ensureProfile() async {
    final u = user;
    if (u == null) return;
    try {
      await _c.from('profiles').upsert({
        'id': u.id,
        'phone': u.phone == null ? null : '+${u.phone}',
      });
    } catch (_) {
      // Profile row is best-effort; app keeps working without it.
    }
  }

  static Future<String?> phone() async {
    final p = user?.phone;
    return (p == null || p.isEmpty) ? null : '+$p';
  }

  static Future<void> signOut() => _c.auth.signOut();

  /// Calls the SQL function delete_my_account() (see supabase/schema.sql).
  static Future<void> deleteAccount() async {
    await _c.rpc('delete_my_account');
    await _c.auth.signOut();
  }
}
