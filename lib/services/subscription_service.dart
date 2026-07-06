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
  // BOOST — only usable once the user has Khilonjiya Premium.
  // When enabled, the job seeker's profile becomes visible in the
  // employer candidate database search.
  // ============================================================

  Future<bool> getBoostStatus() async {

    final profile = await getCurrentUserProfile();

    return profile?['is_boost_enabled'] == true;
  }

  Future<void> setBoostEnabled(bool enabled) async {

    final uid = _uid();

    final isActive = await isProActive();

    if (enabled && !isActive) {
      throw Exception(
        "Boost is a Khilonjiya Premium feature. Activate Premium first.",
      );
    }

    await _db.from('user_profiles').update({
      'is_boost_enabled': enabled,
      'boost_enabled_at':
          enabled ? DateTime.now().toIso8601String() : null,
    }).eq('id', uid);
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

      throw Exception(
        body["error"] ??
            "Failed to create Razorpay order",
      );
    }

    return Map<String, dynamic>.from(
      body,
    );
  }

  // ============================================================
  // VERIFY RAZORPAY PAYMENT
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

    // =========================================================
    // GET USER PROFILE
    // =========================================================

    final profile =
        await getCurrentUserProfile();

    // =========================================================
    // MOBILE NUMBER FORMAT
    // Razorpay expects:
    // 9876543210
    // =========================================================

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

      throw Exception(
        body["error"] ??
            "Payment verification failed",
      );
    }
  }

  // ============================================================
  // FORCE REFRESH
  // ============================================================

  Future<void> refreshSubscription() async {

    await getMySubscription();
  }
}
