import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'core/navigation_service.dart';
import 'core/ui/khilonjiya_ui.dart';
import 'routes/app_routes.dart';

class AppConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static bool get hasSupabase =>
      supabaseUrl.trim().isNotEmpty &&
      supabaseAnonKey.trim().isNotEmpty;
}

/// ------------------------------------------------------------
/// Firebase background handler
/// ------------------------------------------------------------
Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// ------------------------------------------------------------
/// Push notification initialization
/// ------------------------------------------------------------
Future<void> initPushNotifications() async {
  final messaging = FirebaseMessaging.instance;

  // Permission (important)
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Get token
  final token = await messaging.getToken();

  print("FCM TOKEN: $token");

  if (token == null) return;

  final user = Supabase.instance.client.auth.currentUser;

  if (user != null) {
    // ✅ FIXED TABLE
    await Supabase.instance.client
        .from('user_push_tokens')
        .upsert({
      "user_id": user.id,
      "fcm_token": token,
      "platform": "android"
    });
  }

  // =========================================================
  // ✅ FOREGROUND NOTIFICATION HANDLER (MISSING IN YOUR CODE)
  // =========================================================
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("Foreground message: ${message.notification?.title}");

    // You can later show local notification here
  });

  // =========================================================
  // ✅ CLICK HANDLER
  // =========================================================
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    print("Notification clicked");
  });
}
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  /// ------------------------------------------------------------
  /// Supabase init (existing)
  /// ------------------------------------------------------------
  if (AppConfig.hasSupabase) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );
    } catch (_) {}
  }

  /// ------------------------------------------------------------
  /// Firebase init (added)
  /// ------------------------------------------------------------
  try {
    await Firebase.initializeApp();

    FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler,
    );

    await initPushNotifications();
  } catch (_) {}

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
        home: const AppInitializer(),
        routes: AppRoutes.routes,
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
/// Native splash already shown → NO artificial delay
/// ------------------------------------------------------------
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() =>
      _AppInitializerState();
}

class _AppInitializerState
    extends State<AppInitializer> {

  bool _navigated = false;
  String _loadingText = "Initializing...";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
  try {
    if (!AppConfig.hasSupabase) {
      _go(AppRoutes.roleSelection);
      return;
    }

    final client = Supabase.instance.client;
    final session = client.auth.currentSession;
    final user = client.auth.currentUser;

    // ✅ USER LOGGED IN → GO HOME
    if (session != null && user != null) {
      _go(AppRoutes.home);
      return;
    }

    // ❌ NOT LOGGED IN → GO ROLE SELECTION
    _go(AppRoutes.roleSelection);
  } catch (_) {
    _go(AppRoutes.roleSelection);
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
      body: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
        ),
      ),
    );
  }
}