// File: lib/services/employer_subscription_service.dart

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Khilonjiya Premium for employers.
/// Access is granted to the purchasing employer user only — it is NOT
/// shared automatically with other members of the same company.
class EmployerSubscriptionService {

  final SupabaseClient _db = Supabase.instance.client;

  static const String _createOrderUrl =
      "https://rsskivonmfqrzxbmxrkl.supabase.co/functions/v1/create-employer-razorpay-order";

  static const String _verifyPaymentUrl =
      "https://rsskivonmfqrzxbmxrkl.supabase.co/functions/v1/verify-employer-razorpay-payment";

  // ============================================================
  // PLAN CATALOG (mirrors public.subscription_plans)
  // ============================================================

  static const List<Map<String, dynamic>> plans = [
    {
      'plan_key': 'employer_premium_1m',
      'label': 'Khilonjiya Premium — 1 Month',
      'amount_rupees': 999,
      'duration_days': 30,
    },
    {
      'plan_key': 'employer_premium_3m',
      'label': 'Khilonjiya Premium — 3 Months',
      'amount_rupees': 1999,
      'duration_days': 90,
    },
  ];

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
  // GET MY (MOST RECENT) EMPLOYER SUBSCRIPTION
  // ============================================================

  Future<Map<String, dynamic>?> getMySubscription() async {

    final uid = _uid();

    final res = await _db
        .from('employer_subscriptions')
        .select('''
          id,
          employer_id,
          company_id,
          plan_key,
          amount_rupees,
          status,
          started_at,
          expires_at
        ''')
        .eq('employer_id', uid)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (res == null) return null;

    return Map<String, dynamic>.from(res);
  }

  // ============================================================
  // IS PREMIUM ACTIVE (client-side convenience check — the DB
  // RLS policy on job_listings and the get_candidate_database RPC
  // are the real enforcement, this is just for fast UI decisions)
  // ============================================================

  Future<bool> isPremiumActive() async {

    final sub = await getMySubscription();

    if (sub == null) return false;
    if ((sub['status'] ?? '') != 'active') return false;

    final expiresRaw = sub['expires_at'];
    if (expiresRaw == null) return false;

    final expires = DateTime.tryParse(expiresRaw.toString());
    if (expires == null) return false;

    return expires.isAfter(DateTime.now());
  }

  // ============================================================
  // CREATE RAZORPAY ORDER
  // ============================================================

  Future<Map<String, dynamic>> createRazorpayOrder({
    required String planKey,
    required String companyId,
  }) async {

    _ensureAuth();

    final session = _db.auth.currentSession;
    if (session == null) {
      throw Exception("Session missing");
    }

    final response = await http.post(
      Uri.parse(_createOrderUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${session.accessToken}",
      },
      body: jsonEncode({
        "plan_key": planKey,
        "company_id": companyId,
      }),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        body["error"] ?? "Failed to create Razorpay order",
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
      throw Exception(
        body["error"] ?? "Payment verification failed",
      );
    }
  }
}
