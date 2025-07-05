import 'package:flutter/material.dart';
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
import '../presentation/create_listing/create_listing.dart';
import '../presentation/configuration_setup/configuration_setup.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String splashScreen = '/splash-screen';
  static const String loginScreen = '/login-screen';
  static const String onboardingTutorial = '/onboarding-tutorial';
  static const String homeMarketplaceFeed = '/home-marketplace-feed';
  static const String searchAndFilters = '/search-and-filters';
  static const String registrationScreen = '/registration-screen';
  static const String listingDetail = '/listing-detail';
  static const String userProfile = '/user-profile';
  static const String chatMessaging = '/chat-messaging';
  static const String favoritesAndSavedItems = '/favorites-and-saved-items';
  static const String createListing = '/create-listing';
  static const String configurationSetup = '/configuration-setup';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    splashScreen: (context) => const SplashScreen(),
    loginScreen: (context) => const LoginScreen(),
    onboardingTutorial: (context) => const OnboardingTutorial(),
    homeMarketplaceFeed: (context) => const HomeMarketplaceFeed(),
    searchAndFilters: (context) => const SearchAndFilters(),
    registrationScreen: (context) => const RegistrationScreen(),
    listingDetail: (context) => const ListingDetail(),
    userProfile: (context) => const UserProfile(),
    chatMessaging: (context) => const ChatMessaging(),
    favoritesAndSavedItems: (context) => const FavoritesAndSavedItems(),
    createListing: (context) => const CreateListing(),
    configurationSetup: (context) => const ConfigurationSetup(),
    // TODO: Add your other routes here
  };
}
