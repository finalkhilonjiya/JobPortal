// File: lib/services/subscription_service.dart

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionService {

  final SupabaseClient _db =
      Supabase.instance.client;

  /// ============================================================
  /// RAZORPAY EDGE FUNCTIONS
  /// ============================================================

  static const String _createOrderUrl =
      "https://rsskivonmfqrzxbmxrkl.supabase.co/functions/v1/create-razorpay-order";

  static const String _verifyPaymentUrl =
      "https://rsskivonmfqrzxbmxrkl.supabase.co/functions/v1/verify-razorpay-payment";

  /// The exact same 12 fields (and truthiness rules) that
  /// JobSeekerHomeService._calculateProfileCompletion() uses to compute
  /// profile_completion_percentage. Kept in sync deliberately — Premium
  /// activation readiness == 100% profile completion, same definition
  /// everywhere in the app.
  static const List<String> _requiredFieldKeys = [
    'full_name',
    'mobile_number',
    'current_city',
    'current_state',
    'highest_education',
    'total_experience_years',
    'expected_salary_min',
    'skills',
    'bio',
    'preferred_job_types',
    'resume_url',
    'avatar_url',
  ];

  static const Map<String, String> _requiredFieldLabels = {
    'full_name': 'Full name',
    'mobile_number': 'Mobile number',
    'current_city': 'City / district',
    'current_state': 'State',
    'highest_education': 'Highest education',
    'total_experience_years': 'Years of experience',
    'expected_salary_min': 'Expected salary',
    'skills': 'At least one skill',
    'bio': 'About you (bio)',
    'preferred_job_types': 'Preferred job type',
    'resume_url': 'Resume',
    'avatar_url': 'Profile photo',
  };

  // ============================================================
  // AUTH
  // ============================================================

  void _ensureAuth() {

    if (_db.auth.currentUser == null) {
      throw Exception("Login required");
    }
  }

  String _uid() {

    _ensureAuth();

    return _db.auth.currentUser!.id;
  }

  // ============================================================
  // GET CURRENT USER PROFILE
  // ============================================================

  Future<Map<String, dynamic>?>
      getCurrentUserProfile() async {

    final uid = _uid();

    final res = await _db
        .from('user_profiles')
        .select('''
          id,
          full_name,
          mobile_number,
          actual_email,
          current_city,
          current_state,
          highest_education,
          total_experience_years,
          expected_salary_min,
          skills,
          bio,
          preferred_job_types,
          resume_url,
          avatar_url,
          profile_completion_percentage
        ''')
        .eq('id', uid)
        .maybeSingle();

    if (res == null) {
      return null;
    }

    return Map<String, dynamic>.from(res);
  }

  // ============================================================
  // GET ACTIVE SUBSCRIPTION (Khilonjiya Premium — lifetime)
  // ============================================================

  Future<Map<String, dynamic>?>
      getMySubscription() async {

    final uid = _uid();

    final res = await _db
        .from('user_subscriptions')
        .select('''
          user_id,
          status,
          plan_name,
          plan_key,
          amount_rupees,
          is_lifetime,
          started_at,
          expires_at,
          razorpay_order_id,
          razorpay_payment_id,
          mobile_number
        ''')
        .eq('user_id', uid)
        .order(
          'created_at',
          ascending: false,
        )
        .limit(1)
        .maybeSingle();

    if (res == null) {
      return null;
    }

    return Map<String, dynamic>.from(res);
  }

  // ============================================================
  // CHECK ACTIVE ACCESS
  // ============================================================

  Future<bool> isProActive() async {

    final sub =
        await getMySubscription();

    if (sub == null) {
      return false;
    }

    final status =
        (sub['status'] ?? '').toString();

    if (status != 'active') {
      return false;
    }

    final isLifetime =
        sub['is_lifetime'] == true;

    if (isLifetime) {
      return true;
    }

    final expiresRaw =
        sub['expires_at'];

    if (expiresRaw == null) {
      return false;
    }

    final expires =
        DateTime.tryParse(
      expiresRaw.toString(),
    );

    if (expires == null) {
      return false;
    }

    return expires.isAfter(
      DateTime.now(),
    );
  }

  /// True only for the "paid, waiting on profile completion" state.
  Future<bool> isPendingProfileActivation() async {

    final sub = await getMySubscription();

    if (sub == null) return false;

    return (sub['status'] ?? '') == 'paid_pending_profile';
  }

  // ============================================================
  // PROFILE READINESS — same 12-field definition used by the
  // profile completion % calculator server-side.
  // ============================================================

  /// Returns the list of missing item labels (empty = ready to activate).
  Future<List<String>> getMissingProfileItems() async {

    final profile = await getCurrentUserProfile();

    if (profile == null) {
      return _requiredFieldKeys
          .map((k) => _requiredFieldLabels[k] ?? k)
          .toList();
    }

    final missing = <String>[];

    for (final key in _requiredFieldKeys) {
      final v = profile[key];

      bool ok;
      if (v == null) {
        ok = false;
      } else if (v is String) {
        ok = v.trim().isNotEmpty;
      } else if (v is num) {
        ok = v > 0;
      } else if (v is List) {
        ok = v.isNotEmpty;
      } else {
        ok = v.toString().trim().isNotEmpty;
      }

      if (!ok) {
        missing.add(_requiredFieldLabels[key] ?? key);
      }
    }

    return missing;
  }

  Future<bool> isProfileReadyForPremium() async {
    final missing = await getMissingProfileItems();
    return missing.isEmpty;
  }

  /// Reads the persisted profile_completion_percentage (already
  /// computed and saved by JobSeekerHomeService.updateMyProfile on
  /// every save) — use this for display, it's the single source of
  /// truth already used elsewhere in the app.
  Future<int> getProfileCompletionPercent() async {

    final profile = await getCurrentUserProfile();

    final raw = profile?['profile_completion_percentage'];

    final pct = raw is int ? raw : int.tryParse('$raw') ?? 0;

    return pct.clamp(0, 100);
  }

  // ============================================================
  // SELF-SERVICE ACTIVATION
  // Call whenever the subscription page loads. No-op if there's
  // nothing pending. Flips a paid-but-incomplete Premium to active
  // the instant the profile becomes complete.
  // ============================================================

  Future<bool> activatePendingPremium() async {

    _ensureAuth();

    try {
      final res = await _db.rpc('activate_pending_premium');

      if (res == null) return false;

      final row = (res is List && res.isNotEmpty)
          ? Map<String, dynamic>.from(res.first)
          : null;

      return row?['activated'] == true;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // CREATE RAZORPAY ORDER
  // ============================================================

  Future<Map<String, dynamic>>
      createRazorpayOrder() async {

    _ensureAuth();

    final session =
        _db.auth.currentSession;

    if (session == null) {
      throw Exception("Session missing");
    }

    final response = await http.post(

      Uri.parse(_createOrderUrl),

      headers: {

        "Content-Type":
            "application/json",

        "Authorization":
            "Bearer ${session.accessToken}",
      },
    );

    final body =
        jsonDecode(response.body);

    if (response.statusCode != 200) {

      final err = body["error"] ?? "Failed to create Razorpay order";
      final details = body["details"];

      throw Exception(
        details != null ? "$err: $details" : err,
      );
    }

    return Map<String, dynamic>.from(
      body,
    );
  }

  // ============================================================
  // VERIFY RAZORPAY PAYMENT
  // Returns the parsed response — includes `activated` (true if
  // Premium is live now) and `pending_profile` (true if payment
  // succeeded but the profile still needs completing).
  // ============================================================

  Future<Map<String, dynamic>> verifyRazorpayPayment({

    required String razorpayOrderId,

    required String razorpayPaymentId,

    required String razorpaySignature,

  }) async {

    _ensureAuth();

    final session =
        _db.auth.currentSession;

    final user =
        _db.auth.currentUser;

    if (session == null || user == null) {
      throw Exception("Session missing");
    }

    final profile =
        await getCurrentUserProfile();

    String mobile =
        (profile?['mobile_number'] ?? "")
            .toString()
            .trim();

    mobile = mobile
        .replaceAll("+91", "")
        .replaceAll(" ", "")
        .replaceAll("-", "");

    mobile = mobile.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    final response = await http.post(

      Uri.parse(_verifyPaymentUrl),

      headers: {

        "Content-Type":
            "application/json",

        "Authorization":
            "Bearer ${session.accessToken}",
      },

      body: jsonEncode({

        "user_id": user.id,

        "mobile_number": mobile,

        "razorpay_order_id":
            razorpayOrderId,

        "razorpay_payment_id":
            razorpayPaymentId,

        "razorpay_signature":
            razorpaySignature,
      }),
    );

    final body =
        jsonDecode(response.body);

    if (
        response.statusCode != 200 ||
        body["success"] != true
    ) {

      final err = body["error"] ?? "Payment verification failed";
      final details = body["details"];

      throw Exception(
        details != null ? "$err: $details" : err,
      );
    }

    return Map<String, dynamic>.from(body);
  }

  // ============================================================
  // FORCE REFRESH
  // ============================================================

  Future<void> refreshSubscription() async {

    await getMySubscription();
  }
}
