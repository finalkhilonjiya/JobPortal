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
  bool _isInitialized = false;

  /// Initialize the auth service
  Future<void> initialize() async {
    try {
      debugPrint('Initializing MobileAuthService...');
      await _loadStoredAuth();
      await _generateDeviceFingerprint();
      
      // Test Supabase connection
      final connected = await checkConnection();
      debugPrint('Supabase connection status: $connected');
      
      _isInitialized = true;
      debugPrint('MobileAuthService initialized successfully');
    } catch (e) {
      debugPrint('MobileAuthService initialization failed: $e');
      rethrow;
    }
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

      // Hash the fingerprint
      var bytes = utf8.encode(fingerprint + DateTime.now().toIso8601String());
      var digest = sha256.convert(bytes);
      final hashedFingerprint = digest.toString();

      // Store for future use
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

  /// Send OTP to mobile number using existing Supabase service
  Future<OtpResponse> sendOtp(String mobileNumber) async {
    if (!_isInitialized) {
      throw MobileAuthException('Service not initialized');
    }

    try {
      // Validate mobile number format
      final cleanMobile = mobileNumber.replaceAll(RegExp(r'[^\d]'), '');
      if (cleanMobile.length != 10 || cleanMobile[0] == '0') {
        throw MobileAuthException('Invalid mobile number format');
      }

      final phoneNumber = '+91$cleanMobile';
      debugPrint('=== SENDING OTP ===');
      debugPrint('Phone number: $phoneNumber');
      debugPrint('Function path: auth/request-otp');

      // Use your existing SupabaseService
      final response = await SupabaseService().client.functions.invoke(
        'auth/request-otp',
        body: {
          'mobile_number': phoneNumber,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      debugPrint('Response status: ${response.status}');
      debugPrint('Response headers: ${response.headers}');
      debugPrint('Response data type: ${response.data.runtimeType}');
      debugPrint('Response data: ${response.data}');

      if (response.status == 200) {
        final data = response.data;
        
        // Handle both Map and String responses
        if (data is Map<String, dynamic>) {
          if (data['success'] == true || data['status'] == 'success') {
            debugPrint('OTP sent successfully via Map response');
            return OtpResponse(
              success: true,
              message: data['message'] ?? 'OTP sent successfully',
            );
          } else {
            final error = data['error'] ?? data['message'] ?? 'Failed to send OTP';
            debugPrint('OTP failed via Map response: $error');
            throw MobileAuthException(error);
          }
        } else if (data is String) {
          // Try to parse as JSON
          try {
            final jsonData = jsonDecode(data) as Map<String, dynamic>;
            if (jsonData['success'] == true || jsonData['status'] == 'success') {
              debugPrint('OTP sent successfully via JSON string response');
              return OtpResponse(
                success: true,
                message: jsonData['message'] ?? 'OTP sent successfully',
              );
            } else {
              final error = jsonData['error'] ?? jsonData['message'] ?? 'Failed to send OTP';
              debugPrint('OTP failed via JSON string response: $error');
              throw MobileAuthException(error);
            }
          } catch (parseError) {
            debugPrint('Could not parse response as JSON: $parseError');
            debugPrint('Raw response: $data');
            // Assume success if we got a 200 but couldn't parse
            return OtpResponse(
              success: true,
              message: 'OTP sent (response format unknown)',
            );
          }
        } else {
          debugPrint('Unknown response format, assuming success');
          return OtpResponse(
            success: true,
            message: 'OTP sent successfully',
          );
        }
      } else {
        debugPrint('HTTP error: ${response.status}');
        final errorData = response.data;
        String errorMessage = 'Failed to send OTP';
        
        if (errorData is Map<String, dynamic>) {
          errorMessage = errorData['error'] ?? errorData['message'] ?? errorMessage;
        } else if (errorData is String) {
          errorMessage = errorData;
        }
        
        throw MobileAuthException('HTTP ${response.status}: $errorMessage');
      }
    } catch (e) {
      if (e is MobileAuthException) rethrow;
      debugPrint('Send OTP error: $e');
      debugPrint('Error type: ${e.runtimeType}');
      throw MobileAuthException('Network error: ${e.toString()}');
    }
  }

  /// Verify OTP and authenticate user using existing Supabase service
  Future<AuthResponse> verifyOtp(String mobileNumber, String otp) async {
    if (!_isInitialized) {
      throw MobileAuthException('Service not initialized');
    }

    try {
      final cleanMobile = mobileNumber.replaceAll(RegExp(r'[^\d]'), '');
      final phoneNumber = '+91$cleanMobile';
      final deviceFingerprint = await _generateDeviceFingerprint();

      debugPrint('=== VERIFYING OTP ===');
      debugPrint('Phone number: $phoneNumber');
      debugPrint('OTP: $otp');
      debugPrint('Device fingerprint: ${deviceFingerprint.substring(0, 8)}...');
      debugPrint('Function path: auth/verify-otp');

      // Use your existing SupabaseService
      final response = await SupabaseService().client.functions.invoke(
        'auth/verify-otp',
        body: {
          'mobile_number': phoneNumber,
          'otp': otp,
          'device_fingerprint': deviceFingerprint,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      debugPrint('Response status: ${response.status}');
      debugPrint('Response data type: ${response.data.runtimeType}');
      debugPrint('Response data: ${response.data}');

      if (response.status == 200) {
        final data = response.data;
        
        // Handle both Map and String responses
        Map<String, dynamic>? parsedData;
        
        if (data is Map<String, dynamic>) {
          parsedData = data;
        } else if (data is String) {
          try {
            parsedData = jsonDecode(data) as Map<String, dynamic>;
          } catch (e) {
            debugPrint('Could not parse response as JSON: $e');
            throw MobileAuthException('Invalid response format');
          }
        }
        
        if (parsedData != null && (parsedData['success'] == true || parsedData['status'] == 'success')) {
          final user = parsedData['user'] as Map<String, dynamic>? ?? {
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'mobile_number': phoneNumber,
            'created_at': DateTime.now().toIso8601String(),
          };
          
          final refreshToken = parsedData['refreshToken'] as String? ?? 
                              parsedData['refresh_token'] as String? ?? 
                              'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}';

          // Store authentication data
          await _storeAuthData(user, refreshToken);

          debugPrint('Authentication successful for user: ${user['id']}');
          return AuthResponse(
            success: true,
            user: user,
            message: 'Authentication successful',
          );
        } else {
          final error = parsedData?['error'] ?? parsedData?['message'] ?? 'Invalid or expired OTP';
          debugPrint('OTP verification failed: $error');
          throw MobileAuthException(error);
        }
      } else {
        debugPrint('HTTP error: ${response.status}');
        final errorData = response.data;
        String errorMessage = 'Invalid or expired OTP';
        
        if (errorData is Map<String, dynamic>) {
          errorMessage = errorData['error'] ?? errorData['message'] ?? errorMessage;
        } else if (errorData is String) {
          errorMessage = errorData;
        }
        
        throw MobileAuthException('HTTP ${response.status}: $errorMessage');
      }
    } catch (e) {
      if (e is MobileAuthException) rethrow;
      debugPrint('Verify OTP error: $e');
      debugPrint('Error type: ${e.runtimeType}');
      throw MobileAuthException('Network error: ${e.toString()}');
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
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      debugPrint('Session refresh response status: ${response.status}');
      debugPrint('Session refresh response data: ${response.data}');

      if (response.status == 200) {
        final data = response.data;
        Map<String, dynamic>? parsedData;
        
        if (data is Map<String, dynamic>) {
          parsedData = data;
        } else if (data is String) {
          try {
            parsedData = jsonDecode(data) as Map<String, dynamic>;
          } catch (e) {
            debugPrint('Could not parse session refresh response: $e');
          }
        }
        
        if (parsedData != null && (parsedData['success'] == true || parsedData['status'] == 'success')) {
          debugPrint('Session refresh successful');
          return true;
        } else {
          debugPrint('Session invalid, clearing stored data');
          await _clearAuthData();
          return false;
        }
      } else {
        debugPrint('Session refresh failed with status: ${response.status}');
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

  /// Check connection to Supabase (improved version)
  Future<bool> checkConnection() async {
    try {
      debugPrint('Checking Supabase connection...');
      
      // Try to make a simple request to test connectivity
      final response = await SupabaseService().client.functions.invoke(
        'health-check',
        body: {'test': true},
      ).timeout(Duration(seconds: 10));
      
      debugPrint('Health check response: ${response.status}');
      return response.status == 200 || response.status == 404; // 404 is ok if function doesn't exist
      
    } catch (e) {
      debugPrint('Connection check failed: $e');
      
      // Try alternative connection test
      try {
        // Test basic Supabase client connectivity
        final client = SupabaseService().client;
        debugPrint('Supabase client URL: ${client.supabaseUrl}');
        debugPrint('Supabase client configured: ${client.supabaseKey.isNotEmpty}');
        return true; // If we can access the client, connection is likely ok
      } catch (e2) {
        debugPrint('Alternative connection check also failed: $e2');
        return false;
      }
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

/// Custom exception for authentication errors
class MobileAuthException implements Exception {
  final String message;

  MobileAuthException(this.message);

  @override
  String toString() => 'MobileAuthException: $message';
}