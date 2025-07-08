import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import './supabase_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _initializeSessionMonitoring();
  }

  // Session monitoring
  Timer? _sessionTimer;
  StreamSubscription? _authStateSubscription;
  
  // Cache keys
  static const String _authStateKey = 'auth_state_cache';
  static const String _userProfileKey = 'user_profile_cache';
  static const String _sessionExpiryKey = 'session_expiry';

  // Safe client access with fallback
  SupabaseClient? get _client {
    try {
      return SupabaseService().safeClient;
    } catch (e) {
      debugPrint('❌ Failed to get Supabase client: $e');
      return null;
    }
  }

  /// Initialize session monitoring and offline caching
  void _initializeSessionMonitoring() {
    _authStateSubscription = authStateChanges.listen((authState) {
      _cacheAuthState(authState);
      if (authState.event == AuthChangeEvent.signedIn) {
        _startSessionMonitoring();
      } else if (authState.event == AuthChangeEvent.signedOut) {
        _stopSessionMonitoring();
        _clearOfflineCache();
      }
    });
  }

  /// Start session expiry monitoring
  void _startSessionMonitoring() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(Duration(minutes: 5), (timer) {
      _checkSessionExpiry();
    });
  }

  /// Stop session monitoring
  void _stopSessionMonitoring() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  /// Check and refresh session if needed
  Future<void> _checkSessionExpiry() async {
    try {
      final client = _client;
      if (client == null) return;

      final session = client.auth.currentSession;
      if (session == null) return;

      final expiresAt = session.expiresAt;
      final now = DateTime.now().millisecondsSinceEpoch / 1000;
      
      // Refresh if session expires in the next 5 minutes
      if (expiresAt != null && expiresAt - now < 300) {
        debugPrint('🔄 Refreshing session...');
        await client.auth.refreshSession();
        await _cacheSessionExpiry(expiresAt);
      }
    } catch (e) {
      debugPrint('❌ Session refresh failed: $e');
    }
  }

  /// Cache auth state for offline access
  Future<void> _cacheAuthState(AuthState authState) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'event': authState.event.name,
        'user_id': authState.session?.user.id,
        'email': authState.session?.user.email,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(_authStateKey, jsonEncode(cacheData));
    } catch (e) {
      debugPrint('❌ Failed to cache auth state: $e');
    }
  }

  /// Cache session expiry time
  Future<void> _cacheSessionExpiry(int expiresAt) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_sessionExpiryKey, expiresAt);
    } catch (e) {
      debugPrint('❌ Failed to cache session expiry: $e');
    }
  }

  /// Get cached auth state for offline access
  Future<Map<String, dynamic>?> getCachedAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = prefs.getString(_authStateKey);
      if (cacheData != null) {
        return jsonDecode(cacheData);
      }
    } catch (e) {
      debugPrint('❌ Failed to get cached auth state: $e');
    }
    return null;
  }

  /// Clear offline cache
  Future<void> _clearOfflineCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_authStateKey);
      await prefs.remove(_userProfileKey);
      await prefs.remove(_sessionExpiryKey);
    } catch (e) {
      debugPrint('❌ Failed to clear offline cache: $e');
    }
  }

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
    String? role,
  }) async {
    try {
      final client = _client;
      if (client == null) {
        throw AuthException(
            'Supabase not available. Please check your connection and try again.');
      }

      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName ?? email.split('@')[0],
          'role': role ?? 'buyer',
        },
      );

      if (response.user != null) {
        debugPrint('✅ User signed up successfully: ${response.user!.email}');
        // Create user profile after successful signup
        await _createUserProfile(response.user!);
      }

      return response;
    } catch (error) {
      debugPrint('❌ Sign-up failed: $error');
      throw AuthException('Sign-up failed: ${_getErrorMessage(error)}');
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final client = _client;
      if (client == null) {
        throw AuthException(
            'Supabase not available. Please check your connection and try again.');
      }

      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        debugPrint('✅ User signed in successfully: ${response.user!.email}');
        _startSessionMonitoring();
      }

      return response;
    } catch (error) {
      debugPrint('❌ Sign-in failed: $error');
      throw AuthException('Sign-in failed: ${_getErrorMessage(error)}');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      _stopSessionMonitoring();
      await SupabaseService().signOut();
      await _clearOfflineCache();
      debugPrint('✅ User signed out successfully');
    } catch (error) {
      debugPrint('❌ Sign-out failed: $error');
      throw AuthException('Sign-out failed: ${_getErrorMessage(error)}');
    }
  }

  /// Get current user with null safety
  User? getCurrentUser() {
    try {
      return SupabaseService().currentUser;
    } catch (error) {
      debugPrint('❌ Get current user failed: $error');
      return null;
    }
  }

  /// Check if user is authenticated with fallback
  bool isAuthenticated() {
    try {
      return SupabaseService().isAuthenticated;
    } catch (error) {
      debugPrint('❌ Check authentication failed: $error');
      return false;
    }
  }

  /// Listen to auth state changes with error handling
  Stream<AuthState> get authStateChanges {
    try {
      return SupabaseService().authStateChanges;
    } catch (error) {
      debugPrint('❌ Auth state changes failed: $error');
      return Stream.empty();
    }
  }

  /// Reset password with improved error handling
  Future<void> resetPassword(String email) async {
    try {
      final client = _client;
      if (client == null) {
        throw AuthException(
            'Supabase not available. Please check your connection and try again.');
      }

      await client.auth.resetPasswordForEmail(email);
      debugPrint('✅ Password reset email sent to: $email');
    } catch (error) {
      debugPrint('❌ Password reset failed: $error');
      throw AuthException('Password reset failed: ${_getErrorMessage(error)}');
    }
  }

  /// Update user profile with enhanced error handling
  Future<UserResponse> updateProfile({
    String? fullName,
    String? avatarUrl,
  }) async {
    try {
      final client = _client;
      if (client == null) {
        throw AuthException(
            'Supabase not available. Please check your connection and try again.');
      }

      final response = await client.auth.updateUser(
        UserAttributes(
          data: {
            if (fullName != null) 'full_name': fullName,
            if (avatarUrl != null) 'avatar_url': avatarUrl,
          },
        ),
      );

      if (response.user != null) {
        debugPrint('✅ Profile updated successfully');
        await _updateUserProfile(response.user!);
      }

      return response;
    } catch (error) {
      debugPrint('❌ Profile update failed: $error');
      throw AuthException('Profile update failed: ${_getErrorMessage(error)}');
    }
  }

  /// Sign in with OAuth with better error handling
  Future<bool> signInWithOAuth(OAuthProvider provider) async {
    try {
      final client = _client;
      if (client == null) {
        throw AuthException(
            'Supabase not available. Please check your connection and try again.');
      }

      final response = await client.auth.signInWithOAuth(
        provider,
        redirectTo: 'com.marketplace.pro://login-callback',
      );

      debugPrint('✅ OAuth sign-in initiated: ${provider.name}');
      return response;
    } catch (error) {
      debugPrint('❌ OAuth sign-in failed: $error');
      throw AuthException('OAuth sign-in failed: ${_getErrorMessage(error)}');
    }
  }

  /// Check authentication status with connection validation
  Future<bool> validateAuthentication() async {
    try {
      if (!isAuthenticated()) return false;

      // Check if we can access Supabase
      final healthStatus = await SupabaseService().getHealthStatus();
      return healthStatus['connection_ok'] == true &&
          healthStatus['authenticated'] == true;
    } catch (e) {
      debugPrint('❌ Authentication validation failed: $e');
      return false;
    }
  }

  /// Get user metadata safely
  Map<String, dynamic>? getUserMetadata() {
    try {
      final user = getCurrentUser();
      return user?.userMetadata;
    } catch (e) {
      debugPrint('❌ Get user metadata failed: $e');
      return null;
    }
  }

  /// Manual session refresh
  Future<void> refreshSession() async {
    try {
      final client = _client;
      if (client == null) {
        throw AuthException('Supabase not available.');
      }

      final session = await client.auth.refreshSession();
      if (session.session != null) {
        debugPrint('✅ Session refreshed successfully');
      }
    } catch (error) {
      debugPrint('❌ Session refresh failed: $error');
      throw AuthException('Session refresh failed: ${_getErrorMessage(error)}');
    }
  }

  /// Get session expiry information
  Future<Map<String, dynamic>?> getSessionInfo() async {
    try {
      final client = _client;
      if (client == null) return null;

      final session = client.auth.currentSession;
      if (session == null) return null;

      final expiresAt = session.expiresAt;
      final now = DateTime.now().millisecondsSinceEpoch / 1000;

      return {
        'expires_at': expiresAt,
        'expires_in_seconds': expiresAt != null ? (expiresAt - now).round() : null,
        'is_expired': expiresAt != null ? expiresAt <= now : false,
        'needs_refresh': expiresAt != null ? expiresAt - now < 300 : false,
      };
    } catch (e) {
      debugPrint('❌ Get session info failed: $e');
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    _stopSessionMonitoring();
    _authStateSubscription?.cancel();
  }

  /// Extract user-friendly error messages
  String _getErrorMessage(dynamic error) {
    if (error is AuthException) {
      switch (error.message) {
        case 'Invalid login credentials':
          return 'Invalid email or password. Please check your credentials and try again.';
        case 'Email not confirmed':
          return 'Please check your email and click the confirmation link before signing in.';
        case 'User already registered':
          return 'An account with this email already exists. Please sign in instead.';
        case 'Password should be at least 6 characters':
          return 'Password must be at least 6 characters long.';
        default:
          return error.message;
      }
    }

    final errorString = error.toString();
    if (errorString.contains('network')) {
      return 'Network error. Please check your internet connection.';
    } else if (errorString.contains('timeout')) {
      return 'Request timeout. Please try again.';
    }

    return 'An unexpected error occurred. Please try again.';
  }
}

// User Profile Service for extended profile management
class UserProfileService {
  static final UserProfileService _instance = UserProfileService._internal();
  factory UserProfileService() => _instance;
  UserProfileService._internal();

  static const String _userProfilesTable = 'user_profiles';

  SupabaseClient? get _client {
    try {
      return SupabaseService().safeClient;
    } catch (e) {
      debugPrint('❌ Failed to get Supabase client: $e');
      return null;
    }
  }

  /// Create user profile after signup
  Future<void> createUserProfile(User user) async {
    try {
      final client = _client;
      if (client == null) {
        throw ProfileException('Supabase not available.');
      }

      final profileData = {
        'id': user.id,
        'email': user.email,
        'full_name': user.userMetadata?['full_name'] ?? user.email?.split('@')[0],
        'role': user.userMetadata?['role'] ?? 'buyer',
        'avatar_url': user.userMetadata?['avatar_url'],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await client.from(_userProfilesTable).insert(profileData);
      await _cacheUserProfile(profileData);
      debugPrint('✅ User profile created successfully');
    } catch (error) {
      debugPrint('❌ Create user profile failed: $error');
      throw ProfileException('Failed to create user profile: ${error.toString()}');
    }
  }

  /// Get user profile with caching
  Future<Map<String, dynamic>?> getUserProfile([String? userId]) async {
    try {
      final client = _client;
      if (client == null) {
        return await _getCachedUserProfile();
      }

      final targetUserId = userId ?? client.auth.currentUser?.id;
      if (targetUserId == null) return null;

      final response = await client
          .from(_userProfilesTable)
          .select()
          .eq('id', targetUserId)
          .single();

      await _cacheUserProfile(response);
      return response;
    } catch (error) {
      debugPrint('❌ Get user profile failed: $error');
      return await _getCachedUserProfile();
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    String? fullName,
    String? avatarUrl,
    String? bio,
    String? phone,
    String? address,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final client = _client;
      if (client == null) {
        throw ProfileException('Supabase not available.');
      }

      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        throw ProfileException('User not authenticated.');
      }

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updateData['full_name'] = fullName;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;
      if (bio != null) updateData['bio'] = bio;
      if (phone != null) updateData['phone'] = phone;
      if (address != null) updateData['address'] = address;
      if (preferences != null) updateData['preferences'] = preferences;

      await client
          .from(_userProfilesTable)
          .update(updateData)
          .eq('id', userId);

      // Update cache
      final cachedProfile = await _getCachedUserProfile();
      if (cachedProfile != null) {
        cachedProfile.addAll(updateData);
        await _cacheUserProfile(cachedProfile);
      }

      debugPrint('✅ User profile updated successfully');
    } catch (error) {
      debugPrint('❌ Update user profile failed: $error');
      throw ProfileException('Failed to update user profile: ${error.toString()}');
    }
  }

  /// Upload profile picture
  Future<String> uploadProfilePicture(File imageFile) async {
    try {
      final client = _client;
      if (client == null) {
        throw ProfileException('Supabase not available.');
      }

      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        throw ProfileException('User not authenticated.');
      }

      final fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final response = await client.storage
          .from('profiles')
          .upload(fileName, imageFile);

      final publicUrl = client.storage
          .from('profiles')
          .getPublicUrl(fileName);

      // Update profile with new avatar URL
      await updateUserProfile(avatarUrl: publicUrl);

      debugPrint('✅ Profile picture uploaded successfully');
      return publicUrl;
    } catch (error) {
      debugPrint('❌ Profile picture upload failed: $error');
      throw ProfileException('Failed to upload profile picture: ${error.toString()}');
    }
  }

  /// Cache user profile
  Future<void> _cacheUserProfile(Map<String, dynamic> profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_profile_cache', jsonEncode(profile));
    } catch (e) {
      debugPrint('❌ Failed to cache user profile: $e');
    }
  }

  /// Get cached user profile
  Future<Map<String, dynamic>?> _getCachedUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileData = prefs.getString('user_profile_cache');
      if (profileData != null) {
        return jsonDecode(profileData);
      }
    } catch (e) {
      debugPrint('❌ Failed to get cached user profile: $e');
    }
    return null;
  }

  /// Delete user profile
  Future<void> deleteUserProfile() async {
    try {
      final client = _client;
      if (client == null) {
        throw ProfileException('Supabase not available.');
      }

      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        throw ProfileException('User not authenticated.');
      }

      await client.from(_userProfilesTable).delete().eq('id', userId);

      // Clear cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_profile_cache');

      debugPrint('✅ User profile deleted successfully');
    } catch (error) {
      debugPrint('❌ Delete user profile failed: $error');
      throw ProfileException('Failed to delete user profile: ${error.toString()}');
    }
  }
}

// Extension methods for AuthService to integrate with UserProfileService
extension AuthServiceProfileExtension on AuthService {
  /// Create user profile after signup
  Future<void> _createUserProfile(User user) async {
    try {
      await UserProfileService().createUserProfile(user);
    } catch (e) {
      debugPrint('❌ Failed to create user profile: $e');
      // Don't throw here to avoid breaking signup flow
    }
  }

  /// Update user profile after auth update
  Future<void> _updateUserProfile(User user) async {
    try {
      await UserProfileService().updateUserProfile(
        fullName: user.userMetadata?['full_name'],
        avatarUrl: user.userMetadata?['avatar_url'],
      );
    } catch (e) {
      debugPrint('❌ Failed to update user profile: $e');
      // Don't throw here to avoid breaking update flow
    }
  }
}

// Custom exceptions
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => 'AuthException: $message';
}

class ProfileException implements Exception {
  final String message;
  const ProfileException(this.message);
  @override
  String toString() => 'ProfileException: $message';
}