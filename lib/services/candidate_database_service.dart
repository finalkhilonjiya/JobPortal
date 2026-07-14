// File: lib/services/candidate_database_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

import 'employer_applicants_service.dart';

/// Reads the employer-facing candidate database via the
/// `get_candidate_database` Postgres RPC. Every employer can browse the
/// list; resume_url / mobile_number / actual_email come back NULL (and
/// `has_full_access` is false) unless the calling employer has an active
/// Khilonjiya Premium subscription. This is enforced server-side, so the
/// UI only needs to react to `has_full_access` — it cannot be bypassed by
/// calling the table directly.
class CandidateDatabaseService {

  final SupabaseClient _db = Supabase.instance.client;
  final EmployerApplicantsService _applicantsService = EmployerApplicantsService();

  Future<List<Map<String, dynamic>>> getCandidates({
    String? search,
    int limit = 20,
    int offset = 0,
  }) async {

    if (_db.auth.currentUser == null) {
      throw Exception("Login required");
    }

    final res = await _db.rpc('get_candidate_database', params: {
      'p_search': (search == null || search.trim().isEmpty) ? null : search.trim(),
      'p_limit': limit,
      'p_offset': offset,
    });

    if (res == null) return [];

    final rows = List<Map<String, dynamic>>.from(
      (res as List).map((e) => Map<String, dynamic>.from(e)),
    );

    // avatar_url comes back as a raw storage path (e.g. "photos/<uid>/xxx.jpg"),
    // same as resume_url — it needs to be resolved to an actual loadable URL
    // before it can be used in an Image/NetworkImage widget.
    for (final row in rows) {
      final rawAvatar = (row['avatar_url'] ?? '').toString().trim();
      if (rawAvatar.isEmpty) continue;

      try {
        final resolved = await _applicantsService.getPublicOrSignedUrl(rawAvatar);
        row['avatar_url'] = resolved ?? '';
      } catch (_) {
        row['avatar_url'] = '';
      }
    }

    return rows;
  }
}
