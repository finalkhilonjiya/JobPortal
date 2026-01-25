import 'package:flutter/material.dart';

// Updated import for mobile OTP login
import '../presentation/login_screen/mobile_login_screen.dart';
import '../presentation/home_marketplace_feed/home_jobs_feed.dart'; // ← CHANGED
import '../presentation/search_and_filters/search_and_filters.dart';
import '../presentation/registration_screen/registration_screen.dart';
import '../presentation/listing_detail/listing_detail.dart';
import '../presentation/user_profile/user_profile.dart';
import '../presentation/chat_messaging/chat_messaging.dart';
import '../presentation/favorites_and_saved_items/favorites_and_saved_items.dart';
import '../presentation/configuration_setup/configuration_setup.dart';

class AppRoutes {
  // Core App Routes
  static const String initial = '/';

  // Authentication Routes
  static const String loginScreen = '/login-screen';
  static const String registrationScreen = '/registration-screen';
  static const String forgotPasswordScreen = '/forgot-password-screen';
  static const String emailVerificationScreen = '/email-verification-screen';
  static const String phoneVerificationScreen = '/phone-verification-screen';

  // Jobs Routes (RENAMED from Marketplace)
  static const String homeJobsFeed = '/home-jobs-feed'; // ← CHANGED
  static const String categoriesScreen = '/categories-screen';
  static const String searchAndFilters = '/search-and-filters';
  static const String listingDetail = '/listing-detail';
  static const String productDetailScreen = '/product-detail-screen';
  static const String sellerProfileScreen = '/seller-profile-screen';

  // Job Routes
  static const String jobListingsScreen = '/job-listings-screen';
  static const String jobDetailScreen = '/job-detail-screen';
  static const String jobApplicationScreen = '/job-application-screen';

  // Listing Management Routes
  static const String createListing = '/create-listing';
  static const String myListingsScreen = '/my-listings-screen';
  static const String editListingScreen = '/edit-listing-screen';

  // Profile Routes
  static const String userProfile = '/user-profile';
  static const String editProfileScreen = '/edit-profile-screen';
  static const String sellerDashboard = '/seller-dashboard';

  // Communication Routes
  static const String chatMessaging = '/chat-messaging';
  static const String chatListScreen = '/chat-list-screen';
  static const String videoCallScreen = '/video-call-screen';

  // User Preferences Routes
  static const String favoritesAndSavedItems = '/favorites-and-saved-items';
  static const String wishlistScreen = '/wishlist-screen';

  // Transaction Routes
  static const String paymentScreen = '/payment-screen';
  static const String orderHistoryScreen = '/order-history-screen';
  static const String transactionDetailScreen = '/transaction-detail-screen';

  // Notification Routes
  static const String notificationsScreen = '/notifications-screen';
  static const String notificationSettingsScreen = '/notification-settings-screen';

  // Location Routes
  static const String locationPickerScreen = '/location-picker-screen';
  static const String mapViewScreen = '/map-view-screen';

  // Settings & Configuration Routes
  static const String settingsScreen = '/settings-screen';
  static const String configurationSetup = '/configuration-setup';
  static const String languageSettingsScreen = '/language-settings-screen';
  static const String themeSettingsScreen = '/theme-settings-screen';
  static const String privacySettingsScreen = '/privacy-settings-screen';

  // Help & Support Routes
  static const String helpSupportScreen = '/help-support-screen';
  static const String faqScreen = '/faq-screen';
  static const String contactUsScreen = '/contact-us-screen';
  static const String reportIssueScreen = '/report-issue-screen';

  // Legal & Information Routes
  static const String aboutScreen = '/about-screen';
  static const String termsPrivacyScreen = '/terms-privacy-screen';
  static const String privacyPolicyScreen = '/privacy-policy-screen';
  static const String termsOfServiceScreen = '/terms-of-service-screen';

  // Search & Discovery Routes
  static const String advancedSearchScreen = '/advanced-search-screen';
  static const String searchResultsScreen = '/search-results-screen';
  static const String trendingScreen = '/trending-screen';
  static const String nearbyListingsScreen = '/nearby-listings-screen';

  // Analytics & Insights Routes
  static const String analyticsScreen = '/analytics-screen';
  static const String salesReportScreen = '/sales-report-screen';
  static const String performanceScreen = '/performance-screen';

  // Error & Offline Routes
  static const String offlineScreen = '/offline-screen';
  static const String errorScreen = '/error-screen';
  static const String maintenanceScreen = '/maintenance-screen';
  static const String notFoundScreen = '/not-found-screen';

  static Map<String, WidgetBuilder> routes = {
    // Core App Routes
    initial: (context) => const MobileLoginScreen(),

    // Authentication Routes
    loginScreen: (context) => const MobileLoginScreen(),
    registrationScreen: (context) => const RegistrationScreen(),

    // Jobs Routes (CHANGED)
    homeJobsFeed: (context) => const HomeJobsFeed(), // ← CHANGED

    searchAndFilters: (context) => const SearchAndFilters(),
    listingDetail: (context) => const ListingDetail(),

    // Profile Routes
    userProfile: (context) => const UserProfile(),

    // Communication Routes
    chatMessaging: (context) => const ChatMessaging(),

    // User Preferences Routes
    favoritesAndSavedItems: (context) => const FavoritesAndSavedItems(),

    // Settings & Configuration Routes
    configurationSetup: (context) => const ConfigurationSetup(),
  };

  /// Navigate to a route and clear the navigation stack
  static Future<void> pushAndClearStack(BuildContext context, String routeName) async {
    await Navigator.of(context).pushNamedAndRemoveUntil(
      routeName,
      (Route<dynamic> route) => false,
    );
  }

  /// Navigate to a route with arguments
  static Future<void> pushNamed(BuildContext context, String routeName, {Object? arguments}) async {
    await Navigator.of(context).pushNamed(routeName, arguments: arguments);
  }

  /// Replace current route with new route
  static Future<void> pushReplacementNamed(BuildContext context, String routeName, {Object? arguments}) async {
    await Navigator.of(context).pushReplacementNamed(routeName, arguments: arguments);
  }

  /// Pop current route
  static void pop(BuildContext context, [dynamic result]) {
    Navigator.of(context).pop(result);
  }

  /// Check if can pop
  static bool canPop(BuildContext context) {
    return Navigator.of(context).canPop();
  }

  /// Navigate to login screen and clear stack
  static Future<void> navigateToLogin(BuildContext context) async {
    await pushAndClearStack(context, loginScreen);
  }

  /// Navigate to home screen and clear stack (CHANGED)
  static Future<void> navigateToHome(BuildContext context) async {
    await pushAndClearStack(context, homeJobsFeed); // ← CHANGED
  }

  /// Handle unknown routes
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    // Handle routes with parameters
    switch (settings.name) {
      case listingDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (context) => const ListingDetail(),
          settings: settings,
        );

      case chatMessaging:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (context) => const ChatMessaging(),
          settings: settings,
        );

      default:
        return null;
    }
  }

  /// Handle unknown routes (404)
  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Page Not Found'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 100,
                color: Colors.red,
              ),
              const SizedBox(height: 20),
              const Text(
                '404 - Page Not Found',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'The route "${settings.name}" does not exist.',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => navigateToHome(context),
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      ),
      settings: settings,
    );
  }

  /// Get route arguments safely
  static T? getArguments<T>(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is T) {
      return args;
    }
    return null;
  }

  /// Check if current route matches
  static bool isCurrentRoute(BuildContext context, String routeName) {
    return ModalRoute.of(context)?.settings.name == routeName;
  }

  /// Get current route name
  static String? getCurrentRouteName(BuildContext context) {
    return ModalRoute.of(context)?.settings.name;
  }
}