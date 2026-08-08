#!/bin/bash
set -euo pipefail
export LC_ALL=C LANG=C
ROOT=$(cd "$(dirname "$0")/.." && pwd); VERSION=${1:-}
echo "$VERSION" | grep -Eq '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$' || { echo "usage: $0 MAJOR.MINOR.PATCH" >&2; exit 2; }
test "$(node --version)" = "v$(cat "$ROOT/.nvmrc")" || { echo "Node must match .nvmrc" >&2; exit 1; }
test -x "$ROOT/node_modules/.bin/create-dmg" || { echo "run npm ci from repository root" >&2; exit 1; }
APP="$ROOT/build/Release/MobCrew.app"; test -d "$APP"
DIR=$(mktemp -d "$ROOT/build/.dmg-candidate.XXXXXX"); trap 'rm -rf "$DIR"' EXIT; trap 'exit 1' HUP INT TERM
(cd "$ROOT" && "$ROOT/node_modules/.bin/create-dmg" --overwrite --no-code-sign "$APP" "$DIR")
set -- "$DIR"/*.dmg; test "$#" -eq 1 && test -f "$1" || { echo "expected exactly one candidate DMG" >&2; exit 1; }
CANDIDATE=$1; PREFIX="$DIR/verification"
hdiutil verify "$CANDIDATE"
"$ROOT/scripts/verify-release-artifact.sh" "$CANDIDATE" "$VERSION" "$PREFIX"
OUT="$ROOT/build/MobCrew-$VERSION.dmg"; mv "$CANDIDATE" "$OUT"
mv "$PREFIX.evidence" "$OUT.verification.evidence"; mv "$PREFIX.log" "$OUT.verification.log"
shasum -a 256 "$OUT" >"$OUT.sha256"; wc -c <"$OUT" | tr -d ' ' >"$OUT.size"
echo "created=$OUT (the DMG replacement is atomic; companion evidence files are not a multi-file transaction)"
