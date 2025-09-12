import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_export.dart';

class MobileAuthService {
  /* ----------  singleton  ---------- */
  static final MobileAuthService _instance = MobileAuthService._internal();
  factory MobileAuthService() => _instance;
  MobileAuthService._internal();

  /* ----------  keys  ---------- */
  static const String _userKey = 'auth_user';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _deviceFingerprintKey = 'device_fingerprint';

  String? _cachedDeviceFingerprint;
  Map<String, dynamic>? _currentUser;
  String? _refreshToken;
  bool _isInitialized = false;

  /* ----------  INIT  ---------- */
  Future<void> initialize() async {
    try {
      await _loadStoredAuth();
      await _generateDeviceFingerprint();
      _isInitialized = true;
    } catch (e) {
      rethrow;
    }
  }

  /* ----------  SUPABASE CLIENT (safe)  ---------- */
  SupabaseClient get _supabaseClient {
    final client = Supabase.instance.client;
    if (client == null) throw MobileAuthException('Supabase not initialized');
    return client;
  }

  /* ----------  DEVICE FINGERPRINT  ---------- */
  Future<String> _generateDeviceFingerprint() async {
    if (_cachedDeviceFingerprint != null) return _cachedDeviceFingerprint!;
    final prefs = await SharedPreferences.getInstance();
    String? stored = prefs.getString(_deviceFingerprintKey);
    if (stored != null) {
      _cachedDeviceFingerprint = stored;
      return stored;
    }
    final buffer = StringBuffer();
    final deviceInfo = DeviceInfoPlugin();
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

  /* ----------  LOCAL STORAGE  ---------- */
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
  Future<bool> refreshSession() async {
  /*  your old refresh logic here  */
  try {
    if (!isAuthenticated) return false;
    // call your refresh edge-function here
    return true;               // or false on failure
  } catch (_) {
    await _clearAuthData();
    return false;
  }
}


  /* ----------  OTP FLOW  ---------- */
  Future<OtpResponse> sendOtp(String mobile) async {
    if (!_isInitialized) throw MobileAuthException('Service not initialized');
    final clean = mobile.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.length != 10 || clean[0] == '0') {
      throw MobileAuthException('Invalid mobile number format');
    }
    final phone = '+91$clean';
    final res = await _supabaseClient.functions.invoke(
      'request-otp',
      body: {'mobile_number': phone, 'timestamp': DateTime.now().toIso8601String()},
    );
    if (res.status != 200 || res.data['success'] != true) {
      throw MobileAuthException(res.data['error'] ?? 'OTP send failed');
    }
    return OtpResponse(
      success: true,
      message: res.data['message'] ?? 'OTP sent',
      otpForTesting: res.data['otp']?.toString(),
    );
  }

  Future<AuthResponse> verifyOtp(String mobile, String otp) async {
    if (!_isInitialized) throw MobileAuthException('Service not initialized');
    final clean = mobile.replaceAll(RegExp(r'[^\d]'), '');
    final phone = '+91$clean';
    final fingerprint = await _generateDeviceFingerprint();
    final res = await _supabaseClient.functions.invoke(
      'verify-otp',
      body: {
        'mobile_number': phone,
        'otp': otp,
        'device_fingerprint': fingerprint,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    if (res.status != 200 || res.data['success'] != true) {
      throw MobileAuthException(res.data['error'] ?? 'Invalid OTP');
    }
    final user = res.data['user'] ?? {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'mobile_number': phone,
      'created_at': DateTime.now().toIso8601String(),
      'verified': true,
    };
    final refreshToken = res.data['refreshToken'] ?? res.data['refresh_token'] ?? 'refresh_${DateTime.now().millisecondsSinceEpoch}';
    await _storeAuthData(user, refreshToken);
    return AuthResponse(success: true, user: user, message: 'Authenticated');
  }

  /* ----------  UTILS  ---------- */
  bool get isAuthenticated => _currentUser != null && _refreshToken != null;
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get userId => _currentUser?['id'];
  String? get userMobile => _currentUser?['mobile_number'];

  Future<void> logout() async => await _clearAuthData();

  static String formatMobileNumber(String mobile) {
    final clean = mobile.replaceAll(RegExp(r'[^\d]'), '');
    return clean.length == 10 ? '${clean.substring(0, 5)}-${clean.substring(5)}' : mobile;
  }

  static String maskMobileNumber(String mobile) {
    final clean = mobile.replaceAll(RegExp(r'[^\d]'), '');
    return clean.length == 10 ? '+91-${clean.substring(0, 2)}XXX-XX${clean.substring(8)}' : '+91-XXXXX-XXXXX';
  }

  static bool isValidMobileNumber(String mobile) {
    final clean = mobile.replaceAll(RegExp(r'[^\d]'), '');
    return clean.length == 10 && clean[0] != '0';
  }

  Future<bool> checkConnection() async {
    try {
      _supabaseClient; // will throw if singleton null
      return true;
    } catch (_) {
      return false;
    }
  }
}

/* ----------  MODELS  ---------- */
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
