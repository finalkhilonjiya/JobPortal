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
  static const String _deviceFingerprintKey = 'device_fingerprint';

  String? _cachedDeviceFingerprint;
  Map<String, dynamic>? _currentUser;
  String? _refreshToken;
  bool _isInitialized = false;

  /// Initialize the auth service
  Future<void> initialize() async {
    try {
      debugPrint('DEBUG: SUPABASE_ANON_KEY length: ${supabaseKey?.length ?? 0}');

    if (supabaseUrl == null || supabaseKey == null) {
      throw MobileAuthException('Supabase credentials not found in .env file.');
    }

    if (supabaseUrl.contains('.supabase.co')) {
      debugPrint('DEBUG: URL format looks valid');
    } else {
      debugPrint('DEBUG: WARNING - URL format may be invalid');
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
        debugPrint('DEBUG: Using stored device fingerprint: ${stored.substring(0, 10)}...');
        return stored;
      }

      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      String fingerprint = '';

      if (defaultTargetPlatform == TargetPlatform.android) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        fingerprint = '${androidInfo.model}_${androidInfo.id}_${androidInfo.device}';
        debugPrint('DEBUG: Generated Android fingerprint base: $fingerprint');
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        fingerprint = '${iosInfo.model}_${iosInfo.identifierForVendor}';
        debugPrint('DEBUG: Generated iOS fingerprint base: $fingerprint');
      } else {
        fingerprint = 'web_${DateTime.now().millisecondsSinceEpoch}';
        debugPrint('DEBUG: Generated web fingerprint base: $fingerprint');
      }

      var bytes = utf8.encode(fingerprint + DateTime.now().toIso8601String());
      var digest = sha256.convert(bytes);
      final hashedFingerprint = digest.toString();

      await prefs.setString(_deviceFingerprintKey, hashedFingerprint);
      _cachedDeviceFingerprint = hashedFingerprint;

      debugPrint('DEBUG: Generated new device fingerprint: ${hashedFingerprint.substring(0, 10)}...');
      return hashedFingerprint;
    } catch (e) {
      debugPrint('DEBUG: Device fingerprint error: $e');
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
        debugPrint('DEBUG: Loaded stored user data for: ${_currentUser!['id']}');
      }

      _refreshToken = prefs.getString(_refreshTokenKey);
      if (_refreshToken != null) {
        debugPrint('DEBUG: Loaded stored refresh token: ${_refreshToken!.substring(0, 10)}...');
      }
    } catch (e) {
      debugPrint('DEBUG: Error loading stored auth: $e');
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

      debugPrint('DEBUG: Stored authentication data for user: ${user['id']}');
    } catch (e) {
      debugPrint('DEBUG: Error storing auth data: $e');
      throw MobileAuthException('Failed to store authentication data: $e');
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

      debugPrint('DEBUG: Cleared authentication data');
    } catch (e) {
      debugPrint('DEBUG: Error clearing auth data: $e');
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
      debugPrint('DEBUG: === SENDING OTP ===');
      debugPrint('DEBUG: Phone number: $phoneNumber');
      debugPrint('DEBUG: Supabase client available: ${_supabaseClient != null}');

      final requestBody = {
        'action': 'request-otp',
        'mobile_number': phoneNumber,
        'device_fingerprint': await _generateDeviceFingerprint(),
      };
      debugPrint('DEBUG: Request body: $requestBody');

      // Call your edge function with action parameter
      final response = await _supabaseClient.functions.invoke(
        'smart-function',
        body: requestBody,
      );

      debugPrint('DEBUG: OTP Response Status: ${response.status}');
      debugPrint('DEBUG: OTP Response Data: ${response.data}');
      debugPrint('DEBUG: OTP Response Data Type: ${response.data.runtimeType}');

      if (response.status == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['success'] == true) {
          return OtpResponse(
            success: true,
            message: 'OTP sent successfully! Use 123456 for testing.',
            otpForTesting: '123456',
          );
        } else {
          debugPrint('DEBUG: Unexpected success response format: $data');
        }
      } else {
        debugPrint('DEBUG: HTTP error - Status: ${response.status}');
      }
      
      throw MobileAuthException('Failed to send OTP. HTTP ${response.status}: ${response.data}');
    } catch (e) {
      debugPrint('DEBUG: Send OTP Error: $e');
      debugPrint('DEBUG: Error type: ${e.runtimeType}');
      if (e is MobileAuthException) rethrow;
      throw MobileAuthException('Network error during OTP send: ${e.toString()}');
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

      debugPrint('DEBUG: === VERIFYING OTP ===');
      debugPrint('DEBUG: Environment check:');
      debugPrint('DEBUG: - SUPABASE_URL: ${dotenv.env['SUPABASE_URL']}');
      debugPrint('DEBUG: - SUPABASE_ANON_KEY length: ${dotenv.env['SUPABASE_ANON_KEY']?.length ?? 0}');
      debugPrint('DEBUG: - Supabase client available: ${_supabaseClient != null}');
      
      debugPrint('DEBUG: Request details:');
      debugPrint('DEBUG: - Phone: $phoneNumber');
      debugPrint('DEBUG: - OTP: $otp');
      debugPrint('DEBUG: - Device fingerprint: ${deviceFingerprint.substring(0, 10)}...');

      final requestBody = {
        'action': 'verify-otp',
        'mobile_number': phoneNumber,
        'otp': otp,
        'device_fingerprint': deviceFingerprint,
      };
      debugPrint('DEBUG: - Request body: $requestBody');

      // Test the client first
      try {
        debugPrint('DEBUG: Testing Supabase client...');
        final testUrl = dotenv.env['SUPABASE_URL'];
        debugPrint('DEBUG: Base URL: $testUrl');
        debugPrint('DEBUG: Function URL should be: $testUrl/functions/v1/smart-function');
      } catch (testError) {
        debugPrint('DEBUG: Client test error: $testError');
      }

      // Call your edge function for verification
      debugPrint('DEBUG: Calling smart-function...');
      final response = await _supabaseClient.functions.invoke(
        'smart-function',
        body: requestBody,
      );

      debugPrint('DEBUG: === RESPONSE RECEIVED ===');
      debugPrint('DEBUG: Status: ${response.status}');
      debugPrint('DEBUG: Data: ${response.data}');
      debugPrint('DEBUG: Data type: ${response.data.runtimeType}');

      if (response.status == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['success'] == true) {
          final user = data['user'] as Map<String, dynamic>;
          final refreshToken = data['refreshToken'] as String;

          debugPrint('DEBUG: Success response received');
          debugPrint('DEBUG: User data: $user');
          debugPrint('DEBUG: Refresh token: ${refreshToken.substring(0, 10)}...');

          // Store authentication data
          await _storeAuthData(user, refreshToken);

          return AuthResponse(
            success: true,
            user: user,
            message: 'Login successful!',
          );
        } else {
          debugPrint('DEBUG: Unexpected response format: $data');
        }
      }

      // Handle error response
      final errorData = response.data;
      debugPrint('DEBUG: Error response: $errorData');
      if (errorData is Map<String, dynamic> && errorData['error'] != null) {
        final errorMsg = errorData['error'].toString();
        debugPrint('DEBUG: Server error message: $errorMsg');
        if (errorMsg.contains('Invalid or expired')) {
          throw MobileAuthException('Invalid OTP. Please check and try again.');
        }
        throw MobileAuthException('Verification failed: $errorMsg');
      }

      throw MobileAuthException('Invalid OTP. HTTP ${response.status}');
    } catch (e) {
      debugPrint('DEBUG: Verify OTP Error: $e');
      debugPrint('DEBUG: Error type: ${e.runtimeType}');
      debugPrint('DEBUG: Stack trace: ${StackTrace.current}');
      if (e is MobileAuthException) rethrow;
      throw MobileAuthException('Network error during verification: ${e.toString()}');
    }
  }

  /// Refresh user session
  Future<bool> refreshSession() async {
    try {
      if (_currentUser == null || _refreshToken == null) {
        debugPrint('DEBUG: No stored session to refresh');
        return false;
      }

      debugPrint('DEBUG: === REFRESHING SESSION ===');
      debugPrint('DEBUG: User ID: ${_currentUser!['id']}');
      debugPrint('DEBUG: Refresh token: ${_refreshToken!.substring(0, 10)}...');
      
      final response = await _supabaseClient.functions.invoke(
        'smart-function',
        body: {
          'action': 'refresh-session',
          'user_id': _currentUser!['id'],
          'refreshToken': _refreshToken,
        },
      );

      debugPrint('DEBUG: Refresh Response Status: ${response.status}');
      debugPrint('DEBUG: Refresh Response Data: ${response.data}');

      if (response.status == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['success'] == true) {
          debugPrint('DEBUG: Session refreshed successfully');
          return true;
        }
      }

      debugPrint('DEBUG: Session refresh failed, clearing auth data');
      await _clearAuthData();
      return false;
    } catch (e) {
      debugPrint('DEBUG: Session refresh error: $e');
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
    debugPrint('DEBUG: User logged out');
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
        debugPrint('DEBUG: Connection check failed - missing credentials');
        return false;
      }
      
      final client = _supabaseClient;
      debugPrint('DEBUG: Connection check passed - client available: ${client != null}');
      return client != null;
    } catch (e) {
      debugPrint('DEBUG: Connection check error: $e');
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
} Starting MobileAuthService initialization...');

      _checkEnvironmentVariables();
      await _loadStoredAuth();
      await _generateDeviceFingerprint();

      // Check connection
      final connected = await checkConnection();
      debugPrint('DEBUG: Supabase connection status: $connected');

      _isInitialized = true;
      debugPrint('DEBUG: MobileAuthService initialized successfully');
    } catch (e) {
      debugPrint('DEBUG: MobileAuthService initialization failed: $e');
      rethrow;
    }
  }

  /// Check if environment variables are properly loaded
  void _checkEnvironmentVariables() {
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'];

    debugPrint('DEBUG: Environment variables check:');
    debugPrint('DEBUG: SUPABASE_URL loaded: ${supabaseUrl != null}');
    debugPrint('DEBUG: SUPABASE_URL value: ${supabaseUrl ?? "NULL"}');
    debugPrint('DEBUG: SUPABASE_ANON_KEY loaded: ${supabaseKey != null}');
    debugPrint('DEBUG: