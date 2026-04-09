import 'package:supabase_flutter/supabase_flutter.dart';

class SearchService {
  final SupabaseClient _db = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> searchJobs({
    required String keyword,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _db.rpc(
        'search_jobs',
        params: {
          'p_keyword': keyword,
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      final list = List<Map<String, dynamic>>.from(response);

      return list
          .map((e) => Map<String, dynamic>.from(e['job']))
          .toList();
    } catch (e) {
      return [];
    }
  }
}