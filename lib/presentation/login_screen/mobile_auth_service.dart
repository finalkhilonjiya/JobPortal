import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Custom exception
class MobileAuthException implements Exception {
  final String message;
  MobileAuthException(this.message);
  @override
  String toString() => message;
}

class MobileAuthService {
  final SupabaseClient supabase = Supabase.instance.client;

  final String edgeFunctionUrl =
      '${Supabase.instance.client.options.functionsUrl}/smart-function';

  Session? _session;

  /// Initialize service and restore session if possible
  Future<void> initialize() async {
    final currentSession = supabase.auth.currentSession;
    if (currentSession != null) {
      _session = currentSession;
    }
  }

  /// Whether user is authenticated
  bool get isAuthenticated => _session != null;

  /// Refresh stored session (validate with backend)
  Future<bool> refreshSession() async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null || _session == null) return false;

      // Call refresh-session on Edge Function
      final res = await http.post(
        Uri.parse(edgeFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'refresh-session',
          'user_id': currentUser.id,
          'refreshToken': _session?.refreshToken,
        }),
      );

      final body = jsonDecode(res.body);
      return res.statusCode == 200 && body['success'] == true;
    } catch (e) {
      debugPrint("refreshSession error: $e");
      return false;
    }
  }

  /// Send OTP wrapper
  Future<void> sendOtp(String mobileNumber) async {
    final ok = await requestOtp(mobileNumber);
    if (!ok) throw MobileAuthException("Failed to send OTP");
  }

  /// Request OTP from Edge Function
  Future<bool> requestOtp(String mobileNumber) async {
    try {
      final res = await http.post(
        Uri.parse(edgeFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mobile_number': mobileNumber,
          'action': 'request-otp',
          'device_fingerprint': 'flutter-app',
        }),
      );

      final body = jsonDecode(res.body);
      return res.statusCode == 200 && body['success'] == true;
    } catch (e) {
      debugPrint("requestOtp error: $e");
      return false;
    }
  }

  /// Verify OTP and set session
  Future<bool> verifyOtp(String mobileNumber, String otp) async {
    try {
      final res = await http.post(
        Uri.parse(edgeFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mobile_number': mobileNumber,
          'otp': otp,
          'action': 'verify-otp',
          'device_fingerprint': 'flutter-app',
        }),
      );

      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        final String accessToken = body['accessToken'];
        final String refreshToken = body['refreshToken'];

        final session = await supabase.auth.setSession(
          accessToken,
          refreshToken,
        );

        _session = session.session;
        return true;
      } else {
        throw MobileAuthException(body['error'] ?? 'OTP verification failed');
      }
    } catch (e) {
      debugPrint("verifyOtp error: $e");
      return false;
    }
  }

  /// Current user getter
  User? get currentUser => supabase.auth.currentUser;

  /// Logout
  Future<void> logout() async {
    await supabase.auth.signOut();
    _session = null;
  }

  /// Utility: validate mobile number
  static bool isValidMobileNumber(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10;
  }

  /// Utility: format number
  static String formatMobileNumber(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 10) return digits;
    return digits.substring(digits.length - 10);
  }
}