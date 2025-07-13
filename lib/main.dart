import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Diagnostic flags - toggle these to test
class DiagnosticConfig {
  static const bool useSizer = false;          // Toggle Sizer
  static const bool useRoutes = false;         // Toggle route config
  static const bool useNavigatorKey = false;   // Toggle NavigatorKey
  static const bool useComplexInit = false;    // Toggle complex initialization
  static const bool useProviderInInit = false; // Toggle Provider access in initState
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  print("🚀 App starting with diagnostic config:");
  print("   - useSizer: ${DiagnosticConfig.useSizer}");
  print("   - useRoutes: ${DiagnosticConfig.useRoutes}");
  print("   - useNavigatorKey: ${DiagnosticConfig.useNavigatorKey}");
  print("   - useComplexInit: ${DiagnosticConfig.useComplexInit}");
  print("   - useProviderInInit: ${DiagnosticConfig.useProviderInInit}");
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  static final GlobalKey<NavigatorState> navigatorKey = 
      DiagnosticConfig.useNavigatorKey ? GlobalKey<NavigatorState>() : null;

  @override
  Widget build(BuildContext context) {
    print("🏗️ Building MyApp");
    
    Widget app = MaterialApp(
      title: 'Diagnostic App',
      theme: ThemeData(primarySwatch: Colors.blue),
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      
      // Route configuration test
      routes: DiagnosticConfig.useRoutes ? {
        '/': (context) => AppInitializer(),
        '/home': (context) => HomePage(),
      } : null,
      
      // Use either home or initialRoute, not both!
      home: !DiagnosticConfig.useRoutes ? AppInitializer() : null,
      initialRoute: DiagnosticConfig.useRoutes ? '/' : null,
      
      // Error handling
      builder: (context, child) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return Material(
            child: Container(
              color: Colors.red[100],
              padding: EdgeInsets.all(20),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 60, color: Colors.red),
                    SizedBox(height: 20),
                    Text(
                      'Error Caught:',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      details.exception.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red[900]),
                    ),
                  ],
                ),
              ),
            ),
          );
        };
        return child!;
      },
    );
    
    // Wrap with Provider
    app = MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          print("📦 Creating AppStateNotifier");
          return AppStateNotifier();
        }),
      ],
      child: app,
    );
    
    // Optionally wrap with Sizer
    if (DiagnosticConfig.useSizer) {
      // return Sizer(
      //   builder: (context, orientation, screenType) {
      //     print("🏗️ Sizer builder called");
      //     return app;
      //   },
      // );
    }
    
    return app;
  }
}

class AppStateNotifier extends ChangeNotifier {
  String _state = 'initializing';
  String get state => _state;
  
  void updateState(String newState) {
    print('🔄 State update: $_state → $newState');
    _state = newState;
    notifyListeners();
  }
}

class AppInitializer extends StatefulWidget {
  @override
  _AppInitializerState createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  String _phase = 'Created';
  AppStateNotifier? _stateNotifier;
  
  @override
  void initState() {
    super.initState();
    print("🚀 initState called");
    _updatePhase('initState called');
    
    if (DiagnosticConfig.useProviderInInit) {
      // WRONG: This might fail
      try {
        _stateNotifier = Provider.of<AppStateNotifier>(context, listen: false);
        print("✅ Got Provider in initState");
      } catch (e) {
        print("❌ Failed to get Provider in initState: $e");
      }
    }
    
    // Safe approach
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("✅ Post frame callback");
      _updatePhase('Post frame callback');
      
      if (!DiagnosticConfig.useProviderInInit && _stateNotifier == null) {
        _stateNotifier = Provider.of<AppStateNotifier>(context, listen: false);
        print("✅ Got Provider in post frame callback");
      }
      
      _initialize();
    });
  }
  
  void _updatePhase(String phase) {
    if (mounted) {
      setState(() => _phase = phase);
    }
  }
  
  Future<void> _initialize() async {
    _updatePhase('Starting initialization');
    
    if (DiagnosticConfig.useComplexInit) {
      // Simulate complex initialization
      for (int i = 1; i <= 3; i++) {
        await Future.delayed(Duration(seconds: 1));
        _updatePhase('Initialization step $i/3');
        _stateNotifier?.updateState('init-step-$i');
      }
    } else {
      // Simple initialization
      await Future.delayed(Duration(seconds: 2));
    }
    
    _updatePhase('Ready to navigate');
    _stateNotifier?.updateState('initialized');
    
    // Navigate
    if (mounted) {
      if (DiagnosticConfig.useRoutes) {
        print("🧭 Using pushReplacementNamed");
        Navigator.pushReplacementNamed(context, '/home');
      } else if (DiagnosticConfig.useNavigatorKey && MyApp.navigatorKey != null) {
        print("🧭 Using navigatorKey");
        MyApp.navigatorKey!.currentState?.pushReplacement(
          MaterialPageRoute(builder: (_) => HomePage()),
        );
      } else {
        print("🧭 Using direct navigation");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage()),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    print("🏗️ Building AppInitializer");
    
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.science, size: 60, color: Colors.blue),
              SizedBox(height: 20),
              Text(
                'Diagnostic Mode',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                _phase,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(),
              SizedBox(height: 40),
              
              // Show active diagnostic flags
              Container(
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Active Flags:', style: TextStyle(fontWeight: FontWeight.bold)),
                    if (DiagnosticConfig.useSizer) Text('✓ Sizer'),
                    if (DiagnosticConfig.useRoutes) Text('✓ Routes'),
                    if (DiagnosticConfig.useNavigatorKey) Text('✓ NavigatorKey'),
                    if (DiagnosticConfig.useComplexInit) Text('✓ Complex Init'),
                    if (DiagnosticConfig.useProviderInInit) Text('✓ Provider in Init'),
                    if (!DiagnosticConfig.useSizer && 
                        !DiagnosticConfig.useRoutes && 
                        !DiagnosticConfig.useNavigatorKey && 
                        !DiagnosticConfig.useComplexInit &&
                        !DiagnosticConfig.useProviderInInit)
                      Text('None - Basic mode'),
                  ],
                ),
              ),
              
              // Show Provider state if available
              Consumer<AppStateNotifier>(
                builder: (context, state, _) {
                  return Container(
                    margin: EdgeInsets.only(top: 16),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Provider State: ${state.state}'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Diagnostic Complete')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 80, color: Colors.green),
            SizedBox(height: 20),
            Text(
              'All systems working!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Text('Diagnostic Results:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('✅ Basic Flutter: Working'),
                  if (DiagnosticConfig.useSizer) Text('✅ Sizer: Working'),
                  if (DiagnosticConfig.useRoutes) Text('✅ Named Routes: Working'),
                  if (DiagnosticConfig.useNavigatorKey) Text('✅ Navigator Key: Working'),
                  if (DiagnosticConfig.useComplexInit) Text('✅ Complex Init: Working'),
                  if (DiagnosticConfig.useProviderInInit) Text('✅ Provider in Init: Working'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}