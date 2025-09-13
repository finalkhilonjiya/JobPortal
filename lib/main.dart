import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'core/app_export.dart';

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

/* ----------  NAV HELPER  ---------- */
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static Future<void> pushReplacementNamed(String route, {Object? args}) async {
    final ctx = navigatorKey.currentContext;
    if (ctx != null) Navigator.pushReplacementNamed(ctx, route, arguments: args);
  }
}

/* ----------  MAIN  ---------- */
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  try { await dotenv.load(fileName: '.env'); } catch (_) {}
  if (AppConfig.hasSupabase) {
    try {
      await Supabase.initialize(url: AppConfig.supabaseUrl, anonKey: AppConfig.supabaseAnonKey);
    } catch (_) {/* offline handled below */}
  }
  runApp(const MyApp());
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
    return ChangeNotifierProvider(
      create: (_) => AppStateNotifier(),
      child: Consumer<AppStateNotifier>(
        builder: (_, notifier, __) => MaterialApp(
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
    );
  }
}

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
    final auth = AuthService();
    if (Supabase.instance.client == null) {
      notifier.setState(AppState.offline);
      NavigationService.pushReplacementNamed(AppRoutes.loginScreen);
      return;
    }
    if (auth.isAuthenticated()) {
      notifier.setState(AppState.authenticated);
      NavigationService.pushReplacementNamed(AppRoutes.homeMarketplaceFeed);
    } else {
      notifier.setState(AppState.unauthenticated);
      NavigationService.pushReplacementNamed(AppRoutes.loginScreen);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateNotifier>(
      builder: (_, n, __) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(strokeWidth: 3),
              const SizedBox(height: 16),
              Text(n.state == AppState.initializing ? 'Loading…' : 'Redirecting…'),
            ],
          ),
        ),
      ),
    );
  }
}
