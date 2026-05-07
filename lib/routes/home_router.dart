// lib/routes/home_router.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/auth/user_role.dart';
import '../routes/app_routes.dart';
import '../services/mobile_auth_service.dart';

import '../presentation/home_marketplace_feed/job_seeker_main_shell.dart';
import '../presentation/home_marketplace_feed/construction_services_home_page.dart';

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
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _route());
  }

  Future<bool> _hasCompany() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final db = Supabase.instance.client;

    final member = await db
        .from('company_members')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();

    if (member != null) return true;

    final created = await db
        .from('companies')
        .select('id')
        .eq('created_by', user.id)
        .maybeSingle();

    return created != null;
  }

  Future<void> _route() async {
    if (!mounted) return;

    final user = _auth.currentUser;

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
      bool hasCompany = false;
      try {
        hasCompany = await _hasCompany();
      } catch (_) {}

      if (!mounted) return;

      if (!hasCompany) {
        // First time employer — go directly to create org.
        // On success, CreateOrganizationScreen will pop with
        // companyId. We catch that and go to dashboard.
        final companyId = await Navigator.pushNamed(
          context,
          AppRoutes.createOrganization,
        );

        if (!mounted) return;

        // Whether they created org or pressed back,
        // always land on companyDashboard.
        // Dashboard handles both cases (has org / no org).
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.companyDashboard,
          arguments: companyId != null
              ? {'companyId': companyId.toString()}
              : null,
        );
        return;
      }

      // Has company — go straight to dashboard
      Navigator.pushReplacementNamed(
          context, AppRoutes.companyDashboard);
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.roleSelection,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
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