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

  static const String _createBoostOrderUrl =
      "https://rsskivonmfqrzxbmxrkl.supabase.co/functions/v1/create-boost-razorpay-order";

  static const String _verifyBoostPaymentUrl =
      "https://rsskivonmfqrzxbmxrkl.supabase.co/functions/v1/verify-boost-razorpay-payment";

  static const int boostPricePerMonthRupees = 49;

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
          avatar_url,
          resume_url,
          current_job_title,
          current_city,
          current_state,
          total_experience_years,
          expected_salary_min,
          expected_salary_max,
          skills,
          is_boost_enabled
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
  // Khilonjiya Premium is a one-time, lifetime purchase, so a
  // subscription is active whenever status == 'active' AND either
  // is_lifetime == true OR (legacy rows) expires_at is in the future.
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

  // ============================================================
  // CREATE RAZORPAY ORDER (Khilonjiya Premium)
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
  // VERIFY RAZORPAY PAYMENT (Khilonjiya Premium)
  // ============================================================

  Future<void> verifyRazorpayPayment({

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
  }

  // ============================================================
  // BOOST — paid, monthly, requires Premium + a complete profile.
  // Only boosted (and not expired) profiles show up in the
  // employer candidate database.
  // ============================================================

  Future<Map<String, dynamic>?> getBoostSubscription() async {

    final uid = _uid();

    final res = await _db
        .from('boost_subscriptions')
        .select('''
          id,
          user_id,
          months,
          amount_rupees,
          status,
          started_at,
          expires_at
        ''')
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (res == null) return null;

    return Map<String, dynamic>.from(res);
  }

  Future<bool> isBoostActive() async {

    final sub = await getBoostSubscription();

    if (sub == null) return false;
    if ((sub['status'] ?? '') != 'active') return false;

    final expiresRaw = sub['expires_at'];
    if (expiresRaw == null) return false;

    final expires = DateTime.tryParse(expiresRaw.toString());
    if (expires == null) return false;

    return expires.isAfter(DateTime.now());
  }

  /// Returns the list of missing items (empty list = profile is ready).
  /// Mirrors public.is_profile_boost_ready() — the edge function
  /// re-checks this server-side too, this is just for fast UI feedback.
  Future<List<String>> getBoostProfileMissingItems() async {

    final profile = await getCurrentUserProfile();

    final missing = <String>[];

    if (profile == null) {
      return ["Profile not found"];
    }

    if ((profile['avatar_url'] ?? '').toString().trim().isEmpty) {
      missing.add("Profile photo");
    }
    if ((profile['resume_url'] ?? '').toString().trim().isEmpty) {
      missing.add("Resume");
    }
    if ((profile['full_name'] ?? '').toString().trim().isEmpty) {
      missing.add("Full name");
    }
    if ((profile['current_city'] ?? '').toString().trim().isEmpty) {
      missing.add("City");
    }
    if ((profile['current_state'] ?? '').toString().trim().isEmpty) {
      missing.add("State");
    }
    if (profile['total_experience_years'] == null) {
      missing.add("Years of experience");
    }
    if (profile['expected_salary_min'] == null) {
      missing.add("Expected salary");
    }
    final skills = profile['skills'];
    if (skills == null || (skills is List && skills.isEmpty)) {
      missing.add("At least one skill");
    }

    return missing;
  }

  Future<bool> isProfileBoostReady() async {
    final missing = await getBoostProfileMissingItems();
    return missing.isEmpty;
  }

  // ============================================================
  // CREATE RAZORPAY ORDER (Boost)
  // ============================================================

  Future<Map<String, dynamic>> createBoostRazorpayOrder({
    required int months,
  }) async {

    _ensureAuth();

    final session = _db.auth.currentSession;
    if (session == null) {
      throw Exception("Session missing");
    }

    final response = await http.post(
      Uri.parse(_createBoostOrderUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${session.accessToken}",
      },
      body: jsonEncode({
        "months": months,
      }),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode != 200) {
      final err = body["error"] ?? "Failed to create Boost order";
      final details = body["details"];
      throw Exception(
        details != null ? "$err: $details" : err,
      );
    }

    return Map<String, dynamic>.from(body);
  }

  // ============================================================
  // VERIFY RAZORPAY PAYMENT (Boost)
  // ============================================================

  /// Returns the parsed response, which includes:
  /// - activated: true if Boost is live now (profile was already complete)
  /// - pending_profile: true if payment succeeded but the profile still
  ///   needs to be completed before Boost actually turns on
  Future<Map<String, dynamic>> verifyBoostRazorpayPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {

    _ensureAuth();

    final session = _db.auth.currentSession;
    if (session == null) {
      throw Exception("Session missing");
    }

    final response = await http.post(
      Uri.parse(_verifyBoostPaymentUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${session.accessToken}",
      },
      body: jsonEncode({
        "razorpay_order_id": razorpayOrderId,
        "razorpay_payment_id": razorpayPaymentId,
        "razorpay_signature": razorpaySignature,
      }),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode != 200 || body["success"] != true) {
      final err = body["error"] ?? "Boost verification failed";
      final details = body["details"];
      throw Exception(
        details != null ? "$err: $details" : err,
      );
    }

    return Map<String, dynamic>.from(body);
  }

  /// Call this whenever the subscription page loads. It's a harmless
  /// no-op if there's nothing to activate. The moment a paid-but-pending
  /// Boost's profile becomes complete, this flips it to active and
  /// starts the expiry clock (the actual "activation" moment).
  Future<bool> activatePendingBoost() async {

    _ensureAuth();

    try {
      final res = await _db.rpc('activate_pending_boost');

      if (res == null) return false;

      final row = (res is List && res.isNotEmpty)
          ? Map<String, dynamic>.from(res.first)
          : null;

      return row?['activated'] == true;
    } catch (_) {
      // Non-fatal — just means nothing was pending, or a transient error.
      return false;
    }
  }

  // ============================================================
  // FORCE REFRESH
  // ============================================================

  Future<void> refreshSubscription() async {

    await getMySubscription();

    await getBoostSubscription();
  }
}
