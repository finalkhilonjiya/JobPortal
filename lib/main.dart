import 'core/app_export.dart';
import 'package:flutter/foundation.dart';

// Enhanced Configuration Management
class AppConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  
  // Timeouts and delays
  static const Duration initializationTimeout = Duration(seconds: 15);
  static const Duration navigationDelay = Duration(milliseconds: 100);
  static const Duration mountDelay = Duration(milliseconds: 500);
  static const Duration splashMinimumDuration = Duration(seconds: 2);
  
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

// Enhanced App State Management (Auth Removed)
enum AppState {
  initializing,
  initialized,
  error,
  ready,        // Simplified - no auth states
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
      debugPrint('🔄 App state changed to: $newState');
      notifyListeners();
    }
  }

  void setError(String message) {
    _errorMessage = message;
    setState(AppState.error);
  }

  void setOfflineMode(bool offline) {
    _isOfflineMode = offline;
    debugPrint('🌐 Offline mode: $offline');
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

// Enhanced App Initialization Service (Auth Removed)
class AppInitializationService {
  final ServiceLocator _serviceLocator = ServiceLocator();
  final AppStateNotifier _stateNotifier;
  
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  AppInitializationService(this._stateNotifier);

  Future<void> initialize() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      debugPrint('🚀 Starting app initialization...');
      
      // Register services (auth removed)
      _registerServices();
      
      // Initialize Supabase with enhanced retry logic
      await _initializeSupabaseWithRetry();
      
      _isInitialized = true;
      _stateNotifier.setState(AppState.initialized);
      
      stopwatch.stop();
      debugPrint('✅ App initialization completed in ${stopwatch.elapsedMilliseconds}ms');
      
    } catch (e, stackTrace) {
      stopwatch.stop();
      debugPrint('❌ App initialization failed: $e');
      debugPrint('Stack trace: $stackTrace');
      _stateNotifier.setError('Failed to initialize app: ${e.toString()}');
      rethrow;
    } finally {
      _stateNotifier.setRetrying(false);
    }
  }

  void _registerServices() {
    // Auth service registration removed
    _serviceLocator.register<AppStateNotifier>(_stateNotifier);
  }

  Future<void> _initializeSupabaseWithRetry({int maxRetries = 3}) async {
    if (!AppConfig.hasSupabaseCredentials) {
      debugPrint('⚠️ Supabase credentials not found, enabling offline mode');
      _stateNotifier.setOfflineMode(true);
      return;
    }

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('🔄 Supabase initialization attempt $attempt/$maxRetries');
        
        await SupabaseService.initialize()
            .timeout(AppConfig.initializationTimeout);
            
        debugPrint('✅ Supabase initialization completed');
        return;
        
      } catch (e) {
        debugPrint('❌ Supabase attempt $attempt failed: $e');
        
        if (attempt == maxRetries) {
          debugPrint('🔄 All attempts failed, enabling offline mode');
          _stateNotifier.setOfflineMode(true);
          return;
        }
        
        // Progressive delay: 2s, 4s, 6s
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
  }

  AppState determineInitialState() {
    if (_stateNotifier.isOfflineMode) {
      return AppState.offline;
    }
    
    // Simplified - no auth check, just return ready state
    return AppState.ready;
  }
}

// Enhanced Navigation Service
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  static BuildContext? get context => navigatorKey.currentContext;
  
  static Future<void> pushReplacementNamed(String routeName, {Object? arguments}) async {
    final currentContext = context;
    if (currentContext == null) {
      debugPrint('❌ Navigation context not available');
      return;
    }
    
    try {
      debugPrint('🧭 Navigating to: $routeName');
      await Navigator.pushReplacementNamed(currentContext, routeName, arguments: arguments);
    } catch (e) {
      debugPrint('❌ Navigation error: $e');
    }
  }
  
  static Future<void> pushNamed(String routeName, {Object? arguments}) async {
    final currentContext = context;
    if (currentContext == null) {
      debugPrint('❌ Navigation context not available');
      return;
    }
    
    try {
      debugPrint('🧭 Pushing: $routeName');
      await Navigator.pushNamed(currentContext, routeName, arguments: arguments);
    } catch (e) {
      debugPrint('❌ Navigation error: $e');
    }
  }
}

void main() async {
  // Enable performance profiling in debug mode
  if (kDebugMode) {
    debugPrintRebuildDirtyWidgets = true;
  }
  
  WidgetsFlutterBinding.ensureInitialized();

  // 🚨 CRITICAL: Enhanced error handling
  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint('❌ Widget Error: ${details.exception}');
    return CustomErrorWidget(errorDetails: details);
  };

  // 🚨 CRITICAL: Device orientation and system UI
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp
  ]);
  
  // Enhanced system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Set up error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('❌ Flutter error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  runApp(MyApp());
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
                
                // 🚨 CRITICAL: Text scaling and responsiveness
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
                home: const AppInitializer(),
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
  late final Stopwatch _splashStopwatch;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _stateNotifier = Provider.of<AppStateNotifier>(context, listen: false);
    _initializationService = AppInitializationService(_stateNotifier);
    _splashStopwatch = Stopwatch()..start();
    _initializeApp();
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
      debugPrint('❌ App initialization failed: $e');
      // Error state is already handled in the service
    }
  }

  Future<void> _handleInitialNavigation() async {
    // Ensure minimum splash duration for smooth UX
    final elapsed = _splashStopwatch.elapsedMilliseconds;
    final minimumMs = AppConfig.splashMinimumDuration.inMilliseconds;
    final delay = elapsed < minimumMs ? minimumMs - elapsed : 0;

    await Future.delayed(Duration(milliseconds: delay));
    
    if (!mounted) return;

    try {
      final initialState = _initializationService.determineInitialState();
      _stateNotifier.setState(initialState);
      
      // Simplified navigation - no auth checks
      switch (initialState) {
        case AppState.ready:
          debugPrint('✅ App ready, navigating to home');
          NavigationService.pushReplacementNamed(AppRoutes.homeMarketplaceFeed);
          break;
        case AppState.offline:
          debugPrint('🌐 Offline mode, navigating to splash');
          NavigationService.pushReplacementNamed(AppRoutes.splashScreen);
          break;
        case AppState.initialized:
        default:
          debugPrint('📱 Navigating to splash screen');
          NavigationService.pushReplacementNamed(AppRoutes.splashScreen);
      }
    } catch (e) {
      debugPrint('❌ Navigation error: $e');
      // Fallback to splash screen on any navigation error
      NavigationService.pushReplacementNamed(AppRoutes.splashScreen);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('📱 App resumed');
        break;
      case AppLifecycleState.paused:
        debugPrint('📱 App paused');
        break;
      case AppLifecycleState.detached:
        debugPrint('📱 App detached - cleaning up');
        _cleanup();
        break;
      default:
        break;
    }
  }

  Future<void> _cleanup() async {
    try {
      await ServiceLocator().dispose();
      debugPrint('🧹 Cleanup completed');
    } catch (e) {
      debugPrint('❌ Cleanup error: $e');
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
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.3 * 255),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.storefront,
                        size: 60,
                        color: Colors.white,
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
                        : 'Setting up your marketplace experience...',
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
                        NavigationService.pushReplacementNamed(AppRoutes.splashScreen);
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
                        NavigationService.pushReplacementNamed(AppRoutes.splashScreen);
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