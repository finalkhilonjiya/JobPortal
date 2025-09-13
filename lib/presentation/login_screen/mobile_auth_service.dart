// mobile_auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

class MobileAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Request OTP for the given mobile number
  /// Returns true if OTP was sent successfully, false otherwise
  Future<bool> sendOtp(String mobileNumber) async {
    try {
      // Validate mobile number before sending request
      if (!isValidMobileNumber(mobileNumber)) {
        developer.log("Invalid mobile number format: $mobileNumber");
        return false;
      }

      final response = await _supabase.functions.invoke(
        'smart-function',
        body: {
          'action': 'request-otp',
          'mobile_number': mobileNumber,
        },
      );

      // Check if the function returned a success response
      if (response.data != null && response.data is Map) {
        return response.data['success'] == true;
      }

      return true; // Assume success if no error thrown
    } catch (e) {
      developer.log("Error sending OTP: $e");
      return false;
    }
  }

  /// Verify the OTP for the given mobile number
  /// Returns true if OTP is valid and verification successful, false otherwise
  Future<bool> verifyOtp(String mobileNumber, String otp) async {
    try {
      // Validate inputs
      if (!isValidMobileNumber(mobileNumber) || !isValidOtp(otp)) {
        developer.log("Invalid mobile number or OTP format");
        return false;
      }

      final response = await _supabase.functions.invoke(
        'smart-function',
        body: {
          'action': 'verify-otp',
          'mobile_number': mobileNumber,
          'otp': otp,
        },
      );

      // Check response data
      if (response.data != null && response.data is Map) {
        final success = response.data['success'] == true;
        
        if (success) {
          developer.log("OTP verification successful for: $mobileNumber");
          
          // Handle session or token if provided
          if (response.data.containsKey('session') || 
              response.data.containsKey('token')) {
            // Store session/token if needed
            await _handleAuthSuccess(response.data);
          }
        }
        
        return success;
      }

      return false;
    } catch (e) {
      developer.log("Error verifying OTP: $e");
      return false;
    }
  }

  /// Check if there's an active internet connection by testing Supabase connectivity
  Future<bool> checkConnection() async {
    try {
      // Try to perform a simple query to test connection
      await _supabase
          .from('user_profiles')
          .select('id')
          .limit(1)
          .timeout(const Duration(seconds: 10));
      return true;
    } catch (e) {
      developer.log("Connection check failed: $e");
      return false;
    }
  }

  /// Check if the current session is valid
  Future<bool> refreshSession() async {
    try {
      final session = _supabase.auth.currentSession;
      
      if (session == null) {
        developer.log("No current session found");
        return false;
      }

      // Check if session is expired
      final now = DateTime.now();
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(
        session.expiresAt! * 1000
      );

      if (now.isAfter(expiresAt)) {
        developer.log("Session expired, attempting refresh");
        
        // Try to refresh the session
        final response = await _supabase.auth.refreshSession();
        return response.session != null;
      }

      return true;
    } catch (e) {
      developer.log("Error refreshing session: $e");
      return false;
    }
  }

  /// Get the current user session
  Session? getCurrentSession() {
    return _supabase.auth.currentSession;
  }

  /// Get the current user
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      developer.log("User signed out successfully");
    } catch (e) {
      developer.log("Error signing out: $e");
      rethrow;
    }
  }

  /// Handle successful authentication
  Future<void> _handleAuthSuccess(Map<String, dynamic> data) async {
    try {
      // Store any additional user data or tokens as needed
      if (data.containsKey('user_data')) {
        // Handle user profile data
        developer.log("Storing user data...");
      }
      
      if (data.containsKey('preferences')) {
        // Handle user preferences
        developer.log("Storing user preferences...");
      }
    } catch (e) {
      developer.log("Error handling auth success: $e");
    }
  }

  /// Validate mobile number format
  static bool isValidMobileNumber(String mobile) {
    if (mobile.isEmpty) return false;
    
    // Remove any spaces, dashes, or special characters
    final cleanMobile = mobile.replaceAll(RegExp(r'[^\d]'), '');
    
    // Check for Indian mobile number format (10 digits starting with 6-9)
    final RegExp indianMobileRegex = RegExp(r'^[6-9]\d{9}$');
    return indianMobileRegex.hasMatch(cleanMobile);
  }

  /// Validate OTP format
  static bool isValidOtp(String otp) {
    if (otp.isEmpty) return false;
    
    // Remove any spaces
    final cleanOtp = otp.replaceAll(' ', '');
    
    // Check if it's 4-6 digits
    final RegExp otpRegex = RegExp(r'^\d{4,6}$');
    return otpRegex.hasMatch(cleanOtp);
  }

  /// Format mobile number for display
  static String formatMobileNumber(String mobile) {
    final cleanMobile = mobile.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanMobile.length == 10) {
      return '+91 ${cleanMobile.substring(0, 5)} ${cleanMobile.substring(5)}';
    }
    return mobile;
  }

  /// Get masked mobile number for display
  static String getMaskedMobileNumber(String mobile) {
    final cleanMobile = mobile.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanMobile.length == 10) {
      return '+91 ${cleanMobile.substring(0, 2)}****${cleanMobile.substring(6)}';
    }
    return mobile;
  }
}