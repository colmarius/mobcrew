# Releasing MobCrew

Guide for creating MobCrew releases.

## Prerequisites

1. **GitHub CLI**: `brew install gh && gh auth login`
2. **Node.js**: `brew install node`

## Quick Release

```bash
./scripts/release.sh 1.0.0
```

This builds the app, creates a DMG, and publishes to GitHub Releases.

## Pre-Release Checklist

- [ ] All tests pass: `xcodebuild test -project MobCrew/MobCrew.xcodeproj -scheme MobCrew -destination 'platform=macOS'`
- [ ] Manual testing complete (see [../TESTING.md](../TESTING.md))
- [ ] Version number is appropriate (follow [semver](https://semver.org/))
- [ ] No uncommitted changes: `git status`

## Release Process

### 1. Test with a Draft Release

```bash
./scripts/release.sh 1.0.0 --draft
```

- Visit the draft at https://github.com/colmarius/mobcrew/releases
- Download and test the DMG
- Delete the draft if issues are found

### 2. Create the Release

```bash
./scripts/release.sh 1.0.0
```

### 3. Verify

- [ ] Release appears at https://github.com/colmarius/mobcrew/releases
- [ ] DMG downloads correctly
- [ ] App opens and runs on a clean Mac

## Version Numbering

- **Major** (1.0.0 → 2.0.0): Breaking changes
- **Minor** (1.0.0 → 1.1.0): New features
- **Patch** (1.0.0 → 1.0.1): Bug fixes

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

### "Node.js is required"

```bash
brew install node
```

### Build Fails

Check Xcode is installed:
```bash
xcode-select --install
```

### DMG Creation Fails

The `create-dmg` tool is downloaded via npx on first run. Ensure you have internet access.

### Release Already Exists

Delete the existing release first:
```bash
gh release delete v1.0.0 --yes
git tag -d v1.0.0
git push origin :v1.0.0
```

## Future Improvements

- **Code Signing**: Requires Apple Developer ID ($99/year)
- **Notarization**: Allows Gatekeeper approval
- **GitHub Actions**: Automate releases on tag push
- **Sparkle**: In-app auto-update mechanism
