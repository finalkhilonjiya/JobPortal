> Pankaj:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../core/app_export.dart';
import '../widgets/custom_error_widget.dart';
import './routes/app_routes.dart';
import './theme/app_theme.dart';
import './utils/auth_service.dart';
import './utils/supabase_service.dart';

// Configuration Management
class AppConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const Duration initializationTimeout = Duration(seconds: 10);
  static const Duration navigationDelay = Duration(milliseconds: 100);
  static const Duration mountDelay = Duration(milliseconds: 500);
  
  static bool get hasSupabaseCredentials => 
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}

// Service Locator for Dependency Injection
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  final Map<Type, dynamic> _services = {};
  
  T get<T>() {
    final service = _services[T];
    if (service == null) {
      throw Exception('Service of type $T not found. Make sure to register it first.');
    }
    return service as T;
  }
  
  void register<T>(T service) {
    _services[T] = service;
  }
  
  void unregister<T>() {
    _services.remove(T);
  }
  
  void clear() {
    _services.clear();
  }
}

// App State Management
enum AppState {
  initializing,
  initialized,
  error,
  authenticated,
  unauthenticated,
  offline
}

class AppStateNotifier extends ChangeNotifier {
  AppState _state = AppState.initializing;
  String _errorMessage = '';
  bool _isOfflineMode = false;
  bool _navigationInProgress = false;

  AppState get state => _state;
  String get errorMessage => _errorMessage;
  bool get isOfflineMode => _isOfflineMode;
  bool get navigationInProgress => _navigationInProgress;
  bool get isInitialized => _state != AppState.initializing;

  void setState(AppState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  void setError(String message) {
    _errorMessage = message;
    setState(AppState.error);
  }

  void setOfflineMode(bool offline) {
    _isOfflineMode = offline;
    notifyListeners();
  }

  void setNavigationInProgress(bool inProgress) {
    _navigationInProgress = inProgress;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}

// Centralized App Initialization Service
class AppInitializationService {
  final ServiceLocator _serviceLocator = ServiceLocator();
  final AppStateNotifier _stateNotifier;
  late final AuthService _authService;

  AppInitializationService(this._stateNotifier);

  Future<void> initialize() async {
    try {
      debugPrint('🚀 Starting app initialization...');
      
      // Register services
      _registerServices();
      
      // Initialize Supabase with timeout and error handling
      await _initializeSupabaseWithFallback();
      
      // Set up auth state listener only if Supabase is available
      if (!_stateNotifier.isOfflineMode) {
        _setupAuthStateListener();
      }
      
      _stateNotifier.setState(AppState.initialized);
      debugPrint('✅ App initialization completed');
      
    } catch (e) {
      debugPrint('❌ App initialization failed: $e');
      _stateNotifier.setError(e.toString());
      rethrow;
    }
  }

  void _registerServices() {
    _authService = AuthService();
    _serviceLocator.register<AuthService>(_authService);
    _serviceLocator.register<AppStateNotifier>(_stateNotifier);
  }

  Future<void> _initializeSupabaseWithFallback() async {
    try {
      if (!AppConfig.hasSupabaseCredentials) {
        debugPrint('⚠️ Supabase credentials not found, enabling offline mode');
        _stateNotifier.setOfflineMode(true);
        return;
      }

> Pankaj:
// Initialize Supabase with timeout
      await SupabaseService.initialize().timeout(AppConfig.initializationTimeout);
      debugPrint('✅ Supabase initialization completed');
      
    } catch (e) {
      debugPrint('❌ Supabase initialization failed: $e');
      debugPrint('🔄 Falling back to offline mode');
      _stateNotifier.setOfflineMode(true);
    }
  }

  void _setupAuthStateListener() {
    try {
      _authService.authStateChanges.listen(
        (data) {
          final event = data.event;
          debugPrint('🔄 Auth state changed: $event');

          if (event == 'SIGNED_IN') {
            _stateNotifier.setState(AppState.authenticated);
          } else if (event == 'SIGNED_OUT') {
            _stateNotifier.setState(AppState.unauthenticated);
          }
        },
        onError: (error) {
          debugPrint('❌ Auth state listener error: $error');
          _stateNotifier.setError('Authentication error: $error');
        },
      );
    } catch (e) {
      debugPrint('❌ Failed to setup auth listener: $e');
      _stateNotifier.setError('Failed to setup authentication: $e');
    }
  }

  AppState determineInitialState() {
    if (_stateNotifier.isOfflineMode) {
      return AppState.offline;
    }
    
    return _authService.isAuthenticated() 
        ? AppState.authenticated 
        : AppState.unauthenticated;
  }
}

// Navigation Service
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  static BuildContext? get context => navigatorKey.currentContext;
  
  static Future<void> pushReplacementNamed(String routeName) async {
    final currentContext = context;
    if (currentContext == null) {
      debugPrint('❌ Navigation context not available');
      return;
    }
    
    try {
      await Navigator.pushReplacementNamed(currentContext, routeName);
    } catch (e) {
      debugPrint('❌ Navigation error: $e');
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return CustomErrorWidget(errorDetails: details);
  };

  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp
  ]);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateNotifier()),
      ],
      child: Consumer<AppStateNotifier>(
        builder: (context, stateNotifier, child) {
          return Sizer(
            builder: (context, orientation, screenType) {
              return MaterialApp(
                title: 'marketplace_pro',
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: ThemeMode.light,
                navigatorKey: NavigationService.navigatorKey,
                // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(1.0),
                    ),
                    child: child!,
                  );
                },
                // 🚨 END CRITICAL SECTION
                debugShowCheckedModeBanner: false,
                routes: AppRoutes.routes,
                initialRoute: AppRoutes.initial,
                home: AppInitializer(),
              );
            },
          );
        },
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  @override
  _AppInitializerState createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  late final AppInitializationService _initializationService;
  late final AppStateNotifier _stateNotifier;

> Pankaj:
@override
  void initState() {
    super.initState();
    _stateNotifier = Provider.of<AppStateNotifier>(context, listen: false);
    _initializationService = AppInitializationService(_stateNotifier);
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await _initializationService.initialize();
      await _handleInitialNavigation();
    } catch (e) {
      // Error is already handled in the service
      debugPrint('❌ App initialization failed: $e');
    }
  }

  Future<void> _handleInitialNavigation() async {
    // Small delay to ensure widget is mounted
    await Future.delayed(AppConfig.mountDelay);

    if (!mounted) return;

    try {
      final initialState = _initializationService.determineInitialState();
      _stateNotifier.setState(initialState);
      
      switch (initialState) {
        case AppState.authenticated:
          debugPrint('🔐 User authenticated, navigating to home');
          NavigationService.pushReplacementNamed(AppRoutes.homeMarketplaceFeed);
          break;
        case AppState.offline:
        case AppState.unauthenticated:
          debugPrint('🔓 Navigating to splash screen');
          NavigationService.pushReplacementNamed(AppRoutes.splashScreen);
          break;
        default:
          NavigationService.pushReplacementNamed(AppRoutes.splashScreen);
      }
    } catch (e) {
      debugPrint('❌ Navigation error: $e');
      NavigationService.pushReplacementNamed(AppRoutes.splashScreen);
    }
  }

  void _retryInitialization() {
    _stateNotifier.setState(AppState.initializing);
    _stateNotifier.clearError();
    _stateNotifier.setOfflineMode(false);
    _initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateNotifier>(
      builder: (context, stateNotifier, child) {
        // Listen to state changes for navigation
        if (stateNotifier.isInitialized && !stateNotifier.navigationInProgress) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleStateBasedNavigation(stateNotifier.state);
          });
        }

        switch (stateNotifier.state) {
          case AppState.initializing:
            return _buildLoadingScreen();
          case AppState.error:
            return _buildErrorScreen(stateNotifier);
          default:
            return _buildLoadingScreen();
        }
      },
    );
  }

  void _handleStateBasedNavigation(AppState state) {
    if (_stateNotifier.navigationInProgress) return;
    
    _stateNotifier.setNavigationInProgress(true);
    
    Future.delayed(AppConfig.navigationDelay, () {
      if (!mounted) {
        _stateNotifier.setNavigationInProgress(false);
        return;
      }

      try {
        switch (state) {
          case AppState.authenticated:
            NavigationService.pushReplacementNamed(AppRoutes.homeMarketplaceFeed);
            break;
          case AppState.unauthenticated:
            NavigationService.pushReplacementNamed(AppRoutes.loginScreen);
            break;
          case AppState.offline:
          case AppState.initialized:
            NavigationService.pushReplacementNamed(AppRoutes.splashScreen);
            break;
          default:
            break;
        }
      } catch (e) {
        debugPrint('❌ Navigation error in state handler: $e');
      } finally {
        _stateNotifier.setNavigationInProgress(false);
      }
    });
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppTheme.lightTheme.primaryColor,
            ),
            SizedBox(height: 24),
            Text(
              'Initializing Marketplace Pro...',

> Pankaj:
style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Setting up your marketplace experience',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(AppStateNotifier stateNotifier) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
              SizedBox(height: 24),
              Text(
                'Initialization Error',
                style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red[600],
                ),
              ),
              SizedBox(height: 16),
              Text(
                'We encountered an issue while setting up the app. You can continue in offline mode or try again.',
                textAlign: TextAlign.center,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _retryInitialization,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.lightTheme.primaryColor,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Retry',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        NavigationService.pushReplacementNamed(AppRoutes.splashScreen);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppTheme.lightTheme.primaryColor),
                      ),
                      child: Text(
                        'Continue',
                        style: TextStyle(
                          color: AppTheme.lightTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (stateNotifier.isOfflineMode) ...[
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cloud_off,
                        color: Colors.orange[600],
                        size: 20,
                      ),

> Pankaj:
SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Running in offline mode. Some features may be limited.',
                          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up service locator if needed
    ServiceLocator().clear();
    super.dispose();
  }
}
