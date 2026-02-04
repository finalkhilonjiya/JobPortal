import 'package:flutter/material.dart';

// ROLE SELECTION
import '../presentation/role_selection/role_selection_screen.dart';

// LOGIN SCREENS
import '../presentation/login_screen/job_seeker_login_screen.dart';
import '../presentation/login_screen/employer_login_screen.dart';

// JOB SEEKER
import '../presentation/home_marketplace_feed/home_jobs_feed.dart';

// EMPLOYER
import '../presentation/company/dashboard/company_dashboard.dart';

class AppRoutes {
  /* ------------------------------------------------------------
   ROUTE NAMES
  ------------------------------------------------------------- */

  // ENTRY
  static const String initial = '/';

  // ROLE
  static const String roleSelection = '/role-selection';

  // LOGIN
  static const String jobSeekerLogin = '/job-seeker-login';
  static const String employerLogin = '/employer-login';

  // DASHBOARDS
  static const String homeJobsFeed = '/home-jobs-feed';
  static const String companyDashboard = '/company-dashboard';

  /* ------------------------------------------------------------
   ROUTE MAP
  ------------------------------------------------------------- */

  static final Map<String, WidgetBuilder> routes = {
    // ENTRY POINT
    initial: (_) => const RoleSelectionScreen(),

    // ROLE
    roleSelection: (_) => const RoleSelectionScreen(),

    // LOGIN
    jobSeekerLogin: (_) => const JobSeekerLoginScreen(),
    employerLogin: (_) => const EmployerLoginScreen(),

    // DASHBOARDS
    homeJobsFeed: (_) => const HomeJobsFeed(),
    companyDashboard: (_) => const CompanyDashboard(),
  };

  /* ------------------------------------------------------------
   HELPERS
  ------------------------------------------------------------- */

  static Future<void> go(
    BuildContext context,
    String route, {
    bool replace = false,
  }) async {
    if (replace) {
      await Navigator.pushReplacementNamed(context, route);
    } else {
      await Navigator.pushNamed(context, route);
    }
  }

  static void back(BuildContext context) {
    Navigator.pop(context);
  }
}