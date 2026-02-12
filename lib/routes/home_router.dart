// File: lib/routes/home_router.dart

import 'package:flutter/material.dart';

import '../core/auth/user_role.dart';
import '../services/mobile_auth_service.dart';

import '../presentation/home_marketplace_feed/home_jobs_feed.dart';
import '../presentation/company/dashboard/company_dashboard.dart';

class HomeRouter extends StatefulWidget {
  const HomeRouter({Key? key}) : super(key: key);

  @override
  State<HomeRouter> createState() => _HomeRouterState();
}

class _HomeRouterState extends State<HomeRouter> {
  late final MobileAuthService _auth;

  @override
  void initState() {
    super.initState();
    _auth = MobileAuthService();
  }

  Future<UserRole> _resolveRole() async {
    try {
      // Ensure session exists
      await _auth.refreshSession();

      // Always fetch role from DB (final truth)
      return await _auth.syncRoleFromDbStrict();
    } catch (_) {
      return UserRole.jobSeeker;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserRole>(
      future: _resolveRole(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final role = snap.data ?? UserRole.jobSeeker;

        if (role == UserRole.employer) {
          return const CompanyDashboard();
        }

        return const HomeJobsFeed();
      },
    );
  }
}