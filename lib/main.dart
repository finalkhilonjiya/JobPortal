import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Minimal AppConfig
class AppConfig {
  static const String appName = 'khilonjiya.com';
  static const bool hasSupabaseCredentials = false; // Start with offline
}

// Minimal AppState
enum AppState {
  initializing,
  initialized,
  error,
}

// Minimal StateNotifier
class AppStateNotifier extends ChangeNotifier {
  AppState _state = AppState.initializing;
  String _errorMessage = '';

  AppState get state => _state;
  String get errorMessage => _errorMessage;

  void setState(AppState newState) {
    print('🔄 State change: $_state → $newState');
    _state = newState;
    notifyListeners();
  }

  void setError(String message) {
    _errorMessage = message;
    setState(AppState.error);
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  print("🚀 App starting...");
  
  // Simple error handler
  FlutterError.onError = (details) {
    print('❌ Flutter Error: ${details.exception}');
  };
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print("🏗️ Building MyApp");
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateNotifier()),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.white,
        ),
        home: AppInitializer(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  @override
  _AppInitializerState createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    print("🚀 AppInitializer initState");
    _initialize();
  }

  Future<void> _initialize() async {
    print("🔄 Starting initialization");
    final stateNotifier = Provider.of<AppStateNotifier>(context, listen: false);
    
    // Simulate initialization
    await Future.delayed(Duration(seconds: 2));
    
    stateNotifier.setState(AppState.initialized);
    
    // Navigate to home
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print("🏗️ Building AppInitializer");
    
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.storefront,
              size: 80,
              color: Colors.blue,
            ),
            SizedBox(height: 20),
            Text(
              AppConfig.appName,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Initializing...'),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConfig.appName),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 80,
              color: Colors.green,
            ),
            SizedBox(height: 20),
            Text(
              'App is working!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Now add features back one by one',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 30),
            Consumer<AppStateNotifier>(
              builder: (context, state, _) {
                return Container(
                  padding: EdgeInsets.all(16),
                  margin: EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Text(
                    'Current State: ${state.state}',
                    style: TextStyle(color: Colors.blue[700]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}