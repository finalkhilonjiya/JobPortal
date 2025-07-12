#!/bin/bash

# Android Build Script with Memory Optimization
echo "Starting Android build with memory optimization..."

# Set memory optimization environment variables
export GRADLE_OPTS="-Xmx8g -XX:MaxMetaspaceSize=1g -XX:+UseParallelGC -XX:MaxGCPauseMillis=200"
export JAVA_OPTS="-Xmx8g -XX:MaxMetaspaceSize=1g"

# Clean previous builds
echo "Cleaning previous builds..."
flutter clean

# Get dependencies
echo "Getting Flutter dependencies..."
flutter pub get

# Build Android APK with memory optimization
echo "Building Android APK..."
flutter build apk --debug --verbose

echo "Build completed!"