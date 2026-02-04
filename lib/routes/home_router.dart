import 'package:flutter/material.dart';
import '../presentation/home_marketplace_feed/home_jobs_feed.dart';
import '../presentation/company/dashboard/company_dashboard.dart';
import '../presentation/login_screen/mobile_auth_service.dart';
import '../core/auth/user_role.dart';

class HomeRouter extends StatelessWidget {
  const HomeRouter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserRole>(
      future: MobileAuthService().getUserRole(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final role = snap.data!;

        return role == UserRole.employer
            ? const CompanyDashboard()
            : const HomeJobsFeed();
      },
    );
  }
}