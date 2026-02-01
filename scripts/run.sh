#!/bin/bash
# Build and run MobCrew app

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"

echo "Building MobCrew..."
xcodebuild -project "$PROJECT_DIR/MobCrew/MobCrew.xcodeproj" \
  -scheme MobCrew \
  -destination 'platform=macOS' \
  -derivedDataPath "$BUILD_DIR" \
  build -quiet

APP_PATH="$BUILD_DIR/Build/Products/Debug/MobCrew.app"

echo "Launching MobCrew..."
open "$APP_PATH"
