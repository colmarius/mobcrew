# Releasing MobCrew

This process creates a draft, qualifies the exact uploaded DMG, and then publishes that same draft.
Creating, publishing, deleting, or retagging a GitHub release changes shared state and requires
explicit owner approval.

## Prerequisites

1. **GitHub CLI**: `brew install gh && gh auth login`
2. **Node.js 24+**: run `nvm install && nvm use` to select the exact 24.19.0 version in
   [`.nvmrc`](../.nvmrc), or `brew install node`
3. The full **Xcode 26.6+ application** with the Swift 6.3 compiler selected through `xcode-select`
4. A supported Mac for building and a clean supported macOS account or Mac for first-launch checks

CI uses the exact Node.js 24.19.0 pin for reproducibility. The local release scripts require Node.js
24 or newer so a compatible local installation is not rejected solely for using a newer version.

## Pre-release checks

```bash
git switch main
git pull --ff-only
git status --short --branch
git rev-parse HEAD
git branch --show-current
xcodebuild -version
xcrun swift --version
xcodebuild test \
  -project MobCrew/MobCrew.xcodeproj \
  -scheme MobCrew \
  -destination 'platform=macOS'
```

Record the target commit in the release notes. Before proceeding, confirm:

- [ ] The branch is the intended release branch, its upstream is current, and the worktree is clean.
- [ ] The version is a new `MAJOR.MINOR.PATCH` value and `v<version>` does not already exist as a
      release or remote tag.
- [ ] Automated tests pass with the required Xcode and Swift versions.
- [ ] App-level manual regression testing in [TESTING.md](../TESTING.md) is complete.
- [ ] User-facing release notes use current product wording and identify material changes.

The current script does not enforce these gates, so the releaser must complete them before creating
remote state.

## Release Process

### 1. Create one draft artifact

After explicit approval to create a draft:

```bash
./scripts/release.sh 1.0.0 --draft
```

This builds `MobCrew.app`, creates and verifies `MobCrew-1.0.0.dmg`, and uploads that DMG to a draft
GitHub release. Record the draft URL and do not rerun the script without `--draft`: that would rebuild
and attempt to publish a different, unqualified artifact.

### 2. Inspect the exact draft download

Download the DMG back from the draft release so the tested bytes are exactly what GitHub will serve.
Record every command result alongside the target commit and test environment.

#### Integrity, version, and contents

- [ ] Record `shasum -a 256 MobCrew-1.0.0.dmg` and the file size.
- [ ] Run `hdiutil verify MobCrew-1.0.0.dmg`.
- [ ] Mount the DMG read-only, confirm it contains the expected `MobCrew.app` and Applications link,
      then eject it normally.
- [ ] Check `CFBundleShortVersionString` is `1.0.0` and record `CFBundleVersion` from the mounted app's
      `Contents/Info.plist`.
- [ ] Run `lipo -archs MobCrew.app/Contents/MacOS/MobCrew` and record the executable architectures;
      do not infer release support from the build machine or CI destination.

#### App bundle, DMG, and Gatekeeper trust

These are separate properties. Record results independently; a valid local code structure does not
mean Developer ID distribution, notarization, or Gatekeeper acceptance.

- [ ] App structure: `codesign --verify --deep --strict --verbose=2 MobCrew.app`.
- [ ] App identity and entitlements: `codesign --display --verbose=4 MobCrew.app` and
      `codesign --display --entitlements :- MobCrew.app`.
- [ ] App assessment: `spctl --assess --type execute --verbose=4 MobCrew.app`.
- [ ] App notarization ticket: `xcrun stapler validate MobCrew.app`.
- [ ] Outer DMG signature: `codesign --verify --verbose=4 MobCrew-1.0.0.dmg` and
      `codesign --display --verbose=4 MobCrew-1.0.0.dmg`.
- [ ] Outer DMG assessment/ticket: `spctl --assess --type open --context context:primary-signature
      --verbose=4 MobCrew-1.0.0.dmg` and `xcrun stapler validate MobCrew-1.0.0.dmg`.

The repository currently tells `create-dmg` not to sign the outer DMG. The Xcode build uses automatic
signing, but the resulting app identity depends on the release environment. The repository does not
currently define Developer ID or notarization credentials. Report the observed outputs; do not label
the app signed, unsigned, notarized, or Gatekeeper-ready from configuration alone.

### 3. Qualify first launch and upgrade

Use the downloaded, still-quarantined draft DMG on a clean supported macOS account or Mac.

- [ ] Open the DMG, copy MobCrew to Applications, and launch it without removing quarantine or
      disabling Gatekeeper.
- [ ] Record macOS version, hardware architecture, exact Gatekeeper message, and every safe recovery
      step required in **System Settings → Privacy & Security**.
- [ ] Exercise Accessibility allow/defer/recovery and Notifications allow/deny paths.
- [ ] Complete the core timer, roster, floating window, menu bar, Settings, break, and quit/relaunch
      journeys.
- [ ] Replace a previous installed version with the draft build and confirm expected local data is
      retained; record any permission prompts or migration problems.

If any required Mac, OS, architecture, or assistive-technology environment is unavailable, record
that gate as **unverified**. Absence of evidence is not evidence that the configuration is supported.

### 4. Publish the tested draft

After review and explicit approval to publish, open the existing draft on GitHub, confirm its target
commit, notes, tag, checksum, and asset, then choose **Publish release**. Do not rebuild or recreate
the release. Publishing the draft creates/publishes the intended tag from the tested draft state.

### 5. Post-publish verification

- [ ] The published release and tag target the recorded commit.
- [ ] The public asset size and SHA-256 match the qualified draft download.
- [ ] The latest-release link resolves to the new release and the DMG downloads successfully.
- [ ] Public documentation remains accurate for compatibility, install, permissions, trust, privacy,
      updates, and support.

## Failure recovery

If qualification fails while the release is still a draft, keep it unpublished while fixing the
problem. With explicit approval, delete only that draft in the GitHub UI or with:

```bash
gh release delete v1.0.0 --yes
```

First check whether a remote tag exists:

```bash
git ls-remote --exit-code --tags origin refs/tags/v1.0.0
```

A normal unpublished draft does not require deleting a published tag. Never delete a published
release or remote tag as routine recovery: stop and obtain explicit owner approval after assessing
downstream impact. Prefer a new patch release over rewriting public history.

## Script Details

| Script | Purpose |
|--------|---------|
| `scripts/build-release.sh [version]` | Builds app with version injection |
| `scripts/create-dmg.sh <version>` | Creates DMG from built app |
| `scripts/release.sh <version>` | Full release (build → DMG → GitHub) |

## Troubleshooting

### "gh is not authenticated"

```bash
gh auth login
```

### "Node.js 24+ is required"

```bash
brew install node
```

### Build Fails

Confirm the full required Xcode application is installed and selected. Command Line Tools installed
by `xcode-select --install` are not a substitute for Xcode.

```bash
sudo xcode-select --switch /Applications/Xcode_26.6.app/Contents/Developer
xcodebuild -version
xcrun swift --version
```

### DMG Creation Fails

The pinned `create-dmg` 8.1.0 tool is downloaded via npx on first run. Ensure the complete Node.js
distribution and internet access are available.

### Release Already Exists

Stop. Confirm whether it is an unpublished draft or a published release, and whether its tag exists.
Do not delete or retag shared state without explicit owner approval; choose a new patch version when
public history already exists.

## Future Improvements

- **Developer ID signing**: Requires an explicit owner decision, Apple Developer Program access, and
  securely managed credentials
- **Notarization and stapling**: Add only after Developer ID signing is intentionally configured
- **GitHub Actions**: Automate releases on tag push
- **Sparkle**: In-app auto-update mechanism
