import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';

// SupabaseService class that was missing
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
  bool _isInitialized = false;

  /// Initialize the auth service
  Future<void> initialize() async {
    try {
      debugPrint('Initializing MobileAuthService...');

      _checkEnvironmentVariables();
      await _loadStoredAuth();
      await _generateDeviceFingerprint();

      // Check connection
      final connected = await checkConnection();
      debugPrint('Supabase connection status: $connected');

      _isInitialized = true;
      debugPrint('MobileAuthService initialized successfully');
    } catch (e) {
      debugPrint('MobileAuthService initialization failed: $e');
      rethrow;
    }
  }

  /// Check if environment variables are properly loaded
  void _checkEnvironmentVariables() {
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'];

    debugPrint('Environment variables check:');
    debugPrint('SUPABASE_URL loaded: ${supabaseUrl != null}');
    debugPrint('SUPABASE_ANON_KEY loaded: ${supabaseKey != null}');

    if (supabaseUrl == null || supabaseKey == null) {
      throw MobileAuthException('Supabase credentials not found in .env file.');
    }
  }

  /// Get Supabase client safely
  SupabaseClient get _supabaseClient {
    return SupabaseService().client;
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
        debugPrint('Using stored device fingerprint');
        return stored;
      }

      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      String fingerprint = '';

      if (defaultTargetPlatform == TargetPlatform.android) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        fingerprint = '${androidInfo.model}_${androidInfo.id}_${androidInfo.device}';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        fingerprint = '${iosInfo.model}_${iosInfo.identifierForVendor}';
      } else {
        fingerprint = 'web_${DateTime.now().millisecondsSinceEpoch}';
      }

      var bytes = utf8.encode(fingerprint + DateTime.now().toIso8601String());
      var digest = sha256.convert(bytes);
      final hashedFingerprint = digest.toString();

      await prefs.setString(_deviceFingerprintKey, hashedFingerprint);
      _cachedDeviceFingerprint = hashedFingerprint;

      debugPrint('Generated new device fingerprint');
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
        debugPrint('Loaded stored user data');
      }

      _refreshToken = prefs.getString(_refreshTokenKey);
      if (_refreshToken != null) {
        debugPrint('Loaded stored refresh token');
      }
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

      debugPrint('Stored authentication data for user: ${user['id']}');
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

      debugPrint('Cleared authentication data');
    } catch (e) {
      debugPrint('Error clearing auth data: $e');
    }
  }

  /// Send OTP to mobile number
  Future<OtpResponse> sendOtp(String mobileNumber) async {
    if (!_isInitialized) {
      throw MobileAuthException('Service not initialized');
    }

    try {
      final cleanMobile = mobileNumber.replaceAll(RegExp(r'[^\d]'), '');
      if (cleanMobile.length != 10 || cleanMobile[0] == '0') {
        throw MobileAuthException('Please enter a valid 10-digit mobile number');
      }

      final phoneNumber = '+91$cleanMobile';
      debugPrint('=== SENDING OTP ===');
      debugPrint('Phone number: $phoneNumber');

      // Call your edge function with action parameter
      final response = await _supabaseClient.functions.invoke(
        'smart-function',
        body: {
          'action': 'request-otp',
          'mobile_number': phoneNumber,
          'device_fingerprint': await _generateDeviceFingerprint(),
        },
      );

      debugPrint('OTP Response Status: ${response.status}');
      debugPrint('OTP Response Data: ${response.data}');

      if (response.status == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['success'] == true) {
          return OtpResponse(
            success: true,
            message: 'OTP sent successfully! Use 123456 for testing.',
            otpForTesting: '123456', // Fixed OTP for development
          );
        }
      }
      
      throw MobileAuthException('Failed to send OTP. Please try again.');
    } catch (e) {
      debugPrint('Send OTP Error: $e');
      if (e is MobileAuthException) rethrow;
      throw MobileAuthException('Network error. Please check your connection.');
    }
  }

  /// Verify OTP and authenticate user
  Future<AuthResponse> verifyOtp(String mobileNumber, String otp) async {
    if (!_isInitialized) {
      throw MobileAuthException('Service not initialized');
    }

    try {
      final cleanMobile = mobileNumber.replaceAll(RegExp(r'[^\d]'), '');
      final phoneNumber = '+91$cleanMobile';
      final deviceFingerprint = await _generateDeviceFingerprint();

      debugPrint('=== VERIFYING OTP ===');
      debugPrint('Phone: $phoneNumber, OTP: $otp');

      // Call your edge function for verification
      final response = await _supabaseClient.functions.invoke(
        'smart-function',
        body: {
          'action': 'verify-otp',
          'mobile_number': phoneNumber,
          'otp': otp,
          'device_fingerprint': deviceFingerprint,
        },
      );

      debugPrint('Verify Response Status: ${response.status}');
      debugPrint('Verify Response Data: ${response.data}');

      if (response.status == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['success'] == true) {
          final user = data['user'] as Map<String, dynamic>;
          final refreshToken = data['refreshToken'] as String;

          // Store authentication data
          await _storeAuthData(user, refreshToken);

          return AuthResponse(
            success: true,
            user: user,
            message: 'Login successful!',
          );
        }
      }

      // Handle error response
      final errorData = response.data;
      if (errorData is Map<String, dynamic> && errorData['error'] != null) {
        if (errorData['error'].toString().contains('Invalid or expired')) {
          throw MobileAuthException('Invalid OTP. Please check and try again.');
        }
        throw MobileAuthException('Verification failed. Please try again.');
      }

      throw MobileAuthException('Invalid OTP. Please try again.');
    } catch (e) {
      debugPrint('Verify OTP Error: $e');
      if (e is MobileAuthException) rethrow;
      throw MobileAuthException('Network error. Please check your connection.');
    }
  }

  /// Refresh user session
  Future<bool> refreshSession() async {
    try {
      if (_currentUser == null || _refreshToken == null) {
        debugPrint('No stored session to refresh');
        return false;
      }

      debugPrint('=== REFRESHING SESSION ===');
      
      final response = await _supabaseClient.functions.invoke(
        'smart-function',
        body: {
          'action': 'refresh-session',
          'user_id': _currentUser!['id'],
          'refreshToken': _refreshToken,
        },
      );

      debugPrint('Refresh Response Status: ${response.status}');
      debugPrint('Refresh Response Data: ${response.data}');

      if (response.status == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['success'] == true) {
          debugPrint('Session refreshed successfully');
          return true;
        }
      }

      debugPrint('Session refresh failed, clearing auth data');
      await _clearAuthData();
      return false;
    } catch (e) {
      debugPrint('Session refresh error: $e');
      await _clearAuthData();
      return false;
    }
  }

  // Getters
  bool get isAuthenticated => _currentUser != null && _refreshToken != null;
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get userId => _currentUser?['id'];
  String? get userMobile => _currentUser?['mobile_number'];

  // Logout
  Future<void> logout() async {
    await _clearAuthData();
    debugPrint('User logged out');
  }

  // Utility methods
  static String formatMobileNumber(String mobile) {
    final clean = mobile.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.length == 10) {
      return '${clean.substring(0, 5)}-${clean.substring(5)}';
    }
    return mobile;
  }

  static String maskMobileNumber(String mobile) {
    final clean = mobile.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.length == 10) {
      return '+91-${clean.substring(0, 2)}XXX-XX${clean.substring(8)}';
    }
    return '+91-XXXXX-XXXXX';
  }

  static bool isValidMobileNumber(String mobile) {
    final clean = mobile.replaceAll(RegExp(r'[^\d]'), '');
    return clean.length == 10 && clean[0] != '0';
  }

  Future<bool> checkConnection() async {
    try {
      final url = dotenv.env['SUPABASE_URL'];
      final key = dotenv.env['SUPABASE_ANON_KEY'];
      if (url == null || key == null) return false;
      
      final client = _supabaseClient;
      return client != null;
    } catch (_) {
      return false;
    }
  }
}

/// Response classes
class OtpResponse {
  final bool success;
  final String message;
  final String? otpForTesting;

  OtpResponse({
    required this.success,
    required this.message,
    this.otpForTesting,
  });
}

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

/// Custom exception
class MobileAuthException implements Exception {
  final String message;
  MobileAuthException(this.message);
  
  @override
  String toString() => 'MobileAuthException: $message';
}