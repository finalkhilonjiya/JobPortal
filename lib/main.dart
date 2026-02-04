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
  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
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
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  /// Load env
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('Environment loaded successfully');
  } catch (e) {
    debugPrint('Failed to load .env file: $e');
  }

  /// Init Supabase
  if (AppConfig.hasSupabase) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );
      debugPrint('Supabase initialized successfully');
    } catch (e) {
      debugPrint('Supabase initialization failed: $e');
    }
  }

  runApp(const MyApp());

  /// UI chrome
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

            /// ALWAYS start with splash initializer.
            home: const AppInitializer(),
            routes: AppRoutes.routes,

            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.0)),
              child: child!,
            ),
          ),
        ),
      ),
    );
  }
}

/* ----------  APP START / SPLASH ---------- */
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    try {
      debugPrint('Starting app bootstrap...');

      /// Splash delay
      await Future.delayed(const Duration(milliseconds: 1500));

      /// If Supabase env missing → allow app to continue
      /// but still go to role selection.
      if (!AppConfig.hasSupabase) {
        debugPrint('Supabase missing env. Going to role selection.');
        notifier.setState(AppState.offline);
        NavigationService.pushReplacementNamed(AppRoutes.roleSelection);
        return;
      }

      /// Restore session
      final auth = MobileAuthService();
      await auth.initialize();

      /// If already logged in → go directly to HomeRouter
      if (auth.isAuthenticated) {
        debugPrint('User authenticated. Refreshing session...');

        final ok = await auth.refreshSession();
        if (ok) {
          notifier.setState(AppState.authenticated);
          NavigationService.pushReplacementNamed(AppRoutes.homeJobsFeed);
          return;
        }

        /// session invalid
        await auth.logout();
      }

      /// Default start
      notifier.setState(AppState.unauthenticated);
      NavigationService.pushReplacementNamed(AppRoutes.roleSelection);
    } catch (e) {
      debugPrint('Bootstrap error: $e');
      notifier.setState(AppState.unauthenticated);
      NavigationService.pushReplacementNamed(AppRoutes.roleSelection);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateNotifier>(
      builder: (_, n, __) => Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icons/app_icon.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Text(
                  'K',
                  style: TextStyle(
                    fontSize: 72,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Khilonjiya.com',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
              ),
              const SizedBox(height: 20),
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
        return 'Starting...';
      case AppState.authenticated:
        return 'Welcome back!';
      case AppState.unauthenticated:
        return 'Loading...';
    }
  }
}