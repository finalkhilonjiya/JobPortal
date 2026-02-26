// File: lib/services/subscription_service.dart

import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

class SubscriptionService {

  final SupabaseClient _db = Supabase.instance.client;

  /// ============================================================
  /// EDGE FUNCTION (GOOGLE PLAY VERIFY)
  /// ============================================================
  /// CHANGE ONLY PROJECT REF
  static const String _googleVerifyUrl =
      "https://rsskivonmfqrzxbmxrkl.supabase.co/functions/v1/verify-google-subscription";

  // ============================================================
  // AUTH HELPERS
  // ============================================================

  void _ensureAuth() {
    final user = _db.auth.currentUser;
    if (user == null) {
      throw Exception("Login required");
    }
  }

  String _uid() {
    _ensureAuth();
    return _db.auth.currentUser!.id;
  }

  // ============================================================
  // SUBSCRIPTION STATUS
  // ============================================================

  Future<Map<String, dynamic>?> getMySubscription() async {

    final uid = _uid();

    final res = await _db
        .from('subscriptions')
        .select(
            'id, user_id, status, plan_price, starts_at, expires_at')
        .eq('user_id', uid)
        .maybeSingle();

    if (res == null) return null;

    return Map<String, dynamic>.from(res);
  }

  Future<bool> isProActive() async {

    final sub = await getMySubscription();

    if (sub == null) return false;

    final status =
        (sub['status'] ?? '').toString();

    if (status != 'active') return false;

    final expiresRaw =
        sub['expires_at'];

    if (expiresRaw == null) return false;

    final expires =
        DateTime.tryParse(
            expiresRaw.toString());

    if (expires == null) return false;

    return expires.isAfter(
        DateTime.now());
  }

  // ============================================================
  // ✅ GOOGLE PLAY VERIFY (NEW)
  // ============================================================

  Future<void> verifyPlayStorePurchase({
    required String purchaseToken,
    required String productId,
    required String orderId,
  }) async {

    _ensureAuth();

    final user =
        _db.auth.currentUser!;

    final session =
        _db.auth.currentSession;

    if (session == null) {
      throw Exception("Session missing");
    }

    final response =
        await http.post(
      Uri.parse(_googleVerifyUrl),
      headers: {
        "Content-Type":
            "application/json",
        "Authorization":
            "Bearer ${session.accessToken}",
      },
      body: jsonEncode({
        "user_id": user.id,
        "product_id": productId,
        "purchase_token":
            purchaseToken,
        "order_id": orderId,
      }),
    );

    final body =
        jsonDecode(response.body);

    if (response.statusCode != 200 ||
        body["success"] != true) {

      throw Exception(
        body["error"] ??
            "Google subscription verification failed",
      );
    }
  }

  // ============================================================
  // RAZORPAY - CREATE ORDER
  // ============================================================

  Future<Map<String, dynamic>> createOrder({
    int amountRupees = 999,
    String planKey = "pro_monthly",
  }) async {

    final uid = _uid();

    final res =
        await _db.functions.invoke(
      'create-razorpay-order',
      body: {
        "user_id": uid,
        "plan_key": planKey,
        "amount_rupees":
            amountRupees,
      },
    );

    if (res.data == null) {
      throw Exception(
          "Create order failed");
    }

    return Map<String,
            dynamic>.from(
        res.data as Map);
  }

  // ============================================================
  // RAZORPAY VERIFY
  // ============================================================

  Future<void> verifyPayment({
    required String transactionId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {

    final uid = _uid();

    final res =
        await _db.functions.invoke(
      'verify-razorpay-payment',
      body: {
        "transaction_id":
            transactionId,
        "razorpay_order_id":
            razorpayOrderId,
        "razorpay_payment_id":
            razorpayPaymentId,
        "razorpay_signature":
            razorpaySignature,
        "user_id": uid,
      },
    );

    if (res.data == null) {
      throw Exception(
          "Payment verification failed");
    }

    final data =
        Map<String,
            dynamic>.from(
        res.data as Map);

    if (data['success'] != true) {
      throw Exception(
          data['error'] ??
              "Payment verification failed");
    }
  }
}