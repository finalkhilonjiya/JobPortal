// File: lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/navigation_service.dart';
import 'core/ui/khilonjiya_ui.dart';
import 'routes/app_routes.dart';

class AppConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static bool get hasSupabase =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Load env
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // silent fallback
  }

  // Init Supabase only if config exists
  if (AppConfig.hasSupabase) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );
    } catch (_) {
      // silent fallback
    }
  }

  // System UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (_, __, ___) => MaterialApp(
        title: 'Khilonjiya.com',
        debugShowCheckedModeBanner: false,
        navigatorKey: NavigationService.navigatorKey,
        theme: KhilonjiyaUI.theme(),
        themeMode: ThemeMode.light,

        // Always start from splash/initializer
        home: const AppInitializer(),

        // Static routes
        routes: AppRoutes.routes,

        // Dynamic routes
        onGenerateRoute: AppRoutes.onGenerateRoute,

        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child!,
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// AppInitializer
/// - Shows splash for MINIMUM 3 seconds
/// - Then routes based on session
/// ------------------------------------------------------------
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  static const Duration _minSplash = Duration(seconds: 3);

  bool _navigated = false;
  String _loadingText = "Initializing...";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final start = DateTime.now();

    try {
      setState(() => _loadingText = "Starting...");

      // 1) If Supabase config missing -> go role selection
      if (!AppConfig.hasSupabase) {
        await _waitSplash(start);
        _go(AppRoutes.roleSelection);
        return;
      }

      final client = Supabase.instance.client;

      final session = client.auth.currentSession;
      final user = client.auth.currentUser;

      // 2) If logged in -> go HomeRouter (role-based)
      if (session != null && user != null) {
        setState(() => _loadingText = "Welcome back...");
        await _waitSplash(start);
        _go(AppRoutes.home);
        return;
      }

      // 3) Not logged in -> go role selection
      setState(() => _loadingText = "Loading...");
      await _waitSplash(start);
      _go(AppRoutes.roleSelection);
    } catch (_) {
      await _waitSplash(start);
      _go(AppRoutes.roleSelection);
    }
  }

  Future<void> _waitSplash(DateTime start) async {
    final elapsed = DateTime.now().difference(start);
    final remaining = _minSplash - elapsed;

    if (remaining.inMilliseconds > 0) {
      await Future.delayed(remaining);
    }
  }

  void _go(String route) {
    if (!mounted) return;
    if (_navigated) return;
    _navigated = true;

    NavigationService.pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/app_icon.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Text(
                'K',
                style: KhilonjiyaUI.h1.copyWith(
                  fontSize: 72,
                  color: KhilonjiyaUI.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Khilonjiya.com',
              style: KhilonjiyaUI.h1.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(strokeWidth: 3),
            const SizedBox(height: 20),
            Text(
              _loadingText,
              style: KhilonjiyaUI.body.copyWith(
                fontSize: 16,
                color: KhilonjiyaUI.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}