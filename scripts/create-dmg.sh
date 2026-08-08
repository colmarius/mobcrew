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
#   - Node.js 24+ (24.19.0 is pinned in .nvmrc)
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
    echo "✗ Node.js 24+ is required. Install with: brew install node"
    exit 1
fi

NODE_MAJOR=$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo "")
if [[ ! "$NODE_MAJOR" =~ ^[0-9]+$ ]] || [ "$NODE_MAJOR" -lt 24 ]; then
    echo "✗ Node.js 24+ is required (found: $(node --version 2>/dev/null || echo "unknown"))."
    echo "  Upgrade with: brew upgrade node"
    exit 1
fi

if ! command -v npx &> /dev/null; then
    echo "✗ npx is required. Install the complete Node.js distribution."
    exit 1
fi

if [ ! -d "$APP_PATH" ]; then
    echo "✗ App not found at $APP_PATH"
    echo "  Run ./scripts/build-release.sh first"
    exit 1
fi

DMG_NAME="MobCrew-${VERSION}.dmg"
OUTPUT_PATH="$BUILD_DIR/$DMG_NAME"
TEMP_DIR=$(mktemp -d "$BUILD_DIR/.create-dmg.XXXXXX")
trap 'rm -rf "$TEMP_DIR"' EXIT

rm -f "$OUTPUT_PATH"

echo "Creating DMG..."
echo "  App: $APP_PATH"
echo "  Output: $OUTPUT_PATH"

CREATE_DMG_ARGS=("--overwrite" "$APP_PATH" "$TEMP_DIR")
if [ "$NO_CODE_SIGN" = true ]; then
    CREATE_DMG_ARGS=("--overwrite" "--no-code-sign" "$APP_PATH" "$TEMP_DIR")
fi

npx --yes create-dmg@8.1.0 "${CREATE_DMG_ARGS[@]}" 2>&1

shopt -s nullglob
CREATED_DMGS=("$TEMP_DIR"/*.dmg)
shopt -u nullglob
if [ "${#CREATED_DMGS[@]}" -ne 1 ]; then
    echo "✗ Expected exactly one DMG, found ${#CREATED_DMGS[@]}"
    exit 1
fi

hdiutil verify "${CREATED_DMGS[0]}"
mv "${CREATED_DMGS[0]}" "$OUTPUT_PATH"
echo "✓ Created and verified: $OUTPUT_PATH"
