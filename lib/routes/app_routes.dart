import 'package:flutter/material.dart';

import '../presentation/role_selection/role_selection_screen.dart';
import '../presentation/login_screen/job_seeker_login_screen.dart';
import '../presentation/login_screen/employer_login_screen.dart';

import '../routes/home_router.dart';

import '../presentation/registration_screen/registration_screen.dart';
import '../presentation/search_and_filters/search_and_filters.dart';
import '../presentation/listing_detail/listing_detail.dart';
import '../presentation/user_profile/user_profile.dart';
import '../presentation/chat_messaging/chat_messaging.dart';
import '../presentation/favorites_and_saved_items/favorites_and_saved_items.dart';
import '../presentation/configuration_setup/configuration_setup.dart';

import '../presentation/company/dashboard/company_dashboard.dart';

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
  /// MAIN ENTRY AFTER LOGIN
  /// ------------------------------------------------------------
  static const String homeJobsFeed = '/home-jobs-feed';

  /// ------------------------------------------------------------
  /// EMPLOYER ROUTES
  /// ------------------------------------------------------------
  static const String companyDashboard = '/company-dashboard';

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
    /// Your main.dart uses AppRoutes.initial as initialRoute.
    /// So this MUST be RoleSelectionScreen.
    initial: (_) => const RoleSelectionScreen(),

    /// ROLE SELECTION
    roleSelection: (_) => const RoleSelectionScreen(),

    /// LOGIN
    jobSeekerLogin: (_) => const JobSeekerLoginScreen(),
    employerLogin: (_) => const EmployerLoginScreen(),

    /// HOME (Job Seeker + Employer role routing)
    homeJobsFeed: (_) => const HomeRouter(),

    /// EMPLOYER DASHBOARD (direct access)
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