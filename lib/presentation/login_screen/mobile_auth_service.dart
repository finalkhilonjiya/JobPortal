import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

class MobileAuthService {
  static final MobileAuthService _instance = MobileAuthService._internal();
  factory MobileAuthService() => _instance;
  MobileAuthService._internal();

  // Supabase configuration
  String get _supabaseUrl => const String.fromEnvironment('SUPABASE_URL');
  String get _supabaseAnonKey => const String.fromEnvironment('SUPABASE_ANON_KEY');
  
  // Auth endpoints
  String get _requestOtpUrl => '$_supabaseUrl/functions/v1/auth/request-otp';
  String get _verifyOtpUrl => '$_supabaseUrl/functions/v1/auth/verify-otp';
  String get _refreshSessionUrl => '$_supabaseUrl/functions/v1/auth/refresh-session';

  // Storage keys
  static const String _userKey = 'auth_user';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _deviceFingerprintKey = 'device_fingerprint';

  String? _cachedDeviceFingerprint;
  Map<String, dynamic>? _currentUser;
  String? _refreshToken;

  /// Initialize the auth service
  Future<void> initialize() async {
    await _loadStoredAuth();
    await _generateDeviceFingerprint();
  }

  /// Generate unique device fingerprint
  Future<String> _generateDeviceFingerprint() async {
    if (_cachedDeviceFingerprint != null) {
      return _cachedDeviceFingerprint!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      String? stored = prefs.getString(_deviceFingerprintKey);
      
      if (stored != null) {
        _cachedDeviceFingerprint = stored;
        return stored;
      }

      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      String fingerprint = '';
      
      if (defaultTargetPlatform == TargetPlatform.android) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        fingerprint = '${androidInfo.model}_${androidInfo.id}_${androidInfo.androidId}';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        fingerprint = '${iosInfo.model}_${iosInfo.identifierForVendor}';
      } else {
        fingerprint = 'web_${DateTime.now().millisecondsSinceEpoch}';
      }
      
      // Hash the fingerprint
      var bytes = utf8.encode(fingerprint + DateTime.now().toIso8601String());
      var digest = sha256.convert(bytes);
      final hashedFingerprint = digest.toString();
      
      // Store for future use
      await prefs.setString(_deviceFingerprintKey, hashedFingerprint);
      _cachedDeviceFingerprint = hashedFingerprint;
      
      return hashedFingerprint;
    } catch (e) {
      debugPrint('Device fingerprint error: $e');
      final fallback = 'fallback_${DateTime.now().millisecondsSinceEpoch}';
      _cachedDeviceFingerprint = fallback;
      return fallback;
    }
  }

  /// Load stored authentication data
  Future<void> _loadStoredAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        _currentUser = jsonDecode(userJson);
      }
      
      _refreshToken = prefs.getString(_refreshTokenKey);
    } catch (e) {
      debugPrint('Error loading stored auth: $e');
    }
  }

  /// Store authentication data
  Future<void> _storeAuthData(Map<String, dynamic> user, String refreshToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString(_userKey, jsonEncode(user));
      await prefs.setString(_refreshTokenKey, refreshToken);
      
      _currentUser = user;
      _refreshToken = refreshToken;
    } catch (e) {
      debugPrint('Error storing auth data: $e');
      throw AuthException('Failed to store authentication data');
    }
  }

  /// Clear stored authentication data
  Future<void> _clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.remove(_userKey);
      await prefs.remove(_refreshTokenKey);
      
      _currentUser = null;
      _refreshToken = null;
    } catch (e) {
      debugPrint('Error clearing auth data: $e');
    }
  }

  /// Send OTP to mobile number
  Future<OtpResponse> sendOtp(String mobileNumber) async {
    try {
      // Validate mobile number format
      final cleanMobile = mobileNumber.replaceAll(RegExp(r'[^\d]'), '');
      if (cleanMobile.length != 10 || cleanMobile[0] == '0') {
        throw AuthException('Invalid mobile number format');
      }

      final response = await http.post(
        Uri.parse(_requestOtpUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_supabaseAnonKey',
        },
        body: jsonEncode({
          'mobile_number': '+91$cleanMobile',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return OtpResponse(
          success: true,
          message: 'OTP sent successfully',
        );
      } else {
        throw AuthException(data['error'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      debugPrint('Send OTP error: $e');
      throw AuthException('Network error. Please check your connection.');
    }
  }

  /// Verify OTP and authenticate user
  Future<AuthResponse> verifyOtp(String mobileNumber, String otp) async {
    try {
      final cleanMobile = mobileNumber.replaceAll(RegExp(r'[^\d]'), '');
      final deviceFingerprint = await _generateDeviceFingerprint();

      final response = await http.post(
        Uri.parse(_verifyOtpUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_supabaseAnonKey',
        },
        body: jsonEncode({
          'mobile_number': '+91$cleanMobile',
          'otp': otp,
          'device_fingerprint': deviceFingerprint,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final user = data['user'] as Map<String, dynamic>;
        final refreshToken = data['refreshToken'] as String;

        // Store authentication data
        await _storeAuthData(user, refreshToken);

        return AuthResponse(
          success: true,
          user: user,
          message: 'Authentication successful',
        );
      } else {
        throw AuthException(data['error'] ?? 'Invalid or expired OTP');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      debugPrint('Verify OTP error: $e');
      throw AuthException('Network error. Please check your connection.');
    }
  }

  /// Refresh user session
  Future<bool> refreshSession() async {
    try {
      if (_currentUser == null || _refreshToken == null) {
        return false;
      }

      final response = await http.post(
        Uri.parse(_refreshSessionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_supabaseAnonKey',
        },
        body: jsonEncode({
          'user_id': _currentUser!['id'],
          'refreshToken': _refreshToken,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return true;
      } else {
        // Session invalid, clear stored data
        await _clearAuthData();
        return false;
      }
    } catch (e) {
      debugPrint('Refresh session error: $e');
      await _clearAuthData();
      return false;
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _currentUser != null && _refreshToken != null;

  /// Get current user data
  Map<String, dynamic>? get currentUser => _currentUser;

  /// Get user ID
  String? get userId => _currentUser?['id'];

  /// Get user mobile number
  String? get userMobile => _currentUser?['mobile_number'];

  /// Logout user
  Future<void> logout() async {
    await _clearAuthData();
  }

  /// Format mobile number for display
  static String formatMobileNumber(String mobile) {
    final clean = mobile.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.length == 10) {
      return '${clean.substring(0, 5)}-${clean.substring(5)}';
    }
    return mobile;
  }

  /// Mask mobile number for display
  static String maskMobileNumber(String mobile) {
    final clean = mobile.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.length == 10) {
      return '+91-${clean.substring(0, 2)}XXX-XX${clean.substring(8)}';
    }
    return '+91-XXXXX-XXXXX';
  }

  /// Validate mobile number
  static bool isValidMobileNumber(String mobile) {
    final clean = mobile.replaceAll(RegExp(r'[^\d]'), '');
    return clean.length == 10 && clean[0] != '0';
  }
}

/// Response class for OTP operations
class OtpResponse {
  final bool success;
  final String message;

  OtpResponse({
    required this.success,
    required this.message,
  });
}

/// Response class for authentication
class AuthResponse {
  final bool success;
  final Map<String, dynamic>? user;
  final String message;

  AuthResponse({
    required this.success,
    this.user,
    required this.message,
  });
}

/// Custom exception for authentication errors
class AuthException implements Exception {
  final String message;
  
  AuthException(this.message);
  
  @override
  String toString() => 'AuthException: $message';
}