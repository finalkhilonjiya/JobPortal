import 'package:flutter/material.dart';

import '../presentation/role_selection/role_selection_screen.dart';
import '../presentation/login/job_seeker_login_screen.dart';
import '../presentation/login/employer_login_screen.dart';
import '../presentation/home_marketplace_feed/home_jobs_feed.dart';
import '../presentation/company/dashboard/company_dashboard.dart';

class AppRoutes {
  static const roleSelection = '/';
  static const jobSeekerLogin = '/job-seeker-login';
  static const employerLogin = '/employer-login';
  static const homeJobsFeed = '/home-jobs-feed';
  static const companyDashboard = '/company-dashboard';

  static final routes = <String, WidgetBuilder>{
    roleSelection: (_) => const RoleSelectionScreen(),
    jobSeekerLogin: (_) => const JobSeekerLoginScreen(),
    employerLogin: (_) => const EmployerLoginScreen(),
    homeJobsFeed: (_) => const HomeJobsFeed(),
    companyDashboard: (_) => const CompanyDashboard(),
  };
}