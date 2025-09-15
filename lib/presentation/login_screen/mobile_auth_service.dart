import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';

// SupabaseService class
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
  static const String _authUserIdKey = 'auth_user_id';
  static const String _deviceFingerprintKey = 'device_fingerprint';

  String? _cachedDeviceFingerprint;
  Map<String, dynamic>? _currentUser;
  String? _refreshToken;
  String? _authUserId;
  bool _isInitialized = false;

  /// Initialize the auth service
  Future<void> initialize() async {
    try {
      debugPrint('Initializing MobileAuthService with Supabase Auth...');

      _checkEnvironmentVariables();
      await _loadStoredAuth();
      await _generateDeviceFingerprint();

      // 🔑 Try restoring Supabase session automatically
      final restored = await refreshSession();
      debugPrint('Session restore attempt: $restored');

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

    if (supabaseUrl != null) {
      debugPrint('URL format: ${supabaseUrl.contains('.supabase.co') ? 'Valid' : 'Invalid'}');
    }

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
        debugPrint('Loaded stored user data for ID: ${_currentUser!['id']}');
      }

      _refreshToken = prefs.getString(_refreshTokenKey);
      _authUserId = prefs.getString(_authUserIdKey);
      
      if (_refreshToken != null && _authUserId != null) {
        debugPrint('Loaded stored auth session');
      }
    } catch (e) {
      debugPrint('Error loading stored auth: $e');
    }
  }

  /// Store authentication data
  Future<void> _storeAuthData(
    Map<String, dynamic> user, 
    String refreshToken, 
    String authUserId,
    String accessToken,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_userKey, jsonEncode(user));
      await prefs.setString(_refreshTokenKey, refreshToken);
      await prefs.setString(_authUserIdKey, authUserId);

      _currentUser = user;
      _refreshToken = refreshToken;
      _authUserId = authUserId;

      // 🔑 Set Supabase session
      await Supabase.instance.client.auth.setSession(
        AccessTokenResponse(
          accessToken: accessToken,
          refreshToken: refreshToken,
        ),
      );

      debugPrint('Stored authentication data for user: ${user['id']}');
      debugPrint('Auth User ID: $authUserId');
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
      await prefs.remove(_authUserIdKey);

      _currentUser = null;
      _refreshToken = null;
      _authUserId = null;

      // Also sign out from Supabase Auth if signed in
      try {
        await _supabaseClient.auth.signOut();
      } catch (e) {
        debugPrint('Supabase signout error: $e');
      }

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

      final requestBody = {
        'action': 'request-otp',
        'mobile_number': phoneNumber,
        'device_fingerprint': await _generateDeviceFingerprint(),
      };
      debugPrint('Request: $requestBody');

      final response = await _supabaseClient.functions.invoke(
        'smart-function',
        body: requestBody,
      );

      debugPrint('Send OTP Response Status: ${response.status}');
      debugPrint('Send OTP Response Data: ${response.data}');

      if (response.status == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['success'] == true) {
          return OtpResponse(
            success: true,
            message: data['message'] ?? 'OTP sent successfully! Use 123456 for testing.',
            otpForTesting: '123456',
          );
        }
      }
      
      throw MobileAuthException('Failed to send OTP. Please try again.');
    } catch (e) {
      debugPrint('Send OTP Error: $e');
      if (e is MobileAuthException) rethrow;
      throw MobileAuthException('Network error during OTP send: ${e.toString()}');
    }
  }

  /// Verify OTP and authenticate user with Supabase Auth
  Future<AuthResponse> verifyOtp(String mobileNumber, String otp) async {
    if (!_isInitialized) {
      throw MobileAuthException('Service not initialized');
    }

    try {
      final cleanMobile = mobileNumber.replaceAll(RegExp(r'[^\d]'), '');
      final phoneNumber = '+91$cleanMobile';
      final deviceFingerprint = await _generateDeviceFingerprint();

      debugPrint('=== VERIFYING OTP WITH SUPABASE AUTH ===');
      debugPrint('Phone: $phoneNumber');
      debugPrint('OTP: $otp');

      final requestBody = {
        'action': 'verify-otp',
        'mobile_number': phoneNumber,
        'otp': otp,
        'device_fingerprint': deviceFingerprint,
      };
      debugPrint('Request: $requestBody');

      final response = await _supabaseClient.functions.invoke(
        'smart-function',
        body: requestBody,
      );

      debugPrint('Verify OTP Response Status: ${response.status}');
      debugPrint('Verify OTP Response Data: ${response.data}');

      if (response.status == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['success'] == true) {
          final user = data['user'] as Map<String, dynamic>;
          final refreshToken = data['refreshToken'] as String;
          final authUserId = data['auth_user_id'] as String;
          final accessToken = data['accessToken'] as String;

          debugPrint('Authentication successful with Supabase Auth');
          debugPrint('User profile: ${user['id']}');
          debugPrint('Auth user: $authUserId');

          // Store all authentication data & set session
          await _storeAuthData(user, refreshToken, authUserId, accessToken);

          return AuthResponse(
            success: true,
            user: user,
            message: 'Login successful with Supabase Auth!',
          );
        }
      }

      // Handle error response
      final errorData = response.data;
      if (errorData is Map<String, dynamic> && errorData['error'] != null) {
        final errorMsg = errorData['error'].toString();
        if (errorMsg.contains('Invalid or expired')) {
          throw MobileAuthException('Invalid OTP. Please check and try again.');
        }
        throw MobileAuthException('Verification failed: $errorMsg');
      }

      throw MobileAuthException('Invalid OTP. Please try again.');
    } catch (e) {
      debugPrint('Verify OTP Error: $e');
      if (e is MobileAuthException) rethrow;
      throw MobileAuthException('Network error during verification: ${e.toString()}');
    }
  }

  /// Refresh user session
  Future<bool> refreshSession() async {
    try {
      if (_refreshToken == null) {
        debugPrint('No stored refresh token to refresh');
        return false;
      }

      debugPrint('=== REFRESHING SESSION WITH SUPABASE AUTH ===');
      final res = await Supabase.instance.client.auth.refreshSession();
      if (res.session != null) {
        debugPrint('Session refreshed successfully: ${res.session!.user.id}');
        return true;
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
  bool get isAuthenticated => 
    _currentUser != null && 
    _refreshToken != null && 
    _authUserId != null;
    
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get userId => _currentUser?['id'];
  String? get authUserId => _authUserId;
  String? get userMobile => _currentUser?['mobile_number'];

  // Logout with Supabase Auth cleanup
  Future<void> logout() async {
    debugPrint('Logging out user with Supabase Auth cleanup...');
    await _clearAuthData();
    debugPrint('User logged out successfully');
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
      if (url == null || key == null) {
        debugPrint('Connection check failed - missing credentials');
        return false;
      }
      
      final client = _supabaseClient;
      debugPrint('Connection check passed - client available: ${client != null}');
      return client != null;
    } catch (e) {
      debugPrint('Connection check error: $e');
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