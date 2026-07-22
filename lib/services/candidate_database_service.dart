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

  /// Returns candidates plus the total matching count (for "showing X
  /// of Y" and Load More / pagination), and resolves avatar_url to an
  /// actual loadable URL.
  Future<({List<Map<String, dynamic>> candidates, int totalCount})> getCandidates({
    String? search,
    String? state,
    String? district,
    String? qualification,
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
      'p_state': (state == null || state.trim().isEmpty) ? null : state.trim(),
      'p_district': (district == null || district.trim().isEmpty) ? null : district.trim(),
      'p_qualification':
          (qualification == null || qualification.trim().isEmpty) ? null : qualification.trim(),
    });

    if (res == null) return (candidates: <Map<String, dynamic>>[], totalCount: 0);

    final rows = List<Map<String, dynamic>>.from(
      (res as List).map((e) => Map<String, dynamic>.from(e)),
    );

    final totalCount = rows.isNotEmpty
        ? (int.tryParse('${rows.first['total_count']}') ?? rows.length)
        : 0;

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

    return (candidates: rows, totalCount: totalCount);
  }

  /// Distinct state / district / qualification values actually present
  /// among current Premium job seekers — keeps filter dropdowns
  /// relevant instead of showing options with zero matches.
  Future<({List<String> states, List<String> districts, List<String> qualifications})>
      getFilterOptions() async {

    if (_db.auth.currentUser == null) {
      throw Exception("Login required");
    }

    final res = await _db.rpc('get_candidate_filter_options');

    if (res == null || (res is List && res.isEmpty)) {
      return (states: <String>[], districts: <String>[], qualifications: <String>[]);
    }

    final row = (res is List) ? Map<String, dynamic>.from(res.first) : Map<String, dynamic>.from(res);

    List<String> asList(dynamic v) =>
        v is List ? v.map((e) => e.toString()).toList() : <String>[];

    return (
      states: asList(row['states']),
      districts: asList(row['districts']),
      qualifications: asList(row['qualifications']),
    );
  }
}
