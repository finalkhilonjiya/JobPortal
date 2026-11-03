import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config.dart';
import 'core/theme.dart';
import 'screens/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  if (!Env.isConfigured) {
    runApp(const _ConfigMissingApp());
    return;
  }

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  runApp(const HousingApp());
}

class HousingApp extends StatelessWidget {
  const HousingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppInfo.name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const MainShell(),
    );
  }
}

class _ConfigMissingApp extends StatelessWidget {
  const _ConfigMissingApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Text(
              'App is not configured.\n\nBuild with --dart-define=SUPABASE_URL=... '
              'and --dart-define=SUPABASE_ANON_KEY=...',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
