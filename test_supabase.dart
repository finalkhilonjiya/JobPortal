import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  print('🔍 Testing Supabase Configuration...\n');
  
  try {
    // Try to load .env file
    try {
      await dotenv.load(fileName: '.env');
      print('✅ .env file loaded successfully');
    } catch (e) {
      print('⚠️ .env file not found or could not be loaded: $e');
    }
    
    // Check environment variables
    final url = dotenv.env['SUPABASE_URL'] ?? '';
    final key = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    
    print('\n📋 Environment Variables Check:');
    print('SUPABASE_URL: ${url.isNotEmpty ? "✅ SET" : "❌ NOT SET"}');
    print('SUPABASE_ANON_KEY: ${key.isNotEmpty ? "✅ SET" : "❌ NOT SET"}');
    
    if (url.isNotEmpty) {
      print('URL starts with: ${url.substring(0, url.length > 20 ? 20 : url.length)}...');
    }
    
    if (key.isNotEmpty) {
      print('Key starts with: ${key.substring(0, key.length > 10 ? 10 : key.length)}...');
    }
    
    if (url.isEmpty || key.isEmpty) {
      print('\n❌ Configuration Error:');
      print('Please set your Supabase credentials in the .env file:');
      print('SUPABASE_URL=https://your-project-id.supabase.co');
      print('SUPABASE_ANON_KEY=your-anon-key-here');
      print('\nYou can find these in your Supabase project dashboard under Settings > API');
    } else {
      print('\n✅ Configuration looks good!');
      print('You can now run your Flutter app.');
    }
    
  } catch (e) {
    print('❌ Error during configuration check: $e');
  }
}