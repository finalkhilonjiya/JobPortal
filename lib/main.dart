import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'core/app_export.dart';
import 'core/navigation_service.dart';
import 'presentation/login_screen/mobile_auth_service.dart';

/* ----------  CONFIG  ---------- */
class AppConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}

/* ----------  APP-STATE  ---------- */
enum AppState { initializing, offline, authenticated, unauthenticated }

class AppStateNotifier with ChangeNotifier {
  AppState _state = AppState.initializing;
  AppState get state => _state;
  void setState(AppState s) {
    _state = s;
    notifyListeners();
  }
}

/* ----------  MAIN  ---------- */
Future<void> main() async {
  /* 1.  Engine ready */
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  /* 2.  Env + Supabase (no delay) */
  try { 
    await dotenv.load(fileName: '.env'); 
    debugPrint('Environment loaded successfully');
  } catch (e) {
    debugPrint('Failed to load .env file: $e');
  }
  
  if (AppConfig.hasSupabase) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl, 
        anonKey: AppConfig.supabaseAnonKey,
      );
      debugPrint('Supabase initialized successfully');
    } catch (e) {
      debugPrint('Supabase initialization failed: $e');
      /* offline handled below */
    }
  }

  /* 3.  Run app immediately */
  runApp(const MyApp());

  /* 4.  Chrome styling (non-blocking) */
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
}

/* ----------  APP WIDGET  ---------- */
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppStateNotifier(),
      child: Consumer<AppStateNotifier>(
        builder: (_, notifier, __) => Sizer(
          builder: (_, __, ___) => MaterialApp(
            title: 'khilonjiya.com',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            navigatorKey: NavigationService.navigatorKey,
            debugShowCheckedModeBanner: false,
            initialRoute: AppRoutes.initial,
            routes: AppRoutes.routes,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
              child: child!,
            ),
          ),
        ),
      ),
    );
  }
}

/* ----------  APP START  ---------- */
class AppInitializer extends StatefulWidget {
  const AppInitializer({Key? key}) : super(key: key);
  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  late final AppStateNotifier notifier;

  @override
  void initState() {
    super.initState();
    notifier = context.read<AppStateNotifier>();
    /* start immediately after first frame */
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    try {
      debugPrint('Starting app bootstrap...');
      
      // ✅ CHANGED: Extended delay to 4 seconds for splash screen duration
      await Future.delayed(const Duration(milliseconds: 7000));

      // Check if Supabase is available
      if (Supabase.instance.client == null) {
        debugPrint('Supabase not available, going offline');
        notifier.setState(AppState.offline);
        NavigationService.pushReplacementNamed(AppRoutes.loginScreen);
        return;
      }

      // Initialize authentication service
      final auth = MobileAuthService();
      await auth.initialize();
      debugPrint('MobileAuthService initialized');

      // Check if user is already authenticated
      if (auth.isAuthenticated) {
        debugPrint('User has stored session, validating...');

        // Validate stored session
        final sessionValid = await auth.refreshSession();
        if (sessionValid) {
          debugPrint('Session valid, navigating to home');
          notifier.setState(AppState.authenticated);
          NavigationService.pushReplacementNamed(AppRoutes.homeMarketplaceFeed);
        } else {
          debugPrint('Session invalid, going to login');
          notifier.setState(AppState.unauthenticated);
          NavigationService.pushReplacementNamed(AppRoutes.loginScreen);
        }
      } else {
        debugPrint('No stored session, going to login');
        notifier.setState(AppState.unauthenticated);
        NavigationService.pushReplacementNamed(AppRoutes.loginScreen);
      }

    } catch (e) {
      debugPrint('Bootstrap error: $e');
      notifier.setState(AppState.unauthenticated);
      NavigationService.pushReplacementNamed(AppRoutes.loginScreen);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateNotifier>(
      builder: (_, n, __) => Scaffold(
        backgroundColor: const Color(0xFFF0F0F0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo while loading
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFF4285F4),
                  shape: BoxShape.circle,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: Image.asset(
                    'assets/images/company_logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Text(
                        'K',
                        style: TextStyle(
                          fontSize: 36,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Khilonjiya.com',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4285F4), // Updated to primary blue color
                ),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4285F4)),
              ),
              const SizedBox(height: 16),
              Text(
                _getLoadingText(n.state),
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLoadingText(AppState state) {
    switch (state) {
      case AppState.initializing:
        return 'Initializing...';
      case AppState.offline:
        return 'Connecting...';
      case AppState.authenticated:
        return 'Welcome back!';
      case AppState.unauthenticated:
        return 'Loading...';
    }
  }
}
