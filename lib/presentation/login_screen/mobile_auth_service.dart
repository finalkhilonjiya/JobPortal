import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/auth/user_role.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;
}

class MobileAuthService {
  static final MobileAuthService _instance = MobileAuthService._internal();
  factory MobileAuthService() => _instance;
  MobileAuthService._internal();

  static const _roleKey = 'selected_user_role';

  Session? _session;
  User? _currentUser;

  /// ------------------------------------------------------------
  /// INIT (Supabase already persists session internally)
  /// ------------------------------------------------------------
  Future<void> initialize() async {
    // Supabase Flutter already persists session.
    // We only refresh local cache.
    _session = SupabaseService().client.auth.currentSession;
    _currentUser = SupabaseService().client.auth.currentUser;
  }

  /// ------------------------------------------------------------
  /// SEND OTP
  /// ------------------------------------------------------------
  Future<void> sendOtp(String mobile) async {
    final res = await SupabaseService().client.functions.invoke(
      'smart-function',
      body: {
        'action': 'request-otp',
        'mobile_number': '+91$mobile',
      },
    );

    final data = res.data;
    if (data == null || data['success'] != true) {
      throw MobileAuthException(data?['error'] ?? 'Failed to send OTP');
    }
  }

  /// ------------------------------------------------------------
  /// VERIFY OTP (server returns exchange_code)
  /// client exchanges it for REAL session
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
        'role': role.name,
      },
    );

    final data = res.data;
    if (data == null || data['success'] != true) {
      throw MobileAuthException(data?['error'] ?? 'Invalid OTP');
    }

    final exchangeCode = data['exchange_code']?.toString();
    if (exchangeCode == null || exchangeCode.isEmpty) {
      throw MobileAuthException('No session code returned');
    }

    // 🔥 THIS CREATES THE REAL SESSION (correct way)
    final response = await SupabaseService()
        .client
        .auth
        .exchangeCodeForSession(exchangeCode);

    _session = response.session;
    _currentUser = response.user;

    if (_session == null || _currentUser == null) {
      throw MobileAuthException('Failed to create session');
    }

    // store role locally too (fast routing)
    await _storeRole(role);
  }

  /// ------------------------------------------------------------
  /// ROLE STORAGE
  /// ------------------------------------------------------------
  Future<void> _storeRole(UserRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role.name);
  }

  /// ------------------------------------------------------------
  /// AUTH HELPERS
  /// ------------------------------------------------------------
  bool get isAuthenticated =>
      SupabaseService().client.auth.currentUser != null;

  User? get currentUser => SupabaseService().client.auth.currentUser;
  String? get userId => SupabaseService().client.auth.currentUser?.id;

  Future<bool> refreshSession() async {
    try {
      final response = await SupabaseService().client.auth.refreshSession();
      _session = response.session;
      _currentUser = response.user;
      return _session != null && _currentUser != null;
    } catch (_) {
      return false;
    }
  }

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

class MobileAuthException implements Exception {
  final String message;
  MobileAuthException(this.message);

  @override
  String toString() => message;
}