# Supabase Connection Troubleshooting Guide

## Issues Fixed

### 1. ✅ Keyboard Issues in Login Screen
- **Problem**: Mobile keypad was showing instead of full keyboard for email/phone input
- **Solution**: Changed `keyboardType` to always use `TextInputType.emailAddress` for better UX
- **File**: `lib/presentation/login_screen/login_screen.dart`

### 2. ✅ Simplified Registration Screen
- **Problem**: Registration screen was cluttered with too many fields
- **Solution**: Simplified to only essential fields: Email, Phone, Password, Confirm Password
- **Features**: Working camera/gallery profile photo upload
- **File**: `lib/presentation/registration_screen/registration_screen.dart`

### 3. 🔧 Supabase Connection Issues
- **Problem**: Supabase not initializing properly
- **Solutions Applied**:
  - Enhanced error handling and debugging
  - Better environment variable validation
  - Improved retry mechanism
  - Added connection health checks

## Environment Variables Setup

### Codemagic CI/CD
1. Go to your Codemagic project settings
2. Navigate to Environment Variables
3. Add these variables:
   - `SUPABASE_URL`: Your Supabase project URL (e.g., `https://your-project.supabase.co`)
   - `SUPABASE_ANON_KEY`: Your Supabase anonymous key

### Local Development
```bash
flutter run --dart-define=SUPABASE_URL=your_supabase_url --dart-define=SUPABASE_ANON_KEY=your_anon_key
```

## Debugging Steps

### 1. Check Environment Variables
Run the test script to verify environment variables:
```bash
flutter run test_supabase.dart
```

### 2. Check Supabase Project Settings
1. Go to your Supabase dashboard
2. Verify project URL and API keys
3. Check if Row Level Security (RLS) is properly configured
4. Ensure the `user_profiles` table exists

### 3. Network Issues
- Check if your device/emulator has internet access
- Verify Supabase project is not paused
- Check firewall settings

### 4. Database Schema
Ensure your Supabase database has the required tables:

```sql
-- Create user_profiles table
CREATE TABLE user_profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  full_name TEXT,
  display_email TEXT,
  phone_number TEXT,
  avatar_url TEXT,
  role TEXT DEFAULT 'buyer',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view own profile" ON user_profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON user_profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON user_profiles
  FOR INSERT WITH CHECK (auth.uid() = id);
```

### 5. Storage Bucket
Create a storage bucket for profile pictures:
```sql
-- Create profiles bucket
INSERT INTO storage.buckets (id, name, public) 
VALUES ('profiles', 'profiles', true);

-- Create storage policy
CREATE POLICY "Public Access" ON storage.objects
  FOR SELECT USING (bucket_id = 'profiles');

CREATE POLICY "Authenticated users can upload" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'profiles' AND auth.role() = 'authenticated');
```

## Common Error Messages

### "Environment variables not set"
- **Cause**: SUPABASE_URL or SUPABASE_ANON_KEY not defined
- **Solution**: Add environment variables to Codemagic or local build command

### "Invalid SUPABASE_URL format"
- **Cause**: URL format is incorrect
- **Solution**: Ensure URL starts with `https://` and ends with `.supabase.co`

### "Connection check failed"
- **Cause**: Network issues or Supabase project problems
- **Solution**: Check internet connection and Supabase project status

### "User not authenticated"
- **Cause**: User session expired or not logged in
- **Solution**: Implement proper authentication flow

## Testing the Fixes

### 1. Test Login Screen
- Open the app
- Navigate to login screen
- Tap on email/phone field
- Verify full keyboard appears (not mobile keypad)

### 2. Test Registration Screen
- Navigate to registration screen
- Verify only essential fields are shown
- Test profile photo upload (camera/gallery)
- Complete registration process

### 3. Test Supabase Connection
- Check app logs for Supabase initialization messages
- Verify user registration works
- Test profile picture upload

## Log Messages to Look For

### Successful Initialization
```
🔍 Supabase initialization started
🔍 SUPABASE_URL length: 45
🔍 SUPABASE_ANON_KEY length: 84
✅ Supabase initialized successfully
🔗 Connected to: https://your-project.supabase.co
🔍 Connection test result: true
```

### Failed Initialization
```
❌ Supabase initialization failed: [Error details]
❌ Error type: [Error type]
❌ Environment variables not set!
```

## Support

If issues persist:
1. Check the app logs for detailed error messages
2. Verify Supabase project settings
3. Test with the provided test script
4. Ensure all environment variables are correctly set

## Files Modified

1. `lib/presentation/login_screen/login_screen.dart` - Fixed keyboard type
2. `lib/presentation/registration_screen/registration_screen.dart` - Simplified UI
3. `lib/utils/supabase_service.dart` - Enhanced error handling
4. `lib/main.dart` - Improved initialization debugging
5. `codemagic.yaml` - Added environment variable debugging
6. `test_supabase.dart` - Created test script
7. `SUPABASE_TROUBLESHOOTING.md` - This guide