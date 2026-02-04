import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/user_role.dart';

/// ============================================================
/// SUPABASE SERVICE (SINGLE SOURCE OF TRUTH)
/// ============================================================
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;
}

/// ============================================================
/// MOBILE AUTH SERVICE – FINAL / COMPLETE (EDGE FUNCTION OTP)
/// ============================================================
class MobileAuthService {
  static final MobileAuthService _instance = MobileAuthService._internal();
  factory MobileAuthService() => _instance;
  MobileAuthService._internal();

  static const _sessionKey = 'supabase_session';
  static const _roleKey = 'selected_user_role';

  Session? _session;
  User? _currentUser;

  /// ------------------------------------------------------------
  /// INITIALIZE + RESTORE SESSION
  /// ------------------------------------------------------------
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString(_sessionKey);

    if (sessionJson == null) return;

    try {
      final sessionMap = jsonDecode(sessionJson);

      final response = await SupabaseService()
          .client
          .auth
          .recoverSession(jsonEncode(sessionMap));

      _session = response.session;
      _currentUser = response.user;

      debugPrint("Session restored successfully: ${_currentUser?.id}");
    } catch (e) {
      debugPrint("Session restore failed: $e");
      await logout();
    }
  }

  /// ------------------------------------------------------------
  /// EDGE FUNCTION – SEND OTP
  /// ------------------------------------------------------------
  Future<void> sendOtp(String mobile) async {
    final res = await SupabaseService().client.functions.invoke(
      'smart-function',
      body: {
        'action': 'request-otp',
        'mobile_number': '+91$mobile',
      },
    );

    if (res.data == null || res.data['success'] != true) {
      throw MobileAuthException(
        res.data?['error'] ?? 'Failed to send OTP',
      );
    }
  }

  /// ------------------------------------------------------------
  /// EDGE FUNCTION – VERIFY OTP
  /// ------------------------------------------------------------
  Future<void> verifyOtp({
    required String mobile,
    required String otp,
    required UserRole role,
  }) async {
    final res = await SupabaseService().client.functions.invoke(
      'smart-function',
      body: {
        'action': 'verify-otp',
        'mobile_number': '+91$mobile',
        'otp': otp,
        'role': role.name, // ✅ CRITICAL
      },
    );

    if (res.data == null || res.data['success'] != true) {
      throw MobileAuthException(
        res.data?['error'] ?? 'Invalid OTP',
      );
    }

    /// Edge function returns session in res.data['session']
    final sessionMap = res.data['session'];

    if (sessionMap == null) {
      throw MobileAuthException(
        'Session missing from Edge Function response',
      );
    }

    await _storeSession(sessionMap);
    await _storeRole(role);

    /// Sync role to profile table (safety)
    await _syncUserProfileRole(role);
  }

  /// ------------------------------------------------------------
  /// SESSION STORAGE
  /// ------------------------------------------------------------
  Future<void> _storeSession(Map<String, dynamic> session) async {
    final prefs = await SharedPreferences.getInstance();

    /// Save raw session map for restore later
    await prefs.setString(_sessionKey, jsonEncode(session));

    /// Recover into Supabase Auth
    final response = await SupabaseService()
        .client
        .auth
        .recoverSession(jsonEncode(session));

    _session = response.session;
    _currentUser = response.user;

    debugPrint("Session stored successfully: ${_currentUser?.id}");
  }

  /// ------------------------------------------------------------
  /// ROLE STORAGE + SYNC
  /// ------------------------------------------------------------
  Future<void> _storeRole(UserRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role.name);
  }

  Future<void> _syncUserProfileRole(UserRole role) async {
    final user = SupabaseService().client.auth.currentUser;
    if (user == null) return;

    try {
      await SupabaseService().client.from('user_profiles').upsert({
        'id': user.id,
        'role': role.name,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // do nothing (avoid breaking login)
    }
  }

  /// ------------------------------------------------------------
  /// SESSION HELPERS
  /// ------------------------------------------------------------
  bool get isAuthenticated => SupabaseService().client.auth.currentUser != null;

  Future<bool> refreshSession() async {
    try {
      final response = await SupabaseService().client.auth.refreshSession();
      _session = response.session;
      _currentUser = response.user;
      return true;
    } catch (_) {
      return false;
    }
  }

  User? get currentUser => _currentUser;
  String? get userId => _currentUser?.id;

  /// ------------------------------------------------------------
  /// ROLE FETCH
  /// ------------------------------------------------------------
  Future<UserRole> getUserRole() async {
    final user = SupabaseService().client.auth.currentUser;
    if (user == null) return UserRole.jobSeeker;

    final res = await SupabaseService()
        .client
        .from('user_profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    return parseUserRole(res?['role']);
  }

  /// ------------------------------------------------------------
  /// LOGOUT
  /// ------------------------------------------------------------
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.remove(_roleKey);

    await SupabaseService().client.auth.signOut();
    _session = null;
    _currentUser = null;
  }

  /// ------------------------------------------------------------
  /// VALIDATION
  /// ------------------------------------------------------------
  static bool isValidMobileNumber(String value) {
    return value.length == 10 && value[0] != '0';
  }
}

/// ============================================================
/// EXCEPTION
/// ============================================================
class MobileAuthException implements Exception {
  final String message;
  MobileAuthException(this.message);

  @override
  String toString() => message;
}