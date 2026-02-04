import 'package:flutter/material.dart';

// AUTH
import '../presentation/auth/choose_account_type_screen.dart';
import '../presentation/login_screen/mobile_login_screen.dart';
import '../presentation/registration_screen/registration_screen.dart';

// HOME / ROUTING
import '../routes/home_router.dart';

// JOB SEEKER
import '../presentation/home_marketplace_feed/home_jobs_feed.dart';
import '../presentation/search_and_filters/search_and_filters.dart';
import '../presentation/listing_detail/listing_detail.dart';
import '../presentation/favorites_and_saved_items/favorites_and_saved_items.dart';

// EMPLOYER
import '../presentation/company/dashboard/company_dashboard.dart';

// PROFILE / CHAT / CONFIG
import '../presentation/user_profile/user_profile.dart';
import '../presentation/chat_messaging/chat_messaging.dart';
import '../presentation/configuration_setup/configuration_setup.dart';

class AppRoutes {
  /// =========================
  /// CORE
  /// =========================
  static const String initial = '/';

  /// =========================
  /// AUTH
  /// =========================
  static const String chooseAccountType = '/choose-account-type';
  static const String loginScreen = '/login';
  static const String registrationScreen = '/register';

  /// =========================
  /// HOME
  /// =========================
  static const String home = '/home';

  /// =========================
  /// JOB SEEKER
  /// =========================
  static const String homeJobsFeed = '/home-jobs-feed';
  static const String searchAndFilters = '/search';
  static const String listingDetail = '/listing-detail';
  static const String favoritesAndSavedItems = '/favorites';

  /// =========================
  /// EMPLOYER
  /// =========================
  static const String companyDashboard = '/company-dashboard';

  /// =========================
  /// PROFILE / CHAT / SETTINGS
  /// =========================
  static const String userProfile = '/user-profile';
  static const String chatMessaging = '/chat';
  static const String configurationSetup = '/configuration-setup';

  /// =========================
  /// ROUTE MAP
  /// =========================
  static final Map<String, WidgetBuilder> routes = {
    /// ENTRY POINT
    initial: (context) => const ChooseAccountTypeScreen(),

    /// AUTH
    chooseAccountType: (context) => const ChooseAccountTypeScreen(),
    loginScreen: (context) => const MobileLoginScreen(),
    registrationScreen: (context) => const RegistrationScreen(),

    /// ROLE BASED HOME
    home: (context) => const HomeRouter(),

    /// JOB SEEKER
    homeJobsFeed: (context) => const HomeJobsFeed(),
    searchAndFilters: (context) => const SearchAndFilters(),
    listingDetail: (context) => const ListingDetail(),
    favoritesAndSavedItems: (context) => const FavoritesAndSavedItems(),

    /// EMPLOYER
    companyDashboard: (context) => const CompanyDashboard(),

    /// PROFILE / CHAT / SETTINGS
    userProfile: (context) => const UserProfile(),
    chatMessaging: (context) => const ChatMessaging(),
    configurationSetup: (context) => const ConfigurationSetup(),
  };

  /// =========================
  /// HELPERS
  /// =========================

  static Future<void> pushAndClearStack(
    BuildContext context,
    String routeName,
  ) async {
    await Navigator.of(context).pushNamedAndRemoveUntil(
      routeName,
      (_) => false,
    );
  }

  static Future<void> navigateToHome(BuildContext context) async {
    await pushAndClearStack(context, home);
  }

  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Page Not Found')),
        body: Center(
          child: Text(
            'No route defined for ${settings.name}',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}