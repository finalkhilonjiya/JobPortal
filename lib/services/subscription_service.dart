// File: lib/services/subscription_service.dart

import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

class SubscriptionService {

  final SupabaseClient _db = Supabase.instance.client;

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
  // GET ACTIVE SUBSCRIPTION
  // ============================================================

  Future<Map<String, dynamic>?> getMySubscription() async {

    final uid = _uid();

    final res = await _db
        .from('user_subscriptions')
        .select('''
          user_id,
          status,
          plan_name,
          started_at,
          expires_at,
          razorpay_order_id,
          razorpay_payment_id
        ''')
        .eq('user_id', uid)
        .order('expires_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (res == null) return null;

    return Map<String, dynamic>.from(res);
  }

  // ============================================================
  // CHECK ACTIVE ACCESS
  // ============================================================

  Future<bool> isProActive() async {

    final sub = await getMySubscription();

    if (sub == null) return false;

    final expiresRaw = sub['expires_at'];

    if (expiresRaw == null) return false;

    final expires =
        DateTime.tryParse(expiresRaw.toString());

    if (expires == null) return false;

    return expires.isAfter(DateTime.now());
  }

  // ============================================================
  // CREATE RAZORPAY ORDER
  // ============================================================

  Future<Map<String, dynamic>> createRazorpayOrder() async {

    _ensureAuth();

    final session = _db.auth.currentSession;

    if (session == null) {
      throw Exception("Session missing");
    }

    final response = await http.post(
      Uri.parse(_createOrderUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization":
            "Bearer ${session.accessToken}",
      },
    );

    final body = jsonDecode(response.body);

    if (response.statusCode != 200 ||
        body["success"] != true) {

      throw Exception(
        body["error"] ??
            "Failed to create Razorpay order",
      );
    }

    return Map<String, dynamic>.from(body);
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

    final session = _db.auth.currentSession;

    if (session == null) {
      throw Exception("Session missing");
    }

    final response = await http.post(
      Uri.parse(_verifyPaymentUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization":
            "Bearer ${session.accessToken}",
      },
      body: jsonEncode({
        "razorpay_order_id": razorpayOrderId,
        "razorpay_payment_id": razorpayPaymentId,
        "razorpay_signature": razorpaySignature,
      }),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode != 200 ||
        body["success"] != true) {

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