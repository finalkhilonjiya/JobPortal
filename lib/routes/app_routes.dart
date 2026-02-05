import 'package:flutter/material.dart';

import '../presentation/role_selection/role_selection_screen.dart';
import '../presentation/login_screen/job_seeker_login_screen.dart';
import '../presentation/login_screen/employer_login_screen.dart';

import '../routes/home_router.dart';

import '../presentation/home_marketplace_feed/home_jobs_feed.dart';
import '../presentation/company/dashboard/company_dashboard.dart';

import '../presentation/company/jobs/create_job_screen.dart';
import '../presentation/company/applicants/job_applicants_screen.dart';

// TODO: you will send this file next, we will create it after that
// import '../presentation/company/jobs/edit_job_screen.dart';

import '../presentation/registration_screen/registration_screen.dart';
import '../presentation/search_and_filters/search_and_filters.dart';
import '../presentation/listing_detail/listing_detail.dart';
import '../presentation/user_profile/user_profile.dart';
import '../presentation/chat_messaging/chat_messaging.dart';
import '../presentation/favorites_and_saved_items/favorites_and_saved_items.dart';
import '../presentation/configuration_setup/configuration_setup.dart';

class AppRoutes {
  /// ------------------------------------------------------------
  /// CORE
  /// ------------------------------------------------------------
  static const String initial = '/';

  /// ------------------------------------------------------------
  /// ROLE SELECTION
  /// ------------------------------------------------------------
  static const String roleSelection = '/role-selection';

  /// ------------------------------------------------------------
  /// LOGIN (SEPARATE FLOWS)
  /// ------------------------------------------------------------
  static const String jobSeekerLogin = '/job-seeker-login';
  static const String employerLogin = '/employer-login';

  /// ------------------------------------------------------------
  /// POST LOGIN ROUTER (ROLE BASED)
  /// ------------------------------------------------------------
  static const String homeJobsFeed = '/home';

  /// ------------------------------------------------------------
  /// EMPLOYER
  /// ------------------------------------------------------------
  static const String companyDashboard = '/company-dashboard';
  static const String createJob = '/create-job';
  static const String jobApplicants = '/job-applicants';

  /// NEW (required by CompanyDashboard)
  static const String editJob = '/edit-job';

  /// ------------------------------------------------------------
  /// JOB SEEKER (DIRECT ACCESS IF EVER NEEDED)
  /// ------------------------------------------------------------
  static const String jobSeekerHome = '/job-seeker-home';

  /// ------------------------------------------------------------
  /// OTHER EXISTING ROUTES
  /// ------------------------------------------------------------
  static const String registrationScreen = '/registration-screen';
  static const String searchAndFilters = '/search-and-filters';
  static const String listingDetail = '/listing-detail';
  static const String userProfile = '/user-profile';
  static const String chatMessaging = '/chat-messaging';
  static const String favoritesAndSavedItems = '/favorites-and-saved-items';
  static const String configurationSetup = '/configuration-setup';

  /// ------------------------------------------------------------
  /// ROUTES MAP (ONLY FOR SIMPLE ROUTES)
  /// ------------------------------------------------------------
  static final Map<String, WidgetBuilder> routes = {
    /// SAFETY ONLY
    initial: (_) => const RoleSelectionScreen(),

    /// ROLE SELECTION
    roleSelection: (_) => const RoleSelectionScreen(),

    /// LOGIN
    jobSeekerLogin: (_) => const JobSeekerLoginScreen(),
    employerLogin: (_) => const EmployerLoginScreen(),

    /// ROLE-BASED HOME ROUTER
    homeJobsFeed: (_) => const HomeRouter(),

    /// DIRECT HOMES (OPTIONAL)
    jobSeekerHome: (_) => const HomeJobsFeed(),
    companyDashboard: (_) => const CompanyDashboard(),

    /// EMPLOYER
    createJob: (_) => const CreateJobScreen(),

    /// EXISTING
    registrationScreen: (_) => const RegistrationScreen(),
    searchAndFilters: (_) => const SearchAndFilters(),
    listingDetail: (_) => const ListingDetail(),
    userProfile: (_) => const UserProfile(),
    chatMessaging: (_) => const ChatMessaging(),
    favoritesAndSavedItems: (_) => const FavoritesAndSavedItems(),
    configurationSetup: (_) => const ConfigurationSetup(),
  };

  /// ------------------------------------------------------------
  /// onGenerateRoute (FOR ARGUMENT ROUTES)
  /// ------------------------------------------------------------
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
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

      case editJob:
        final jobId = settings.arguments;

        if (jobId == null || jobId is! String || jobId.trim().isEmpty) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text("Job ID missing for edit job screen"),
              ),
            ),
          );
        }

        /// IMPORTANT:
        /// We will create EditJobScreen next.
        /// For now show placeholder so app doesn't crash.
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text("Edit Job")),
            body: Center(
              child: Text("Edit Job screen coming next\nJob ID: $jobId"),
            ),
          ),
        );
    }

    return null;
  }

  /// ------------------------------------------------------------
  /// HELPERS
  /// ------------------------------------------------------------
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