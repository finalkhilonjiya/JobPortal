import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import './supabase_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Safe client access with fallback
  SupabaseClient? get _client {
    try {
      return SupabaseService().safeClient;
    } catch (e) {
      debugPrint('❌ Failed to get Supabase client: $e');
      return null;
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
      await SupabaseService().signOut();
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
      // Return empty stream as fallback
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

// Custom auth exception for better error handling
class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}
