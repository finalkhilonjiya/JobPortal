import 'package:flutter/material.dart';

// Auth
import '../presentation/login_screen/mobile_login_screen.dart';
import '../presentation/registration_screen/registration_screen.dart';

// Core app
import '../routes/home_router.dart';

// Jobs
import '../presentation/home_marketplace_feed/home_jobs_feed.dart';
import '../presentation/listing_detail/listing_detail.dart';
import '../presentation/search_and_filters/search_and_filters.dart';

// User
import '../presentation/user_profile/user_profile.dart';
import '../presentation/favorites_and_saved_items/favorites_and_saved_items.dart';

// Communication
import '../presentation/chat_messaging/chat_messaging.dart';

// Setup / config
import '../presentation/configuration_setup/configuration_setup.dart';

class AppRoutes {
  // =====================
  // CORE
  // =====================
  static const String initial = '/';

  // =====================
  // AUTH
  // =====================
  static const String login = '/login';
  static const String register = '/register';

  // =====================
  // HOME / JOBS
  // =====================
  static const String home = '/home';
  static const String jobsFeed = '/jobs-feed';
  static const String jobDetail = '/job-detail';
  static const String search = '/search';

  // =====================
  // USER
  // =====================
  static const String profile = '/profile';
  static const String savedJobs = '/saved-jobs';

  // =====================
  // COMMUNICATION
  // =====================
  static const String chat = '/chat';

  // =====================
  // SETUP
  // =====================
  static const String configurationSetup = '/configuration-setup';

  // =====================
  // ROUTE MAP
  // =====================
  static final Map<String, WidgetBuilder> routes = {
    // Core
    initial: (_) => const MobileLoginScreen(),

    // Auth
    login: (_) => const MobileLoginScreen(),
    register: (_) => const RegistrationScreen(),

    // Home / jobs
    home: (_) => const HomeRouter(),
    jobsFeed: (_) => const HomeJobsFeed(),
    jobDetail: (_) => const ListingDetail(),
    search: (_) => const SearchAndFilters(),

    // User
    profile: (_) => const UserProfile(),
    savedJobs: (_) => const FavoritesAndSavedItems(),

    // Communication
    chat: (_) => const ChatMessaging(),

    // Setup
    configurationSetup: (_) => const ConfigurationSetup(),
  };

  // =====================
  // NAV HELPERS
  // =====================
  static Future<void> pushAndClear(BuildContext context, String route) async {
    await Navigator.of(context).pushNamedAndRemoveUntil(
      route,
      (_) => false,
    );
  }

  static Future<void> push(
    BuildContext context,
    String route, {
    Object? arguments,
  }) async {
    await Navigator.of(context).pushNamed(route, arguments: arguments);
  }

  static Future<void> replace(
    BuildContext context,
    String route, {
    Object? arguments,
  }) async {
    await Navigator.of(context)
        .pushReplacementNamed(route, arguments: arguments);
  }

  static void pop(BuildContext context, [Object? result]) {
    Navigator.of(context).pop(result);
  }

  // =====================
  // COMMON FLOWS
  // =====================
  static Future<void> goToLogin(BuildContext context) async {
    await pushAndClear(context, login);
  }

  static Future<void> goToHome(BuildContext context) async {
    await pushAndClear(context, home);
  }

  // =====================
  // UNKNOWN ROUTE
  // =====================
  static Route<dynamic> unknown(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: const Text('Page not found'),
        ),
        body: Center(
          child: Text(
            'No route defined for ${settings