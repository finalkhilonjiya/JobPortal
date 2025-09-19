import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

/// Authentication service for mobile OTP with real JWT tokens
class MobileAuthService {
  static final MobileAuthService _instance = MobileAuthService._internal();
  factory MobileAuthService() => _instance;
  MobileAuthService._internal();

  static const String _sessionKey = 'supabase_session';
  static const String _userKey = 'user_data';

  Session? _session;
  Map<String, dynamic>? _currentUser;

  /// Initialize auth service: restore saved session if available
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString(_sessionKey);
    final userJson = prefs.getString(_userKey);

    debugPrint('=== INITIALIZING AUTH SERVICE ===');

    if (sessionJson != null && userJson != null) {
      try {
        final sessionData = jsonDecode(sessionJson);
        final userData = jsonDecode(userJson);

        debugPrint('Found stored session for user: ${userData['id']}');

        // Create session object from stored data
        final user = User.fromJson(sessionData['user']);
        if (user == null) {
          throw Exception('Failed to parse user data from stored session');
        }
        
        _session = Session(
          accessToken: sessionData['access_token'],
          refreshToken: sessionData['refresh_token'],
          expiresIn: sessionData['expires_in'] ?? 3600,
          tokenType: sessionData['token_type'] ?? 'bearer',
          user: user,
        );
        _currentUser = userData;

        // CRITICAL: Set the session in Supabase client using the recoverSession method
        try {
          final sessionString = jsonEncode({
            'access_token': _session!.accessToken,
            'refresh_token': _session!.refreshToken,
            'expires_in': _session!.expiresIn,
            'expires_at': _session!.expiresAt,
            'token_type': _session!.tokenType,
            'user': _session!.user.toJson(),
          });

          await SupabaseService().client.auth.recoverSession(sessionString);
          debugPrint('✅ Successfully restored Supabase session');
          debugPrint('Current user ID: ${SupabaseService().client.auth.currentUser?.id}');
          
          // Verify the session is still valid by making a test call
          await _verifySessionValidity();
          
        } catch (e) {
          debugPrint('❌ Failed to restore Supabase session: $e');
          // Try to refresh the session
          final refreshed = await refreshSession();
          if (!refreshed) {
            debugPrint('Session refresh failed, clearing invalid session');
            await _clearSession();
          }
        }
      } catch (e) {
        debugPrint('❌ Failed to parse stored session: $e');
        await _clearSession();
      }
    } else {
      debugPrint('No stored session found');
    }

    debugAuthState();
    debugPrint('=== AUTH INITIALIZATION COMPLETE ===');
  }

  /// Verify if the current session is valid by making a test API call
  Future<bool> _verifySessionValidity() async {
    try {
      // Test the session by making a simple authenticated call
      final response = await SupabaseService().client
          .from('user_profiles')
          .select('id')
          .eq('id', _currentUser?['id'])
          .maybeSingle();
      
      debugPrint('Session validation successful');
      return true;
    } catch (e) {
      debugPrint('Session validation failed: $e');
      return false;
    }
  }

  /// Store Supabase session locally with enhanced data
  Future<void> _storeSession(Map<String, dynamic> authResponse) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Store session data
    final sessionData = {
      'access_token': authResponse['accessToken'],
      'refresh_token': authResponse['refreshToken'],
      'expires_in': 3600,
      'expires_at': authResponse['expiresAt'],
      'token_type': authResponse['tokenType'] ?? 'bearer',
      'user': {
        'id': authResponse['auth_user_id'],
        'email': authResponse['user']['email'] ?? 'user${authResponse['user']['mobile_number']?.replaceAll(RegExp(r'\D'), '')}@temp.khilonjiya.com',
        'phone': authResponse['user']['mobile_number'],
        'user_metadata': {
          'mobile_number': authResponse['user']['mobile_number'],
          'mobile_verified': true,
          'auth_method': 'mobile_otp'
        },
        'app_metadata': {
          'provider': 'phone',
          'providers': ['phone']
        }
      }
    };

    await prefs.setString(_sessionKey, jsonEncode(sessionData));
    await prefs.setString(_userKey, jsonEncode(authResponse['user']));

    // Create Session object
    final user = User.fromJson(sessionData['user']);
    if (user == null) {
      throw MobileAuthException('Failed to parse user data from auth response');
    }
    
    _session = Session(
      accessToken: authResponse['accessToken'],
      refreshToken: authResponse['refreshToken'],
      expiresIn: 3600,
      tokenType: authResponse['tokenType'] ?? 'bearer',
      user: user,
    );
    _currentUser = authResponse['user'];

    debugPrint('✅ Stored session for user: ${_currentUser?['id']}');
  }

  /// Clear stored session and sign out from Supabase
  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.remove(_userKey);
    
    _session = null;
    _currentUser = null;
    
    try {
      await SupabaseService().client.auth.signOut();
    } catch (e) {
      debugPrint('Error during signOut: $e');
    }
    
    debugPrint('🗑️ Cleared all session data');
  }

  /// Send OTP (always returns 123456 in dev)
  Future<OtpResponse> sendOtp(String mobileNumber) async {
    try {
      final phoneNumber = '+91${mobileNumber.replaceAll(RegExp(r'[^\d]'), '')}';
      debugPrint('Sending OTP to: $phoneNumber');
      
      final response = await SupabaseService().client.functions.invoke(
        'smart-function',
        body: {
          'action': 'request-otp',
          'mobile_number': phoneNumber,
          'device_fingerprint': await _getDeviceFingerprint(),
        },
      );

      debugPrint('OTP Response Status: ${response.status}');
      debugPrint('OTP Response Data: ${response.data}');

      if (response.status == 200 &&
          response.data is Map &&
          response.data['success'] == true) {
        return OtpResponse(
          success: true,
          message: response.data['message'] ?? 'OTP sent',
          otpForTesting: '123456', // Fixed OTP for development
        );
      }
      throw MobileAuthException('Failed to send OTP: ${response.data}');
    } catch (e) {
      debugPrint('❌ Send OTP Error: $e');
      throw MobileAuthException('Network error during OTP send');
    }
  }

  /// Verify OTP and log user in with real JWT tokens
  Future<AuthResponse> verifyOtp(String mobileNumber, String otp) async {
    try {
      final phoneNumber = '+91${mobileNumber.replaceAll(RegExp(r'[^\d]'), '')}';
      debugPrint('Verifying OTP for: $phoneNumber with code: $otp');
      
      final response = await SupabaseService().client.functions.invoke(
        'smart-function',
        body: {
          'action': 'verify-otp',
          'mobile_number': phoneNumber,
          'otp': otp,
          'device_fingerprint': await _getDeviceFingerprint(),
        },
      );

      debugPrint('Verify Response Status: ${response.status}');
      debugPrint('Verify Response Data: ${response.data}');

      if (response.status == 200 &&
          response.data is Map &&
          response.data['success'] == true) {
        
        final data = response.data;
        
        // Validate that we received real tokens
        if (data['accessToken'] == null || data['refreshToken'] == null) {
          throw MobileAuthException('Invalid response: missing tokens');
        }

        // Store the session with real tokens
        await _storeSession(data);

        // CRITICAL: Set the session in Supabase client immediately
        try {
          final sessionString = jsonEncode({
            'access_token': data['accessToken'],
            'refresh_token': data['refreshToken'],
            'expires_in': 3600,
            'expires_at': data['expiresAt'],
            'token_type': data['tokenType'] ?? 'bearer',
            'user': _session!.user.toJson(),
          });

          await SupabaseService().client.auth.recoverSession(sessionString);
          debugPrint('✅ Successfully set Supabase session after login');
          
        } catch (e) {
          debugPrint('⚠️ Warning: Could not set Supabase session: $e');
          // Don't fail the login, but log the issue
        }

        // Debug auth state after login
        debugAuthState();

        return AuthResponse(
          success: true,
          user: data['user'],
          message: data['message'] ?? 'Login successful',
        );
      }

      throw MobileAuthException('Invalid OTP or login failed: ${response.data}');
    } catch (e) {
      debugPrint('❌ Verify OTP Error: $e');
      throw MobileAuthException('Verification failed: ${e.toString()}');
    }
  }

  /// Refresh session using both custom and Supabase refresh
  Future<bool> refreshSession() async {
    if (_session == null || _session!.refreshToken?.isEmpty == true) {
      debugPrint('No session to refresh');
      return false;
    }

    try {
      debugPrint('Attempting to refresh session...');

      // First try Supabase native refresh
      try {
        final refreshedSession = await SupabaseService()
            .client
            .auth
            .refreshSession(_session!.refreshToken);

        if (refreshedSession.session != null) {
          debugPrint('✅ Supabase native refresh successful');
          
          // Update stored session
          final prefs = await SharedPreferences.getInstance();
          final sessionData = {
            'access_token': refreshedSession.session!.accessToken,
            'refresh_token': refreshedSession.session!.refreshToken,
            'expires_in': refreshedSession.session!.expiresIn,
            'expires_at': refreshedSession.session!.expiresAt,
            'token_type': refreshedSession.session!.tokenType,
            'user': refreshedSession.session!.user.toJson(),
          };
          
          await prefs.setString(_sessionKey, jsonEncode(sessionData));
          _session = refreshedSession.session;
          
          return true;
        }
      } catch (e) {
        debugPrint('Supabase native refresh failed: $e');
      }

      // Fallback to custom refresh endpoint
      final response = await SupabaseService().client.functions.invoke(
        'smart-function',
        body: {
          'action': 'refresh-session',
          'user_id': _session!.user.id,
          'refreshToken': _session!.refreshToken,
        },
      );

      debugPrint('Custom refresh response: ${response.data}');

      if (response.status == 200 &&
          response.data is Map &&
          response.data['success'] == true) {
        
        final data = response.data;
        
        // If refresh returns new tokens, update them
        if (data['accessToken'] != null && data['refreshToken'] != null) {
          final prefs = await SharedPreferences.getInstance();
          final sessionData = {
            'access_token': data['accessToken'],
            'refresh_token': data['refreshToken'],
            'expires_in': 3600,
            'expires_at': data['expiresAt'],
            'token_type': 'bearer',
            'user': _session!.user.toJson(),
          };
          
          await prefs.setString(_sessionKey, jsonEncode(sessionData));
          
          _session = Session(
            accessToken: data['accessToken'],
            refreshToken: data['refreshToken'],
            expiresIn: 3600,
            tokenType: 'bearer',
            user: _session!.user,
          );
          
          // Update Supabase client session
          try {
            await SupabaseService().client.auth.recoverSession(jsonEncode(sessionData));
            debugPrint('✅ Updated Supabase session with refreshed tokens');
          } catch (e) {
            debugPrint('⚠️ Warning: Could not update Supabase session: $e');
          }
        }
        
        debugPrint('✅ Session refresh successful');
        return true;
      }

      debugPrint('❌ Session refresh failed');
      await _clearSession();
      return false;
    } catch (e) {
      debugPrint('❌ Refresh session error: $e');
      await _clearSession();
      return false;
    }
  }

  /// Get device fingerprint for session tracking
  Future<String> _getDeviceFingerprint() async {
    // Simple device fingerprint - you can enhance this
    return 'flutter_${DateTime.now().millisecondsSinceEpoch % 100000}';
  }

  // Enhanced getters with better validation
  bool get isAuthenticated {
    final hasLocalSession = _session != null && _currentUser != null;
    final hasSupabaseUser = SupabaseService().client.auth.currentUser != null;
    final hasSupabaseSession = SupabaseService().client.auth.currentSession != null;
    
    debugPrint('Auth Check - Local: $hasLocalSession, Supabase User: $hasSupabaseUser, Supabase Session: $hasSupabaseSession');
    
    return hasLocalSession && hasSupabaseUser && hasSupabaseSession;
  }

  bool get isSupabaseAuthenticated {
    return SupabaseService().client.auth.currentUser != null &&
           SupabaseService().client.auth.currentSession != null;
  }

  Map<String, dynamic>? get currentUser => _currentUser;
  String? get userId => _currentUser?['id'];
  Session? get currentSession => _session;

  /// Keep session alive by periodically refreshing
  Future<void> keepSessionAlive() async {
    if (!isAuthenticated) return;
    
    try {
      // Try to refresh the session to keep it alive
      final currentSession = SupabaseService().client.auth.currentSession;
      if (currentSession != null && currentSession.refreshToken != null) {
        await SupabaseService().client.auth.refreshSession(currentSession.refreshToken!);
        debugPrint('Session refreshed to keep alive');
      }
    } catch (e) {
      debugPrint('Keep alive refresh failed: $e');
    }
  }
  Future<bool> ensureValidSession() async {
    debugPrint('=== ENSURING VALID SESSION ===');
    
    final currentUser = SupabaseService().client.auth.currentUser;
    final currentSession = SupabaseService().client.auth.currentSession;
    
    debugPrint('Current user exists: ${currentUser != null}');
    debugPrint('Current session exists: ${currentSession != null}');
    
    if (currentUser == null || currentSession == null) {
      debugPrint('No valid session, attempting refresh');
      return await refreshSession();
    }
    
    // Check if token is close to expiry (refresh if less than 5 minutes left)
    if (currentSession.expiresAt != null) {
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(currentSession.expiresAt! * 1000);
      final now = DateTime.now();
      final minutesUntilExpiry = expiresAt.difference(now).inMinutes;
      
      debugPrint('Token expires in $minutesUntilExpiry minutes');
      
      if (minutesUntilExpiry < 5) {
        debugPrint('Token expires soon, refreshing');
        return await refreshSession();
      }
    }
    
    debugPrint('Session is valid');
    return true;
  }

  /// Force session restoration (console logging only)
  Future<bool> forceRestoreSession() async {
    if (_session == null || _currentUser == null) {
      debugPrint('No local session to restore');
      return false;
    }
    
    try {
      debugPrint('Attempting session restoration...');
      
      // Method 1: Direct token setting
      final sessionString = jsonEncode({
        'access_token': _session!.accessToken,
        'refresh_token': _session!.refreshToken,
        'expires_in': 3600,
        'token_type': 'bearer',
        'user': _session!.user.toJson(),
      });
      
      await SupabaseService().client.auth.recoverSession(sessionString);
      
      // Verify it worked
      final user = SupabaseService().client.auth.currentUser;
      if (user != null) {
        debugPrint('Session restoration successful');
        return true;
      }
      
      debugPrint('Session restoration failed - no user after recovery');
      return false;
      
    } catch (e) {
      debugPrint('Session restoration error: $e');
      return false;
    }
  }
  void debugAuthState() {
    final supabaseUser = SupabaseService().client.auth.currentUser;
    final supabaseSession = SupabaseService().client.auth.currentSession;
    
    debugPrint('=== DETAILED AUTH STATE DEBUG ===');
    debugPrint('Local session exists: ${_session != null}');
    debugPrint('Local user exists: ${_currentUser != null}');
    debugPrint('Local user ID: ${_currentUser?['id']}');
    debugPrint('Local access token: ${_session?.accessToken != null ? "EXISTS (${_session!.accessToken.length} chars)" : "NULL"}');
    debugPrint('---');
    debugPrint('Supabase user exists: ${supabaseUser != null}');
    debugPrint('Supabase user ID: ${supabaseUser?.id}');
    debugPrint('Supabase user email: ${supabaseUser?.email}');
    debugPrint('Supabase user phone: ${supabaseUser?.phone}');
    debugPrint('---');
    debugPrint('Supabase session exists: ${supabaseSession != null}');
    debugPrint('Supabase access token: ${supabaseSession?.accessToken != null ? "EXISTS (${supabaseSession!.accessToken.length} chars)" : "NULL"}');
    debugPrint('Supabase token expires at: ${supabaseSession?.expiresAt}');
    debugPrint('---');
    debugPrint('isAuthenticated: $isAuthenticated');
    debugPrint('isSupabaseAuthenticated: $isSupabaseAuthenticated');
    debugPrint('Auth headers will use: ${supabaseSession?.accessToken != null ? "Bearer ${supabaseSession!.accessToken.substring(0, 20)}..." : "Anon key"}');
    debugPrint('=================================');
  }

  /// Get current access token for manual API calls
  String? get currentAccessToken {
    final supabaseSession = SupabaseService().client.auth.currentSession;
    return supabaseSession?.accessToken ?? _session?.accessToken;
  }

  /// Enhanced logout with cleanup
  Future<void> logout() async {
    debugPrint('🚪 Logging out user...');
    await _clearSession();
    debugPrint('✅ Logout complete');
  }

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