// lib/services/auth/mobile_auth_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MobileAuthService {
  static final MobileAuthService _instance = MobileAuthService._internal();
  factory MobileAuthService() => _instance;
  MobileAuthService._internal();

  static const String _userKey = 'auth_user';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _deviceFingerprintKey = 'device_fingerprint';

  String? _cachedDeviceFingerprint;
  Map<String, dynamic>? _currentUser;
  String? _refreshToken;
  bool _isInitialized = false;

  Future<void> initialize() async {
    await _loadStoredAuth();
    await _generateDeviceFingerprint();
    _isInitialized = true;
  }

  SupabaseClient get _supabaseClient => Supabase.instance.client;

  Future<String> _generateDeviceFingerprint() async {
    if (_cachedDeviceFingerprint != null) return _cachedDeviceFingerprint!;
    final prefs = await SharedPreferences.getInstance();
    String? stored = prefs.getString(_deviceFingerprintKey);
    if (stored != null) {
      _cachedDeviceFingerprint = stored;
      return stored;
    }
    final deviceInfo = DeviceInfoPlugin();
    final buffer = StringBuffer();
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = await deviceInfo.androidInfo;
      buffer.write('${android.model}_${android.id}_${android.device}');
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = await deviceInfo.iosInfo;
      buffer.write('${ios.model}_${ios.identifierForVendor}');
    } else {
      buffer.write('web_${DateTime.now().millisecondsSinceEpoch}');
    }
    final hash = sha256.convert(utf8.encode(buffer.toString())).toString();
    await prefs.setString(_deviceFingerprintKey, hash);
    _cachedDeviceFingerprint = hash;
    return hash;
  }

  Future<void> _loadStoredAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) _currentUser = jsonDecode(userJson);
    _refreshToken = prefs.getString(_refreshTokenKey);
  }

  Future<void> _storeAuthData(Map<String, dynamic> user, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
    await prefs.setString(_refreshTokenKey, token);
    _currentUser = user;
    _refreshToken = token;
  }

  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_refreshTokenKey);
    _currentUser = null;
    _refreshToken = null;
  }

  /* ---------- DEMO OTP = 123456 ---------- */
  Future<OtpResponse> sendOtp(String mobile) async {
    if (!_isInitialized) throw MobileAuthException('Service not initialized');
    final clean = mobile.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.length != 10 || clean[0] == '0') {
      throw MobileAuthException('Invalid mobile number format');
    }
    final phone = '+91$clean';

    final res = await _supabaseClient.functions.invoke(
      'smart-function',
      body: {'mobile_number': phone, 'action': 'request-otp'},
    );

    if (res.status != 200 || res.data['success'] != true) {
      throw MobileAuthException(res.data['error'] ?? 'OTP send failed');
    }
    return OtpResponse(
      success: true,
      message: res.data['message'] ?? 'OTP sent',
      otpForTesting: '123456', // demo OTP
    );
  }

  Future<AuthResponse> verifyOtp(String mobile, String otp) async {
    if (!_isInitialized) throw MobileAuthException('Service not initialized');
    final clean = mobile.replaceAll(RegExp(r'[^\d]'), '');
    final phone = '+91$clean';
    final fingerprint = await _generateDeviceFingerprint();

    final res = await _supabaseClient.functions.invoke(
      'smart-function',
      body: {
        'mobile_number': phone,
        'otp': otp,
        'device_fingerprint': fingerprint,
        'action': 'verify-otp',
      },
    );

    if (res.status != 200 || res.data['success'] != true) {
      throw MobileAuthException(res.data['error'] ?? 'Invalid OTP');
    }

    final user = res.data['user'];
    final refreshToken = 'refresh_${DateTime.now().millisecondsSinceEpoch}';
    await _storeAuthData(user, refreshToken);

    return AuthResponse(success: true, user: user, message: 'Authenticated');
  }

  /* ---------- Utils ---------- */
  bool get isAuthenticated => _currentUser != null && _refreshToken != null;
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get userId => _currentUser?['id'];
  String? get userMobile => _currentUser?['mobile_number'];
  Future<void> logout() async => await _clearAuthData();
}

/* ---------- Models ---------- */
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

class MobileAuthException implements Exception {
  final String message;
  MobileAuthException(this.message);
  @override
  String toString() => 'MobileAuthException: $message';
}