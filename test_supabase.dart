import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'lib/utils/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  debugPrint('🧪 Starting Supabase connection test...');
  
  try {
    // Test environment variables
    debugPrint('🔍 Testing environment variables...');
    debugPrint('🔍 SUPABASE_URL: ${SupabaseService.supabaseUrl.isNotEmpty ? "SET" : "NOT SET"}');
    debugPrint('🔍 SUPABASE_ANON_KEY: ${SupabaseService.supabaseAnonKey.isNotEmpty ? "SET" : "NOT SET"}');
    
    if (SupabaseService.supabaseUrl.isEmpty || SupabaseService.supabaseAnonKey.isEmpty) {
      debugPrint('❌ Environment variables not set!');
      debugPrint('❌ Please ensure SUPABASE_URL and SUPABASE_ANON_KEY are defined');
      return;
    }
    
    // Test initialization
    debugPrint('🔄 Initializing Supabase...');
    await SupabaseService.initialize();
    
    // Test connection
    debugPrint('🔍 Testing connection...');
    final healthStatus = await SupabaseService().getHealthStatus();
    debugPrint('🔍 Health status: $healthStatus');
    
    if (healthStatus['connection_ok'] == true) {
      debugPrint('✅ Supabase connection successful!');
    } else {
      debugPrint('❌ Supabase connection failed!');
    }
    
  } catch (e) {
    debugPrint('❌ Test failed: $e');
    debugPrint('❌ Error type: ${e.runtimeType}');
  }
  
  debugPrint('🧪 Test completed');
}