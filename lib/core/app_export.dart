// Core Flutter exports
export 'package:flutter/material.dart';
export 'package:flutter/services.dart';

// Color extension for withValues method
extension ColorExtension on Color {
  Color withValues({double? alpha}) {
    return alpha != null ? withOpacity(alpha / 255.0) : this;
  }
}

// Third-party package exports
export 'package:sizer/sizer.dart';
export 'package:provider/provider.dart';
export 'package:shared_preferences/shared_preferences.dart';
// export 'package:geolocator/geolocator.dart'; // Commented out to avoid ServiceStatus ambiguity. Import directly where needed.
export 'package:image_picker/image_picker.dart';
export 'package:cached_network_image/cached_network_image.dart';
export 'package:google_fonts/google_fonts.dart';
export 'package:flutter_svg/flutter_svg.dart';
// export 'package:intl/intl.dart'; // Commented out to avoid TextDirection ambiguity. Import directly where needed.
export 'package:url_launcher/url_launcher.dart';
export 'package:http/http.dart';
export 'package:sqflite/sqflite.dart';
// export 'package:path/path.dart'; // Removed to prevent Context/BuildContext conflict. Import directly where needed.
export 'package:flutter_local_notifications/flutter_local_notifications.dart';
// export 'package:permission_handler/permission_handler.dart'; // Commented out to avoid ServiceStatus ambiguity. Import directly where needed.
export 'package:supabase_flutter/supabase_flutter.dart';

// App-specific exports
export '../routes/app_routes.dart';
export '../widgets/custom_icon_widget.dart';
export '../widgets/custom_image_widget.dart';
export '../widgets/custom_error_widget.dart';
export '../theme/app_theme.dart';
export '../utils/supabase_service.dart';
export '../utils/auth_service.dart'; // Re-enabled to ensure AuthService is available everywhere
export '../utils/listing_service.dart';
export '../utils/category_service.dart';
export '../utils/favorite_service.dart';
export '../utils/message_service.dart';

// Presentation layer exports
export '../presentation/splash_screen/splash_screen.dart';
export '../presentation/login_screen/login_screen.dart';
export '../presentation/onboarding_tutorial/onboarding_tutorial.dart';
export '../presentation/home_marketplace_feed/home_marketplace_feed.dart';
export '../presentation/user_profile/user_profile.dart';
export '../presentation/favorites_and_saved_items/favorites_and_saved_items.dart';
export '../presentation/listing_detail/listing_detail.dart';
export '../presentation/create_listing/create_listing.dart';
export '../presentation/chat_messaging/chat_messaging.dart';
export '../presentation/search_and_filters/search_and_filters.dart';
export '../presentation/registration_screen/registration_screen.dart';
export '../presentation/configuration_setup/configuration_setup.dart';