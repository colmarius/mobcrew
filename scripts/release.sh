#!/bin/bash
# Create a GitHub release for MobCrew
#
# Usage:
#   ./scripts/release.sh <version> [--draft]
#
# Arguments:
#   version  Version string (e.g., 1.0.0)
#   --draft  Create as draft release for testing
#
# Prerequisites:
#   - gh CLI installed and authenticated (brew install gh && gh auth login)
#   - Node.js 24+ for DMG creation (24.19.0 is pinned in .node-version)
#
# This script:
#   1. Builds the app in Release configuration
#   2. Creates a DMG package
#   3. Creates a GitHub release with auto-generated notes
#   4. Uploads the DMG as a release asset

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS_DIR="$PROJECT_DIR/scripts"
BUILD_DIR="$PROJECT_DIR/build"

VERSION="${1:-}"
DRAFT=false

if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version> [--draft]"
    echo ""
    echo "Examples:"
    echo "  $0 1.0.0         Create release v1.0.0"
    echo "  $0 1.0.0 --draft Create draft release for testing"
    exit 1
fi

shift
while [[ $# -gt 0 ]]; do
    case $1 in
        --draft)
            DRAFT=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if ! command -v gh &> /dev/null; then
    echo "✗ GitHub CLI (gh) is required."
    echo "  Install: brew install gh"
    echo "  Then:    gh auth login"
    exit 1
fi

if ! gh auth status &> /dev/null; then
    echo "✗ GitHub CLI is not authenticated."
    echo "  Run: gh auth login"
    exit 1
fi

if ! command -v node &> /dev/null; then
    echo "✗ Node.js 24+ is required for DMG creation."
    echo "  Install: brew install node"
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

TAG="v${VERSION}"
DMG_PATH="$BUILD_DIR/MobCrew-${VERSION}.dmg"

echo "=== MobCrew Release $TAG ==="
echo ""

echo "Step 1: Building app..."
"$SCRIPTS_DIR/build-release.sh" "$VERSION"
echo ""

echo "Step 2: Creating DMG..."
"$SCRIPTS_DIR/create-dmg.sh" "$VERSION"
echo ""

if [ ! -f "$DMG_PATH" ]; then
    echo "✗ DMG not found at $DMG_PATH"
    exit 1
fi

echo "Step 3: Creating GitHub release..."
RELEASE_ARGS=(
    "$TAG"
    "$DMG_PATH"
    --title "MobCrew $VERSION"
    --generate-notes
)

if [ "$DRAFT" = true ]; then
    RELEASE_ARGS+=("--draft")
    echo "  (Creating as draft)"
fi

gh release create "${RELEASE_ARGS[@]}"

echo ""
echo "=== Release Complete ==="
echo "✓ Tag: $TAG"
echo "✓ DMG: $DMG_PATH"
if [ "$DRAFT" = true ]; then
    echo "✓ Status: Draft (edit and publish at https://github.com/colmarius/mobcrew/releases)"
else
    echo "✓ Download: https://github.com/colmarius/mobcrew/releases/download/$TAG/MobCrew-${VERSION}.dmg"
fi
