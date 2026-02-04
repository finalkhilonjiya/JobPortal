import 'package:flutter/material.dart';

import '../presentation/home_marketplace_feed/home_jobs_feed.dart';
import '../presentation/company/dashboard/company_dashboard.dart';
import '../presentation/login_screen/mobile_auth_service.dart';
import '../core/auth/user_role.dart';
import '../routes/app_routes.dart';

class HomeRouter extends StatelessWidget {
  const HomeRouter({Key? key}) : super(key: key);

  Future<UserRole?> _resolveUserRole() async {
    final auth = MobileAuthService();

    // Ensure session is valid
    final isValid = await auth.ensureValidSession();
    if (!isValid) {
      return null;
    }

    return await auth.getUserRole();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserRole?>(
      future: _resolveUserRole(),
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Auth/session failed → back to login
        if (!snapshot.hasData) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AppRoutes.pushAndClearStack(context, AppRoutes.loginScreen);
          });

          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Role-based routing
        switch (snapshot.data!) {
          case UserRole.employer:
            return const CompanyDashboard();

          case UserRole.jobSeeker:
          default:
            return const HomeJobsFeed();
        }
      },
    );
  }
}