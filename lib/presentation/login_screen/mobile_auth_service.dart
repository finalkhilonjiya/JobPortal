// lib/presentation/login/mobile_auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class MobileAuthException implements Exception {
  final String message;
  MobileAuthException(this.message);
}

class MobileAuthService {
  static const String _functionUrl =
      "https://YOUR_PROJECT_ID.functions.supabase.co/smart-function";

  bool isAuthenticated = false;
  String? _userId;

  Future<void> initialize() async {
    // nothing heavy for now
  }

  Future<bool> checkConnection() async {
    try {
      final res = await http.post(
        Uri.parse(_functionUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"action": "ping"}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> sendOtp(String mobileNumber) async {
    final res = await http.post(
      Uri.parse(_functionUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"action": "request-otp", "mobile_number": mobileNumber}),
    );

    if (res.statusCode != 200) {
      throw MobileAuthException("Failed to send OTP");
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String mobileNumber, String otp) async {
    final res = await http.post(
      Uri.parse(_functionUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "action": "verify-otp",
        "mobile_number": mobileNumber,
        "otp": otp,
      }),
    );

    final body = jsonDecode(res.body);

    if (res.statusCode != 200) {
      throw MobileAuthException(body["error"] ?? "OTP verification failed");
    }

    isAuthenticated = true;
    _userId = body["user_id"];
    return body;
  }

  Future<bool> refreshSession() async {
    return isAuthenticated;
  }

  static bool isValidMobileNumber(String input) {
    return RegExp(r'^[6-9]\d{9}$').hasMatch(input);
  }
}