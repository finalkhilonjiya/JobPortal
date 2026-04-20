// File: lib/services/subscription_service.dart

import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

class SubscriptionService {

  final SupabaseClient _db = Supabase.instance.client;

  /// ============================================================
  /// GOOGLE VERIFY EDGE FUNCTION
  /// ============================================================

  static const String _googleVerifyUrl =
      "https://rsskivonmfqrzxbmxrkl.supabase.co/functions/v1/verify-google-subscription";

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
  // ✅ GET ACTIVE SUBSCRIPTION
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
        purchase_token
      ''')
      .eq('user_id', uid)
      .eq('status', 'active')
      .order('expires_at', ascending: false) // ✅ pick latest
      .limit(1) // ✅ avoid multiple rows issue
      .maybeSingle();

  if (res == null) return null;

  return Map<String, dynamic>.from(res);
}

  // ============================================================
  // ✅ CHECK ACTIVE ACCESS
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
  // ✅ GOOGLE PLAY ONE-TIME PURCHASE VERIFY
  // ============================================================

  Future<void> verifyOneTimePurchase({
    required String purchaseToken,
    required String productId,
    required String orderId,
  }) async {

    _ensureAuth();

    final session = _db.auth.currentSession;

    if (session == null) {
      throw Exception("Session missing");
    }

    final response = await http.post(
      Uri.parse(_googleVerifyUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization":
            "Bearer ${session.accessToken}",
      },
      body: jsonEncode({
        "product_id": productId,
        "purchase_token": purchaseToken,
        "order_id": orderId,
        "purchase_type": "one_time"
      }),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode != 200 ||
        body["success"] != true) {

      throw Exception(
        body["error"] ??
            "Google Play verification failed",
      );
    }
  }

  // ============================================================
  // ✅ LEGACY (KEEP SAFE)
  // ============================================================

  Future<void> verifyPlayStorePurchase({
    required String purchaseToken,
    required String productId,
    required String orderId,
  }) async {

    await verifyOneTimePurchase(
      purchaseToken: purchaseToken,
      productId: productId,
      orderId: orderId,
    );
  }

  // ============================================================
  // ✅ FORCE REFRESH
  // ============================================================

  Future<void> refreshSubscription() async {
    await getMySubscription();
  }
}