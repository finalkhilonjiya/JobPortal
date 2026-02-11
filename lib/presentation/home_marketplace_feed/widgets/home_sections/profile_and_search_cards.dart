import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/ui/khilonjiya_ui.dart';

class ProfileAndSearchCards extends StatefulWidget {
  final VoidCallback? onMissingDetailsTap;
  final VoidCallback? onViewAllTap;

  /// Placeholder navigation:
  /// - Left card tap -> Complete Profile page (later)
  /// - Right card "View all" -> Jobs posted today page (later)
  const ProfileAndSearchCards({
    Key? key,
    this.onMissingDetailsTap,
    this.onViewAllTap,
  }) : super(key: key);

  @override
  State<ProfileAndSearchCards> createState() => _ProfileAndSearchCardsState();
}

class _ProfileAndSearchCardsState extends State<ProfileAndSearchCards> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _loading = true;

  // LEFT CARD
  String _profileName = "Your Profile";
  int _profileCompletion = 0;
  String _lastUpdatedText = "Updated recently";
  int _missingDetails = 0;

  // RIGHT CARD
  int _jobsPostedToday = 0;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);

    try {
      final user = _supabase.auth.currentUser;

      // Not logged in
      if (user == null) {
        setState(() {
          _profileName = "Your Profile";
          _profileCompletion = 0;
          _lastUpdatedText = "Updated recently";
          _missingDetails = 0;
          _jobsPostedToday = 0;
          _loading = false;
        });
        return;
      }

      // 1) Profile
      final profile = await _supabase
          .from('user_profiles')
          .select(
            'full_name, profile_completion_percentage, last_profile_update, '
            'email, mobile_number, avatar_url, location, bio, '
            'current_job_title, current_company, total_experience_years, '
            'resume_url, resume_headline, resume_updated_at, '
            'skills, highest_education, preferred_job_types, preferred_locations, '
            'expected_salary_min, expected_salary_max, notice_period_days, '
            'current_city, current_state, is_open_to_work',
          )
          .eq('id', user.id)
          .maybeSingle();

      // Name
      final fullName = (profile?['full_name'] ?? '').toString().trim();
      _profileName = _firstNameOrFallback(fullName);

      // Completion %
      final pct = profile?['profile_completion_percentage'];
      _profileCompletion = _toInt(pct).clamp(0, 100);

      // Last updated
      final lastUpdateRaw = profile?['last_profile_update']?.toString();
      _lastUpdatedText = _formatLastUpdated(lastUpdateRaw);

      // Missing details count (ALL required across tables)
      _missingDetails = await _calculateMissingDetailsCount(profile);

      // 2) Jobs posted today (All India) - status active only
      _jobsPostedToday = await _fetchJobsPostedTodayCount();

      if (!mounted) return;
      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _profileName = "Your Profile";
        _profileCompletion = 0;
        _lastUpdatedText = "Updated recently";
        _missingDetails = 0;
        _jobsPostedToday = 0;
      });
    }
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Row(
        children: [
          Expanded(child: _skeletonCard()),
          const SizedBox(width: 12),
          Expanded(child: _skeletonCard()),
        ],
      );
    }

    final value = (_profileCompletion.clamp(0, 100)) / 100.0;

    return Row(
      children: [
        // LEFT CARD (Profile)
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              // Placeholder: complete profile page will be created later
              // You will wire navigation later
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: KhilonjiyaUI.cardDecoration(radius: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress Circle (fixed center)
                  SizedBox(
                    width: 54,
                    height: 54,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 54,
                          height: 54,
                          child: CircularProgressIndicator(
                            value: value,
                            strokeWidth: 4,
                            backgroundColor: const Color(0xFFEFF2F6),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              KhilonjiyaUI.primary,
                            ),
                          ),
                        ),
                        Text(
                          "${_profileCompletion.clamp(0, 100)}%",
                          style: KhilonjiyaUI.caption.copyWith(
                            fontWeight: FontWeight.w900,
                            color: KhilonjiyaUI.text,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(_profileName, style: KhilonjiyaUI.cardTitle),
                  const SizedBox(height: 4),
                  Text(_lastUpdatedText, style: KhilonjiyaUI.sub),

                  const SizedBox(height: 10),

                  InkWell(
                    onTap: widget.onMissingDetailsTap,
                    child: Text(
                      "$_missingDetails Missing details",
                      style: KhilonjiyaUI.link,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // RIGHT CARD (Jobs posted today)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: KhilonjiyaUI.cardDecoration(radius: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$_jobsPostedToday",
                  style: KhilonjiyaUI.h1.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text("Jobs posted today", style: KhilonjiyaUI.cardTitle),
                const SizedBox(height: 4),
                Text("All India • Active only", style: KhilonjiyaUI.sub),
                const SizedBox(height: 10),
                InkWell(
                  onTap: widget.onViewAllTap,
                  child: Text("View all", style: KhilonjiyaUI.link),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _skeletonCard() {
    return Container(
      height: 150,
      decoration: KhilonjiyaUI.cardDecoration(radius: 16),
      padding: const EdgeInsets.all(14),
      child: const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // DATA
  // ------------------------------------------------------------

  Future<int> _fetchJobsPostedTodayCount() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    // Supabase expects ISO strings
    final startIso = start.toIso8601String();
    final endIso = end.toIso8601String();

    final res = await _supabase
        .from('job_listings')
        .select('id')
        .eq('status', 'active')
        .gte('created_at', startIso)
        .lt('created_at', endIso);

    return (res as List).length;
  }

  /// Missing details based on:
  /// - required profile fields (app-level requirements)
  /// - at least 1 education row
  ///
  /// Experience NOT required as per your instruction.
  Future<int> _calculateMissingDetailsCount(Map<String, dynamic>? profile) async {
    int missing = 0;

    // If profile row missing entirely, treat as all missing
    if (profile == null) {
      // Count only our required fields + education requirement
      // (we don't know exact number, but we keep consistent logic)
      return 12;
    }

    bool isEmpty(dynamic v) {
      if (v == null) return true;
      if (v is String) return v.trim().isEmpty;
      if (v is List) return v.isEmpty;
      return false;
    }

    // REQUIRED FIELDS (you said: all required information from all tables)
    // Practically: we must define what is required for your profile completion.
    // These are the common must-have fields for a job portal.

    // user_profiles
    if (isEmpty(profile['full_name'])) missing++;
    if (isEmpty(profile['email'])) missing++;
    if (isEmpty(profile['mobile_number'])) missing++;
    if (isEmpty(profile['current_city'])) missing++;
    if (isEmpty(profile['current_state'])) missing++;
    if (isEmpty(profile['highest_education'])) missing++;
    if (isEmpty(profile['skills'])) missing++;
    if (profile['expected_salary_min'] == null) missing++;
    if (profile['expected_salary_max'] == null) missing++;
    if (isEmpty(profile['preferred_locations'])) missing++;
    if (isEmpty(profile['preferred_job_types'])) missing++;
    if (profile['is_open_to_work'] != true) missing++;

    // Education requirement: at least 1 row in user_education
    final userId = _supabase.auth.currentUser!.id;
    final edu = await _supabase
        .from('user_education')
        .select('id')
        .eq('user_id', userId)
        .limit(1);

    if ((edu as List).isEmpty) missing++;

    return missing;
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------

  String _firstNameOrFallback(String fullName) {
    if (fullName.trim().isEmpty) return "Your Profile";
    final parts = fullName.trim().split(RegExp(r"\s+"));
    if (parts.isEmpty) return "Your Profile";
    return "${parts.first}'s profile";
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  String _formatLastUpdated(String? iso) {
    if (iso == null || iso.trim().isEmpty) return "Updated recently";

    final d = DateTime.tryParse(iso);
    if (d == null) return "Updated recently";

    final diff = DateTime.now().difference(d);

    if (diff.inMinutes < 60) return "Updated just now";
    if (diff.inHours < 24) return "Updated today";
    if (diff.inDays == 1) return "Updated 1d ago";
    if (diff.inDays < 7) return "Updated ${diff.inDays}d ago";
    if (diff.inDays < 30) return "Updated ${(diff.inDays / 7).floor()}w ago";

    return "Updated ${(diff.inDays / 30).floor()}mo ago";
  }
}