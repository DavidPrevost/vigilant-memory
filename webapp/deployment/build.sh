#!/bin/bash
set -e

# Flutter Web Build Script for Production
# This script builds the Flutter web app for deployment

echo "🚀 Building Flutter Web App for Production"
echo "=========================================="

# Check if we're in the webapp directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: Must run from webapp directory"
    echo "Usage: cd webapp && ./deployment/build.sh"
    exit 1
fi

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Error: Flutter is not installed"
    echo "Install Flutter: https://flutter.dev/docs/get-started/install"
    exit 1
fi

# Check Flutter version
echo ""
echo "📋 Flutter version:"
flutter --version | head -1

# Clean previous builds
echo ""
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo ""
echo "📦 Getting dependencies..."
flutter pub get

# Run code generation for Freezed models
echo ""
echo "🔧 Running code generation..."
flutter pub run build_runner build --delete-conflicting-outputs

# Build web app
echo ""
echo "🏗️  Building web app..."
flutter build web \
    --release \
    --web-renderer canvaskit \
    --base-href "/" \
    --source-maps

# Check build success
if [ ! -d "build/web" ]; then
    echo "❌ Build failed - build/web directory not found"
    exit 1
fi

# Display build info
echo ""
echo "✅ Build successful!"
echo ""
echo "📊 Build statistics:"
BUILD_SIZE=$(du -sh build/web | cut -f1)
echo "   Total size: $BUILD_SIZE"
echo "   Output: $(pwd)/build/web"
echo ""

# List main files
echo "📁 Main files:"
ls -lh build/web/index.html build/web/main.dart.js 2>/dev/null | awk '{print "   " $9, "-", $5}'

echo ""
echo "🎉 Ready for deployment!"
echo ""
echo "Next steps:"
echo "  1. Deploy to server: ./deployment/deploy.sh pi@<IP> mesoldseparately.org"
echo "  2. Or manually copy build/web/* to your web server"
