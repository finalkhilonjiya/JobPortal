import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../core/app_export.dart'; // Your existing imports

class MobileAuthService {
  static final MobileAuthService _instance = MobileAuthService._internal();
  factory MobileAuthService() => _instance;
  MobileAuthService._internal();

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
        // Fixed: Use 'device' instead of 'androidId' which doesn't exist in newer versions
        fingerprint = '${androidInfo.model}_${androidInfo.id}_${androidInfo.device}';
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
      throw MobileAuthException('Failed to store authentication data');
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

  /// Send OTP to mobile number using existing Supabase service
  Future<OtpResponse> sendOtp(String mobileNumber) async {
    try {
      // Validate mobile number format
      final cleanMobile = mobileNumber.replaceAll(RegExp(r'[^\d]'), '');
      if (cleanMobile.length != 10 || cleanMobile[0] == '0') {
        throw MobileAuthException('Invalid mobile number format');
      }

      debugPrint('Sending OTP to: +91$cleanMobile');

      // Use your existing SupabaseService
      final response = await SupabaseService().client.functions.invoke(
        'auth/request-otp',
        body: {'mobile_number': '+91$cleanMobile'},
      );

      debugPrint('OTP request response status: ${response.status}');
      debugPrint('OTP request response data: ${response.data}');

      if (response.status == 200) {
        final data = response.data;
        if (data != null && data['success'] == true) {
          return OtpResponse(
            success: true,
            message: 'OTP sent successfully',
          );
        } else {
          throw MobileAuthException(data?['error'] ?? 'Failed to send OTP');
        }
      } else {
        final errorData = response.data;
        throw MobileAuthException(errorData?['error'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      if (e is MobileAuthException) rethrow;
      debugPrint('Send OTP error: $e');
      throw MobileAuthException('Network error. Please check your connection.');
    }
  }

  /// Verify OTP and authenticate user using existing Supabase service
  Future<AuthResponse> verifyOtp(String mobileNumber, String otp) async {
    try {
      final cleanMobile = mobileNumber.replaceAll(RegExp(r'[^\d]'), '');
      final deviceFingerprint = await _generateDeviceFingerprint();

      debugPrint('Verifying OTP for: +91$cleanMobile');

      // Use your existing SupabaseService
      final response = await SupabaseService().client.functions.invoke(
        'auth/verify-otp',
        body: {
          'mobile_number': '+91$cleanMobile',
          'otp': otp,
          'device_fingerprint': deviceFingerprint,
        },
      );

      debugPrint('OTP verify response status: ${response.status}');
      debugPrint('OTP verify response data: ${response.data}');

      if (response.status == 200) {
        final data = response.data;
        if (data != null && data['success'] == true) {
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
          throw MobileAuthException(data?['error'] ?? 'Invalid or expired OTP');
        }
      } else {
        final errorData = response.data;
        throw MobileAuthException(errorData?['error'] ?? 'Invalid or expired OTP');
      }
    } catch (e) {
      if (e is MobileAuthException) rethrow;
      debugPrint('Verify OTP error: $e');
      throw MobileAuthException('Network error. Please check your connection.');
    }
  }

  /// Refresh user session using existing Supabase service
  Future<bool> refreshSession() async {
    try {
      if (_currentUser == null || _refreshToken == null) {
        debugPrint('No stored auth data for session refresh');
        return false;
      }

      debugPrint('Refreshing session for user: ${_currentUser!['id']}');

      final response = await SupabaseService().client.functions.invoke(
        'auth/refresh-session',
        body: {
          'user_id': _currentUser!['id'],
          'refreshToken': _refreshToken,
        },
      );

      debugPrint('Session refresh response status: ${response.status}');

      if (response.status == 200) {
        final data = response.data;
        if (data != null && data['success'] == true) {
          return true;
        } else {
          // Session invalid, clear stored data
          await _clearAuthData();
          return false;
        }
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
    debugPrint('Logging out user');
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

  /// Check connection to Supabase (using existing service)
  Future<bool> checkConnection() async {
    try {
      final healthStatus = await SupabaseService().getHealthStatus();
      debugPrint('Supabase health check: $healthStatus');
      return true;
    } catch (e) {
      debugPrint('Connection check failed: $e');
      return false;
    }
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

  @override
  String toString() => 'OtpResponse(success: $success, message: $message)';
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

  @override
  String toString() => 'AuthResponse(success: $success, user: $user, message: $message)';
}

/// Custom exception for authentication errors (renamed to avoid conflict)
class MobileAuthException implements Exception {
  final String message;
  
  MobileAuthException(this.message);
  
  @override
  String toString() => 'MobileAuthException: $message';
}