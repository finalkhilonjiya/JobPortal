import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles Supabase initialization
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
  }
}

/// Authentication service for mobile OTP
class MobileAuthService {
  static final MobileAuthService _instance = MobileAuthService._internal();
  factory MobileAuthService() => _instance;
  MobileAuthService._internal();

  static const String _sessionKey = 'supabase_session';

  Session? _session;
  Map<String, dynamic>? _currentUser;

  /// Initialize auth service: restore saved session if available
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString(_sessionKey);

    if (sessionJson != null) {
      try {
        final data = jsonDecode(sessionJson);
        _session = Session.fromJson(data);
        _currentUser = _session?.user.toJson();
        SupabaseService().client.auth.currentSession = _session;
        debugPrint('Restored Supabase session for user: ${_currentUser?['id']}');
      } catch (e) {
        debugPrint('Failed to restore session: $e');
      }
    }
  }

  /// Store Supabase session locally
  Future<void> _storeSession(Session session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
    _session = session;
    _currentUser = session.user.toJson();
    debugPrint('Stored session for user: ${_currentUser?['id']}');
  }

  /// Clear stored session
  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    _session = null;
    _currentUser = null;
    await SupabaseService().client.auth.signOut();
    debugPrint('Cleared Supabase session');
  }

  /// Send OTP (always returns 123456 in dev)
  Future<OtpResponse> sendOtp(String mobileNumber) async {
    try {
      final phoneNumber = '+91${mobileNumber.replaceAll(RegExp(r'[^\d]'), '')}';
      final response = await SupabaseService().client.functions.invoke(
        'smart-function',
        body: {
          'action': 'request-otp',
          'mobile_number': phoneNumber,
        },
      );

      if (response.status == 200 &&
          response.data is Map &&
          response.data['success'] == true) {
        return OtpResponse(
          success: true,
          message: response.data['message'] ?? 'OTP sent',
          otpForTesting: '123456', // dummy OTP
        );
      }
      throw MobileAuthException('Failed to send OTP');
    } catch (e) {
      debugPrint('Send OTP Error: $e');
      throw MobileAuthException('Network error during OTP send');
    }
  }

  /// Verify OTP and log user in
  Future<AuthResponse> verifyOtp(String mobileNumber, String otp) async {
    try {
      final phoneNumber = '+91${mobileNumber.replaceAll(RegExp(r'[^\d]'), '')}';
      final response = await SupabaseService().client.functions.invoke(
        'smart-function',
        body: {
          'action': 'verify-otp',
          'mobile_number': phoneNumber,
          'otp': otp,
        },
      );

      if (response.status == 200 &&
          response.data is Map &&
          response.data['success'] == true) {
        final data = response.data;
        final user = data['user'] as Map<String, dynamic>;
        final accessToken = data['accessToken'] as String;
        final refreshToken = data['refreshToken'] as String;

        // Build session for Supabase
        final session = Session(
          accessToken: accessToken,
          refreshToken: refreshToken,
          tokenType: 'bearer',
          user: User.fromJson(user),
        );

        await _storeSession(session);
        SupabaseService().client.auth.currentSession = session;

        return AuthResponse(
          success: true,
          user: user,
          message: data['message'] ?? 'Login successful',
        );
      }

      throw MobileAuthException('Invalid OTP or login failed');
    } catch (e) {
      debugPrint('Verify OTP Error: $e');
      throw MobileAuthException('Verification failed: ${e.toString()}');
    }
  }

  /// Refresh session (calls edge function)
  Future<bool> refreshSession() async {
    if (_session == null) return false;
    try {
      final response = await SupabaseService().client.functions.invoke(
        'smart-function',
        body: {
          'action': 'refresh-session',
          'user_id': _session!.user.id,
          'refreshToken': _session!.refreshToken,
        },
      );

      if (response.status == 200 &&
          response.data is Map &&
          response.data['success'] == true) {
        return true;
      }
      await _clearSession();
      return false;
    } catch (e) {
      await _clearSession();
      return false;
    }
  }

  // Getters
  bool get isAuthenticated => _session != null;
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get userId => _currentUser?['id'];

  Future<void> logout() async => _clearSession();

  /// Utility methods
  static String formatMobileNumber(String mobile) {
    final clean = mobile.replaceAll(RegExp(r'[^\d]'), '');
    return clean.length == 10
        ? '${clean.substring(0, 5)}-${clean.substring(5)}'
        : mobile;
  }

  static bool isValidMobileNumber(String mobile) {
    final clean = mobile.replaceAll(RegExp(r'[^\d]'), '');
    return clean.length == 10 && clean[0] != '0';
  }
}

/// Response classes
class OtpResponse {
  final bool success;
  final String message;
  final String? otpForTesting;
  OtpResponse({required this.success, required this.message, this.otpForTesting});
}

class AuthResponse {
  final bool success;
  final Map<String, dynamic>? user;
  final String message;
  AuthResponse({required this.success, this.user, required this.message});
}

/// Custom exception
class MobileAuthException implements Exception {
  final String message;
  MobileAuthException(this.message);
  @override
  String toString() => 'MobileAuthException: $message';
}