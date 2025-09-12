import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/app_export.dart';
import './presentation/login_screen/mobile_login_screen.dart';
import './presentation/login_screen/mobile_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load env variables
  await dotenv.load(fileName: ".env");

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Khilonjiya",
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: FutureBuilder(
        future: AppInitializationService.initializeApp(),
        builder: (context, snapshot) {
          // While initializing (after native splash disappears)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SplashScreen();
          }

          // Initialization failed
          if (snapshot.hasError) {
            return ErrorScreen(
              error: snapshot.error.toString(),
              onRetry: () {
                // force rebuild (re-run FutureBuilder)
                (context as Element).reassemble();
              },
            );
          }

          // Initialization succeeded
          final authService = MobileAuthService();
          return authService.isAuthenticated
              ? HomeMarketplaceFeed() // Replace with your actual home widget
              : MobileLoginScreen();
        },
      ),
    );
  }
}

/// Simple loading splash (shows after native splash disappears)
class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/images/company_logo.png",
              height: 100,
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              "Connecting to server...",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error screen if initialization fails
class ErrorScreen extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const ErrorScreen({Key? key, required this.error, required this.onRetry})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 64),
              SizedBox(height: 16),
              Text(
                "Initialization Failed",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[800],
                ),
              ),
              SizedBox(height: 12),
              Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red[700]),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: Icon(Icons.refresh),
                label: Text("Retry"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}