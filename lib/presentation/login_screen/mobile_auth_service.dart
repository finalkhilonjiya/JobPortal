import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class MobileAuthService {
  final SupabaseClient supabase = Supabase.instance.client;

  final String edgeFunctionUrl =
      '${Supabase.instance.client.functionsUrl}/smart-function';

  /// Request OTP for mobile number
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
      if (res.statusCode == 200 && body['success'] == true) {
        debugPrint("OTP requested successfully for $mobileNumber");
        return true;
      } else {
        debugPrint("OTP request failed: ${body['error']}");
        return false;
      }
    } catch (e, st) {
      debugPrint("OTP request error: $e\n$st");
      return false;
    }
  }

  /// Verify OTP and log user in
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

        // Save session into Supabase Auth
        final session = Session(
          accessToken: accessToken,
          refreshToken: refreshToken,
          user: User.fromJson(body['user']),
          tokenType: "bearer",
          providerToken: null,
          expiresIn: 3600, // 1 hour (Edge Function default JWT expiry)
        );

        await supabase.auth.setSession(session);

        debugPrint("User logged in successfully: ${body['user']['id']}");
        return true;
      } else {
        debugPrint("OTP verification failed: ${body['error']}");
        return false;
      }
    } catch (e, st) {
      debugPrint("OTP verification error: $e\n$st");
      return false;
    }
  }

  /// Get current logged-in user
  User? get currentUser {
    return supabase.auth.currentUser;
  }

  /// Logout user
  Future<void> logout() async {
    try {
      await supabase.auth.signOut();
      debugPrint("User logged out successfully");
    } catch (e) {
      debugPrint("Logout error: $e");
    }
  }
}