import 'package:flutter/material.dart';

import '../presentation/role_selection/role_selection_screen.dart';
import '../presentation/auth/job_seeker_login_screen.dart';
import '../presentation/auth/employer_login_screen.dart';

import '../routes/home_router.dart';

import '../presentation/home_marketplace_feed/home_jobs_feed.dart';
import '../presentation/home_marketplace_feed/saved_jobs_page.dart';
import '../presentation/home_marketplace_feed/recommended_jobs_page.dart';

import '../presentation/company/dashboard/company_dashboard.dart';
import '../presentation/company/jobs/create_job_screen.dart';
import '../presentation/company/jobs/employer_job_list_screen.dart';
import '../presentation/company/jobs/job_applicants_screen.dart';

class AppRoutes {
  // ------------------------------------------------------------
  // CORE
  // ------------------------------------------------------------
  static const String initial = '/';
  static const String roleSelection = '/role-selection';

  // ------------------------------------------------------------
  // AUTH
  // ------------------------------------------------------------
  static const String jobSeekerLogin = '/job-seeker-login';
  static const String employerLogin = '/employer-login';

  // ------------------------------------------------------------
  // POST LOGIN (ROLE BASED)
  // ------------------------------------------------------------
  static const String home = '/home';

  // ------------------------------------------------------------
  // JOB SEEKER PAGES
  // ------------------------------------------------------------
  static const String homeJobsFeed = '/job-seeker/home-feed';
  static const String recommendedJobs = '/job-seeker/recommended-jobs';
  static const String savedJobs = '/job-seeker/saved-jobs';

  // ------------------------------------------------------------
  // EMPLOYER PAGES
  // ------------------------------------------------------------
  static const String companyDashboard = '/employer/dashboard';
  static const String employerJobs = '/employer/jobs';
  static const String createJob = '/employer/jobs/create';
  static const String jobApplicants = '/employer/jobs/applicants';

  // ------------------------------------------------------------
  // STATIC ROUTES
  // ------------------------------------------------------------
  static final Map<String, WidgetBuilder> routes = {
    // Safety
    initial: (_) => const RoleSelectionScreen(),

    // Role selection
    roleSelection: (_) => const RoleSelectionScreen(),

    // Auth
    jobSeekerLogin: (_) => const JobSeekerLoginScreen(),
    employerLogin: (_) => const EmployerLoginScreen(),

    // Role based router (single entry after login)
    home: (_) => const HomeRouter(),

    // Job seeker direct routes
    homeJobsFeed: (_) => const HomeJobsFeed(),
    recommendedJobs: (_) => const RecommendedJobsPage(),
    savedJobs: (_) => const SavedJobsPage(),

    // Employer direct routes
    companyDashboard: (_) => const CompanyDashboard(),
    employerJobs: (_) => const EmployerJobListScreen(),
    createJob: (_) => const CreateJobScreen(),
  };

  // ------------------------------------------------------------
  // DYNAMIC ROUTES
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