import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/force_update_service.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'core/navigation_service.dart';
import 'core/ui/khilonjiya_ui.dart';
import 'routes/app_routes.dart';

class AppConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static bool get hasSupabase =>
      supabaseUrl.trim().isNotEmpty &&
      supabaseAnonKey.trim().isNotEmpty;
}

/// =============================================================
/// SAVE FCM TOKEN — call this after every login and on startup
/// One row per user — upsert on user_id replaces old token
/// =============================================================
Future<void> saveFcmToken() async {
  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final messaging = FirebaseMessaging.instance;
    final token = await messaging.getToken();
    if (token == null) return;

    // Read the active role from secure storage
    final prefs = await SharedPreferences.getInstance();
    // Role is stored by MobileAuthService under 'user_role' key
    // We read it from FlutterSecureStorage — but since saveFcmToken
    // is called right after login, we pass the role as a parameter.
    // See saveFcmTokenWithRole() below.

    await Supabase.instance.client
        .from('user_devices')
        .upsert(
          {
            "user_id": user.id,
            "fcm_token": token,
            "platform": "android",
            // active_role will be set by saveFcmTokenWithRole
          },
          onConflict: 'user_id',
        );

    print("✅ FCM token saved for user ${user.id}");
  } catch (e) {
    print("❌ FCM save error: $e");
  }
}

// Call this from login screens instead of saveFcmToken()
Future<void> saveFcmTokenWithRole(String role) async {
  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final messaging = FirebaseMessaging.instance;
    final token = await messaging.getToken();
    if (token == null) return;

    await Supabase.instance.client
        .from('user_devices')
        .upsert(
          {
            "user_id": user.id,
            "fcm_token": token,
            "platform": "android",
            "active_role": role,
          },
          onConflict: 'user_id',
        );

    print("✅ FCM token saved with role: $role");
  } catch (e) {
    print("❌ FCM save error: $e");
  }
}

/// =============================================================
/// LOCAL NOTIFICATION SETUP
/// =============================================================
final FlutterLocalNotificationsPlugin localNotifications =
    FlutterLocalNotificationsPlugin();

Future<void> initLocalNotifications() async {
  const android =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const settings = InitializationSettings(android: android);
  await localNotifications.initialize(settings);

  const channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    importance: Importance.max,
  );

  await localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

/// =============================================================
/// Firebase background handler
/// =============================================================
Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// =============================================================
/// PUSH INIT — only sets up listeners, token saved via saveFcmToken
/// =============================================================
Future<void> initPushNotifications() async {
  final messaging = FirebaseMessaging.instance;

  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Save token if user is already logged in (returning user)
  await saveFcmToken();

  // If token rotates, update it
  FirebaseMessaging.instance.onTokenRefresh
      .listen((newToken) async {
    try {
      final user =
          Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client
          .from('user_devices')
          .upsert(
            {
              "user_id": user.id,
              "fcm_token": newToken,
              "platform": "android",
            },
            onConflict: 'user_id',
          );

      print("✅ FCM token refreshed");
    } catch (e) {
      print("❌ FCM refresh error: $e");
    }
  });

  // Foreground notifications
  FirebaseMessaging.onMessage
      .listen((RemoteMessage message) async {
    final title =
        message.notification?.title ?? "Notification";
    final body = message.notification?.body ?? "";

    await localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  });

  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    NavigationService.pushReplacementNamed(AppRoutes.home);
  });

  final initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null) {
    NavigationService.pushReplacementNamed(AppRoutes.home);
  }
}

/// =============================================================
/// MAIN
/// =============================================================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  if (AppConfig.hasSupabase) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );
    } catch (_) {}
  }

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler,
    );
    await initLocalNotifications();
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

/// =============================================================
/// APP UI
/// =============================================================
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
          data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.0)),
          child: child!,
        ),
      ),
    );
  }
}

/// =============================================================
/// APP INITIALIZER
/// =============================================================
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() =>
      _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    try {
      await ForceUpdateService.check();

      if (!AppConfig.hasSupabase) {
        _go(AppRoutes.roleSelection);
        return;
      }

      final client = Supabase.instance.client;
      final session = client.auth.currentSession;
      final user = client.auth.currentUser;

      if (session != null && user != null) {
        _go(AppRoutes.home);
        return;
      }

      _go(AppRoutes.roleSelection);
    } catch (_) {
      _go(AppRoutes.roleSelection);
    }
  }

  void _go(String route) {
    if (!mounted || _navigated) return;
    _navigated = true;
    NavigationService.pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      body: const Center(
        child: CircularProgressIndicator(strokeWidth: 3),
      ),
    );
  }
}