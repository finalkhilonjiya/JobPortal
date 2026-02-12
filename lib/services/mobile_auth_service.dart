import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/auth/user_role.dart';

class MobileAuthException implements Exception {
  final String message;
  MobileAuthException(this.message);

  @override
  String toString() => message;
}

class MobileAuthService {
  MobileAuthService._internal();
  static final MobileAuthService _instance = MobileAuthService._internal();
  factory MobileAuthService() => _instance;

  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _kRoleKey = 'user_role';

  User? _currentUser;

  // ------------------------------------------------------------
  // PUBLIC GETTERS
  // ------------------------------------------------------------
  User? get currentUser => _currentUser ?? _supabase.auth.currentUser;
  String? get userId => currentUser?.id;

  /// More correct (always check Supabase session)
  bool get isAuthenticated => _supabase.auth.currentUser != null;

  // ------------------------------------------------------------
  // VALIDATION
  // ------------------------------------------------------------
  static bool isValidMobileNumber(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9]'), '');
    return cleaned.length == 10;
  }

  // ------------------------------------------------------------
  // INIT
  // ------------------------------------------------------------
  Future<void> initialize() async {
    _currentUser = _supabase.auth.currentUser;
  }

  // ------------------------------------------------------------
  // SEND OTP
  // ------------------------------------------------------------
  Future<void> sendOtp(String mobile) async {
    final cleaned = mobile.replaceAll(RegExp(r'[^0-9]'), '');

    if (!isValidMobileNumber(cleaned)) {
      throw MobileAuthException('Enter a valid 10-digit mobile number');
    }

    try {
      final res = await _supabase.functions.invoke(
        'smart-function',
        body: {
          'action': 'request-otp',
          'mobile_number': cleaned,
        },
      );

      final data = _safeJson(res.data);

      if (res.status != 200 || data['success'] != true) {
        throw MobileAuthException(data['error'] ?? 'Failed to send OTP');
      }
    } catch (_) {
      throw MobileAuthException('Failed to send OTP');
    }
  }

  // ------------------------------------------------------------
  // VERIFY OTP
  // ------------------------------------------------------------
  Future<void> verifyOtp({
    required String mobile,
    required String otp,
    required UserRole role,
  }) async {
    final cleaned = mobile.replaceAll(RegExp(r'[^0-9]'), '');

    if (!isValidMobileNumber(cleaned)) {
      throw MobileAuthException('Enter a valid 10-digit mobile number');
    }

    if (otp.trim().length != 6) {
      throw MobileAuthException('Enter a valid 6-digit OTP');
    }

    try {
      final res = await _supabase.functions.invoke(
        'smart-function',
        body: {
          'action': 'verify-otp',
          'mobile_number': cleaned,
          'otp': otp.trim(),
          'role': role.name, // employer OR jobSeeker
        },
      );

      final data = _safeJson(res.data);

      if (res.status != 200 || data['success'] != true) {
        throw MobileAuthException(data['error'] ?? 'Invalid OTP');
      }

      // EDGE FUNCTION RETURNS: data.session.refresh_token
      final sessionJson = data['session'];
      if (sessionJson == null || sessionJson is! Map) {
        throw MobileAuthException('Server session missing');
      }

      final refreshToken = sessionJson['refresh_token']?.toString();

      if (refreshToken == null || refreshToken.isEmpty) {
        throw MobileAuthException('Refresh token missing');
      }

      // ------------------------------------------------------------
      // Supabase Flutter:
      // setSession(refreshToken)
      // ------------------------------------------------------------
      final authRes = await _supabase.auth.setSession(refreshToken);

      _currentUser = authRes.user ?? _supabase.auth.currentUser;

      if (_currentUser == null) {
        throw MobileAuthException('Login failed (session not created)');
      }

      // Save role locally for routing speed
      await _storage.write(key: _kRoleKey, value: role.name);

      // DB is final truth
      await syncRoleFromDbStrict(fallback: role);
    } catch (e) {
      if (e is MobileAuthException) rethrow;
      throw MobileAuthException('Invalid OTP');
    }
  }

  // ------------------------------------------------------------
  // SESSION REFRESH
  // ------------------------------------------------------------
  Future<bool> refreshSession() async {
    try {
      _currentUser = _supabase.auth.currentUser;
      return _currentUser != null;
    } catch (_) {
      return false;
    }
  }

  Future<bool> ensureValidSession() async {
    return await refreshSession();
  }

  // ------------------------------------------------------------
  // ROLE
  // ------------------------------------------------------------
  Future<UserRole> getUserRole() async {
    final local = await _storage.read(key: _kRoleKey);
    final parsedLocal = _parseRole(local);
    if (parsedLocal != null) return parsedLocal;

    return await syncRoleFromDbStrict(fallback: UserRole.jobSeeker);
  }

  Future<UserRole> syncRoleFromDbStrict({
    UserRole fallback = UserRole.jobSeeker,
  }) async {
    final uid = userId;
    if (uid == null) return fallback;

    try {
      final res = await _supabase
          .from('user_profiles')
          .select('role')
          .eq('id', uid)
          .maybeSingle();

      final roleStr = res?['role']?.toString();
      final parsed = _parseRole(roleStr) ?? fallback;

      await _storage.write(key: _kRoleKey, value: parsed.name);
      return parsed;
    } catch (_) {
      return fallback;
    }
  }

  UserRole? _parseRole(String? role) {
    if (role == null) return null;

    final v = role.trim().toLowerCase();

    if (v == 'employer') return UserRole.employer;

    if (v == 'jobseeker') return UserRole.jobSeeker;
    if (v == 'job_seeker') return UserRole.jobSeeker;
    if (v == 'job-seeker') return UserRole.jobSeeker;

    // legacy mapping
    if (v == 'buyer') return UserRole.jobSeeker;

    return null;
  }

  // ------------------------------------------------------------
  // LOGOUT
  // ------------------------------------------------------------
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {}

    _currentUser = null;
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