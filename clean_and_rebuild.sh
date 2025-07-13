#!/bin/bash

echo "🧹 Cleaning Flutter project..."
flutter clean

echo "📦 Getting dependencies..."
flutter pub get

echo "� Cleaning Android build..."
cd android
./gradlew clean
cd ..

echo "🏗️ Building Android release..."
flutter build apk --release

echo "📱 Building Android debug..."
flutter build apk --debug

echo "🍎 Building iOS (if on macOS)..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    flutter build ios --release
    flutter build ios --debug
else
    echo "⚠️  Skipping iOS build (not on macOS)"
fi

echo "✅ Build completed!"
echo ""
echo "📋 Next steps:"
echo "1. Install the APK on your devices:"
echo "   - Debug: build/app/outputs/flutter-apk/app-debug.apk"
echo "   - Release: build/app/outputs/flutter-apk/app-release.apk"
echo ""
echo "2. Test the app and check logcat for any remaining errors:"
echo "   adb logcat | grep -E '(FATAL|ERROR|WARN)'"
echo ""
echo "3. Monitor memory usage:"
echo "   adb shell dumpsys meminfo com.khilonjiya.marketplace"
echo ""
echo "� If you encounter issues:"
echo "- Check the error.txt file for detailed fixes"
echo "- Ensure all permissions are granted on the device"
echo "- Verify Google Play Services are up to date"