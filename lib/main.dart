import 'core/app_export.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Enhanced Configuration Management
class AppConfig {
  // Change from const to getters that use SupabaseService
  static String get supabaseUrl => SupabaseService.supabaseUrl;
  static String get supabaseAnonKey => SupabaseService.supabaseAnonKey;
  
  // Timeouts and delays
  static const Duration initializationTimeout = Duration(seconds: 15);
  static const Duration navigationDelay = Duration(milliseconds: 100);
  static const Duration mountDelay = Duration(milliseconds: 500);
  
  // App metadata
  static const String appName = 'khilonjiya.com';
  static const String appVersion = '1.0.0';
  
  static bool get hasSupabaseCredentials => 
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}

// Enhanced Service Locator
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  final Map<Type, dynamic> _services = {};
  
  T get<T>() {
    final service = _services[T];
    if (service == null) {
      throw Exception('Service of type $T not found. Register it first.');
    }
    return service as T;
  }
  
  void register<T>(T service) {
    _services[T] = service;
  }
  
  void unregister<T>() {
    _services.remove(T);
  }
  
  Future<void> dispose() async {
    _services.clear();
  }
}

// Enhanced App State Management
enum AppState {
  initializing,
  initialized,
  error,
  authenticated,
  unauthenticated,
  offline,
  maintenance
}

class AppStateNotifier extends ChangeNotifier {
  AppState _state = AppState.initializing;
  String _errorMessage = '';
  bool _isOfflineMode = false;
  bool _navigationInProgress = false;
  bool _isRetrying = false;

  AppState get state => _state;
  String get errorMessage => _errorMessage;
  bool get isOfflineMode => _isOfflineMode;
  bool get navigationInProgress => _navigationInProgress;
  bool get isInitialized => _state != AppState.initializing;
  bool get isRetrying => _isRetrying;

  void setState(AppState newState) {
    if (_state != newState) {
      _state = newState;
      debugPrint('App state changed to: $newState');
      notifyListeners();
    }
  }

  void setError(String message) {
    _errorMessage = message;
    setState(AppState.error);
  }

  void setOfflineMode(bool offline) {
    _isOfflineMode = offline;
    debugPrint('Offline mode: $offline');
    notifyListeners();
  }

  void setNavigationInProgress(bool inProgress) {
    _navigationInProgress = inProgress;
    notifyListeners();
  }

  void setRetrying(bool retrying) {
    _isRetrying = retrying;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  void retry() {
    clearError();
    setOfflineMode(false);
    setRetrying(true);
    setState(AppState.initializing);
  }
}

// Enhanced App Initialization Service
class AppInitializationService {
  final ServiceLocator _serviceLocator = ServiceLocator();
  final AppStateNotifier _stateNotifier;
  late final AuthService _authService;
  
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  AppInitializationService(this._stateNotifier);

  Future<void> initialize() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      debugPrint('Starting app initialization...');
      
      // Register services
      _registerServices();
      
      // Initialize Supabase with enhanced retry logic
      await _initializeSupabaseWithRetry();
      
      // Set up auth state listener if not offline
      if (!_stateNotifier.isOfflineMode) {
        _setupAuthStateListener();
      }
      
      _isInitialized = true;
      _stateNotifier.setState(AppState.initialized);
      
      stopwatch.stop();
      debugPrint('App initialization completed in ${stopwatch.elapsedMilliseconds}ms');
      
    } catch (e, stackTrace) {
      stopwatch.stop();
      debugPrint('App initialization failed: $e');
      debugPrint('Stack trace: $stackTrace');
      _stateNotifier.setError('Failed to initialize app: ${e.toString()}');
      rethrow;
    } finally {
      _stateNotifier.setRetrying(false);
    }
  }

  void _registerServices() {
    _authService = AuthService();
    _serviceLocator.register<AuthService>(_authService);
    _serviceLocator.register<AppStateNotifier>(_stateNotifier);
  }

  Future<void> _initializeSupabaseWithRetry({int maxRetries = 3}) async {
    // Debug environment variables
    debugPrint('Checking Supabase credentials...');
    debugPrint('SUPABASE_URL: ${AppConfig.supabaseUrl.isNotEmpty ? "SET" : "NOT SET"}');
    debugPrint('SUPABASE_ANON_KEY: ${AppConfig.supabaseAnonKey.isNotEmpty ? "SET" : "NOT SET"}');
    
    if (!AppConfig.hasSupabaseCredentials) {
      debugPrint('Supabase credentials not found, enabling offline mode');
      debugPrint('Please ensure SUPABASE_URL and SUPABASE_ANON_KEY are set in Codemagic environment variables');
      _stateNotifier.setOfflineMode(true);
      return;
    }

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('Supabase initialization attempt $attempt/$maxRetries');
        debugPrint('URL: ${AppConfig.supabaseUrl.substring(0, 20)}...');
        debugPrint('Key: ${AppConfig.supabaseAnonKey.substring(0, 10)}...');
        
        await SupabaseService.initialize()
            .timeout(AppConfig.initializationTimeout);
            
        debugPrint('Supabase initialization completed successfully');
        
        // Verify connection
        final healthStatus = await SupabaseService().getHealthStatus();
        debugPrint('Health check: $healthStatus');
        
        return;
        
      } catch (e) {
        debugPrint('Supabase attempt $attempt failed: $e');
        debugPrint('Error type: ${e.runtimeType}');
        
        if (attempt == maxRetries) {
          debugPrint('All attempts failed, enabling offline mode');
          debugPrint('Please check your Supabase project settings and network connection');
          _stateNotifier.setOfflineMode(true);
          return;
        }
        
        // Progressive delay: 2s, 4s, 6s
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
  }

  void _setupAuthStateListener() {
    try {
      _authService.authStateChanges.listen(
        (data) {
          final event = data.event;
          debugPrint('Auth state changed: $event');

          switch (event) {
            case AuthChangeEvent.signedIn:
              _stateNotifier.setState(AppState.authenticated);
              break;
            case AuthChangeEvent.signedOut:
              _stateNotifier.setState(AppState.unauthenticated);
              break;
            case AuthChangeEvent.tokenRefreshed:
              debugPrint('Token refreshed');
              break;
            default:
              debugPrint('Unknown auth event: $event');
          }
        },
        onError: (error) {
          debugPrint('Auth state listener error: $error');
          _stateNotifier.setError('Authentication error: $error');
        },
      );
    } catch (e) {
      debugPrint('Failed to setup auth listener: $e');
      _stateNotifier.setError('Failed to setup authentication: $e');
    }
  }

  AppState determineInitialState() {
    if (_stateNotifier.isOfflineMode) {
      return AppState.offline;
    }
    
    try {
      return _authService.isAuthenticated() 
          ? AppState.authenticated 
          : AppState.unauthenticated;
    } catch (e) {
      debugPrint('Error determining auth state: $e');
      return AppState.unauthenticated;
    }
  }
}

// Enhanced Navigation Service
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  static BuildContext? get context => navigatorKey.currentContext;
  
  static Future<void> pushReplacementNamed(String routeName, {Object? arguments}) async {
    final currentContext = context;
    if (currentContext == null) {
      debugPrint('Navigation context not available');
      return;
    }
    
    try {
      debugPrint('Navigating to: $routeName');
      await Navigator.pushReplacementNamed(currentContext, routeName, arguments: arguments);
    } catch (e) {
      debugPrint('Navigation error: $e');
    }
  }
  
  static Future<void> pushNamed(String routeName, {Object? arguments}) async {
    final currentContext = context;
    if (currentContext == null) {
      debugPrint('Navigation context not available');
      return;
    }
    
    try {
      debugPrint('Pushing: $routeName');
      await Navigator.pushNamed(currentContext, routeName, arguments: arguments);
    } catch (e) {
      debugPrint('Navigation error: $e');
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Essential error handling only
  if (kDebugMode) {
    debugPrintRebuildDirtyWidgets = true;
  }

  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint('Widget Error: ${details.exception}');
    return CustomErrorWidget(errorDetails: details);
  };

  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('Flutter error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  // START APP IMMEDIATELY
  runApp(MyApp());
  
  // MOVE HEAVY OPERATIONS AFTER APP STARTS (non-blocking)
  _setupSystemUI();
}

// Setup system UI
void _setupSystemUI() async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp
  ]);
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
                title: AppConfig.appName,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: ThemeMode.system,
                navigatorKey: NavigationService.navigatorKey,
                
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: const TextScaler.linear(1.0),
                    ),
                    child: child!,
                  );
                },
                
                debugShowCheckedModeBanner: false,
                routes: AppRoutes.routes,
                initialRoute: AppRoutes.initial,
              );
            },
          );
        },
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({Key? key}) : super(key: key);

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> with WidgetsBindingObserver {
  late final AppInitializationService _initializationService;
  late final AppStateNotifier _stateNotifier;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // START IMMEDIATELY WITHOUT DELAY
    _stateNotifier = Provider.of<AppStateNotifier>(context, listen: false);
    _initializationService = AppInitializationService(_stateNotifier);
    
    // START INITIALIZATION RIGHT AWAY
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeApp();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      await _initializationService.initialize();
      await _handleInitialNavigation();
    } catch (e) {
      debugPrint('App initialization failed: $e');
      // Error state is already handled in the service
    }
  }

  Future<void> _handleInitialNavigation() async {
    if (!mounted) return;

    try {
      final initialState = _initializationService.determineInitialState();
      _stateNotifier.setState(initialState);
      
      // Navigation flow: Direct to auth/home
      switch (initialState) {
        case AppState.authenticated:
          debugPrint('User already authenticated, navigating directly to home');
          NavigationService.pushReplacementNamed(AppRoutes.homeMarketplaceFeed);
          break;
        case AppState.offline:
          debugPrint('Offline mode, navigating to login');
          NavigationService.pushReplacementNamed(AppRoutes.loginScreen);
          break;
        case AppState.unauthenticated:
        case AppState.initialized:
        default:
          debugPrint('User not authenticated, navigating to login');
          NavigationService.pushReplacementNamed(AppRoutes.loginScreen);
      }
    } catch (e) {
      debugPrint('Navigation error: $e');
      // Fallback to login screen
      NavigationService.pushReplacementNamed(AppRoutes.loginScreen);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('App resumed - checking auth state');
        // Optionally refresh auth state when app comes to foreground
        if (_initializationService.isInitialized && !_stateNotifier.isOfflineMode) {
          _checkAuthStateOnResume();
        }
        break;
      case AppLifecycleState.paused:
        debugPrint('App paused');
        break;
      case AppLifecycleState.detached:
        debugPrint('App detached - cleaning up');
        _cleanup();
        break;
      default:
        break;
    }
  }

  Future<void> _checkAuthStateOnResume() async {
    try {
      final currentState = _initializationService.determineInitialState();
      if (currentState != _stateNotifier.state) {
        debugPrint('Auth state changed while app was in background');
        _stateNotifier.setState(currentState);
      }
    } catch (e) {
      debugPrint('Error checking auth state on resume: $e');
    }
  }

  Future<void> _cleanup() async {
    try {
      await ServiceLocator().dispose();
      debugPrint('Cleanup completed');
    } catch (e) {
      debugPrint('Cleanup error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateNotifier>(
      builder: (context, stateNotifier, child) {
        switch (stateNotifier.state) {
          case AppState.initializing:
            return _buildLoadingScreen();
          case AppState.error:
            return _buildErrorScreen(stateNotifier);
          case AppState.offline:
            return _buildOfflineScreen();
          default:
            return _buildLoadingScreen();
        }
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App logo
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Color(0xFF2563EB),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'K',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      AppConfig.appName,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.lightTheme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'আমাৰ সংস্কৃতি, আমাৰ গৌৰৱ',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.lightTheme.colorScheme.primary,
                        ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _stateNotifier.isRetrying 
                        ? 'Retrying connection...' 
                        : 'Loading...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(AppStateNotifier stateNotifier) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red[400],
              ),
              const SizedBox(height: 24),
              Text(
                'Connection Error',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                stateNotifier.errorMessage.isNotEmpty 
                    ? stateNotifier.errorMessage
                    : 'Unable to connect to our servers. Please check your internet connection and try again.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: stateNotifier.isRetrying ? null : () {
                        stateNotifier.retry();
                        _initializeApp();
                      },
                      icon: stateNotifier.isRetrying 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(stateNotifier.isRetrying ? 'Retrying...' : 'Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        stateNotifier.setOfflineMode(true);
                        NavigationService.pushReplacementNamed(AppRoutes.loginScreen);
                      },
                      icon: const Icon(Icons.cloud_off),
                      label: const Text('Continue'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppTheme.lightTheme.colorScheme.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (stateNotifier.isOfflineMode) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Some features may be limited in offline mode.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

  Widget _buildOfflineScreen() {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off,
                size: 80,
                color: Colors.blue[400],
              ),
              const SizedBox(height: 24),
              Text(
                'Offline Mode',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'You\'re currently offline. Some features may be limited. Connect to the internet for the full experience.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _stateNotifier.retry();
                        _initializeApp();
                      },
                      icon: const Icon(Icons.wifi),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[400],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        NavigationService.pushReplacementNamed(AppRoutes.loginScreen);
                      },
                      icon: const Icon(Icons.offline_bolt),
                      label: const Text('Continue'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.blue[400]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 