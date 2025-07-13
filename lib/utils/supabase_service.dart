import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:math';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  late final SupabaseClient _client;
  bool _isInitialized = false;
  static bool _initializationInProgress = false;

  // Singleton pattern
  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  // Environment variables with multiple fallback sources
  static String get supabaseUrl {
    // Try dart-define first (for production builds)
    final dartDefineUrl = const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    if (dartDefineUrl.isNotEmpty) {
      return dartDefineUrl;
    }
    
    // Try .env file (for development)
    final envUrl = dotenv.env['SUPABASE_URL'] ?? '';
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    
    // Return empty string if not found
    return '';
  }

  static String get supabaseAnonKey {
    // Try dart-define first (for production builds)
    final dartDefineKey = const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
    if (dartDefineKey.isNotEmpty) {
      return dartDefineKey;
    }
    
    // Try .env file (for development)
    final envKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    if (envKey.isNotEmpty) {
      return envKey;
    }
    
    // Return empty string if not found
    return '';
  }

  // Static initialization method with improved error handling
  static Future<void> initialize() async {
    // Prevent multiple simultaneous initialization attempts
    if (_instance._isInitialized || _initializationInProgress) {
      return;
    }

    _initializationInProgress = true;

    try {
      // Load .env file if it exists (for development)
      try {
        await dotenv.load(fileName: '.env');
        debugPrint('✅ .env file loaded successfully');
      } catch (e) {
        debugPrint('⚠️ .env file not found or could not be loaded: $e');
        debugPrint('⚠️ This is normal for production builds using dart-define');
      }

      // Enhanced debugging for environment variables
      debugPrint('🔍 Supabase initialization started');
      debugPrint('🔍 SUPABASE_URL length: ${supabaseUrl.length}');
      debugPrint('🔍 SUPABASE_ANON_KEY length: ${supabaseAnonKey.length}');
      
      if (supabaseUrl.isNotEmpty) {
        debugPrint('🔍 URL starts with: ${supabaseUrl.substring(0, min(20, supabaseUrl.length))}...');
      }
      if (supabaseAnonKey.isNotEmpty) {
        debugPrint('🔍 Key starts with: ${supabaseAnonKey.substring(0, min(10, supabaseAnonKey.length))}...');
      }

      // Validate environment variables
      if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
        throw SupabaseException(
          'Environment variables SUPABASE_URL and SUPABASE_ANON_KEY must be defined.\n'
          'For development: Add them to your .env file\n'
          'For production: Use --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key\n'
          'Current values:\n'
          'SUPABASE_URL: ${supabaseUrl.isEmpty ? "NOT SET" : "SET"}\n'
          'SUPABASE_ANON_KEY: ${supabaseAnonKey.isEmpty ? "NOT SET" : "SET"}',
        );
      }

      // Validate URL format
      if (!_isValidUrl(supabaseUrl)) {
        throw SupabaseException('Invalid SUPABASE_URL format: $supabaseUrl');
      }

      // Initialize Supabase with retry mechanism
      await _initializeWithRetry();

      _instance._client = Supabase.instance.client;
      _instance._isInitialized = true;

      debugPrint('✅ Supabase initialized successfully');
      debugPrint('🔗 Connected to: ${_maskUrl(supabaseUrl)}');
      
      // Test connection immediately
      final connectionTest = await _instance.checkConnection();
      debugPrint('🔍 Connection test result: $connectionTest');
      
    } catch (e) {
      debugPrint('❌ Supabase initialization failed: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      debugPrint('❌ Error details: ${e.toString()}');
      rethrow;
    } finally {
      _initializationInProgress = false;
    }
  }

  // Retry mechanism for Supabase initialization
  static Future<void> _initializeWithRetry({int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        await Supabase.initialize(
          url: supabaseUrl,
          anonKey: supabaseAnonKey,
          debug: kDebugMode,
          authOptions: FlutterAuthClientOptions(
            authFlowType: AuthFlowType.pkce,
            autoRefreshToken: true,
          ),
        );
        return; // Success, exit retry loop
      } catch (e) {
        debugPrint('❌ Supabase initialization attempt $attempt failed: $e');

        if (attempt == maxRetries) {
          throw SupabaseException(
            'Failed to initialize Supabase after $maxRetries attempts. Last error: $e',
          );
        }

        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(milliseconds: 1000 * attempt));
      }
    }
  }

  // URL validation helper
  static bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // URL masking for security in logs
  static String _maskUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return '${uri.scheme}://${uri.host}';
    } catch (e) {
      return 'invalid-url';
    }
  }

  // Client getter with better error handling
  SupabaseClient get client {
    if (!_isInitialized) {
      throw SupabaseException(
        'Supabase not initialized. Call SupabaseService.initialize() first or check your environment variables.',
      );
    }
    return _client;
  }

  // Async client getter for backward compatibility
  Future<SupabaseClient> get clientAsync async {
    if (!_isInitialized) {
      await initialize();
    }
    return _client;
  }

  // Safe client getter that returns null if not initialized
  SupabaseClient? get safeClient {
    return _isInitialized ? _client : null;
  }

  // Initialization status
  bool get isInitialized => _isInitialized;

  // Connection status check
  Future<bool> checkConnection() async {
    try {
      if (!_isInitialized) return false;

      // Simple query to test connection
      await _client.from('user_profiles').select('id').limit(1).maybeSingle();

      return true;
    } catch (e) {
      debugPrint('❌ Connection check failed: $e');
      return false;
    }
  }

  // Auth helpers with null safety
  bool get isAuthenticated {
    try {
      return _isInitialized && _client.auth.currentUser != null;
    } catch (e) {
      debugPrint('❌ Auth check failed: $e');
      return false;
    }
  }

  String? get currentUserId {
    try {
      return _isInitialized ? _client.auth.currentUser?.id : null;
    } catch (e) {
      debugPrint('❌ Get user ID failed: $e');
      return null;
    }
  }

  User? get currentUser {
    try {
      return _isInitialized ? _client.auth.currentUser : null;
    } catch (e) {
      debugPrint('❌ Get current user failed: $e');
      return null;
    }
  }

  // Enhanced sign out with error handling
  Future<void> signOut() async {
    try {
      if (!_isInitialized) {
        debugPrint('⚠️ Cannot sign out: Supabase not initialized');
        return;
      }

      await _client.auth.signOut();
      debugPrint('✅ User signed out successfully');
    } catch (e) {
      debugPrint('❌ Sign out failed: $e');
      throw SupabaseException('Sign out failed: $e');
    }
  }

  // Auth state stream with error handling
  Stream<AuthState> get authStateChanges {
    if (!_isInitialized) {
      throw SupabaseException(
        'Cannot access auth state: Supabase not initialized',
      );
    }

    return _client.auth.onAuthStateChange.handleError((error) {
      debugPrint('❌ Auth state change error: $error');
    });
  }

  // Cleanup method for testing or reinitialization
  static Future<void> dispose() async {
    try {
      if (_instance._isInitialized) {
        await _instance._client.dispose();
        _instance._isInitialized = false;
        debugPrint('🧹 Supabase service disposed');
      }
    } catch (e) {
      debugPrint('❌ Dispose failed: $e');
    }
  }

  // Health check method
  Future<Map<String, dynamic>> getHealthStatus() async {
    final status = <String, dynamic>{
      'initialized': _isInitialized,
      'authenticated': isAuthenticated,
      'user_id': currentUserId,
      'connection_ok': false,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (_isInitialized) {
      status['connection_ok'] = await checkConnection();
    }

    return status;
  }
}

// Custom exception class for better error handling
class SupabaseException implements Exception {
  final String message;

  const SupabaseException(this.message);

  @override
  String toString() => 'SupabaseException: $message';
}
