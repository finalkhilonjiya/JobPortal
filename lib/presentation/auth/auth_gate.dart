import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/app_routes.dart';
import '../../services/mobile_auth_service.dart';
import '../../core/auth/user_role.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final MobileAuthService _authService = MobileAuthService();

  @override
  void initState() {
    super.initState();
    _decideRoute();
  }

  Future<void> _decideRoute() async {
    try {
      // Ensure session is restored / valid
      await _authService.initialize();

      final session = Supabase.instance.client.auth.currentSession;
      final user = Supabase.instance.client.auth.currentUser;

      if (session == null || user == null) {
        _goToLogin();
        return;
      }

      final role = await _authService.getUserRole();

      switch (role) {
        case UserRole.employer:
          // TEMPORARY: employer dashboard not built yet
          _goToHome();
          break;

        case UserRole.jobSeeker:
        default:
          _goToHome();
      }
    } catch (e) {
      _goToLogin();
    }
  }

  void _goToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.loginScreen,
        (_) => false,
      );
    });
  }

  void _goToHome() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.homeJobsFeed,
        (_) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Simple loading screen while deciding
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}