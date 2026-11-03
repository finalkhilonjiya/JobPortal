/// Values come from --dart-define (never hard-code keys in the repo).
///
/// flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///             --dart-define=SUPABASE_ANON_KEY=eyJ...
class Env {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}

class AppInfo {
  /// Working name. Change here + android/app/src/main/res/values/strings.xml.
  static const String name = 'Housing';
  static const String countryCode = '+91';
}
