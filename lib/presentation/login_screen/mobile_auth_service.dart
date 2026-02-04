import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/auth/user_role.dart';

class MobileAuthService {
  static final MobileAuthService _instance = MobileAuthService._internal();
  factory MobileAuthService() => _instance;
  MobileAuthService._internal();

  static const _sessionKey = 'supabase_session';
  static const _userKey = 'user_data';

  Session? _session;
  Map<String, dynamic>? _currentUser;

  /* ---------------- INIT ---------------- */

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString(_sessionKey);
    final userJson = prefs.getString(_userKey);

    if (sessionJson == null || userJson == null) return;

    try {
      final sessionData = jsonDecode(sessionJson);
      final user = User.fromJson(sessionData['user']);
      if (user == null) return;

      _session = Session(
        accessToken: sessionData['access_token'],
        refreshToken: sessionData['refresh_token'],
        expiresIn: sessionData['expires_in'],
        tokenType: sessionData['token_type'],
        user: user,
      );
      _currentUser = jsonDecode(userJson);

      await Supabase.instance.client.auth.recoverSession(
        jsonEncode(sessionData),
      );
    } catch (_) {
      await logout();
    }
  }

  /* ---------------- OTP ---------------- */

  Future<void> sendOtp(String mobile) async {
    await Supabase.instance.client.functions.invoke(
      'smart-function',
      body: {
        'action': 'request-otp',
        'mobile_number': '+91$mobile',
        'device_fingerprint': _deviceId(),
      },
    );
  }

  Future<void> verifyOtp(String mobile, String otp) async {
    final res = await Supabase.instance.client.functions.invoke(
      'smart-function',
      body: {
        'action': 'verify-otp',
        'mobile_number': '+91$mobile',
        'otp': otp,
        'device_fingerprint': _deviceId(),
      },
    );

    if (res.data == null || res.data['success'] != true) {
      throw MobileAuthException('Invalid OTP');
    }

    await _storeSession(res.data);
    await _syncUserRole();
  }

  /* ---------------- ROLE ---------------- */

  Future<void> _syncUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final roleStr = prefs.getString('selected_user_role') ?? 'jobSeeker';

    final userId = Supabase.instance.client.auth.currentUser!.id;

    await Supabase.instance.client.from('user_profiles').upsert({
      'id': userId,
      'role': roleStr,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /* ---------------- SESSION ---------------- */

  Future<void> _storeSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    final sessionData = {
      'access_token': data['accessToken'],
      'refresh_token': data['refreshToken'],
      'expires_in': 3600,
      'token_type': 'bearer',
      'user': {'id': data['auth_user_id']},
    };

    await prefs.setString(_sessionKey, jsonEncode(sessionData));
    await prefs.setString(_userKey, jsonEncode(data['user']));
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await Supabase.instance.client.auth.signOut();
  }

  /* ---------------- HELPERS ---------------- */

  bool get isAuthenticated =>
      Supabase.instance.client.auth.currentUser != null;

  Future<UserRole> getUserRole() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return UserRole.jobSeeker;

    final res = await Supabase.instance.client
        .from('user_profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    return parseUserRole(res?['role']);
  }

  static bool isValidMobileNumber(String mobile) {
    final m = mobile.replaceAll(RegExp(r'\D'), '');
    return m.length == 10 && !m.startsWith('0');
  }

  String _deviceId() => 'flutter_${DateTime.now().millisecondsSinceEpoch}';
}

/* ---------------- ERR ---------------- */

class MobileAuthException implements Exception {
  final String message;
  MobileAuthException(this.message);
}