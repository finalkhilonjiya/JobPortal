// lib/routes/home_router.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/auth/user_role.dart';
import '../routes/app_routes.dart';
import '../services/mobile_auth_service.dart';

import '../presentation/home_marketplace_feed/job_seeker_main_shell.dart';
import '../presentation/home_marketplace_feed/construction_services_home_page.dart';
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
    // Navigate after first frame so context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) => _route());
  }

  Future<void> _route() async {
    if (!mounted) return;

    final user = _auth.currentUser;

    // No session — go to role selection
    if (user == null) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.roleSelection,
        (_) => false,
      );
      return;
    }

    UserRole? role;
    try {
      role = await _auth.getUserRole();
    } catch (_) {}

    if (!mounted) return;

    // No role — go to role selection
    if (role == null) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.roleSelection,
        (_) => false,
      );
      return;
    }

    if (role == UserRole.construction) {
      Navigator.pushReplacementNamed(
          context, AppRoutes.constructionHome);
      return;
    }

    if (role == UserRole.jobSeeker) {
      Navigator.pushReplacementNamed(
          context, AppRoutes.jobSeekerHome);
      return;
    }

    if (role == UserRole.employer) {
      // Always go to companyDashboard.
      // CompanyDashboard handles the "no org" state itself
      // and pushes createOrganization as a proper route,
      // so Navigator.pop works correctly.
      Navigator.pushReplacementNamed(
          context, AppRoutes.companyDashboard);
      return;
    }

    // Fallback
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.roleSelection,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Just show a spinner while routing
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: Color(0xFF16A34A),
        ),
      ),
    );
  }
}