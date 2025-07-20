import 'package:flutter/material.dart';
// Existing screens
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/onboarding_tutorial/onboarding_tutorial.dart';
import '../presentation/home_marketplace_feed/home_marketplace_feed.dart';
import '../presentation/search_and_filters/search_and_filters.dart';
import '../presentation/registration_screen/registration_screen.dart';
import '../presentation/listing_detail/listing_detail.dart';
import '../presentation/user_profile/user_profile.dart';
import '../presentation/chat_messaging/chat_messaging.dart';
import '../presentation/favorites_and_saved_items/favorites_and_saved_items.dart';
// REMOVED: import '../presentation/create_listing/create_listing.dart';
import '../presentation/configuration_setup/configuration_setup.dart';

// Additional screens we'll create
// import '../presentation/forgot_password/forgot_password_screen.dart';
// import '../presentation/email_verification/email_verification_screen.dart';
// import '../presentation/categories/categories_screen.dart';
// import '../presentation/product_detail/product_detail_screen.dart';
// import '../presentation/seller_profile/seller_profile_screen.dart';
// import '../presentation/edit_profile/edit_profile_screen.dart';
// import '../presentation/settings/settings_screen.dart';
// import '../presentation/notifications/notifications_screen.dart';
// import '../presentation/my_listings/my_listings_screen.dart';
// import '../presentation/edit_listing/edit_listing_screen.dart';
// import '../presentation/payment/payment_screen.dart';
// import '../presentation/order_history/order_history_screen.dart';
// import '../presentation/help_support/help_support_screen.dart';
// import '../presentation/about/about_screen.dart';
// import '../presentation/terms_privacy/terms_privacy_screen.dart';
// import '../presentation/location_picker/location_picker_screen.dart';
// import '../presentation/job_listings/job_listings_screen.dart';
// import '../presentation/job_detail/job_detail_screen.dart';
// import '../presentation/job_application/job_application_screen.dart';

class AppRoutes {
  // 🏠 Core App Routes
  static const String initial = '/';
  static const String splashScreen = '/splash-screen';
  
  // 🔐 Authentication Routes
  static const String loginScreen = '/login-screen';
  static const String registrationScreen = '/registration-screen';
  static const String forgotPasswordScreen = '/forgot-password-screen';
  static const String emailVerificationScreen = '/email-verification-screen';
  static const String phoneVerificationScreen = '/phone-verification-screen';
  
  // 🎪 Onboarding Routes
  static const String onboardingTutorial = '/onboarding-tutorial';
  
  // 🏪 Marketplace Routes
  static const String homeMarketplaceFeed = '/home-marketplace-feed';
  static const String categoriesScreen = '/categories-screen';
  static const String searchAndFilters = '/search-and-filters';
  static const String listingDetail = '/listing-detail';
  static const String productDetailScreen = '/product-detail-screen';
  static const String sellerProfileScreen = '/seller-profile-screen';
  
  // 💼 Job Routes
  static const String jobListingsScreen = '/job-listings-screen';
  static const String jobDetailScreen = '/job-detail-screen';
  static const String jobApplicationScreen = '/job-application-screen';
  
  // 📝 Listing Management Routes
  static const String createListing = '/create-listing';
  static const String myListingsScreen = '/my-listings-screen';
  static const String editListingScreen = '/edit-listing-screen';
  
  // 👤 Profile Routes
  static const String userProfile = '/user-profile';
  static const String editProfileScreen = '/edit-profile-screen';
  static const String sellerDashboard = '/seller-dashboard';
  
  // 💬 Communication Routes
  static const String chatMessaging = '/chat-messaging';
  static const String chatListScreen = '/chat-list-screen';
  static const String videoCallScreen = '/video-call-screen';
  
  // ❤️ User Preferences Routes
  static const String favoritesAndSavedItems = '/favorites-and-saved-items';
  static const String wishlistScreen = '/wishlist-screen';
  
  // 💰 Transaction Routes
  static const String paymentScreen = '/payment-screen';
  static const String orderHistoryScreen = '/order-history-screen';
  static const String transactionDetailScreen = '/transaction-detail-screen';
  
  // 🔔 Notification Routes
  static const String notificationsScreen = '/notifications-screen';
  static const String notificationSettingsScreen = '/notification-settings-screen';
  
  // 📍 Location Routes
  static const String locationPickerScreen = '/location-picker-screen';
  static const String mapViewScreen = '/map-view-screen';
  
  // ⚙️ Settings & Configuration Routes
  static const String settingsScreen = '/settings-screen';
  static const String configurationSetup = '/configuration-setup';
  static const String languageSettingsScreen = '/language-settings-screen';
  static const String themeSettingsScreen = '/theme-settings-screen';
  static const String privacySettingsScreen = '/privacy-settings-screen';
  
  // 🆘 Help & Support Routes
  static const String helpSupportScreen = '/help-support-screen';
  static const String faqScreen = '/faq-screen';
  static const String contactUsScreen = '/contact-us-screen';
  static const String reportIssueScreen = '/report-issue-screen';
  
  // 📄 Legal & Information Routes
  static const String aboutScreen = '/about-screen';
  static const String termsPrivacyScreen = '/terms-privacy-screen';
  static const String privacyPolicyScreen = '/privacy-policy-screen';
  static const String termsOfServiceScreen = '/terms-of-service-screen';
  
  // 🔍 Search & Discovery Routes
  static const String advancedSearchScreen = '/advanced-search-screen';
  static const String searchResultsScreen = '/search-results-screen';
  static const String trendingScreen = '/trending-screen';
  static const String nearbyListingsScreen = '/nearby-listings-screen';
  
  // 📊 Analytics & Insights Routes
  static const String analyticsScreen = '/analytics-screen';
  static const String salesReportScreen = '/sales-report-screen';
  static const String performanceScreen = '/performance-screen';
  
  // 🚫 Error & Offline Routes
  static const String offlineScreen = '/offline-screen';
  static const String errorScreen = '/error-screen';
  static const String maintenanceScreen = '/maintenance-screen';
  static const String notFoundScreen = '/not-found-screen';

  static Map<String, WidgetBuilder> routes = {
    // 🏠 Core App Routes
    initial: (context) => const SplashScreen(),
    splashScreen: (context) => const SplashScreen(),
    
    // 🔐 Authentication Routes
    loginScreen: (context) => const LoginScreen(),
    registrationScreen: (context) => const RegistrationScreen(),
    // forgotPasswordScreen: (context) => const ForgotPasswordScreen(),
    // emailVerificationScreen: (context) => const EmailVerificationScreen(),
    // phoneVerificationScreen: (context) => const PhoneVerificationScreen(),
    
    // 🎪 Onboarding Routes
    onboardingTutorial: (context) => const OnboardingTutorial(),
    
    // 🏪 Marketplace Routes
    homeMarketplaceFeed: (context) => const HomeMarketplaceFeed(),
    // categoriesScreen: (context) => const CategoriesScreen(),
    searchAndFilters: (context) => const SearchAndFilters(),
    listingDetail: (context) => const ListingDetail(),
    // productDetailScreen: (context) => const ProductDetailScreen(),
    // sellerProfileScreen: (context) => const SellerProfileScreen(),
    
    // 💼 Job Routes
    // jobListingsScreen: (context) => const JobListingsScreen(),
    // jobDetailScreen: (context) => const JobDetailScreen(),
    // jobApplicationScreen: (context) => const JobApplicationScreen(),
    
    // 📝 Listing Management Routes
    // COMMENTED OUT: Create listing is now handled within HomeMarketplaceFeed
    // createListing: (context) => const CreateListingScreen(),
    // myListingsScreen: (context) => const MyListingsScreen(),
    // editListingScreen: (context) => const EditListingScreen(),
    
    // 👤 Profile Routes
    userProfile: (context) => const UserProfile(),
    // editProfileScreen: (context) => const EditProfileScreen(),
    // sellerDashboard: (context) => const SellerDashboard(),
    
    // 💬 Communication Routes
    chatMessaging: (context) => const ChatMessaging(),
    // chatListScreen: (context) => const ChatListScreen(),
    // videoCallScreen: (context) => const VideoCallScreen(),
    
    // ❤️ User Preferences Routes
    favoritesAndSavedItems: (context) => const FavoritesAndSavedItems(),
    // wishlistScreen: (context) => const WishlistScreen(),
    
    // 💰 Transaction Routes
    // paymentScreen: (context) => const PaymentScreen(),
    // orderHistoryScreen: (context) => const OrderHistoryScreen(),
    // transactionDetailScreen: (context) => const TransactionDetailScreen(),
    
    // 🔔 Notification Routes
    // notificationsScreen: (context) => const NotificationsScreen(),
    // notificationSettingsScreen: (context) => const NotificationSettingsScreen(),
    
    // 📍 Location Routes
    // locationPickerScreen: (context) => const LocationPickerScreen(),
    // mapViewScreen: (context) => const MapViewScreen(),
    
    // ⚙️ Settings & Configuration Routes
    // settingsScreen: (context) => const SettingsScreen(),
    configurationSetup: (context) => const ConfigurationSetup(),
    // languageSettingsScreen: (context) => const LanguageSettingsScreen(),
    // themeSettingsScreen: (context) => const ThemeSettingsScreen(),
    // privacySettingsScreen: (context) => const PrivacySettingsScreen(),
    
    // 🆘 Help & Support Routes
    // helpSupportScreen: (context) => const HelpSupportScreen(),
    // faqScreen: (context) => const FaqScreen(),
    // contactUsScreen: (context) => const ContactUsScreen(),
    // reportIssueScreen: (context) => const ReportIssueScreen(),
    
    // 📄 Legal & Information Routes
    // aboutScreen: (context) => const AboutScreen(),
    // termsPrivacyScreen: (context) => const TermsPrivacyScreen(),
    // privacyPolicyScreen: (context) => const PrivacyPolicyScreen(),
    // termsOfServiceScreen: (context) => const TermsOfServiceScreen(),
    
    // 🔍 Search & Discovery Routes
    // advancedSearchScreen: (context) => const AdvancedSearchScreen(),
    // searchResultsScreen: (context) => const SearchResultsScreen(),
    // trendingScreen: (context) => const TrendingScreen(),
    // nearbyListingsScreen: (context) => const NearbyListingsScreen(),
    
    // 📊 Analytics & Insights Routes
    // analyticsScreen: (context) => const AnalyticsScreen(),
    // salesReportScreen: (context) => const SalesReportScreen(),
    // performanceScreen: (context) => const PerformanceScreen(),
    
    // 🚫 Error & Offline Routes
    // offlineScreen: (context) => const OfflineScreen(),
    // errorScreen: (context) => const ErrorScreen(),
    // maintenanceScreen: (context) => const MaintenanceScreen(),
    // notFoundScreen: (context) => const NotFoundScreen(),
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

  /// Navigate to home screen and clear stack
  static Future<void> navigateToHome(BuildContext context) async {
    await pushAndClearStack(context, homeMarketplaceFeed);
  }

  /// Navigate to onboarding and clear stack
  static Future<void> navigateToOnboarding(BuildContext context) async {
    await pushAndClearStack(context, onboardingTutorial);
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
      
      // Add more parameterized routes here
      
      default:
        return null; // Let the main routes handle it
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