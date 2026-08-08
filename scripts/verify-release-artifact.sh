#!/bin/bash
set -euo pipefail
export LC_ALL=C LANG=C
DMG=${1:-}; VERSION=${2:-}; PREFIX=${3:-}
test -f "$DMG" && echo "$VERSION" | grep -Eq '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$' || { echo "usage: $0 DMG MAJOR.MINOR.PATCH [OUTPUT_PREFIX]" >&2; exit 2; }
for c in hdiutil codesign spctl xcrun lipo; do command -v "$c" >/dev/null || { echo "missing required inspection tool: $c" >&2; exit 1; }; done
test -x /usr/libexec/PlistBuddy || { echo "missing PlistBuddy" >&2; exit 1; }
xcrun --find stapler >/dev/null 2>&1 || { echo "missing stapler" >&2; exit 1; }
PREFIX=${PREFIX:-"${DMG%.dmg}.verification"}; EVIDENCE="$PREFIX.evidence"; LOG="$PREFIX.log"
DIR=$(mktemp -d "${TMPDIR:-/tmp}/mobcrew-verify.XXXXXX"); MOUNT="$DIR/mount"; mkdir "$MOUNT"
cleanup() { hdiutil detach "$MOUNT" >>"$LOG" 2>&1 || true; rm -rf "$DIR"; }; trap cleanup EXIT; trap 'exit 1' HUP INT TERM
: >"$LOG"; hdiutil verify "$DMG" >>"$LOG" 2>&1
hdiutil attach -readonly -nobrowse -mountpoint "$MOUNT" "$DMG" >>"$LOG" 2>&1
APP="$MOUNT/MobCrew.app"; PLIST="$APP/Contents/Info.plist"; test -d "$APP"
plist() { /usr/libexec/PlistBuddy -c "Print :$1" "$PLIST"; }
ID=$(plist CFBundleIdentifier); VER=$(plist CFBundleShortVersionString); BUILD=$(plist CFBundleVersion); EXE=$(plist CFBundleExecutable)
echo "$BUILD" | grep -Eq '^[1-9][0-9]*$' || { echo "bundle build must be a positive integer" >&2; exit 1; }
test "$ID" = com.colmarius.MobCrew && test "$VER" = "$VERSION" && test -f "$APP/Contents/MacOS/$EXE" && test -x "$APP/Contents/MacOS/$EXE"
test -L "$MOUNT/Applications" && test "$(readlink "$MOUNT/Applications")" = /Applications
ARCHS=$(lipo -archs "$APP/Contents/MacOS/$EXE" 2>>"$LOG"); test -n "$ARCHS"
codesign --verify --deep --strict --verbose=2 "$APP" >>"$LOG" 2>&1
SIG=$(codesign -dv --verbose=4 "$APP" 2>&1 || true); printf '%s\n' "$SIG" >>"$LOG"
case "$SIG" in *'Authority=Developer ID Application:'*) KIND=developer-id;; *'Signature=adhoc'*) KIND=adhoc;; *'Authority='*) KIND=other;; *) KIND=unclassified;; esac
test "$KIND" != unclassified || { echo "unable to classify app signature" >&2; exit 1; }
TEAM=$(printf '%s\n' "$SIG" | sed -n 's/^TeamIdentifier=//p' | head -1); test -n "$TEAM" || TEAM=none
case "$SIG" in *'flags=0x10000(runtime)'*) HARDENED=true;; *) HARDENED=false;; esac
probe() { NAME=$1; shift; if "$@" >>"$LOG" 2>&1; then RESULT=accepted; RC=0; else RC=$?; RESULT=not-accepted; fi; printf '%s exit=%s\n' "$NAME" "$RC" >>"$LOG"; eval "$NAME=$RESULT"; eval "${NAME}_EXIT=$RC"; }
probe APP_STAPLER xcrun stapler validate "$APP"; probe APP_SPCTL spctl --assess --type execute --verbose=4 "$APP"
DS=$(codesign --verify --verbose=4 "$DMG" 2>&1) && DRC=0 || DRC=$?; printf '%s\n' "$DS" >>"$LOG"
if [ "$DRC" = 0 ]; then DMG_SIG=valid-signature
elif printf '%s\n' "$DS" | grep -Eqi 'not signed at all|code object is not signed'; then DMG_SIG=unsigned
elif printf '%s\n' "$DS" | grep -Eqi 'invalid|modified|unsealed|resource envelope'; then DMG_SIG=invalid; echo "invalid DMG signature" >&2; exit 1
else echo "unable to classify DMG signature" >&2; exit 1; fi
probe DMG_STAPLER xcrun stapler validate "$DMG"; probe DMG_SPCTL spctl --assess --type open --context context:primary-signature --verbose=4 "$DMG"
hdiutil detach "$MOUNT" >>"$LOG" 2>&1; trap 'rm -rf "$DIR"' EXIT
TMP="$EVIDENCE.tmp.$$"; { printf 'schema=mobcrew-artifact-v1\nversion=%s\nbuild=%s\nbundle_id=%s\nexecutable=%s\narchitectures=%s\napp_signature_kind=%s\ndeveloper_id=%s\nteam=%s\nhardened_runtime=%s\napp_stapler=%s\napp_stapler_exit=%s\napp_spctl=%s\napp_spctl_exit=%s\ndmg_signature=%s\ndmg_stapler=%s\ndmg_stapler_exit=%s\ndmg_spctl=%s\ndmg_spctl_exit=%s\n' "$VER" "$BUILD" "$ID" "$EXE" "$ARCHS" "$KIND" "$(test "$KIND" = developer-id && echo true || echo false)" "$TEAM" "$HARDENED" "$APP_STAPLER" "$APP_STAPLER_EXIT" "$APP_SPCTL" "$APP_SPCTL_EXIT" "$DMG_SIG" "$DMG_STAPLER" "$DMG_STAPLER_EXIT" "$DMG_SPCTL" "$DMG_SPCTL_EXIT"; } >"$TMP"
mv "$TMP" "$EVIDENCE"; echo "$EVIDENCE"
