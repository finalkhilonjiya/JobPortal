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

        // CRITICAL: Restore the session in Supabase client
        if (_session != null) {
          try {
            await SupabaseService().client.auth.setSession(_session!.accessToken, _session!.refreshToken);
            debugPrint('Successfully restored Supabase session for user: ${_currentUser?['id']}');
          } catch (e) {
            debugPrint('Failed to restore Supabase session: $e');
            // Clear invalid session
            await _clearSession();
          }
        }
      } catch (e) {
        debugPrint('Failed to restore session: $e');
        // Clear invalid session
        await _clearSession();
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

        // Build session for Supabase - Handle nullable User.fromJson
        final userObj = User.fromJson(user);
        if (userObj == null) {
          throw MobileAuthException('Failed to parse user data');
        }
        
        final session = Session(
          accessToken: accessToken,
          refreshToken: refreshToken,
          tokenType: 'bearer',
          user: userObj,
        );

        await _storeSession(session);

        // CRITICAL: Set the session in Supabase client so it knows user is authenticated
        try {
          await SupabaseService().client.auth.setSession(accessToken, refreshToken);
          debugPrint('Successfully set Supabase session - User is now authenticated');
        } catch (e) {
          debugPrint('Warning: Could not set Supabase session: $e');
          // Try alternative approach
          try {
            await SupabaseService().client.auth.recoverSession(jsonEncode({
              'access_token': accessToken,
              'refresh_token': refreshToken,
              'expires_in': 3600,
              'token_type': 'bearer',
              'user': user,
            }));
            debugPrint('Successfully recovered Supabase session');
          } catch (e2) {
            debugPrint('Failed to recover session: $e2');
          }
        }

        // Debug auth state after setting session
        debugAuthState();

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
        
        // If refresh returns new tokens, update them
        final data = response.data;
        if (data['accessToken'] != null && data['refreshToken'] != null) {
          final newAccessToken = data['accessToken'] as String;
          final newRefreshToken = data['refreshToken'] as String;
          
          // Update session with new tokens
          final newSession = Session(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
            tokenType: 'bearer',
            user: _session!.user,
          );
          
          await _storeSession(newSession);
          
          // Update Supabase client session
          try {
            await SupabaseService().client.auth.setSession(newAccessToken, newRefreshToken);
          } catch (e) {
            debugPrint('Warning: Could not update Supabase session: $e');
          }
        }
        
        return true;
      }
      await _clearSession();
      return false;
    } catch (e) {
      debugPrint('Refresh session error: $e');
      await _clearSession();
      return false;
    }
  }

  // Getters
  bool get isAuthenticated => _session != null && SupabaseService().client.auth.currentUser != null;
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get userId => _currentUser?['id'];

  /// Debug method to check Supabase auth state
  void debugAuthState() {
    final supabaseUser = SupabaseService().client.auth.currentUser;
    final supabaseSession = SupabaseService().client.auth.currentSession;
    
    debugPrint('=== AUTH STATE DEBUG ===');
    debugPrint('Local session exists: ${_session != null}');
    debugPrint('Local user ID: ${_currentUser?['id']}');
    debugPrint('Supabase user exists: ${supabaseUser != null}');
    debugPrint('Supabase user ID: ${supabaseUser?.id}');
    debugPrint('Supabase session exists: ${supabaseSession != null}');
    debugPrint('Supabase access token: ${supabaseSession?.accessToken != null ? "EXISTS" : "NULL"}');
    debugPrint('Auth headers will use: ${supabaseSession?.accessToken != null ? "Bearer token" : "Anon key"}');
    debugPrint('========================');
  }

  /// Get current access token for manual API calls
  String? get currentAccessToken {
    final supabaseSession = SupabaseService().client.auth.currentSession;
    return supabaseSession?.accessToken ?? _session?.accessToken;
  }

  /// Check if user is properly authenticated with Supabase
  bool get isSupabaseAuthenticated {
    return SupabaseService().client.auth.currentUser != null &&
           SupabaseService().client.auth.currentSession != null;
  }

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