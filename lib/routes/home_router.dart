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
  // ROLE
  // ------------------------------------------------------------
  Future<UserRole?> _resolveRoleOrNull() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    return await _auth.syncRoleFromDbStrict(
      fallback: UserRole.jobSeeker,
    );
  }

  // ------------------------------------------------------------
  // ✅ FIXED COMPANY CHECK (CRITICAL)
  // ------------------------------------------------------------
  Future<bool> _hasCompany() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final db = Supabase.instance.client;

    // 1️⃣ Check membership
    final member = await db
        .from('company_members')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();

    if (member != null) return true;

    // 2️⃣ Fallback → first-time creation case
    final created = await db
        .from('companies')
        .select('id')
        .eq('created_by', user.id)
        .maybeSingle();

    if (created != null) return true;

    return false;
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
  // UI
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

        // ❌ no session
        if (role == null) {
          _goToRoleSelection();
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // --------------------------------------------------------
        // EMPLOYER
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

              // ❌ NO COMPANY
              if (!hasCompany) {
                return const CreateOrganizationScreen();
              }

              // ✅ HAS COMPANY
              return const CompanyDashboard();
            },
          );
        }

        // --------------------------------------------------------
        // JOB SEEKER
        // --------------------------------------------------------
        return const JobSeekerMainShell();
      },
    );
  }
}