#!/bin/bash
set -euo pipefail
export LC_ALL=C LANG=C

SOURCE=$(cd "$(dirname "$0")/.." && pwd)
T=$(mktemp -d "${TMPDIR:-/tmp}/mobcrew-release-tests.XXXXXX")
trap 'rm -rf "$T"' EXIT
trap 'exit 1' HUP INT TERM

REMOTE="$T/remote.git"
WORK="$T/work"
MOCK="$T/mock"
STATE="$T/state"
GH_LOG="$T/gh.log"
mkdir "$MOCK" "$STATE"

git init -q --bare "$REMOTE"
git init -q -b main "$WORK"
mkdir "$WORK/scripts"
cp "$SOURCE/scripts/release.sh" "$WORK/scripts/"
cat >"$WORK/scripts/verify-release-artifact.sh" <<'EOF'
#!/bin/bash
set -euo pipefail
cp "$1.verification.evidence" "$3.evidence"
cp "$1.verification.log" "$3.log"
EOF
chmod +x "$WORK/scripts/verify-release-artifact.sh"
printf '24.19.0\n' >"$WORK/.nvmrc"
printf '{}\n' >"$WORK/package-lock.json"
printf 'build/\n' >"$WORK/.gitignore"
git -C "$WORK" add .
git -C "$WORK" -c user.name=test -c user.email=test@example.invalid \
  -c commit.gpgsign=false commit -qm initial
git -C "$WORK" remote add origin https://github.com/colmarius/mobcrew.git
git -C "$WORK" config url."$REMOTE".insteadOf https://github.com/colmarius/mobcrew.git
git -C "$WORK" push -qu origin main
git --git-dir="$REMOTE" symbolic-ref HEAD refs/heads/main
git -C "$WORK" branch --set-upstream-to=origin/main main >/dev/null

cat >"$MOCK/node" <<'EOF'
#!/bin/sh
echo v${MOCK_NODE:-24.19.0}
EOF
cat >"$MOCK/xcodebuild" <<'EOF'
#!/bin/sh
printf 'Xcode %s\nBuild version TEST\n' "${MOCK_XCODE:-26.6}"
EOF
cat >"$MOCK/xcrun" <<'EOF'
#!/bin/sh
echo "Apple Swift version ${MOCK_SWIFT:-6.3} (mock)"
EOF
cat >"$MOCK/gh" <<'EOF'
#!/bin/sh
set -eu
printf '%s\n' "$*" >>"${GH_LOG:?}"

read_state() { cat "${STATE:?}/$1"; }
write_live() {
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$(read_state release_id)" "$(read_state draft)" v1.2.3 "$(read_state target)" \
    "$(read_state title)" "$(read_state body)" false "$(read_state asset_count)" \
    "$(read_state asset_id)" "$(read_state asset_name)" "$(read_state asset_size)" \
    "$(read_state asset_digest)"
}

case "$1" in
  auth)
    test "$2" = status
    test "${MOCK_AUTH:-ok}" = ok
    ;;
  repo)
    test "$2" = view
    test "${MOCK_REPO:-ok}" = ok
    echo colmarius/mobcrew
    ;;
  api)
    shift
    if test "$1" = -i; then
      ENDPOINT=$2
      case "$ENDPOINT" in
        repos/colmarius/mobcrew/git/ref/tags/v1.2.3)
          test ! -f "$STATE/tag_query_error" || { echo 'HTTP 500' >&2; exit 1; }
          if test "$(read_state tag_present)" = true || test -f "$STATE/tag_conflict"; then
            echo 'HTTP/2 200'
            exit 0
          fi
          ;;
        repos/colmarius/mobcrew/releases/tags/v1.2.3)
          if test "$(read_state release_present)" = true; then
            echo 'HTTP/2 200'
            exit 0
          fi
          ;;
        *) echo "unexpected inspected endpoint: $ENDPOINT" >&2; exit 98;;
      esac
      echo 'gh: Not Found (HTTP 404)' >&2
      exit 1
    fi

    if test "$1" = --method; then
      test "$2" = PATCH
      ENDPOINT=$3
      shift 3
      test "$ENDPOINT" = "repos/colmarius/mobcrew/releases/77"
      test "$*" = "-f draft=false"
      printf 'false\n' >"$STATE/draft"
      git --git-dir="${TEST_REMOTE:?}" update-ref refs/tags/v1.2.3 "$(read_state target)"
      exit 0
    fi

    ENDPOINT=$1
    case "$ENDPOINT" in
      repos/colmarius/mobcrew)
        test "${MOCK_PUSH:-true}" = true && echo true || echo false
        ;;
      repos/colmarius/mobcrew/commits/main)
        read_state target
        ;;
      repos/colmarius/mobcrew/releases/tags/v1.2.3|repos/colmarius/mobcrew/releases/77)
        test "$(read_state release_present)" = true
        write_live
        ;;
      *) echo "unexpected API endpoint: $ENDPOINT" >&2; exit 97;;
    esac
    ;;
  release)
    case "$2" in
      create)
        test "$(read_state release_present)" = false
        printf 'true\n' >"$STATE/release_present"
        printf 'true\n' >"$STATE/draft"
        printf '0\n' >"$STATE/asset_count"
        ;;
      upload)
        test "$(read_state release_present)" = true
        cp "$4" "$STATE/server-asset"
        printf '1\n' >"$STATE/asset_count"
        printf '501\n' >"$STATE/asset_id"
        basename "$4" >"$STATE/asset_name"
        wc -c <"$4" | tr -d ' ' >"$STATE/asset_size"
        printf 'sha256:%s\n' "$(shasum -a 256 "$4" | awk '{print $1}')" >"$STATE/asset_digest"
        ;;
      download)
        shift 2
        DEST=; PATTERN=
        while test "$#" -gt 0; do
          case "$1" in
            --dir) DEST=$2; shift 2;;
            --pattern) PATTERN=$2; shift 2;;
            *) shift;;
          esac
        done
        test -n "$DEST" && test -n "$PATTERN"
        cp "$STATE/server-asset" "$DEST/$PATTERN"
        ;;
      *) echo "unexpected release command: $*" >&2; exit 96;;
    esac
    ;;
  *) echo "unexpected gh command: $*" >&2; exit 95;;
esac
EOF
chmod +x "$MOCK"/*
export PATH="$MOCK:$PATH" GH_LOG STATE TEST_REMOTE="$REMOTE"

read_state() { cat "$STATE/$1"; }

reset_state() {
  rm -f "$STATE/tag_query_error" "$STATE/tag_conflict" "$STATE/server-asset"
  printf 'false\n' >"$STATE/release_present"
  printf 'false\n' >"$STATE/tag_present"
  printf '77\n' >"$STATE/release_id"
  printf 'true\n' >"$STATE/draft"
  printf '%s\n' "$(git -C "$WORK" rev-parse HEAD)" >"$STATE/target"
  printf 'MobCrew 1.2.3\n' >"$STATE/title"
  printf 'Release v1.2.3\n' >"$STATE/body"
  printf '0\n' >"$STATE/asset_count"
  printf '\n' >"$STATE/asset_id"
  printf '\n' >"$STATE/asset_name"
  printf '\n' >"$STATE/asset_size"
  printf '\n' >"$STATE/asset_digest"
}

set_matching_asset() {
  DMG=$1
  printf 'true\n' >"$STATE/release_present"
  printf 'true\n' >"$STATE/draft"
  printf '1\n' >"$STATE/asset_count"
  printf '501\n' >"$STATE/asset_id"
  basename "$DMG" >"$STATE/asset_name"
  wc -c <"$DMG" | tr -d ' ' >"$STATE/asset_size"
  printf 'sha256:%s\n' "$(shasum -a 256 "$DMG" | awk '{print $1}')" >"$STATE/asset_digest"
  cp "$DMG" "$STATE/server-asset"
}

clear_log() { : >"$GH_LOG"; }
assert_no_mutation() { ! grep -Eq '^release (create|upload)|^api --method PATCH' "$GH_LOG"; }
run_check_ok() {
  reset_state; clear_log
  (cd "$T" && "$WORK/scripts/release.sh" check 1.2.3) >/dev/null
  test "$(command -v gh)" = "$MOCK/gh"
  grep -q '^api repos/colmarius/mobcrew --jq .permissions.push$' "$GH_LOG"
  assert_no_mutation
}
run_check_fail() {
  NAME=$1; shift
  clear_log
  if (cd "$T" && env "$@" "$WORK/scripts/release.sh" check 1.2.3) >/dev/null 2>&1; then
    echo "expected check failure: $NAME" >&2
    exit 1
  fi
  assert_no_mutation
}
run_fail() {
  NAME=$1; shift
  clear_log
  if (cd "$T" && "$@") >/dev/null 2>&1; then
    echo "expected failure: $NAME" >&2
    exit 1
  fi
}

# Preflight success and failure matrix. All GitHub calls use the mock.
run_check_ok
if (cd "$T" && "$WORK/scripts/release.sh" check 01.2.3) >/dev/null 2>&1; then
  echo 'accepted malformed SemVer' >&2
  exit 1
fi
mkdir -p "$WORK/build"; printf 'known-good\n' >"$WORK/build/known-good.dmg"
KNOWN=$(shasum -a 256 "$WORK/build/known-good.dmg" | awk '{print $1}')
echo dirty >>"$WORK/.nvmrc"; run_check_fail dirty; git -C "$WORK" checkout -q -- .
run_check_fail wrong-node MOCK_NODE=24.18.0
run_check_fail wrong-xcode MOCK_XCODE=26.5
run_check_fail wrong-swift MOCK_SWIFT=6.2
run_check_fail auth MOCK_AUTH=bad
run_check_fail repo MOCK_REPO=bad
run_check_fail push MOCK_PUSH=false
printf 'true\n' >"$STATE/release_present"; run_check_fail existing-release; reset_state
printf 'true\n' >"$STATE/tag_present"; run_check_fail remote-tag-api; reset_state
touch "$STATE/tag_query_error"; run_check_fail tag-query-error; reset_state
test "$(shasum -a 256 "$WORK/build/known-good.dmg" | awk '{print $1}')" = "$KNOWN"

git -C "$WORK" remote set-url origin https://github.com/evil/fork.git
run_check_fail wrong-origin
git -C "$WORK" remote set-url origin https://github.com/colmarius/mobcrew.git
git -C "$WORK" branch --unset-upstream
run_check_fail no-upstream
git -C "$WORK" branch --set-upstream-to=origin/main main >/dev/null
git -C "$WORK" remote add wrong "$REMOTE"
git -C "$WORK" fetch -q wrong main
git -C "$WORK" branch --set-upstream-to=wrong/main main >/dev/null
run_check_fail wrong-upstream
git -C "$WORK" branch --set-upstream-to=origin/main main >/dev/null
git -C "$WORK" checkout -qb other
run_check_fail wrong-branch
git -C "$WORK" checkout -q main

OTHER="$T/other"
git clone -q "$REMOTE" "$OTHER"
git -C "$OTHER" config user.name test
git -C "$OTHER" config user.email test@example.invalid
git -C "$OTHER" config commit.gpgsign false
echo behind >"$OTHER/behind"; git -C "$OTHER" add .; git -C "$OTHER" commit -qm behind; git -C "$OTHER" push -q origin main
run_check_fail behind
git -C "$WORK" reset -q --hard origin/main
echo local >"$WORK/local"; git -C "$WORK" add .; git -C "$WORK" \
  -c user.name=test -c user.email=test@example.invalid -c commit.gpgsign=false commit -qm local
echo remote >"$OTHER/remote"; git -C "$OTHER" add .; git -C "$OTHER" commit -qm remote; git -C "$OTHER" push -q origin main
run_check_fail diverged
git -C "$WORK" fetch -q origin; git -C "$WORK" reset -q --hard origin/main
git -C "$WORK" tag v1.2.3
run_check_fail local-tag
git -C "$WORK" tag -d v1.2.3 >/dev/null

SHALLOW="$T/shallow"
git clone -q --depth 1 --branch main "file://$REMOTE" "$SHALLOW"
git -C "$SHALLOW" remote set-url origin https://github.com/colmarius/mobcrew.git
git -C "$SHALLOW" config url."$REMOTE".insteadOf https://github.com/colmarius/mobcrew.git
clear_log
if (cd "$T" && "$SHALLOW/scripts/release.sh" check 1.2.3) >/dev/null 2>&1; then
  echo 'accepted shallow release checkout' >&2
  exit 1
fi
assert_no_mutation

# Seed an internally consistent fake prepared artifact and evidence chain.
git -C "$WORK" reset -q --hard origin/main
reset_state
TARGET=$(git -C "$WORK" rev-parse HEAD)
printf '%s\n' "$TARGET" >"$STATE/target"
DMG="$WORK/build/MobCrew-1.2.3.dmg"
printf 'fake DMG bytes for offline state tests\n' >"$DMG"
cat >"$DMG.verification.evidence" <<'EOF'
schema=mobcrew-artifact-v1
version=1.2.3
build=42
bundle_id=com.colmarius.MobCrew
executable=MobCrew
architectures=arm64 x86_64
app_signature_kind=adhoc
developer_id=false
team=none
hardened_runtime=false
app_stapler=not-accepted
app_stapler_exit=65
app_spctl=not-accepted
app_spctl_exit=3
dmg_signature=unsigned
dmg_stapler=not-accepted
dmg_stapler_exit=65
dmg_spctl=not-accepted
dmg_spctl_exit=3
EOF
printf 'raw inspection log\n' >"$DMG.verification.log"
DMG_SIZE=$(wc -c <"$DMG" | tr -d ' ')
DMG_SHA=$(shasum -a 256 "$DMG" | awk '{print $1}')
LOCK_SHA=$(shasum -a 256 "$WORK/package-lock.json" | awk '{print $1}')
EVIDENCE_SHA=$(shasum -a 256 "$DMG.verification.evidence" | awk '{print $1}')
LOG_SHA=$(shasum -a 256 "$DMG.verification.log" | awk '{print $1}')
MANIFEST="$WORK/build/MobCrew-1.2.3.manifest"
cat >"$MANIFEST" <<EOF
schema=mobcrew-release-v1
repository=colmarius/mobcrew
version=1.2.3
tag=v1.2.3
target_sha=$TARGET
artifact_name=MobCrew-1.2.3.dmg
artifact_size=$DMG_SIZE
artifact_sha256=$DMG_SHA
bundle_id=com.colmarius.MobCrew
bundle_version=1.2.3
bundle_build=42
architectures=arm64 x86_64
xcode_version=Xcode 26.6 Build version TEST
swift_version=Apple Swift version 6.3 (mock)
node_version=v24.19.0
package_lock_sha256=$LOCK_SHA
verification_evidence_sha256=$EVIDENCE_SHA
verification_log_sha256=$LOG_SHA
EOF

# Absent -> create metadata -> upload -> read back. Re-running never clobbers.
clear_log
(cd "$T" && "$WORK/scripts/release.sh" create-draft 1.2.3) >/dev/null
grep -Fq "release create v1.2.3 --repo colmarius/mobcrew --draft --target $TARGET" "$GH_LOG"
grep -q '^release upload v1.2.3 .* --repo colmarius/mobcrew$' "$GH_LOG"
test "$(read_state asset_count)" = 1
clear_log
(cd "$T" && "$WORK/scripts/release.sh" create-draft 1.2.3) >/dev/null
assert_no_mutation

# A matching partial draft resumes upload; conflicting remote state never mutates.
printf '0\n' >"$STATE/asset_count"; printf '\n' >"$STATE/asset_id"; printf '\n' >"$STATE/asset_name"; printf '\n' >"$STATE/asset_size"; printf '\n' >"$STATE/asset_digest"
clear_log
(cd "$T" && "$WORK/scripts/release.sh" create-draft 1.2.3) >/dev/null
grep -q '^release upload ' "$GH_LOG"

set_matching_asset "$DMG"; printf 'Wrong title\n' >"$STATE/title"
run_fail conflicting-title "$WORK/scripts/release.sh" create-draft 1.2.3; assert_no_mutation
printf 'MobCrew 1.2.3\n' >"$STATE/title"; printf 'wrong body\n' >"$STATE/body"
run_fail conflicting-body "$WORK/scripts/release.sh" create-draft 1.2.3; assert_no_mutation
printf 'Release v1.2.3\n' >"$STATE/body"; printf '%040d\n' 0 >"$STATE/target"
run_fail conflicting-target "$WORK/scripts/release.sh" create-draft 1.2.3; assert_no_mutation
printf '%s\n' "$TARGET" >"$STATE/target"; printf 'false\n' >"$STATE/draft"
run_fail published-state "$WORK/scripts/release.sh" create-draft 1.2.3; assert_no_mutation
printf 'true\n' >"$STATE/draft"; printf '2\n' >"$STATE/asset_count"
run_fail extra-assets "$WORK/scripts/release.sh" create-draft 1.2.3; assert_no_mutation
printf '1\n' >"$STATE/asset_count"; printf 'other.dmg\n' >"$STATE/asset_name"
run_fail wrong-asset "$WORK/scripts/release.sh" create-draft 1.2.3; assert_no_mutation
set_matching_asset "$DMG"; printf 'sha256:%064d\n' 0 >"$STATE/asset_digest"
run_fail wrong-api-digest "$WORK/scripts/release.sh" create-draft 1.2.3; assert_no_mutation
set_matching_asset "$DMG"

clear_log
(cd "$T" && "$WORK/scripts/release.sh" status 1.2.3) >/dev/null
assert_no_mutation

# Draft verification downloads the exact asset and writes strict remote evidence.
clear_log
(cd "$T" && "$WORK/scripts/release.sh" verify-draft 1.2.3) >/dev/null
REMOTE_EVIDENCE="$WORK/build/MobCrew-1.2.3.remote-evidence"
test -f "$REMOTE_EVIDENCE"
grep -q '^repository=colmarius/mobcrew$' "$REMOTE_EVIDENCE"
grep -q "^downloaded_sha256=$DMG_SHA$" "$REMOTE_EVIDENCE"
SAVED_MANIFEST="$T/manifest.saved"; cp "$MANIFEST" "$SAVED_MANIFEST"
SAVED_REMOTE="$T/remote.saved"; cp "$REMOTE_EVIDENCE" "$SAVED_REMOTE"

printf 'unknown=value\n' >>"$MANIFEST"
run_fail unknown-manifest-key "$WORK/scripts/release.sh" verify-draft 1.2.3; assert_no_mutation
cp "$SAVED_MANIFEST" "$MANIFEST"; cat "$SAVED_MANIFEST" >>"$MANIFEST"
run_fail duplicate-manifest "$WORK/scripts/release.sh" verify-draft 1.2.3; assert_no_mutation
cp "$SAVED_MANIFEST" "$MANIFEST"; cp "$DMG" "$T/dmg.saved"; printf 'mutation\n' >>"$DMG"
run_fail mutated-artifact "$WORK/scripts/release.sh" verify-draft 1.2.3; assert_no_mutation
cp "$T/dmg.saved" "$DMG"

write_qualification() {
  Q=$1
  cat >"$Q" <<EOF
schema=mobcrew-qualification-v1
manifest_sha256=$(shasum -a 256 "$MANIFEST" | awk '{print $1}')
remote_evidence_sha256=$(shasum -a 256 "$REMOTE_EVIDENCE" | awk '{print $1}')
artifact_integrity=tested
gatekeeper_first_launch=tested
core_regression=tested
permissions=tested
upgrade=tested
release_notes=tested
publication_approved=tested
EOF
}
QUAL="$T/qualification.txt"
write_qualification "$QUAL"
printf 'unknown=value\n' >>"$REMOTE_EVIDENCE"
run_fail unknown-remote-key "$WORK/scripts/release.sh" publish 1.2.3 "$QUAL"; assert_no_mutation
cp "$SAVED_REMOTE" "$REMOTE_EVIDENCE"; write_qualification "$QUAL"; printf 'unknown=value\n' >>"$QUAL"
run_fail unknown-qualification-key "$WORK/scripts/release.sh" publish 1.2.3 "$QUAL"; assert_no_mutation
write_qualification "$QUAL"; sed 's/publication_approved=tested/publication_approved=unverified/' "$QUAL" >"$QUAL.tmp"; mv "$QUAL.tmp" "$QUAL"
run_fail unapproved-qualification "$WORK/scripts/release.sh" publish 1.2.3 "$QUAL"; assert_no_mutation
write_qualification "$QUAL"

publish_with_tty() {
  if test "$(uname -s)" = Darwin; then
    printf 'v1.2.3\n' | script -q /dev/null "$WORK/scripts/release.sh" publish 1.2.3 "$QUAL"
  else
    printf 'v1.2.3\n' | script -qefc "'$WORK/scripts/release.sh' publish 1.2.3 '$QUAL'" /dev/null
  fi
}

# A canonical tag appearing after confirmation blocks PATCH. A matching state publishes by numeric ID only.
touch "$STATE/tag_conflict"; clear_log
if publish_with_tty >/dev/null 2>&1; then
  echo 'published despite final tag conflict' >&2
  exit 1
fi
assert_no_mutation
rm "$STATE/tag_conflict"; clear_log
publish_with_tty >/dev/null
grep -q '^api --method PATCH repos/colmarius/mobcrew/releases/77 -f draft=false$' "$GH_LOG"
test "$(read_state draft)" = false

if grep -Eq 'release delete|--clobber|git/ref.*--method (POST|PATCH|DELETE)' "$GH_LOG"; then
  echo 'destructive or clobbering GitHub command observed' >&2
  exit 1
fi
test "$(command -v gh)" = "$MOCK/gh"

echo "release hardening tests passed (offline mock gh: $MOCK/gh)"
