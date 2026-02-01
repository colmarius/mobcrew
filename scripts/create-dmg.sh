#!/bin/bash
# Create DMG from built MobCrew.app
#
# Usage:
#   ./scripts/create-dmg.sh <version> [--no-code-sign]
#
# Arguments:
#   version        Version string for DMG filename (e.g., 1.0.0)
#   --no-code-sign Skip code signing (default for now)
#
# Prerequisites:
#   - Node.js (for npx create-dmg)
#   - Built app at build/Release/MobCrew.app
#
# Output:
#   build/MobCrew-<version>.dmg

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_PATH="$BUILD_DIR/Release/MobCrew.app"

VERSION="${1:-}"
NO_CODE_SIGN=true

if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version> [--no-code-sign]"
    echo "Example: $0 1.0.0"
    exit 1
fi

shift
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-code-sign)
            NO_CODE_SIGN=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if ! command -v node &> /dev/null; then
    echo "✗ Node.js is required. Install with: brew install node"
    exit 1
fi

if [ ! -d "$APP_PATH" ]; then
    echo "✗ App not found at $APP_PATH"
    echo "  Run ./scripts/build-release.sh first"
    exit 1
fi

DMG_NAME="MobCrew-${VERSION}.dmg"
OUTPUT_PATH="$BUILD_DIR/$DMG_NAME"

rm -f "$BUILD_DIR"/MobCrew-*.dmg 2>/dev/null || true

echo "Creating DMG..."
echo "  App: $APP_PATH"
echo "  Output: $OUTPUT_PATH"

CREATE_DMG_ARGS=("--overwrite" "$APP_PATH" "$BUILD_DIR")
if [ "$NO_CODE_SIGN" = true ]; then
    CREATE_DMG_ARGS=("--overwrite" "--no-code-sign" "$APP_PATH" "$BUILD_DIR")
fi

npx create-dmg "${CREATE_DMG_ARGS[@]}" 2>&1 || true

CREATED_DMG=$(find "$BUILD_DIR" -maxdepth 1 -name "MobCrew*.dmg" -type f | head -1)
if [ -n "$CREATED_DMG" ] && [ -f "$CREATED_DMG" ]; then
    mv "$CREATED_DMG" "$OUTPUT_PATH"
    echo "✓ Created: $OUTPUT_PATH"
else
    echo "✗ DMG creation failed"
    exit 1
fi
