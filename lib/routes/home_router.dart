import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/auth/user_role.dart';
import '../routes/app_routes.dart';
import '../services/mobile_auth_service.dart';

import '../presentation/home_marketplace_feed/job_seeker_main_shell.dart';
import '../presentation/company/dashboard/company_dashboard.dart';
import '../presentation/company/dashboard/create_organization_screen.dart';

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

  // ------------------------------------------------------------
  // RESOLVE ROLE
  // ------------------------------------------------------------
  Future<UserRole?> _resolveRoleOrNull() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    return await _auth.syncRoleFromDbStrict(
      fallback: UserRole.jobSeeker,
    );
  }

  // ------------------------------------------------------------
  // CHECK COMPANY MEMBERSHIP
  // ------------------------------------------------------------
  Future<bool> _hasCompany() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final res = await Supabase.instance.client
        .from('company_members')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();

    return res != null;
  }

  // ------------------------------------------------------------
  // REDIRECT
  // ------------------------------------------------------------
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

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserRole?>(
      future: _resolveRoleOrNull(),
      builder: (context, roleSnap) {
        if (roleSnap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final role = roleSnap.data;

        // ❌ No session
        if (role == null) {
          _goToRoleSelection();
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // --------------------------------------------------------
        // EMPLOYER FLOW (STRICT)
        // --------------------------------------------------------
        if (role == UserRole.employer) {
          return FutureBuilder<bool>(
            future: _hasCompany(),
            builder: (context, companySnap) {
              if (companySnap.connectionState != ConnectionState.done) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final hasCompany = companySnap.data ?? false;

              // ❌ NO COMPANY → CREATE
              if (!hasCompany) {
                return const CreateOrganizationScreen();
              }

              // ✅ HAS COMPANY → DASHBOARD
              return const CompanyDashboard();
            },
          );
        }

        // --------------------------------------------------------
        // JOB SEEKER FLOW
        // --------------------------------------------------------
        return const JobSeekerMainShell();
      },
    );
  }
}