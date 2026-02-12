import 'package:flutter/material.dart';

import '../core/auth/user_role.dart';
import '../routes/app_routes.dart';
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
  late final Future<UserRole?> _roleFuture;

  @override
  void initState() {
    super.initState();
    _auth = MobileAuthService();
    _roleFuture = _resolveRoleOrNull();
  }

  Future<UserRole?> _resolveRoleOrNull() async {
    // 1) Ensure session exists
    final ok = await _auth.refreshSession();
    if (!ok) return null;

    // 2) DB is final truth
    return await _auth.syncRoleFromDbStrict(fallback: UserRole.jobSeeker);
  }

  void _goToRoleSelection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.roleSelection,
        (_) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserRole?>(
      future: _roleFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final role = snap.data;

        // ❌ No session → go RoleSelection
        if (role == null) {
          _goToRoleSelection();
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ✅ Role based routing
        if (role == UserRole.employer) {
          return const CompanyDashboard();
        }

        return const HomeJobsFeed();
      },
    );
  }
}