import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/user_role.dart';

class MobileAuthService {
  MobileAuthService._internal();
  static final MobileAuthService _instance = MobileAuthService._internal();
  factory MobileAuthService() => _instance;

  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _kAccessTokenKey = 'sb_access_token';
  static const String _kRefreshTokenKey = 'sb_refresh_token';
  static const String _kUserIdKey = 'sb_user_id';
  static const String _kRoleKey = 'user_role';

  User? _currentUser;

  // ------------------------------------------------------------
  // PUBLIC GETTERS
  // ------------------------------------------------------------
  User? get currentUser => _currentUser ?? _supabase.auth.currentUser;
  String? get userId => currentUser?.id;
  bool get isAuthenticated => currentUser != null;

  // ------------------------------------------------------------
  // INIT (called from AppInitializer)
  // ------------------------------------------------------------
  Future<void> initialize() async {
    _currentUser = _supabase.auth.currentUser;

    // If supabase already restored session internally
    if (_currentUser != null) return;

    // Otherwise try restore from secure storage
    await recoverSession();
  }

  // ------------------------------------------------------------
  // OTP REQUEST
  // ------------------------------------------------------------
  Future<void> requestOtp({
    required String mobileNumber,
  }) async {
    final res = await _supabase.functions.invoke(
      'smart-function',
      body: {
        'action': 'request-otp',
        'mobile_number': mobileNumber,
      },
    );

    final data = _safeJson(res.data);

    if (res.status != 200 || data['success'] != true) {
      throw Exception(data['error'] ?? 'Failed to request OTP');
    }
  }

  // ------------------------------------------------------------
  // OTP VERIFY
  // role MUST be passed (jobSeeker/employer)
  // ------------------------------------------------------------
  Future<void> verifyOtp({
    required String mobileNumber,
    required String otp,
    required UserRole role,
  }) async {
    final res = await _supabase.functions.invoke(
      'smart-function',
      body: {
        'action': 'verify-otp',
        'mobile_number': mobileNumber,
        'otp': otp,
        'role': role.name, // "jobSeeker" or "employer"
      },
    );

    final data = _safeJson(res.data);

    if (res.status != 200 || data['success'] != true) {
      throw Exception(data['error'] ?? 'Invalid OTP');
    }

    // Flutter expects session object
    final session = data['session'];
    final user = data['user'];

    if (session == null || user == null) {
      throw Exception('Invalid server response: session/user missing');
    }

    // Save tokens
    await _storage.write(
      key: _kAccessTokenKey,
      value: session['access_token']?.toString() ?? '',
    );
    await _storage.write(
      key: _kRefreshTokenKey,
      value: session['refresh_token']?.toString() ?? '',
    );
    await _storage.write(
      key: _kUserIdKey,
      value: user['id']?.toString() ?? '',
    );

    // Save role locally (fast startup)
    await _storage.write(
      key: _kRoleKey,
      value: user['role']?.toString() ?? role.name,
    );

    // IMPORTANT:
    // Supabase client still needs a real session locally.
    // We set it using setSession().
    final accessToken = session['access_token']?.toString() ?? '';
    final refreshToken = session['refresh_token']?.toString() ?? '';

    if (accessToken.isEmpty || refreshToken.isEmpty) {
      throw Exception('Invalid session tokens returned');
    }

    await _supabase.auth.setSession(refreshToken);

    _currentUser = _supabase.auth.currentUser;
  }

  // ------------------------------------------------------------
  // SESSION RECOVERY
  // ------------------------------------------------------------
  Future<bool> recoverSession() async {
    try {
      final refreshToken = await _storage.read(key: _kRefreshTokenKey);
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final response = await _supabase.auth.setSession(refreshToken);
      _currentUser = response.user;

      return _currentUser != null;
    } catch (e) {
      debugPrint('recoverSession failed: $e');
      return false;
    }
  }

  // ------------------------------------------------------------
  // REQUIRED BY job_service.dart + listing_service.dart
  // ------------------------------------------------------------
  Future<bool> ensureValidSession() async {
    // If already authenticated
    if (_supabase.auth.currentUser != null) return true;

    // Try recover
    return await recoverSession();
  }

  // ------------------------------------------------------------
  // REFRESH SESSION (optional)
  // ------------------------------------------------------------
  Future<bool> refreshSession() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) return false;

      // Supabase auto refreshes internally.
      // This is just a manual "ping".
      final user = _supabase.auth.currentUser;
      return user != null;
    } catch (_) {
      return false;
    }
  }

  // ------------------------------------------------------------
  // ROLE (from DB, fallback local)
  // ------------------------------------------------------------
  Future<UserRole> getUserRole() async {
    // First try local stored role (fast)
    final local = await _storage.read(key: _kRoleKey);
    if (local != null && local.isNotEmpty) {
      return UserRoleParsing.fromString(local);
    }

    // Then try DB
    final uid = userId;
    if (uid == null) return UserRole.jobSeeker;

    try {
      final res = await _supabase
          .from('user_profiles')
          .select('role')
          .eq('id', uid)
          .maybeSingle();

      final roleStr = res?['role']?.toString();
      final parsed = UserRoleParsing.fromString(roleStr);

      // cache it
      await _storage.write(key: _kRoleKey, value: parsed.name);

      return parsed;
    } catch (_) {
      return UserRole.jobSeeker;
    }
  }

  // ------------------------------------------------------------
  // LOGOUT
  // ------------------------------------------------------------
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {}

    _currentUser = null;

    await _storage.delete(key: _kAccessTokenKey);
    await _storage.delete(key: _kRefreshTokenKey);
    await _storage.delete(key: _kUserIdKey);
    await _storage.delete(key: _kRoleKey);
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------
  Map<String, dynamic> _safeJson(dynamic input) {
    if (input == null) return {};
    if (input is Map<String, dynamic>) return input;
    if (input is String) {
      try {
        return jsonDecode(input) as Map<String, dynamic>;
      } catch (_) {
        return {};
      }
    }
    return {};
  }
}