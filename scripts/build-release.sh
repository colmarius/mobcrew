#!/bin/bash
# Build MobCrew app in Release configuration
#
# Usage:
#   ./scripts/build-release.sh [version]
#
# Arguments:
#   version  Optional version string (e.g., 1.0.0). If provided, updates the app version.
#
# Output:
#   build/Release/MobCrew.app

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build/Release"
XCODE_PROJECT="$PROJECT_DIR/MobCrew/MobCrew.xcodeproj"
VERSION="${1:-}"

echo "Building MobCrew (Release)..."

BUILD_ARGS=(
    -project "$XCODE_PROJECT"
    -scheme MobCrew
    -configuration Release
    -destination 'platform=macOS'
    CONFIGURATION_BUILD_DIR="$BUILD_DIR"
)

if [ -n "$VERSION" ]; then
    BUILD_NUMBER=$(git -C "$PROJECT_DIR" rev-list --count HEAD 2>/dev/null || echo "1")
    BUILD_ARGS+=(
        MARKETING_VERSION="$VERSION"
        CURRENT_PROJECT_VERSION="$BUILD_NUMBER"
    )
    echo "  Version: $VERSION (build $BUILD_NUMBER)"
fi

xcodebuild "${BUILD_ARGS[@]}" build -quiet

if [ -d "$BUILD_DIR/MobCrew.app" ]; then
    echo "✓ Built: $BUILD_DIR/MobCrew.app"
else
    echo "✗ Build failed: MobCrew.app not found"
    exit 1
fi
