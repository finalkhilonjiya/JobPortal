import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import './supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _initializeSessionMonitoring();
    _initializeSocialLogins();
  }

  // Social login instances
  late GoogleSignIn _googleSignIn;
  late FacebookAuth _facebookAuth;

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
      debugPrint('âŒ Failed to get Supabase client: $e');
      return null;
    }
  }

  /// Initialize social login services
  void _initializeSocialLogins() {
    _googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      clientId: dotenv.env['GOOGLE_CLIENT_ID'],

    );
    _facebookAuth = FacebookAuth.instance;
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
      
      if (expiresAt != null && expiresAt - now < 300) {
        debugPrint('ðŸ”„ Refreshing session...');
        await client.auth.refreshSession();
        await _cacheSessionExpiry(expiresAt);
      }
    } catch (e) {
      debugPrint('âŒ Session refresh failed: $e');
    }
  }

  /// Validate if input is email or phone number
  bool _isEmail(String input) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(input);
  }

  /// Validate if input is phone number
  bool _isPhoneNumber(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^\d]'), '');
    return RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned) || 
           RegExp(r'^\d{10,15}$').hasMatch(cleaned);
  }

  /// Normalize phone number format
  String _normalizePhoneNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleaned.length == 10 && cleaned.startsWith(RegExp(r'[6-9]'))) {
      return '+91$cleaned';
    } else if (cleaned.length == 12 && cleaned.startsWith('91')) {
      return '+$cleaned';
    } else if (!cleaned.startsWith('+')) {
      return '+$cleaned';
    }
    return cleaned;
  }

  /// Sign up with email/phone and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      // Check if Supabase client is available
      final client = _client;
      if (client == null) {
        throw AppAuthException('Supabase not initialized. Please check your connection.');
      }

      debugPrint('ðŸ“¤ Attempting signup with email: $email');

      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': 'buyer',
          if (phone != null && phone.isNotEmpty) 'phone_number': phone,
        },
      );

      debugPrint('ðŸ“¤ Supabase signUp() response:');
      debugPrint('user:  [38;5;10m [1m [4m [7m${response.user} [0m');
      debugPrint('session: ${response.session}');

      if (response.user != null) {
        // Create user profile after successful signup
        await _createUserProfile(response.user!, {
          'full_name': fullName,
          'role': 'buyer',
          if (phone != null && phone.isNotEmpty) 'phone_number': phone,
        });
        return response;
      }

      throw AppAuthException('Sign-up failed. Please try again.');
    } on AuthException catch (e) {
      debugPrint('âŒ Sign-up failed (AuthException): ${e.message}');
      throw AppAuthException(_getErrorMessage(e));
    } catch (error) {
      debugPrint('âŒ Unexpected error during sign-up: $error');
      if (error is AppAuthException) {
        rethrow;
      }
      throw AppAuthException('Unexpected error: ${_getErrorMessage(error)}');
    }
  }

  /// Sign in with email/phone and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Check if Supabase client is available
      final client = _client;
      if (client == null) {
        throw AppAuthException('Supabase not initialized. Please check your connection.');
      }

      String loginEmail = email;
      
      // Check if input is phone number
      if (_isPhoneNumber(email)) {
        // Try to get email from phone number
        final phoneEmail = await _getEmailFromPhone(email);
        if (phoneEmail != null) {
          loginEmail = phoneEmail;
          debugPrint('ðŸ“¥ Found email for phone: $loginEmail');
        } else {
          throw AppAuthException('No account found with this phone number.');
        }
      }

      debugPrint('ðŸ“¥ Attempting login with email: $loginEmail');

      final response = await client.auth.signInWithPassword(
        email: loginEmail,
        password: password,
      );

      debugPrint('ðŸ“¥ Supabase signIn() response:');
      debugPrint('user: ${response.user}');
      debugPrint('session: ${response.session}');

      if (response.session != null) {
        return response;
      }

      throw AppAuthException('Login failed. Please try again.');
    } on AuthException catch (e) {
      debugPrint('âŒ Sign-in failed (AuthException): ${e.message}');
      
      // Provide better error messages
      if (e.message.contains('Invalid login credentials')) {
        throw AppAuthException('Invalid email or password. Please check your credentials.');
      } else if (e.message.contains('Email not confirmed')) {
        throw AppAuthException('Please verify your email before logging in. Check your inbox for the verification link.');
      }
      
      throw AppAuthException(_getErrorMessage(e));
    } catch (error) {
      debugPrint('âŒ Unexpected error during sign-in: $error');
      
      if (error is AppAuthException) {
        rethrow;
      }
      
      throw AppAuthException('Login failed: ${_getErrorMessage(error)}');
    }
  }

  /// Get email from phone number for login
  Future<String?> _getEmailFromPhone(String phone) async {
    try {
      final client = _client;
      if (client == null) return null;

      final response = await client
          .from('user_profiles')
          .select('email')
          .eq('phone_number', phone)
          .maybeSingle();

      return response?['email'];
    } catch (e) {
      debugPrint('âŒ Failed to get email from phone: $e');
      return null;
    }
  }

  /// Extract user-friendly error messages
  String _getErrorMessage(dynamic error) {
    debugPrint('ðŸ” Processing error: $error');
    debugPrint('ðŸ” Error type: ${error.runtimeType}');
    
    if (error is AuthException) {
      // Handle Supabase AuthException specifically
      final message = error.message.toLowerCase();
      
      if (message.contains('invalid login credentials') || 
          message.contains('invalid email or password')) {
        return 'Invalid email or password. Please check your credentials.';
      }
      if (message.contains('email not confirmed')) {
        return 'Please verify your email address. Check your inbox for the verification link.';
      }
      if (message.contains('user already registered')) {
        return 'An account with this email already exists. Please sign in instead.';
      }
      if (message.contains('password should be at least')) {
        return 'Password must be at least 6 characters long.';
      }
      if (message.contains('invalid email')) {
        return 'Please enter a valid email address.';
      }
      if (message.contains('network')) {
        return 'Network error. Please check your internet connection.';
      }
      
      // Return the original message if no specific case matches
      return error.message;
    }
    
    if (error is AppAuthException) {
      return error.message;
    }

    // Handle string errors
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network')) {
      return 'Network error. Please check your internet connection.';
    }
    if (errorString.contains('timeout')) {
      return 'Request timeout. Please try again.';
    }
    if (errorString.contains('connection')) {
      return 'Connection error. Please check your internet and try again.';
    }
    
    // Generic error
    return 'An unexpected error occurred. Please try again.';
  }

  /// Create user profile after signup
  Future<void> _createUserProfile(User user, [Map<String, dynamic>? additionalData]) async {
    try {
      await UserProfileService().createUserProfile(user, additionalData);
    } catch (e) {
      debugPrint('âŒ Failed to create user profile: $e');
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
      debugPrint('âŒ Failed to cache auth state: $e');
    }
  }

  /// Cache session expiry time
  Future<void> _cacheSessionExpiry(int expiresAt) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_sessionExpiryKey, expiresAt);
    } catch (e) {
      debugPrint('âŒ Failed to cache session expiry: $e');
    }
  }

  /// Clear offline cache
  Future<void> _clearOfflineCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_authStateKey);
      await prefs.remove(_userProfileKey);
      await prefs.remove(_sessionExpiryKey);
    } catch (e) {
      debugPrint('âŒ Failed to clear offline cache: $e');
    }
  }

  /// Get current user with null safety
  User? getCurrentUser() {
    try {
      return SupabaseService().currentUser;
    } catch (error) {
      debugPrint('âŒ Get current user failed: $error');
      return null;
    }
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    try {
      return SupabaseService().isAuthenticated;
    } catch (error) {
      debugPrint('âŒ Check authentication failed: $error');
      return false;
    }
  }

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges {
    try {
      return SupabaseService().authStateChanges;
    } catch (error) {
      debugPrint('âŒ Auth state changes failed: $error');
      return Stream.empty();
    }
  }

  /// Sign in with Google
  Future<AuthResponse> signInWithGoogle() async {
    try {
      final client = _client;
      if (client == null) {
        throw AppAuthException('Supabase not available. Please check your connection.');
      }

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw AppAuthException('Google sign-in was cancelled.');
      }

      final googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw AppAuthException('Failed to get Google authentication tokens.');
      }

      final response = await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken!,
      );

      if (response.user != null) {
        debugPrint('âœ… Google sign-in successful: ${response.user!.email}');
        
        await _handleSocialLoginProfile(response.user!, 'google', {
          'avatar_url': googleUser.photoUrl,
          'full_name': googleUser.displayName ?? response.user!.email?.split('@')[0],
        });
      }

      return response;
    } catch (error) {
      debugPrint('âŒ Google sign-in failed: $error');
      await _googleSignIn.signOut();
      
      if (error is AppAuthException) {
        rethrow;
      }
      throw AppAuthException('Google sign-in failed: ${_getErrorMessage(error)}');
    }
  }

  /// Sign in with Facebook
  Future<AuthResponse> signInWithFacebook() async {
    try {
      final client = _client;
      if (client == null) {
        throw AppAuthException('Supabase not available. Please check your connection.');
      }

      final facebookResult = await _facebookAuth.login(
        permissions: ['email', 'public_profile'],
      );

      if (facebookResult.status != LoginStatus.success) {
        throw AppAuthException('Facebook sign-in was cancelled or failed.');
      }

      // Fixed: Use tokenString instead of token
      final accessToken = facebookResult.accessToken?.tokenString;
      if (accessToken == null) {
        throw AppAuthException('Failed to get Facebook access token.');
      }

      final userData = await _facebookAuth.getUserData(
        fields: "name,email,picture.width(200)",
      );

      final response = await client.auth.signInWithIdToken(
        provider: OAuthProvider.facebook,
        idToken: accessToken,
      );

      if (response.user != null) {
        debugPrint('âœ… Facebook sign-in successful: ${response.user!.email}');
        
        await _handleSocialLoginProfile(response.user!, 'facebook', {
          'avatar_url': userData['picture']?['data']?['url'],
          'full_name': userData['name'] ?? response.user!.email?.split('@')[0],
        });
      }

      return response;
    } catch (error) {
      debugPrint('âŒ Facebook sign-in failed: $error');
      await _facebookAuth.logOut();
      
      if (error is AppAuthException) {
        rethrow;
      }
      throw AppAuthException('Facebook sign-in failed: ${_getErrorMessage(error)}');
    }
  }

  /// Handle social login profile creation/update
  Future<void> _handleSocialLoginProfile(
    User user, 
    String provider, 
    Map<String, dynamic> additionalData
  ) async {
    try {
      final profileData = {
        'username_type': 'email',
        'display_email': user.email,
        'social_provider': provider,
        'role': 'buyer',
        ...additionalData,
      };

      await _createUserProfile(user, profileData);
    } catch (e) {
      debugPrint('âŒ Failed to handle social login profile: $e');
    }
  }

  /// Sign out current user (including social logins)
  Future<void> signOut() async {
    try {
      _stopSessionMonitoring();
      
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        debugPrint('Google sign-out error: $e');
      }
      
      try {
        await _facebookAuth.logOut();
      } catch (e) {
        debugPrint('Facebook sign-out error: $e');
      }

      await SupabaseService().signOut();
      await _clearOfflineCache();
      debugPrint('âœ… User signed out successfully');
    } catch (error) {
      debugPrint('âŒ Sign-out failed: $error');
      throw AppAuthException('Sign-out failed: ${_getErrorMessage(error)}');
    }
  }

  /// Reset password with username flexibility
  Future<void> resetPassword(String username) async {
    try {
      final client = _client;
      if (client == null) {
        throw AppAuthException('Supabase not available. Please check your connection.');
      }

      String? email;

      if (_isEmail(username)) {
        email = username.toLowerCase().trim();
      } else if (_isPhoneNumber(username)) {
        final phone = _normalizePhoneNumber(username);
        email = await _getEmailFromPhone(phone);
        if (email == null) {
          throw AppAuthException('No account found with this phone number.');
        }
      } else {
        throw AppAuthException('Please enter a valid email address or phone number.');
      }

      await client.auth.resetPasswordForEmail(email);
      debugPrint('âœ… Password reset email sent to: $email');
    } catch (error) {
      debugPrint('âŒ Password reset failed: $error');
      
      if (error is AppAuthException) {
        rethrow;
      }
      throw AppAuthException('Password reset failed: ${_getErrorMessage(error)}');
    }
  }

  /// Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final client = _client;
      if (client == null) return false;

      if (_isEmail(username)) {
        final email = username.toLowerCase().trim();
        final response = await client
            .from('user_profiles')
            .select('id')
            .eq('display_email', email)
            .maybeSingle();
        return response == null;
      } else if (_isPhoneNumber(username)) {
        final phone = _normalizePhoneNumber(username);
        final response = await client
            .from('user_profiles')
            .select('id')
            .eq('phone_number', phone)
            .maybeSingle();
        return response == null;
      }

      return false;
    } catch (e) {
      debugPrint('âŒ Username availability check failed: $e');
      return false;
    }
  }

  /// Get user display name (phone or email)
  String? getUserDisplayName() {
    try {
      final user = getCurrentUser();
      if (user == null) return null;

      final metadata = user.userMetadata;
      if (metadata != null) {
        final usernameType = metadata['username_type'];
        if (usernameType == 'phone') {
          return metadata['phone_number'];
        } else {
          return metadata['display_email'] ?? user.email;
        }
      }

      return user.email;
    } catch (e) {
      debugPrint('âŒ Get user display name failed: $e');
      return null;
    }
  }

  /// Update user profile
  Future<UserResponse> updateProfile({
    String? fullName,
    String? avatarUrl,
  }) async {
    try {
      final client = _client;
      if (client == null) {
        throw AppAuthException('Supabase not available. Please check your connection.');
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
        debugPrint('âœ… Profile updated successfully');
        await _updateUserProfile(response.user!);
      }

      return response;
    } catch (error) {
      debugPrint('âŒ Profile update failed: $error');
      
      if (error is AppAuthException) {
        rethrow;
      }
      throw AppAuthException('Profile update failed: ${_getErrorMessage(error)}');
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
      debugPrint('âŒ Failed to update user profile: $e');
    }
  }

  /// Check authentication status with connection validation
  Future<bool> validateAuthentication() async {
    try {
      if (!isAuthenticated()) return false;

      final healthStatus = await SupabaseService().getHealthStatus();
      return healthStatus['connection_ok'] == true &&
          healthStatus['authenticated'] == true;
    } catch (e) {
      debugPrint('âŒ Authentication validation failed: $e');
      return false;
    }
  }

  /// Get user metadata safely
  Map<String, dynamic>? getUserMetadata() {
    try {
      final user = getCurrentUser();
      return user?.userMetadata;
    } catch (e) {
      debugPrint('âŒ Get user metadata failed: $e');
      return null;
    }
  }

  /// Manual session refresh
  Future<void> refreshSession() async {
    try {
      final client = _client;
      if (client == null) {
        throw AppAuthException('Supabase not available.');
      }

      final session = await client.auth.refreshSession();
      if (session.session != null) {
        debugPrint('âœ… Session refreshed successfully');
      }
    } catch (error) {
      debugPrint('âŒ Session refresh failed: $error');
      
      if (error is AppAuthException) {
        rethrow;
      }
      throw AppAuthException('Session refresh failed: ${_getErrorMessage(error)}');
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
      debugPrint('âŒ Get session info failed: $e');
      return null;
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
      debugPrint('âŒ Failed to get cached auth state: $e');
    }
    return null;
  }

  /// Dispose resources
  void dispose() {
    _stopSessionMonitoring();
    _authStateSubscription?.cancel();
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
      debugPrint('âŒ Failed to get Supabase client: $e');
      return null;
    }
  }

  /// Create user profile after signup
  Future<void> createUserProfile(User user, [Map<String, dynamic>? additionalData]) async {
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
        'username_type': user.userMetadata?['username_type'] ?? 'email',
        'phone_number': user.userMetadata?['phone_number'],
        'display_email': user.userMetadata?['display_email'] ?? user.email,
        'social_provider': user.userMetadata?['social_provider'],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        ...?additionalData,
      };

      await client.from(_userProfilesTable).upsert(profileData);
      await _cacheUserProfile(profileData);
      debugPrint('âœ… User profile created successfully');
    } catch (error) {
      debugPrint('âŒ Create user profile failed: $error');
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
      debugPrint('âŒ Get user profile failed: $error');
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
      if (phone != null) updateData['phone_number'] = phone;
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

      debugPrint('âœ… User profile updated successfully');
    } catch (error) {
      debugPrint('âŒ Update user profile failed: $error');
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

      debugPrint('âœ… Profile picture uploaded successfully');
      return publicUrl;
    } catch (error) {
      debugPrint('âŒ Profile picture upload failed: $error');
      throw ProfileException('Failed to upload profile picture: ${error.toString()}');
    }
  }

  /// Cache user profile
  Future<void> _cacheUserProfile(Map<String, dynamic> profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_profile_cache', jsonEncode(profile));
    } catch (e) {
      debugPrint('âŒ Failed to cache user profile: $e');
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
      debugPrint('âŒ Failed to get cached user profile: $e');
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

      debugPrint('âœ… User profile deleted successfully');
    } catch (error) {
      debugPrint('âŒ Delete user profile failed: $error');
      throw ProfileException('Failed to delete user profile: ${error.toString()}');
    }
  }

  /// Get user by phone number
  Future<Map<String, dynamic>?> getUserByPhone(String phoneNumber) async {
    try {
      final client = _client;
      if (client == null) return null;

      final normalizedPhone = _normalizePhoneNumber(phoneNumber);
      final response = await client
          .from(_userProfilesTable)
          .select()
          .eq('phone_number', normalizedPhone)
          .maybeSingle();

      return response;
    } catch (error) {
      debugPrint('âŒ Get user by phone failed: $error');
      return null;
    }
  }

  /// Get user by email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final client = _client;
      if (client == null) return null;

      final response = await client
          .from(_userProfilesTable)
          .select()
          .eq('display_email', email.toLowerCase().trim())
          .maybeSingle();

      return response;
    } catch (error) {
      debugPrint('âŒ Get user by email failed: $error');
      return null;
    }
  }

  /// Update user preferences
  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    try {
      await updateUserProfile(preferences: preferences);
    } catch (error) {
      debugPrint('âŒ Update user preferences failed: $error');
      throw ProfileException('Failed to update preferences: ${error.toString()}');
    }
  }

  /// Get user preferences
  Future<Map<String, dynamic>?> getUserPreferences() async {
    try {
      final profile = await getUserProfile();
      return profile?['preferences'] as Map<String, dynamic>?;
    } catch (error) {
      debugPrint('âŒ Get user preferences failed: $error');
      return null;
    }
  }

  /// Search users by name or email
  Future<List<Map<String, dynamic>>> searchUsers(String query, {int limit = 10}) async {
    try {
      final client = _client;
      if (client == null) return [];

      final response = await client
          .from(_userProfilesTable)
          .select('id, full_name, display_email, avatar_url, role')
          .or('full_name.ilike.%$query%,display_email.ilike.%$query%')
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('âŒ Search users failed: $error');
      return [];
    }
  }

  /// Get users by role
  Future<List<Map<String, dynamic>>> getUsersByRole(String role, {int limit = 50}) async {
    try {
      final client = _client;
      if (client == null) return [];

      final response = await client
          .from(_userProfilesTable)
          .select()
          .eq('role', role)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('âŒ Get users by role failed: $error');
      return [];
    }
  }

  /// Update user role
  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      final client = _client;
      if (client == null) {
        throw ProfileException('Supabase not available.');
      }

      await client
          .from(_userProfilesTable)
          .update({'role': newRole, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', userId);

      debugPrint('âœ… User role updated successfully');
    } catch (error) {
      debugPrint('âŒ Update user role failed: $error');
      throw ProfileException('Failed to update user role: ${error.toString()}');
    }
  }

  /// Check if user exists by username
  Future<bool> userExists(String username) async {
    try {
      final client = _client;
      if (client == null) return false;

      if (_isEmail(username)) {
        final user = await getUserByEmail(username);
        return user != null;
      } else if (_isPhoneNumber(username)) {
        final user = await getUserByPhone(username);
        return user != null;
      }

      return false;
    } catch (error) {
      debugPrint('âŒ Check user exists failed: $error');
      return false;
    }
  }

  /// Helper method to validate email
  bool _isEmail(String input) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(input);
  }

  /// Helper method to validate phone number
  bool _isPhoneNumber(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^\d]'), '');
    return RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned) || 
           RegExp(r'^\d{10,15}$').hasMatch(cleaned);
  }

  /// Helper method to normalize phone number
  String _normalizePhoneNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleaned.length == 10 && cleaned.startsWith(RegExp(r'[6-9]'))) {
      return '+91$cleaned';
    } else if (cleaned.length == 12 && cleaned.startsWith('91')) {
      return '+$cleaned';
    } else if (!cleaned.startsWith('+')) {
      return '+$cleaned';
    }
    return cleaned;
  }
}

// Custom exceptions
class AppAuthException implements Exception {
  final String message;
  const AppAuthException(this.message);
  
  @override
  String toString() => 'AppAuthException: $message';
}

class ProfileException implements Exception {
  final String message;
  const ProfileException(this.message);
  
  @override
  String toString() => 'ProfileException: $message';
}