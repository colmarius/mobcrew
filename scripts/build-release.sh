#!/bin/bash
set -euo pipefail
export LC_ALL=C LANG=C

ROOT=$(cd "$(dirname "$0")/.." && pwd)
VERSION=${1:-}
case "$VERSION" in ''|*[!0-9.]*|*.*.*.*) echo "usage: $0 MAJOR.MINOR.PATCH" >&2; exit 2;; esac
echo "$VERSION" | grep -Eq '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$' || { echo "invalid SemVer: $VERSION" >&2; exit 2; }
if [ -n "${BUILD_NUMBER:-}" ]; then
  echo "$BUILD_NUMBER" | grep -Eq '^[1-9][0-9]*$' || { echo "BUILD_NUMBER must be numeric and positive" >&2; exit 1; }
  BUILD=$BUILD_NUMBER
else
  test "$(git -C "$ROOT" rev-parse --is-shallow-repository)" = false || { echo "shallow history requires BUILD_NUMBER" >&2; exit 1; }
  BUILD=$(git -C "$ROOT" rev-list --count HEAD)
fi
OUT="$ROOT/build/Release"
mkdir -p "$ROOT/build"
TMP=$(mktemp -d "$ROOT/build/.release-app.XXXXXX")
BACKUP="$OUT/.MobCrew.app.backup.$$"
INSTALLED=false
cleanup() {
  if [ "$INSTALLED" != true ] && [ -d "$BACKUP" ]; then
    rm -rf "$OUT/MobCrew.app"
    mv "$BACKUP" "$OUT/MobCrew.app" || true
  fi
  rm -rf "$TMP" "$OUT/.MobCrew.app.new"
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM
xcodebuild -project "$ROOT/MobCrew/MobCrew.xcodeproj" -scheme MobCrew -configuration Release \
  -destination 'platform=macOS' CONFIGURATION_BUILD_DIR="$TMP" MARKETING_VERSION="$VERSION" \
  CURRENT_PROJECT_VERSION="$BUILD" build -quiet
APP="$TMP/MobCrew.app"; PLIST="$APP/Contents/Info.plist"
test -d "$APP" && test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PLIST")" = "$VERSION"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$PLIST")" = "$BUILD"
codesign --verify --deep --strict "$APP"
mkdir -p "$OUT"
rm -rf "$OUT/.MobCrew.app.new"
mv "$APP" "$OUT/.MobCrew.app.new"
rm -rf "$BACKUP"
[ ! -e "$OUT/MobCrew.app" ] || mv "$OUT/MobCrew.app" "$BACKUP"
mv "$OUT/.MobCrew.app.new" "$OUT/MobCrew.app"
INSTALLED=true
rm -rf "$BACKUP"
echo "built_version=$VERSION build=$BUILD app=$OUT/MobCrew.app"
