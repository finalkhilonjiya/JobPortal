import 'package:supabase_flutter/supabase_flutter.dart';

class CompanyService {
  final supabase = Supabase.instance.client;

  Future<void> createCompany({
    required String name,
    required String businessTypeId,
    String? city,
    String? state,
    String? logoUrl,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    // 1️⃣ Insert company
    final companyRes = await supabase
        .from('companies')
        .insert({
          'name': name,
          'business_type_id': businessTypeId,
          'headquarters_city': city,
          'headquarters_state': state,
          'logo_url': logoUrl,
          'created_by': user.id,
          'owner_id': user.id,
        })
        .select()
        .single();

    final companyId = companyRes['id'];

    // 2️⃣ Insert company member
    await supabase.from('company_members').insert({
      'company_id': companyId,
      'user_id': user.id,
      'role': 'owner',
      'status': 'active',
    });
  }
}