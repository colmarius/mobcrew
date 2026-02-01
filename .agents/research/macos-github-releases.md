# Research: macOS App GitHub Releases

**Date:** 2026-02-01
**Status:** Complete
**Tags:** release, macos, github, dmg, notarization, gh-cli

## Summary

Research on best practices for releasing macOS apps via GitHub, with insights from Ghostty's sophisticated release pipeline. Covers DMG creation, code signing, notarization, and automation with `gh` CLI.

## Key Learnings

1. **Two-stage releases** prevent incomplete releases reaching users - stage artifacts first, validate, then publish
2. **DMG creation** with `create-dmg` (npm package) provides good-looking installers with minimal effort
3. **Code signing + notarization** are essential for macOS apps to avoid Gatekeeper warnings
4. **`gh release` commands** make GitHub release management scriptable and CI-friendly
5. **Semantic versioning** with monotonic build numbers ensures proper auto-update sequencing

## Ghostty's Release Architecture

Ghostty uses a sophisticated multi-stage pipeline:

### Two Distinct Workflows

1. **Release Tag Workflow** - For official version releases (triggered by `v*.*.*` tags)
2. **Release Tip Workflow** - For continuous nightly builds from main branch

### macOS Build Process

```bash
# Phase 1: Build with xcodebuild
xcodebuild -target Ghostty -configuration Release

# Phase 2: Inject version info into Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION"

# Phase 3: Code sign
codesign --force --sign "$IDENTITY" --options runtime --entitlements Ghostty.entitlements Ghostty.app

# Phase 4: Create DMG
npm install --global create-dmg
create-dmg Ghostty.app --identity "$IDENTITY"

# Phase 5: Notarize
xcrun notarytool submit "Ghostty.dmg" --keychain-profile "notarytool-profile" --wait
xcrun stapler staple "Ghostty.dmg"
```

### Version Strategy

- **Version**: Semantic (X.Y.Z) from Git tag
- **Build Number**: Monotonic count via `git rev-list --count HEAD`
- **Commit SHA**: Stored in Info.plist for traceability

## Tools for MobCrew

### Essential Tools

| Tool | Purpose |
|------|---------|
| `gh` CLI | Create GitHub releases, upload assets |
| `create-dmg` | Create good-looking DMG files |
| `codesign` | Code sign the app bundle |
| `xcrun notarytool` | Submit for Apple notarization |
| `xcrun stapler` | Staple notarization ticket |

### gh CLI Release Commands

```bash
# Create a release with notes
gh release create v1.0.0 --notes "First release"

# Create with auto-generated notes
gh release create v1.0.0 --generate-notes

# Upload assets to existing release
gh release upload v1.0.0 MobCrew.dmg MobCrew.zip

# Create draft release (for review before publishing)
gh release create v1.0.0 --draft --notes-file CHANGELOG.md

# List releases
gh release list --limit 10
```

### create-dmg Usage

```bash
# Install
npm install --global create-dmg

# Create DMG (auto-generates nice layout)
create-dmg 'MobCrew.app' --overwrite

# With code signing
create-dmg 'MobCrew.app' --identity "Developer ID Application: Your Name"

# Skip code signing (for local testing)
create-dmg 'MobCrew.app' --no-code-sign
```

## Recommended Approach for MobCrew

### Phase 1: Basic Release Script (No Signing)

Start simple - build, create DMG, upload to GitHub.

```bash
#!/bin/bash
# scripts/release.sh

VERSION="${1:?Usage: release.sh <version>}"

# Build release
xcodebuild -project MobCrew/MobCrew.xcodeproj -scheme MobCrew \
  -configuration Release -destination 'platform=macOS' \
  CONFIGURATION_BUILD_DIR=build/Release

# Create DMG (no signing initially)
npx create-dmg 'build/Release/MobCrew.app' build --overwrite --no-code-sign

# Rename DMG
mv "build/MobCrew ${VERSION}.dmg" "build/MobCrew-${VERSION}.dmg"

# Create GitHub release
gh release create "v${VERSION}" \
  "build/MobCrew-${VERSION}.dmg" \
  --title "MobCrew ${VERSION}" \
  --generate-notes
```

### Phase 2: Add Code Signing (Requires Developer ID)

- Obtain Apple Developer ID certificate ($99/year)
- Store certificate in keychain
- Add `--identity` flag to create-dmg

### Phase 3: Add Notarization

```bash
# Store credentials (one-time setup)
xcrun notarytool store-credentials "MobCrew" \
  --apple-id "your@email.com" \
  --team-id "TEAMID" \
  --password "app-specific-password"

# Notarize
xcrun notarytool submit MobCrew.dmg --keychain-profile "MobCrew" --wait
xcrun stapler staple MobCrew.dmg
```

### Phase 4: GitHub Actions Automation

Automate releases on tag push with GitHub Actions.

## Code Signing Requirements

For distribution outside Mac App Store:

| Requirement | Description |
|-------------|-------------|
| **Developer ID Certificate** | "Developer ID Application" certificate from Apple |
| **Hardened Runtime** | Enable in Xcode: Signing & Capabilities → Hardened Runtime |
| **Notarization** | Submit to Apple for malware scanning |
| **Stapling** | Attach notarization ticket to DMG for offline validation |

Without code signing/notarization, users see "unidentified developer" warning and must right-click → Open.

## File Naming Conventions

```text
MobCrew-1.0.0.dmg          # Main DMG for users
MobCrew-1.0.0.zip          # Optional: zipped app bundle
MobCrew-1.0.0-dSYM.zip     # Debug symbols (for crash reports)
```

## Sources

- [Ghostty Releases](https://github.com/ghostty-org/ghostty/releases) - Example of sophisticated release pipeline
- [Ghostty release-tag.yml](https://github.com/ghostty-org/ghostty/blob/main/.github/workflows/release-tag.yml) - Full CI/CD workflow
- [sindresorhus/create-dmg](https://github.com/sindresorhus/create-dmg) - Simple DMG creation tool
- [gh CLI release docs](https://cli.github.com/manual/gh_release) - GitHub CLI release commands

## Open Questions

- [x] What tools to use for DMG creation → create-dmg (npm)
- [x] How to handle versioning → Semantic versioning with git tags
- [ ] Whether to implement auto-update (Sparkle) initially → Defer to future
- [ ] Cost/benefit of Developer ID certificate for initial release

## Related Research

- [[github-pages-landing-page.md]] - Landing page already links to /releases
