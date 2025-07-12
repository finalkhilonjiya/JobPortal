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