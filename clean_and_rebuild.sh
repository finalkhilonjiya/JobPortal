#!/bin/bash

echo "🧹 Cleaning Flutter project..."
flutter clean

echo "📦 Getting Flutter dependencies..."
flutter pub get

echo "🗑️ Cleaning Android build..."
cd android
./gradlew clean
cd ..

echo "🔧 Cleaning iOS build..."
cd ios
rm -rf Pods
rm -rf Podfile.lock
pod install
cd ..

echo "🏗️ Building Android app..."
flutter build apk --debug

echo "✅ Clean and rebuild completed!"
echo "📱 You can now run: flutter run"