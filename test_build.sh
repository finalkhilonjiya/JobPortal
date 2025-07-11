#!/bin/bash

echo "🧪 Testing Flutter Build Process"
echo "================================"

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found in PATH"
    echo "Please install Flutter or add it to your PATH"
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -1)"

# Clean the project
echo "🧹 Cleaning project..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Check for any dependency issues
echo "🔍 Checking dependencies..."
flutter pub deps

# Try to build (this will fail without Android SDK, but we can check for embedding issues)
echo "🔨 Attempting build (will fail without Android SDK, but checking for embedding issues)..."
flutter build apk --debug 2>&1 | head -20

echo ""
echo "✅ Test completed!"
echo "If you see any 'v1 embedding' errors above, the fixes didn't work."
echo "If you see Android SDK errors, that's expected without the SDK installed."
echo ""
echo "🚀 Ready to push to Codemagic for actual build!"