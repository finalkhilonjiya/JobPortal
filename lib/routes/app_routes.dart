import 'package:flutter/material.dart';

// Login / Entry
import '../presentation/login_screen/mobile_login_screen.dart';

// Job seeker side
import '../presentation/home_marketplace_feed/home_jobs_feed.dart';
import '../presentation/search_and_filters/search_and_filters.dart';
import '../presentation/listing_detail/listing_detail.dart';
import '../presentation/user_profile/user_profile.dart';
import '../presentation/chat_messaging/chat_messaging.dart';
import '../presentation/favorites_and_saved_items/favorites_and_saved_items.dart';

// Employer side
import '../presentation/company/dashboard/company_dashboard.dart';
import '../presentation/configuration_setup/configuration_setup.dart';

class AppRoutes {
  /* ---------------- CORE ---------------- */
  static const String initial = '/';

  /* ---------------- ENTRY ---------------- */
  static const String login = '/login';

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

  /* ---------------- ROUTE MAP ---------------- */
  static final Map<String, WidgetBuilder> routes = {
    /// Entry
    initial: (_) => const MobileLoginScreen(),
    login: (_) => const MobileLoginScreen(),

    /// Job seeker
    homeJobsFeed: (_) => const HomeJobsFeed(),
    searchAndFilters: (_) => const SearchAndFilters(),
    listingDetail: (_) => const ListingDetail(),
    userProfile: (_) => const UserProfile(),
    chatMessaging: (_) => const ChatMessaging(),
    favorites: (_) => const FavoritesAndSavedItems(),

    /// Employer
    companyDashboard: (_) => const CompanyDashboard(),
    configurationSetup: (_) => const ConfigurationSetup(),
  };

  /* ---------------- HELPERS ---------------- */

  static Future<void> push(
    BuildContext context,
    String route, {
    Object? args,
  }) async {
    await Navigator.pushNamed(context, route, arguments: args);
  }

  static Future<void> replace(
    BuildContext context,
    String route, {
    Object? args,
  }) async {
    await Navigator.pushReplacementNamed(context, route, arguments: args);
  }

  static Future<void> clearAndPush(
    BuildContext context,
    String route,
  ) async {
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