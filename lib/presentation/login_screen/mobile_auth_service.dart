import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/auth/user_role.dart';

/// ---------------- SUPABASE ----------------

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

/// ---------------- AUTH SERVICE ----------------

class MobileAuthService {
  static final MobileAuthService _instance = MobileAuthService._internal();
  factory MobileAuthService() => _instance;
  MobileAuthService._internal();

  static const String _sessionKey = 'supabase_session';
  static const String _userKey = 'user_data';
  static const String _roleKey = 'selected_user_role';

  Session? _session;
  Map<String, dynamic>? _currentUser;

  /* ================= INITIALIZE ================= */

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString(_sessionKey);
    final userJson = prefs.getString(_userKey);

    if (sessionJson == null || userJson == null) return;

    try {
      final sessionData = jsonDecode(sessionJson);
      final userData = jsonDecode(userJson);

      final user = User.fromJson(sessionData['user']);
      if (user == null) throw Exception('Invalid user');

      _session = Session(
        accessToken: sessionData['access_token'],
        refreshToken: sessionData['refresh_token'],
        expiresIn: sessionData['expires_in'],
        tokenType: sessionData['token_type'],
        user: user,
      );

      _currentUser = userData;

      await SupabaseService().client.auth.recoverSession(
        jsonEncode(sessionData),
      );
    } catch (e) {
      debugPrint('Session restore failed: $e');
      await _clearSession();
    }
  }

  /* ================= OTP ================= */

  Future<void> sendOtp(String mobile) async {
    await SupabaseService().client.functions.invoke(
      'smart-function',
      body: {
        'action': 'request-otp',
        'mobile_number': '+91$mobile',
      },
    );
  }

  Future<AuthResponse> verifyOtp(
    String mobile,
    String otp, {
    required UserRole role,
  }) async {
    final res = await SupabaseService().client.functions.invoke(
      'smart-function',
      body: {
        'action': 'verify-otp',
        'mobile_number': '+91$mobile',
        'otp': otp,
      },
    );

    if (res.data == null || res.data['success'] != true) {
      throw MobileAuthException('OTP verification failed');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role.name);

    await _storeSession(res.data);
    await _syncUserProfileRole(role);

    return AuthResponse(
      success: true,
      user: res.data['user'],
      message: 'Login successful',
    );
  }

  /* ================= ROLE ================= */

  Future<void> _syncUserProfileRole(UserRole role) async {
    final userId = SupabaseService().client.auth.currentUser!.id;

    await SupabaseService().client.from('user_profiles').upsert({
      'id': userId,
      'role': role.name,
      'updated_at': DateTime.now().toIso8601String(),
    });

    debugPrint('User role synced: ${role.name}');
  }

  Future<UserRole> getUserRole() async {
    final user = SupabaseService().client.auth.currentUser;
    if (user == null) return UserRole.jobSeeker;

    final res = await SupabaseService().client
        .from('user_profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    return parseUserRole(res?['role']);
  }

  /* ================= SESSION ================= */

  Future<void> _storeSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    final sessionData = {
      'access_token': data['accessToken'],
      'refresh_token': data['refreshToken'],
      'expires_in': 3600,
      'token_type': 'bearer',
      'user': {
        'id': data['auth_user_id'],
      },
    };

    await prefs.setString(_sessionKey, jsonEncode(sessionData));
    await prefs.setString(_userKey, jsonEncode(data['user']));

    _session = Session(
      accessToken: data['accessToken'],
      refreshToken: data['refreshToken'],
      expiresIn: 3600,
      tokenType: 'bearer',
      user: User.fromJson(sessionData['user'])!,
    );
  }

  Future<bool> refreshSession() async {
    try {
      final session = SupabaseService().client.auth.currentSession;
      if (session?.refreshToken == null) return false;

      await SupabaseService()
          .client
          .auth
          .refreshSession(session!.refreshToken!);

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> ensureValidSession() async {
    if (SupabaseService().client.auth.currentSession == null) {
      return refreshSession();
    }
    return true;
  }

  /* ================= LOGOUT ================= */

  Future<void> logout() async {
    await _clearSession();
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await SupabaseService().client.auth.signOut();
    _session = null;
    _currentUser = null;
  }

  /* ================= GETTERS ================= */

  bool get isAuthenticated =>
      SupabaseService().client.auth.currentUser != null;

  Map<String, dynamic>? get currentUser => _currentUser;

  String? get userId => SupabaseService().client.auth.currentUser?.id;

  /* ================= UTIL ================= */

  static bool isValidMobileNumber(String mobile) {
    final clean = mobile.replaceAll(RegExp(r'\D'), '');
    return clean.length == 10 && clean[0] != '0';
  }
}

/// ---------------- MODELS ----------------

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

class MobileAuthException implements Exception {
  final String message;
  MobileAuthException(this.message);
}