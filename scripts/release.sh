#!/bin/bash
set -euo pipefail
export LC_ALL=C LANG=C
ROOT=$(cd "$(dirname "$0")/.." && pwd); REPO=colmarius/mobcrew; REMOTE=https://github.com/colmarius/mobcrew.git
OP=${1:-}; VERSION=${2:-}; TAG=v$VERSION; TITLE="MobCrew $VERSION"; BODY="Release $TAG"
DIR="$ROOT/build"; DMG="$DIR/MobCrew-$VERSION.dmg"; MANIFEST="$DIR/MobCrew-$VERSION.manifest"; REMOTE_EVIDENCE="$DIR/MobCrew-$VERSION.remote-evidence"
die() { echo "release: $*" >&2; exit 1; }
semver() { echo "$VERSION" | grep -Eq '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$' || die "VERSION must be strict MAJOR.MINOR.PATCH"; }
sha() { shasum -a 256 "$1" | awk '{print $1}'; }
size() { wc -c <"$1" | tr -d ' '; }
kv() { sed -n "s/^$2=//p" "$1"; }
hex40() { printf '%s\n' "$1" | grep -Eq '^[0-9a-f]{40}$'; }
hex64() { printf '%s\n' "$1" | grep -Eq '^[0-9a-f]{64}$'; }
positive() { printf '%s\n' "$1" | grep -Eq '^[1-9][0-9]*$'; }
nonnegative() { printf '%s\n' "$1" | grep -Eq '^(0|[1-9][0-9]*)$'; }
strict() { FILE=$1; KEYS=$2; test -f "$FILE" || die "missing $FILE"; while IFS= read -r L || [ -n "$L" ]; do case "$L" in *$'\r'*|*$'\t'*) die "control character in $FILE";; *=*) K=${L%%=*};; *) die "line without = in $FILE";; esac; printf '%s\n' "$K" | grep -Eq '^[a-z][a-z0-9_]*$' || die "invalid key in $FILE"; printf '%s\n' "$KEYS" | grep -qx "$K" || die "unknown key $K in $FILE"; done <"$FILE"; printf '%s\n' "$KEYS" | while IFS= read -r K; do test "$(grep -c "^$K=" "$FILE" || true)" = 1 || die "missing or duplicate $K in $FILE"; done; }
MANIFEST_KEYS='schema
repository
version
tag
target_sha
artifact_name
artifact_size
artifact_sha256
bundle_id
bundle_version
bundle_build
architectures
xcode_version
swift_version
node_version
package_lock_sha256
verification_evidence_sha256
verification_log_sha256'
ARTIFACT_KEYS='schema
version
build
bundle_id
executable
architectures
app_signature_kind
developer_id
team
hardened_runtime
app_stapler
app_stapler_exit
app_spctl
app_spctl_exit
dmg_signature
dmg_stapler
dmg_stapler_exit
dmg_spctl
dmg_spctl_exit'
REMOTE_KEYS='schema
repository
manifest_sha256
release_id
asset_id
tag
target_sha
title
body_sha256
asset_name
asset_size
api_digest
downloaded_sha256'
QUAL_KEYS='schema
manifest_sha256
remote_evidence_sha256
artifact_integrity
gatekeeper_first_launch
core_regression
permissions
upgrade
release_notes
publication_approved'
api_absent() { TMP=$(mktemp "${TMPDIR:-/tmp}/mobcrew-gh.XXXXXX"); if gh api -i "$1" >"$TMP" 2>&1; then rm "$TMP"; return 1; fi; grep -Eq 'HTTP 404|HTTP/2 404|HTTP/[0-9.]+ 404' "$TMP" && { rm "$TMP"; return 0; }; cat "$TMP" >&2; rm "$TMP"; return 2; }
published_release_http() { api_absent "repos/$REPO/releases/tags/$TAG" && return 4; RC=$?; test "$RC" = 1 && return 0; return 1; }
matching_draft_id() {
  IDS=$(gh api --paginate "repos/$REPO/releases?per_page=100" --jq '.[] | select(.draft == true and .tag_name == "'"$TAG"'") | .id') || die "draft lookup failed"
  COUNT=$(printf '%s\n' "$IDS" | sed '/^$/d' | wc -l | tr -d ' ')
  case "$COUNT" in
    0) return 4;;
    1) RID=$(printf '%s\n' "$IDS" | sed '/^$/d'); positive "$RID" || die "invalid draft release ID"; printf '%s\n' "$RID";;
    *) die "multiple drafts exist for $TAG; resolve manually";;
  esac
}
remote_tag_absent() { api_absent "repos/$REPO/git/ref/tags/$TAG" && return 0; RC=$?; test "$RC" = 1 && die "remote tag exists: $TAG"; die "remote tag query failed"; }
context() { MUT=${1:-false}; test "$(git -C "$ROOT" config --get remote.origin.url)" = "$REMOTE" || die "stored origin URL must be $REMOTE"; gh auth status >/dev/null 2>&1 || die "gh authentication failed"; test "$(gh repo view "$REPO" --json nameWithOwner --jq .nameWithOwner)" = "$REPO" || die "gh repository mismatch"; test "$MUT" != true || test "$(gh api "repos/$REPO" --jq .permissions.push)" = true || die "GitHub push permission required"; }
preflight() {
  ALLOW_DRAFT=${1:-false}
  semver; command -v gh >/dev/null; command -v node >/dev/null; command -v xcodebuild >/dev/null; command -v xcrun >/dev/null
  context true
  test "$(git -C "$ROOT" branch --show-current)" = main || die "branch must be main"
  test "$(git -C "$ROOT" rev-parse --abbrev-ref '@{upstream}')" = origin/main || die "upstream must be origin/main"
  test -z "$(git -C "$ROOT" status --porcelain)" || die "worktree is dirty"
  test "$(git -C "$ROOT" rev-parse --is-shallow-repository)" = false || die "history is shallow"
  git -C "$ROOT" fetch --quiet origin main --tags
  HEAD=$(git -C "$ROOT" rev-parse HEAD); test "$HEAD" = "$(git -C "$ROOT" rev-parse origin/main)" || die "HEAD must exactly equal freshly fetched origin/main"
  CANONICAL_MAIN=$(gh api "repos/$REPO/commits/main" --jq .sha); hex40 "$CANONICAL_MAIN" || die "invalid canonical main SHA"; test "$HEAD" = "$CANONICAL_MAIN" || die "HEAD must equal canonical GitHub main"
  test "$(git -C "$ROOT" tag -l "$TAG")" = "" || die "local tag exists: $TAG"; remote_tag_absent
  test "$(xcodebuild -version | sed -n '1p')" = 'Xcode 26.6' || die "Xcode must be exactly 26.6"
  xcrun swift --version | grep -q 'Swift version 6.3' || die "Swift must be exactly 6.3"
  test "$(node --version)" = "v$(cat "$ROOT/.nvmrc")" || die "Node must match .nvmrc"
  if published_release_http >/dev/null; then die "published release already exists: $TAG"; else RC=$?; test "$RC" = 4 || die "published release lookup failed"; fi
  if RID=$(matching_draft_id); then test "$ALLOW_DRAFT" = true || die "draft release already exists: $TAG (ID $RID)"; else RC=$?; test "$RC" = 4 || die "draft lookup failed"; fi
}
validate_artifact_evidence() {
  E=$1; strict "$E" "$ARTIFACT_KEYS"
  test "$(kv "$E" schema)" = mobcrew-artifact-v1 || die "invalid artifact evidence schema"
  test "$(kv "$E" version)" = "$VERSION" || die "artifact evidence version mismatch"
  positive "$(kv "$E" build)" || die "invalid artifact build"
  test "$(kv "$E" bundle_id)" = com.colmarius.MobCrew || die "artifact bundle ID mismatch"
  test -n "$(kv "$E" executable)" || die "missing artifact executable"
  test -n "$(kv "$E" architectures)" || die "missing artifact architectures"
  case "$(kv "$E" app_signature_kind)" in developer-id|adhoc|other) :;; *) die "invalid app signature kind";; esac
  case "$(kv "$E" developer_id)" in true|false) :;; *) die "invalid Developer ID state";; esac
  if test "$(kv "$E" app_signature_kind)" = developer-id; then test "$(kv "$E" developer_id)" = true || die "inconsistent Developer ID state"; else test "$(kv "$E" developer_id)" = false || die "inconsistent Developer ID state"; fi
  case "$(kv "$E" hardened_runtime)" in true|false) :;; *) die "invalid hardened runtime state";; esac
  for K in app_stapler app_spctl dmg_stapler dmg_spctl; do case "$(kv "$E" "$K")" in accepted|not-accepted) :;; *) die "invalid $K state";; esac; done
  for K in app_stapler_exit app_spctl_exit dmg_stapler_exit dmg_spctl_exit; do nonnegative "$(kv "$E" "$K")" || die "invalid $K"; done
  case "$(kv "$E" dmg_signature)" in valid-signature|unsigned) :;; *) die "invalid DMG signature state";; esac
}
validate_manifest() {
  M=${1:-$MANIFEST}; E="$DMG.verification.evidence"
  strict "$M" "$MANIFEST_KEYS"; test "$(kv "$M" schema)" = mobcrew-release-v1 || die "invalid manifest schema"; test "$(kv "$M" repository)" = "$REPO" || die "manifest repository mismatch"; test "$(kv "$M" version)" = "$VERSION" || die "manifest version mismatch"; test "$(kv "$M" tag)" = "$TAG" || die "manifest tag mismatch"
  hex40 "$(kv "$M" target_sha)" || die "invalid target SHA"; validate_artifact_evidence "$E"
  test "$(kv "$M" artifact_name)" = "MobCrew-$VERSION.dmg" || die "artifact name mismatch"; test "$(kv "$M" artifact_size)" = "$(size "$DMG")" || die "artifact size changed"; test "$(kv "$M" artifact_sha256)" = "$(sha "$DMG")" || die "artifact changed"
  nonnegative "$(kv "$M" artifact_size)" || die "invalid artifact size"; hex64 "$(kv "$M" artifact_sha256)" || die "invalid artifact digest"; positive "$(kv "$M" bundle_build)" || die "invalid bundle build"
  test "$(kv "$M" bundle_id)" = "$(kv "$E" bundle_id)" || die "bundle ID evidence mismatch"; test "$(kv "$M" bundle_version)" = "$(kv "$E" version)" || die "bundle version evidence mismatch"; test "$(kv "$M" bundle_build)" = "$(kv "$E" build)" || die "bundle build evidence mismatch"; test "$(kv "$M" architectures)" = "$(kv "$E" architectures)" || die "architecture evidence mismatch"; test "$(kv "$M" bundle_id)" = com.colmarius.MobCrew || die "bundle ID mismatch"; test "$(kv "$M" node_version)" = "v$(cat "$ROOT/.nvmrc")" || die "manifest Node mismatch"
  case "$(kv "$M" xcode_version)" in 'Xcode 26.6 Build version '*) :;; *) die "manifest Xcode mismatch";; esac
  case "$(kv "$M" swift_version)" in 'Apple Swift version 6.3 '*|'Swift version 6.3 '*) :;; *) die "manifest Swift mismatch";; esac
  for K in package_lock_sha256 verification_evidence_sha256 verification_log_sha256; do hex64 "$(kv "$M" "$K")" || die "invalid $K"; done
  test "$(kv "$M" package_lock_sha256)" = "$(sha "$ROOT/package-lock.json")" || die "lockfile changed"
  test "$(kv "$M" verification_evidence_sha256)" = "$(sha "$E")" || die "evidence changed"
  test "$(kv "$M" verification_log_sha256)" = "$(sha "$DMG.verification.log")" || die "inspection log changed"
}
validate_remote_evidence() {
  R=${1:-$REMOTE_EVIDENCE}; strict "$R" "$REMOTE_KEYS"
  test "$(kv "$R" schema)" = mobcrew-remote-v1 || die "invalid remote evidence schema"
  test "$(kv "$R" repository)" = "$REPO" || die "remote evidence repository mismatch"
  hex64 "$(kv "$R" manifest_sha256)" || die "invalid manifest digest in remote evidence"
  test "$(kv "$R" manifest_sha256)" = "$(sha "$MANIFEST")" || die "remote evidence manifest mismatch"
  positive "$(kv "$R" release_id)" || die "invalid release ID"; positive "$(kv "$R" asset_id)" || die "invalid asset ID"
  test "$(kv "$R" tag)" = "$TAG" || die "remote evidence tag mismatch"; test "$(kv "$R" target_sha)" = "$(kv "$MANIFEST" target_sha)" || die "remote evidence target mismatch"; hex40 "$(kv "$R" target_sha)" || die "invalid remote target SHA"
  test "$(kv "$R" title)" = "$TITLE" || die "remote evidence title mismatch"; hex64 "$(kv "$R" body_sha256)" || die "invalid body digest"; test "$(kv "$R" body_sha256)" = "$(printf '%s\n' "$BODY" | shasum -a 256 | awk '{print $1}')" || die "remote evidence body mismatch"
  test "$(kv "$R" asset_name)" = "$(kv "$MANIFEST" artifact_name)" || die "remote asset name mismatch"; nonnegative "$(kv "$R" asset_size)" || die "invalid remote asset size"; test "$(kv "$R" asset_size)" = "$(kv "$MANIFEST" artifact_size)" || die "remote asset size mismatch"
  hex64 "$(kv "$R" downloaded_sha256)" || die "invalid downloaded digest"; test "$(kv "$R" downloaded_sha256)" = "$(kv "$MANIFEST" artifact_sha256)" || die "downloaded digest mismatch"
  test "$(kv "$R" api_digest)" = unavailable || test "$(kv "$R" api_digest)" = "sha256:$(kv "$MANIFEST" artifact_sha256)" || die "API digest mismatch"
}
live_id_fields() { gh api "repos/$REPO/releases/$1" --jq '[.id,.draft,.tag_name,.target_commitish,.name,(.body//""),(.prerelease|tostring),(.assets|length),(.assets[0].id//""),(.assets[0].name//""),(.assets[0].size//""),(.assets[0].digest//"")]|@tsv'; }
case "$OP" in
 check) test "$#" = 2 || die "usage: $0 check VERSION"; preflight; echo "preflight passed for $TAG";;
 prepare) test "$#" = 2 || die "usage: $0 prepare VERSION"; preflight; npm ci --no-audit --no-fund --prefix "$ROOT"; "$ROOT/scripts/test.sh"; "$ROOT/scripts/build-release.sh" "$VERSION"; "$ROOT/scripts/create-dmg.sh" "$VERSION"; E="$DMG.verification.evidence"; TMP="$MANIFEST.tmp.$$"; { printf 'schema=mobcrew-release-v1\nrepository=%s\nversion=%s\ntag=%s\ntarget_sha=%s\nartifact_name=%s\nartifact_size=%s\nartifact_sha256=%s\nbundle_id=%s\nbundle_version=%s\nbundle_build=%s\narchitectures=%s\nxcode_version=%s\nswift_version=%s\nnode_version=%s\npackage_lock_sha256=%s\nverification_evidence_sha256=%s\nverification_log_sha256=%s\n' "$REPO" "$VERSION" "$TAG" "$HEAD" "$(basename "$DMG")" "$(size "$DMG")" "$(sha "$DMG")" "$(kv "$E" bundle_id)" "$(kv "$E" version)" "$(kv "$E" build)" "$(kv "$E" architectures)" "$(xcodebuild -version | tr '\n' ' ')" "$(xcrun swift --version | head -1)" "$(node --version)" "$(sha "$ROOT/package-lock.json")" "$(sha "$E")" "$(sha "$DMG.verification.log")"; } >"$TMP"; validate_manifest "$TMP"; mv "$TMP" "$MANIFEST"; echo "$MANIFEST";;
 create-draft) test "$#" = 2 || die "usage: $0 create-draft VERSION"; preflight true; validate_manifest; test "$(kv "$MANIFEST" target_sha)" = "$HEAD" || die "manifest target is not current origin/main"; "$ROOT/scripts/verify-release-artifact.sh" "$DMG" "$VERSION" "$DIR/.draft-verification" >/dev/null; test "$(sha "$DIR/.draft-verification.evidence")" = "$(sha "$DMG.verification.evidence")" || die "material verification differs; rerun prepare before retrying"; remote_tag_absent; if RID=$(matching_draft_id); then :; else RC=$?; test "$RC" = 4 || die "draft lookup failed"; RID=$(gh api --method POST "repos/$REPO/releases" -f tag_name="$TAG" -f target_commitish="$(kv "$MANIFEST" target_sha)" -f name="$TITLE" -f body="$BODY" -F draft=true -F prerelease=false --jq .id); positive "$RID" || die "invalid created draft ID"; DISCOVERED=$(matching_draft_id) || die "created draft cannot be rediscovered"; test "$DISCOVERED" = "$RID" || die "created draft identity is ambiguous"; fi; IFS="$(printf '\t')" read -r LIVE_ID DRAFT RTAG TARGET RTITLE RBODY PRE COUNT AID ANAME ASIZE DIGEST <<EOF
$(live_id_fields "$RID")
EOF
  test "$LIVE_ID" = "$RID" || die "draft numeric identity changed"; test "$DRAFT|$RTAG|$TARGET|$RTITLE|$PRE" = "true|$TAG|$(kv "$MANIFEST" target_sha)|$TITLE|false" || die "conflicting draft metadata"; test "$(printf '%s\n' "$RBODY" | shasum -a 256 | awk '{print $1}')" = "$(printf '%s\n' "$BODY" | shasum -a 256 | awk '{print $1}')" || die "body mismatch"; case "$COUNT" in 0) UPLOADED_AID=$(gh api --method POST "https://uploads.github.com/repos/$REPO/releases/$RID/assets?name=$(basename "$DMG")" -H 'Content-Type: application/octet-stream' --input "$DMG" --jq .id); positive "$UPLOADED_AID" || die "invalid uploaded asset ID"; IFS="$(printf '\t')" read -r POST_ID POST_DRAFT POST_TAG POST_TARGET POST_TITLE POST_BODY POST_PRE POST_COUNT POST_AID POST_NAME POST_SIZE POST_DIGEST <<EOF
$(live_id_fields "$RID")
EOF
    test "$POST_ID|$POST_DRAFT|$POST_TAG|$POST_TARGET|$POST_TITLE|$POST_PRE|$POST_COUNT|$POST_AID|$POST_NAME|$POST_SIZE" = "$RID|true|$TAG|$(kv "$MANIFEST" target_sha)|$TITLE|false|1|$UPLOADED_AID|$(basename "$DMG")|$(size "$DMG")" || die "draft state changed during upload"; test "$(printf '%s\n' "$POST_BODY" | shasum -a 256 | awk '{print $1}')" = "$(printf '%s\n' "$BODY" | shasum -a 256 | awk '{print $1}')" || die "draft body changed during upload"; test -z "$POST_DIGEST" || test "$POST_DIGEST" = "sha256:$(sha "$DMG")" || die "uploaded API digest mismatch"; echo "draft upload matches; run verify-draft";; 1) positive "$AID" || die "invalid asset ID"; test "$ANAME" = "$(basename "$DMG")" && test "$ASIZE" = "$(size "$DMG")" || die "conflicting asset"; test -z "$DIGEST" || test "$DIGEST" = "sha256:$(sha "$DMG")" || die "conflicting asset digest"; echo "matching asset exists; run verify-draft";; *) die "extra assets present";; esac;;
 status) semver; context false; if RID=$(matching_draft_id); then gh api "repos/$REPO/releases/$RID" --jq '{id,draft,tag_name,target_commitish,name,prerelease,assets:[.assets[]|{id,name,size,digest}]}'; else RC=$?; test "$RC" = 4 || die "draft lookup failed"; gh api "repos/$REPO/releases/tags/$TAG" --jq '{id,draft,tag_name,target_commitish,name,prerelease,assets:[.assets[]|{id,name,size,digest}]}'; fi;;
 verify-draft) semver; context false; validate_manifest; RID=$(matching_draft_id) || { RC=$?; test "$RC" = 4 && die "draft does not exist: $TAG"; die "draft lookup failed"; }; IFS="$(printf '\t')" read -r LIVE_ID DRAFT RTAG TARGET RTITLE RBODY PRE COUNT AID ANAME ASIZE DIGEST <<EOF
$(live_id_fields "$RID")
EOF
  test "$LIVE_ID" = "$RID" || die "draft numeric identity changed"; test "$DRAFT|$RTAG|$TARGET|$RTITLE|$PRE|$COUNT|$ANAME|$ASIZE" = "true|$TAG|$(kv "$MANIFEST" target_sha)|$TITLE|false|1|$(basename "$DMG")|$(size "$DMG")" || die "draft does not match"; positive "$AID"; T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; gh release download "$TAG" --repo "$REPO" --pattern "$(basename "$DMG")" --dir "$T"; DOWN=$(sha "$T/$(basename "$DMG")"); test "$DOWN" = "$(sha "$DMG")" || die "download digest mismatch"; test -z "$DIGEST" || test "$DIGEST" = "sha256:$DOWN" || die "API digest mismatch"; TMP="$REMOTE_EVIDENCE.tmp.$$"; printf 'schema=mobcrew-remote-v1\nrepository=%s\nmanifest_sha256=%s\nrelease_id=%s\nasset_id=%s\ntag=%s\ntarget_sha=%s\ntitle=%s\nbody_sha256=%s\nasset_name=%s\nasset_size=%s\napi_digest=%s\ndownloaded_sha256=%s\n' "$REPO" "$(sha "$MANIFEST")" "$RID" "$AID" "$TAG" "$TARGET" "$TITLE" "$(printf '%s\n' "$RBODY" | shasum -a 256 | awk '{print $1}')" "$ANAME" "$ASIZE" "${DIGEST:-unavailable}" "$DOWN" >"$TMP"; validate_remote_evidence "$TMP"; mv "$TMP" "$REMOTE_EVIDENCE"; echo "$REMOTE_EVIDENCE";;
 publish) test "$#" = 3 || die "usage: $0 publish VERSION QUALIFICATION_FILE"; Q=$3; semver; context true; validate_manifest; validate_remote_evidence; strict "$Q" "$QUAL_KEYS"; test "$(kv "$Q" schema)" = mobcrew-qualification-v1 || die "invalid qualification schema"; test "$(kv "$Q" manifest_sha256)" = "$(sha "$MANIFEST")" || die "qualification manifest mismatch"; test "$(kv "$Q" remote_evidence_sha256)" = "$(sha "$REMOTE_EVIDENCE")" || die "qualification remote evidence mismatch"; for K in manifest_sha256 remote_evidence_sha256; do hex64 "$(kv "$Q" "$K")" || die "invalid qualification hash"; done; for K in artifact_integrity gatekeeper_first_launch core_regression permissions upgrade release_notes publication_approved; do test "$(kv "$Q" "$K")" = tested || die "$K must be tested/approved"; done; test -r /dev/tty && test -w /dev/tty || die "real TTY required"; printf 'Type %s to publish: ' "$TAG" >/dev/tty; IFS= read -r ANSWER </dev/tty; test "$ANSWER" = "$TAG" || die "confirmation mismatch"; RID=$(kv "$REMOTE_EVIDENCE" release_id); IFS="$(printf '\t')" read -r LIVE_ID DRAFT RTAG TARGET RTITLE RBODY PRE COUNT AID ANAME ASIZE DIGEST <<EOF
$(live_id_fields "$RID")
EOF
  test "$LIVE_ID" = "$RID" && test "$AID" = "$(kv "$REMOTE_EVIDENCE" asset_id)" || die "live numeric identity changed"; test "$DRAFT|$RTAG|$TARGET|$RTITLE|$PRE|$COUNT|$ANAME|$ASIZE" = "true|$(kv "$REMOTE_EVIDENCE" tag)|$(kv "$REMOTE_EVIDENCE" target_sha)|$(kv "$REMOTE_EVIDENCE" title)|false|1|$(kv "$REMOTE_EVIDENCE" asset_name)|$(kv "$REMOTE_EVIDENCE" asset_size)" || die "live release state changed"; test "$(printf '%s\n' "$RBODY" | shasum -a 256 | awk '{print $1}')" = "$(kv "$REMOTE_EVIDENCE" body_sha256)" || die "live body changed"; test "$(kv "$REMOTE_EVIDENCE" api_digest)" = unavailable || test "$DIGEST" = "$(kv "$REMOTE_EVIDENCE" api_digest)" || die "live API digest changed"; T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; gh release download "$TAG" --repo "$REPO" --pattern "$ANAME" --dir "$T"; test "$(sha "$T/$ANAME")" = "$(kv "$MANIFEST" artifact_sha256)" || die "live asset changed"; remote_tag_absent; gh api --method PATCH "repos/$REPO/releases/$RID" -f draft=false >/dev/null; IFS="$(printf '\t')" read -r POST_ID POST_DRAFT POST_TAG POST_TARGET POST_TITLE POST_BODY POST_PRE POST_COUNT POST_AID POST_NAME POST_SIZE POST_DIGEST <<EOF
$(live_id_fields "$RID")
EOF
  test "$POST_ID|$POST_DRAFT|$POST_TAG|$POST_TARGET|$POST_TITLE|$POST_PRE|$POST_COUNT|$POST_AID|$POST_NAME|$POST_SIZE|$POST_DIGEST" = "$LIVE_ID|false|$RTAG|$TARGET|$RTITLE|$PRE|$COUNT|$AID|$ANAME|$ASIZE|$DIGEST" || die "post-publish metadata changed"; test "$(printf '%s\n' "$POST_BODY" | shasum -a 256 | awk '{print $1}')" = "$(kv "$REMOTE_EVIDENCE" body_sha256)" || die "post-publish body changed"; git -C "$ROOT" fetch --quiet "$REMOTE" "refs/tags/$TAG:refs/tags/$TAG"; test "$(git -C "$ROOT" rev-parse "$TAG^{commit}")" = "$(kv "$MANIFEST" target_sha)" || die "published tag mismatch; stop for manual recovery";;
 *) die "usage: $0 {check|prepare|create-draft|status|verify-draft|publish} VERSION [QUALIFICATION_FILE]";;
esac
