import 'package:supabase_flutter/supabase_flutter.dart';

class EmployerService {
  final SupabaseClient _db = Supabase.instance.client;

  /// ------------------------------------------------------------
  /// CHECK: Is user already part of any company?
  /// ------------------------------------------------------------
  Future<bool> isUserInCompany() async {
    final user = _db.auth.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    final res = await _db
        .from('company_members')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();

    return res != null;
  }

  /// ------------------------------------------------------------
  /// OPTIONAL (future use)
  /// Get company id
  /// ------------------------------------------------------------
  Future<String?> getCompanyId() async {
    final user = _db.auth.currentUser;

    if (user == null) return null;

    final res = await _db
        .from('company_members')
        .select('company_id')
        .eq('user_id', user.id)
        .maybeSingle();

    return res?['company_id']?.toString();
  }
}