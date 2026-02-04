import 'package:flutter/material.dart';

// Entry
import '../presentation/login_screen/mobile_login_screen.dart';

// Job seeker
import '../presentation/home_marketplace_feed/home_jobs_feed.dart';
import '../presentation/search_and_filters/search_and_filters.dart';
import '../presentation/listing_detail/listing_detail.dart';
import '../presentation/user_profile/user_profile.dart';
import '../presentation/chat_messaging/chat_messaging.dart';
import '../presentation/favorites_and_saved_items/favorites_and_saved_items.dart';

// Employer
import '../presentation/company/dashboard/company_dashboard.dart';
import '../presentation/configuration_setup/configuration_setup.dart';

class AppRoutes {
  /* ---------------- CORE ---------------- */
  static const String initial = '/';

  /* ---------------- ENTRY ---------------- */
  static const String login = '/login';

  // 🔥 BACKWARD COMPATIBILITY (DO NOT REMOVE)
  static const String loginScreen = login;

  /* ---------------- JOB SEEKER ---------------- */
  static const String homeJobsFeed = '/home-jobs-feed';
  static const String searchAndFilters = '/search-and-filters';
  static const String listingDetail = '/listing-detail';
  static const String userProfile = '/user-profile';
  static const String chatMessaging = '/chat-messaging';
  static const String favorites = '/favorites';

  /* ---------------- EMPLOYER ---------------- */
  static const String companyDashboard = '/company-dashboard';
  static const String configurationSetup = '/configuration-setup';

  /* ---------------- ROUTES ---------------- */
  static final Map<String, WidgetBuilder> routes = {
    initial: (_) => const MobileLoginScreen(),
    login: (_) => const MobileLoginScreen(),

    // Job seeker
    homeJobsFeed: (_) => const HomeJobsFeed(),
    searchAndFilters: (_) => const SearchAndFilters(),
    listingDetail: (_) => const ListingDetail(),
    userProfile: (_) => const UserProfile(),
    chatMessaging: (_) => const ChatMessaging(),
    favorites: (_) => const FavoritesAndSavedItems(),

    // Employer
    companyDashboard: (_) => CompanyDashboard(), // ❗ NOT const
    configurationSetup: (_) => const ConfigurationSetup(),
  };

  /* ---------------- HELPERS ---------------- */

  static Future<void> push(BuildContext context, String route) async {
    await Navigator.pushNamed(context, route);
  }

  static Future<void> replace(BuildContext context, String route) async {
    await Navigator.pushReplacementNamed(context, route);
  }

  static Future<void> clearAndPush(BuildContext context, String route) async {
    await Navigator.pushNamedAndRemoveUntil(
      context,
      route,
      (_) => false,
    );
  }

  static void pop(BuildContext context) {
    Navigator.pop(context);
  }
}