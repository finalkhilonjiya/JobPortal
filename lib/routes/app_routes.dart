import 'package:flutter/material.dart';

import '../presentation/role_selection/role_selection_screen.dart';
import '../presentation/auth/job_seeker_login_screen.dart';
import '../presentation/auth/employer_login_screen.dart';

import 'home_router.dart';

import '../presentation/home_marketplace_feed/home_jobs_feed.dart';
import '../presentation/home_marketplace_feed/saved_jobs_page.dart';
import '../presentation/home_marketplace_feed/recommended_jobs_page.dart';
import '../presentation/home_marketplace_feed/profile_performance_page.dart';

import '../presentation/company/dashboard/company_dashboard.dart';
import '../presentation/company/jobs/create_job_screen.dart';
import '../presentation/company/jobs/employer_job_list_screen.dart';
import '../presentation/company/jobs/job_applicants_screen.dart';

class AppRoutes {
  // ------------------------------------------------------------
  // CORE
  // ------------------------------------------------------------
  static const String initial = '/';

  // ------------------------------------------------------------
  // ROLE SELECTION
  // ------------------------------------------------------------
  static const String roleSelection = '/role-selection';

  // ------------------------------------------------------------
  // AUTH
  // ------------------------------------------------------------
  static const String jobSeekerLogin = '/job-seeker-login';
  static const String employerLogin = '/employer-login';

  // ------------------------------------------------------------
  // POST LOGIN (ROLE BASED)
  // ------------------------------------------------------------
  /// IMPORTANT:
  /// Many files already use AppRoutes.home.
  /// So we keep this as the official home route.
  static const String home = '/home';

  /// Backward compatible alias (optional)
  static const String homeJobsFeed = home;

  // ------------------------------------------------------------
  // JOB SEEKER (DIRECT ROUTES)
  // ------------------------------------------------------------
  static const String jobSeekerHome = '/job-seeker-home';
  static const String savedJobs = '/saved-jobs';
  static const String recommendedJobs = '/recommended-jobs';
  static const String profilePerformance = '/profile-performance';

  // ------------------------------------------------------------
  // EMPLOYER
  // ------------------------------------------------------------
  static const String companyDashboard = '/company-dashboard';
  static const String employerJobs = '/employer-jobs';
  static const String createJob = '/create-job';

  // Requires argument: jobId (String)
  static const String jobApplicants = '/job-applicants';

  // ------------------------------------------------------------
  // ROUTES MAP (NO-ARGUMENT ROUTES ONLY)
  // ------------------------------------------------------------
  static final Map<String, WidgetBuilder> routes = {
    // Safety
    initial: (_) => const RoleSelectionScreen(),

    // Role selection
    roleSelection: (_) => const RoleSelectionScreen(),

    // Login
    jobSeekerLogin: (_) => const JobSeekerLoginScreen(),
    employerLogin: (_) => const EmployerLoginScreen(),

    // Role-based router (final truth)
    home: (_) => const HomeRouter(),

    // Job seeker
    jobSeekerHome: (_) => const HomeJobsFeed(),
    savedJobs: (_) => const SavedJobsPage(),
    recommendedJobs: (_) => const RecommendedJobsPage(),
    profilePerformance: (_) => const ProfilePerformancePage(),

    // Employer
    companyDashboard: (_) => const CompanyDashboard(),
    employerJobs: (_) => const EmployerJobListScreen(),
    createJob: (_) => const CreateJobScreen(),
  };

  // ------------------------------------------------------------
  // onGenerateRoute (ARGUMENT ROUTES)
  // ------------------------------------------------------------
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case jobApplicants:
        final jobId = settings.arguments;

        if (jobId == null || jobId is! String || jobId.trim().isEmpty) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text("Job ID missing for applicants screen"),
              ),
            ),
          );
        }

        return MaterialPageRoute(
          builder: (_) => JobApplicantsScreen(jobId: jobId),
        );
    }

    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(
          child: Text("Route not found: ${settings.name}"),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------
  static Future<void> pushAndClearStack(
    BuildContext context,
    String routeName,
  ) async {
    await Navigator.of(context).pushNamedAndRemoveUntil(
      routeName,
      (_) => false,
    );
  }

  static Future<void> pushNamed(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    await Navigator.of(context).pushNamed(
      routeName,
      arguments: arguments,
    );
  }

  static Future<void> pushReplacementNamed(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    await Navigator.of(context).pushReplacementNamed(
      routeName,
      arguments: arguments,
    );
  }

  static void pop(BuildContext context, [dynamic result]) {
    Navigator.of(context).pop(result);
  }

  static bool canPop(BuildContext context) {
    return Navigator.of(context).canPop();
  }

  static T? getArguments<T>(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is T ? args : null;
  }

  static String? getCurrentRouteName(BuildContext context) {
    return ModalRoute.of(context)?.settings.name;
  }
}