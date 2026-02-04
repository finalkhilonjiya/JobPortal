import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../presentation/home_marketplace_feed/home_jobs_feed.dart';
import '../presentation/company/dashboard/company_dashboard.dart';
import '../presentation/role_selection/role_selection_screen.dart';
import '../core/auth/user_role.dart';

class HomeRouter extends StatelessWidget {
  const HomeRouter({Key? key}) : super(key: key);

  Future<UserRole?> _resolveUserRole() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    final res = await Supabase.instance.client
        .from('user_profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    if (res == null || res['role'] == null) {
      return null; // FIRST TIME USER
    }

    return parseUserRole(res['role']);
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

        // No role selected yet → FORCE ROLE SELECTION
        if (!snapshot.hasData || snapshot.data == null) {
          return const RoleSelectionScreen();
        }

        // Employer
        if (snapshot.data == UserRole.employer) {
          return const CompanyDashboard();
        }

        // Job seeker (default)
        return const HomeJobsFeed();
      },
    );
  }
}