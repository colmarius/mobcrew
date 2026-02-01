#!/bin/bash
# Run MobCrew tests

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"

# Check for specific test class argument
if [ -n "$1" ]; then
  echo "Running tests for: $1"
  xcodebuild test -project "$PROJECT_DIR/MobCrew/MobCrew.xcodeproj" \
    -scheme MobCrew \
    -destination 'platform=macOS' \
    -derivedDataPath "$BUILD_DIR" \
    -only-testing:"MobCrewTests/$1" \
    -quiet
else
  echo "Running all tests..."
  xcodebuild test -project "$PROJECT_DIR/MobCrew/MobCrew.xcodeproj" \
    -scheme MobCrew \
    -destination 'platform=macOS' \
    -derivedDataPath "$BUILD_DIR" \
    -quiet
fi

echo "Tests completed successfully!"
