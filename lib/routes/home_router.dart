import 'package:flutter/material.dart';

import '../core/auth/user_role.dart';
import '../presentation/company/dashboard/company_dashboard.dart';
import '../presentation/home_marketplace_feed/home_jobs_feed.dart';
import '../presentation/login_screen/mobile_auth_service.dart';

class HomeRouter extends StatelessWidget {
  const HomeRouter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserRole>(
      future: MobileAuthService().getUserRole(),
      builder: (context, snapshot) {
        /// Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        /// Error fallback (default = JobSeeker)
        if (snapshot.hasError) {
          return const HomeJobsFeed();
        }

        final role = snapshot.data ?? UserRole.jobSeeker;

        if (role == UserRole.employer) {
          return const CompanyDashboard();
        }

        return const HomeJobsFeed();
      },
    );
  }
}