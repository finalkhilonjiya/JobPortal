import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/force_update_service.dart'; // ADD TOP


// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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

/// =============================================================
/// LOCAL NOTIFICATION SETUP
/// =============================================================
final FlutterLocalNotificationsPlugin localNotifications =
    FlutterLocalNotificationsPlugin();

Future<void> initLocalNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');

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
/// PUSH INIT (FIXED FULL)
/// =============================================================
Future<void> initPushNotifications() async {
  final messaging = FirebaseMessaging.instance;

  // ✅ Permission
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // ✅ Get token
  final token = await messaging.getToken();
  print("FCM TOKEN: $token");

  final user = Supabase.instance.client.auth.currentUser;

  if (user != null && token != null) {
    await Supabase.instance.client
        .from('user_devices') // ✅ CORRECT TABLE
        .upsert({
      "user_id": user.id,
      "fcm_token": token,
      "platform": "android"
    });
  }

  // =========================================================
  // ✅ TOKEN REFRESH (CRITICAL FIX)
  // =========================================================
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      await Supabase.instance.client.from('user_devices').upsert({
        "user_id": user.id,
        "fcm_token": newToken,
        "platform": "android"
      });
    }
  });

  // =========================================================
  // ✅ FOREGROUND NOTIFICATION (FIXED)
  // =========================================================
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    final title = message.notification?.title ?? "Notification";
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

  // =========================================================
  // ✅ CLICK HANDLING
  // =========================================================
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    NavigationService.pushNamed(AppRoutes.home);
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

  // =========================================================
  // SUPABASE
  // =========================================================
  if (AppConfig.hasSupabase) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );
    } catch (_) {}
  }

  // =========================================================
  // FIREBASE + PUSH
  // =========================================================
  try {
    await Firebase.initializeApp();

    FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler,
    );

    await initLocalNotifications(); // ✅ ADDED
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
/// APP UI (UNCHANGED)
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
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child!,
        ),
      ),
    );
  }
}

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  
Future<void> _bootstrap() async {
  try {
    // ✅ FORCE UPDATE CHECK (FIRST THING)
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