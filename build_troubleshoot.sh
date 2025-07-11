#!/bin/bash

echo "🔧 Flutter Build Troubleshooting Script"
echo "======================================="

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check Flutter installation
if command_exists flutter; then
    echo "✅ Flutter is installed"
    flutter --version
else
    echo "❌ Flutter is not installed or not in PATH"
    echo "Please install Flutter from https://flutter.dev/docs/get-started/install"
    exit 1
fi

# Check Android SDK
if [ -d "$ANDROID_HOME" ] || [ -d "$ANDROID_SDK_ROOT" ]; then
    echo "✅ Android SDK found"
else
    echo "⚠️  Android SDK not found in ANDROID_HOME or ANDROID_SDK_ROOT"
    echo "This is required for Android builds"
fi

# Clean and get dependencies
echo "🧹 Cleaning project..."
flutter clean

echo "📦 Getting dependencies..."
flutter pub get

# Check for dependency issues
echo "🔍 Checking dependencies..."
flutter pub deps

# Check for any obvious issues
echo "🔍 Running Flutter doctor..."
flutter doctor

# Try to analyze the project
echo "🔍 Running Flutter analyze..."
flutter analyze

echo ""
echo "✅ Troubleshooting completed!"
echo ""
echo "If you still have build issues, try:"
echo "1. flutter clean && flutter pub get"
echo "2. flutter build apk --debug --verbose"
echo "3. Check the verbose output for specific error messages"
echo ""
echo "Common issues:"
echo "- Gradle version conflicts (fixed in this update)"
echo "- Missing Android SDK (needed for local builds)"
echo "- Dependency conflicts (check pubspec.yaml)"
echo "- Memory issues (increased heap size in gradle.properties)"