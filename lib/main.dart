import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/force_update_service.dart';
import 'screens/force_update_screen.dart';

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

    if (user == null) {
      print("⚠️ No logged in user for FCM save");
      return;
    }

    final messaging = FirebaseMessaging.instance;

    print("📲 Getting FCM token...");

    final token = await messaging
        .getToken()
        .timeout(const Duration(seconds: 15));

    if (token == null || token.trim().isEmpty) {
      print("⚠️ FCM token is null");
      return;
    }

    print("✅ FCM TOKEN RECEIVED");

    await Supabase.instance.client
        .from('user_devices')
        .upsert(
          {
            "user_id": user.id,
            "fcm_token": token,
            "platform": "android",
          },
          onConflict: 'user_id',
        )
        .timeout(const Duration(seconds: 15));

    print("✅ FCM token saved for user ${user.id}");

  } catch (e, s) {
    print("❌ FCM SAVE ERROR");
    print(e);
    print(s);
  }
}
// Call this from login screens instead of saveFcmToken()
Future<void> saveFcmTokenWithRole(String role) async {
  try {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      print("⚠️ No logged in user");
      return;
    }

    final messaging = FirebaseMessaging.instance;

    print("📲 Getting FCM token with role...");

    final token = await messaging
        .getToken()
        .timeout(const Duration(seconds: 15));

    if (token == null || token.trim().isEmpty) {
      print("⚠️ FCM token null");
      return;
    }

    print("✅ FCM TOKEN RECEIVED");

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
        )
        .timeout(const Duration(seconds: 15));

    print("✅ FCM token saved with role: $role");

  } catch (e, s) {
    print("❌ FCM SAVE ERROR");
    print(e);
    print(s);
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

  try {

    final messaging = FirebaseMessaging.instance;

    print("🔔 Requesting notification permission");

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    ).timeout(const Duration(seconds: 10));

    print("✅ Notification permission completed");

    // DO NOT BLOCK APP IF THIS FAILS
    unawaited(saveFcmToken());

    FirebaseMessaging.instance.onTokenRefresh
        .listen((newToken) async {

      try {

        print("🔄 FCM token refreshed");

        final user =
            Supabase.instance.client.auth.currentUser;

        if (user == null) return;

        final existing = await Supabase.instance.client
            .from('user_devices')
            .select('active_role')
            .eq('user_id', user.id)
            .maybeSingle()
            .timeout(const Duration(seconds: 10));

        final activeRole =
            existing?['active_role']?.toString();

        await Supabase.instance.client
            .from('user_devices')
            .upsert(
              {
                "user_id": user.id,
                "fcm_token": newToken,
                "platform": "android",
                if (activeRole != null &&
                    activeRole.isNotEmpty)
                  "active_role": activeRole,
              },
              onConflict: 'user_id',
            )
            .timeout(const Duration(seconds: 10));

        print("✅ FCM token refreshed & saved");

      } catch (e, s) {

        print("❌ TOKEN REFRESH ERROR");
        print(e);
        print(s);
      }
    });

    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) async {

        try {

          final title =
              message.notification?.title ?? "Notification";

          final body =
              message.notification?.body ?? "";

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

        } catch (e) {

          print("❌ LOCAL NOTIFICATION ERROR");
          print(e);
        }
      },
    );

    FirebaseMessaging.onMessageOpenedApp.listen((message) {

      print("📩 Notification opened app");

      NavigationService.pushReplacementNamed(
        AppRoutes.home,
      );
    });

    try {

      final initialMessage = await messaging
          .getInitialMessage()
          .timeout(const Duration(seconds: 5));

      if (initialMessage != null) {

        print("📩 App opened from terminated notification");

        NavigationService.pushReplacementNamed(
          AppRoutes.home,
        );
      }

    } catch (e) {

      print("❌ INITIAL MESSAGE ERROR");
      print(e);
    }

  } catch (e, s) {

    print("❌ PUSH INIT ERROR");
    print(e);
    print(s);
  }
}

/// =============================================================
/// MAIN
/// =============================================================


Future<void> _initializeBackgroundServices() async {

  try {

    print("🔥 INITIALIZING FIREBASE");

    await Firebase.initializeApp()
        .timeout(const Duration(seconds: 15));

    FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler,
    );

    print("✅ FIREBASE INITIALIZED");

    await initLocalNotifications()
        .timeout(const Duration(seconds: 10));

    print("✅ LOCAL NOTIFICATIONS READY");

    await initPushNotifications()
        .timeout(const Duration(seconds: 15));

    print("✅ PUSH NOTIFICATIONS READY");

  } catch (e, s) {

    print("❌ BACKGROUND INIT ERROR");
    print(e);
    print(s);
  }
}
Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  try {

    await dotenv.load(fileName: '.env');

    print("✅ DOTENV LOADED");

  } catch (e) {

    print("❌ DOTENV ERROR");
    print(e);
  }

  if (AppConfig.hasSupabase) {

    try {

      print("🚀 INITIALIZING SUPABASE");

      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      ).timeout(const Duration(seconds: 15));

      print("✅ SUPABASE INITIALIZED");

    } catch (e, s) {

      print("❌ SUPABASE INIT ERROR");
      print(e);
      print(s);
    }
  }

  // RUN UI IMMEDIATELY
  runApp(const MyApp());

  // BACKGROUND INITIALIZATION
  unawaited(_initializeBackgroundServices());

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
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

  print("🚀 BOOTSTRAP START");

  try {

    await ForceUpdateService.check()
        .timeout(const Duration(seconds: 10));

    print("✅ FORCE UPDATE CHECK DONE");

    // =====================================================
    // FORCE UPDATE BLOCK
    // =====================================================

    if (ForceUpdateService.updateRequired) {

      print("⚠️ FORCE UPDATE REQUIRED");

      if (!mounted) return;

      await Navigator.of(context).pushAndRemoveUntil(

        MaterialPageRoute(
          builder: (_) => const ForceUpdateScreen(),
        ),

        (route) => false,
      );

      return;
    }

    // =====================================================
    // NORMAL FLOW
    // =====================================================

    if (!AppConfig.hasSupabase) {

      print("⚠️ NO SUPABASE CONFIG");

      _go(AppRoutes.roleSelection);

      return;
    }

    final client = Supabase.instance.client;

    print("📦 GETTING SESSION");

    final session = client.auth.currentSession;

    print("✅ SESSION:");
    print(session);

    final user = client.auth.currentUser;

    print("✅ USER:");
    print(user);

    // OPTIONAL SESSION VALIDATION
    if (session != null && user != null) {

      try {

        print("🔎 VALIDATING SESSION");

        await client
            .from('user_profiles')
            .select('id')
            .limit(1)
            .timeout(const Duration(seconds: 10));

        print("✅ SESSION VALID");

      } catch (e, s) {

        print("❌ SESSION VALIDATION FAILED");
        print(e);
        print(s);

        try {

          await client.auth.signOut();

          print("✅ BAD SESSION CLEARED");

        } catch (e) {

          print("❌ SIGNOUT ERROR");
          print(e);
        }

        _go(AppRoutes.roleSelection);

        return;
      }

      print("🏠 GOING HOME");

      _go(AppRoutes.home);

      return;
    }

    print("➡️ GOING ROLE SELECTION");

    _go(AppRoutes.roleSelection);

  } catch (e, s) {

    print("❌ BOOTSTRAP ERROR");
    print(e);
    print(s);

    _go(AppRoutes.roleSelection);
  }
}

  void _go(String route) {

  if (!mounted || _navigated) return;

  _navigated = true;

  WidgetsBinding.instance.addPostFrameCallback((_) {

    NavigationService.pushReplacementNamed(route);

  });
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