# Supabase Setup Guide for khilonjiya.com

## 🚨 Current Issue: Supabase Not Initialized

Your app is failing to initialize Supabase because the required environment variables are not configured. Here's how to fix it:

## 🔧 Quick Fix Steps

### 1. Get Your Supabase Credentials

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project (or create a new one)
3. Go to **Settings** → **API**
4. Copy the following values:
   - **Project URL** (starts with `https://`)
   - **anon public** key (starts with `eyJ`)

### 2. Configure Environment Variables

#### Option A: For Development (Recommended)
Edit the `.env` file in your project root:

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

Replace `your-project-id` and `your-anon-key-here` with your actual values.

#### Option B: For Production (CI/CD)
Set these environment variables in your Codemagic project:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

## 🧪 Test Your Configuration

Run this command to verify your setup:

```bash
dart test_supabase.dart
```

## 🔍 Troubleshooting

### Common Issues:

1. **"Environment variables not found"**
   - Make sure your `.env` file exists and has the correct format
   - Check that there are no extra spaces or quotes around the values

2. **"Invalid URL format"**
   - Ensure your Supabase URL starts with `https://`
   - Make sure it ends with `.supabase.co`

3. **"Connection failed"**
   - Check your internet connection
   - Verify your Supabase project is active
   - Ensure your project's API is enabled

### Debug Information

The app will show detailed debug information in the console:
- ✅ `.env file loaded successfully`
- 🔍 `SUPABASE_URL length: XX`
- 🔍 `SUPABASE_ANON_KEY length: XX`
- ✅ `Supabase initialized successfully`

## 📱 Running the App

After configuring the environment variables:

```bash
flutter pub get
flutter run
```

## 🔒 Security Notes

- Never commit your `.env` file to version control
- The `.env` file is already in `.gitignore`
- For production, use environment variables in your CI/CD pipeline

## 📞 Support

If you're still having issues:
1. Check the console output for specific error messages
2. Verify your Supabase project is active and accessible
3. Ensure you're using the correct credentials from the API settings page