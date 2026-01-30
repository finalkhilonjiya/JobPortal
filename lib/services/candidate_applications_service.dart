import 'package:supabase_flutter/supabase_flutter.dart';

class CandidateApplicationsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getMyApplications() async {
    final response = await _supabase
        .from('v_candidate_applications')
        .select()
        .order('applied_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}
