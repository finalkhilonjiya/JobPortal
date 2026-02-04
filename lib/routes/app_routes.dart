import 'package:flutter/material.dart';

import '../presentation/role_selection/role_selection_screen.dart';
import '../presentation/login_screen/job_seeker_login_screen.dart';
import '../presentation/login_screen/employer_login_screen.dart';

import '../routes/home_router.dart';

import '../presentation/home_marketplace_feed/home_jobs_feed.dart';
import '../presentation/company/dashboard/company_dashboard.dart';

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
  /// LOGIN (SEPARATE)
  /// ------------------------------------------------------------
  static const String jobSeekerLogin = '/job-seeker-login';
  static const String employerLogin = '/employer-login';

  /// ------------------------------------------------------------
  /// POST LOGIN ROUTER
  /// ------------------------------------------------------------
  static const String homeJobsFeed = '/home-jobs-feed';

  /// ------------------------------------------------------------
  /// EMPLOYER
  /// ------------------------------------------------------------
  static const String companyDashboard = '/company-dashboard';

  /// ------------------------------------------------------------
  /// JOB SEEKER HOME (DIRECT)
  /// (You already have this screen. We keep it clean.)
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
  /// ROUTES MAP
  /// ------------------------------------------------------------
  static Map<String, WidgetBuilder> routes = {
    /// IMPORTANT:
    /// main.dart uses home: AppInitializer()
    /// so "/" is NOT used as startup.
    /// But we keep it correct.
    initial: (_) => const RoleSelectionScreen(),

    /// ROLE SELECTION
    roleSelection: (_) => const RoleSelectionScreen(),

    /// LOGIN
    jobSeekerLogin: (_) => const JobSeekerLoginScreen(),
    employerLogin: (_) => const EmployerLoginScreen(),

    /// ROUTER AFTER LOGIN (checks user_profiles.role)
    homeJobsFeed: (_) => const HomeRouter(),

    /// DIRECT HOME (job seeker feed)
    jobSeekerHome: (_) => const HomeJobsFeed(),

    /// EMPLOYER DASHBOARD
    companyDashboard: (_) => const CompanyDashboard(),

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
  /// HELPERS
  /// ------------------------------------------------------------
  static Future<void> pushAndClearStack(
    BuildContext context,
    String routeName,
  ) async {
    await Navigator.of(context).pushNamedAndRemoveUntil(
      routeName,
      (Route<dynamic> route) => false,
    );
  }

  static Future<void> pushNamed(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    await Navigator.of(context).pushNamed(routeName, arguments: arguments);
  }

  static Future<void> pushReplacementNamed(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    await Navigator.of(context)
        .pushReplacementNamed(routeName, arguments: arguments);
  }

  static void pop(BuildContext context, [dynamic result]) {
    Navigator.of(context).pop(result);
  }

  static bool canPop(BuildContext context) {
    return Navigator.of(context).canPop();
  }

  static T? getArguments<T>(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is T) return args;
    return null;
  }

  static String? getCurrentRouteName(BuildContext context) {
    return ModalRoute.of(context)?.settings.name;
  }
}