# How to Create and Publish a Mac App

Research guide for MobCrew - a native macOS mob programming timer app.

---

## Target Platforms

| Platform | Status | Notes |
|----------|--------|-------|
| **macOS** | ✅ Primary | Menu bar app with SwiftUI/AppKit |
| **iOS/iPadOS** | 🔮 Future | SwiftUI code largely reusable; UI adaptation needed for touch |

### Platform-Specific Considerations

**macOS-specific features** (won't translate to iOS):

- Menu bar presence/icon
- NSStatusItem for quick access
- Keyboard shortcuts
- Multi-window support

**Shared features** (will work cross-platform):

- Timer logic and state management
- Participant/mob rotation management
- Notifications
- Settings/preferences UI (SwiftUI)

**Strategy**: Build macOS-first with clean separation between platform-specific UI (AppKit/menu bar) and shared business logic (SwiftUI views, models). This enables future iOS port with minimal refactoring.

---

## Overview

There are two distribution paths for macOS apps:

1. **Mac App Store** - Apple's curated marketplace
2. **Direct Distribution** - Using Developer ID + Notarization

---

## Step 1: Join Apple Developer Program

**Cost**: $99/year
**Enrollment**: <https://developer.apple.com/programs/enroll/>

**Requirements**:

- Apple ID with two-factor authentication
- Valid payment method
- Legal entity info (for organizations)

**What you get**:

- Access to beta OS releases
- App Store Connect
- Developer ID certificates for distribution
- TestFlight for beta testing
- Analytics and sales reports

---

## Step 2: Set Up Development Environment

### Required Tools

- **Xcode** (latest version from Mac App Store)
- **Apple Developer Account** signed in to Xcode
- **Certificates & Provisioning Profiles** (managed automatically or manually)

### Signing Identities Needed

| Purpose | Certificate Type |
|---------|-----------------|
| Development | Apple Development |
| App Store | Apple Distribution |
| Direct Distribution | Developer ID Application |
| Installers | Developer ID Installer |

---

## Step 3: Configure Your App

### In Xcode Project Settings

1. Set **Bundle Identifier** (e.g., `com.yourname.MobCrew`)
2. Enable **Hardened Runtime** (required for notarization)
3. Configure **App Sandbox** (required for App Store)
4. Set **Deployment Target** (minimum macOS version)
5. Add required **Entitlements**

### Info.plist Essentials

- `CFBundleName` - App name
- `CFBundleIdentifier` - Unique bundle ID
- `CFBundleVersion` - Build number
- `CFBundleShortVersionString` - Version string (e.g., "1.0.0")
- `LSMinimumSystemVersion` - Minimum macOS version
- `NSHumanReadableCopyright` - Copyright notice

---

## Step 4: Build & Archive

```bash
# Build archive via command line
xcodebuild archive \
  -scheme "MobCrew" \
  -archivePath "build/MobCrew.xcarchive"

# Or use Xcode: Product → Archive
```

---

## Step 5A: App Store Distribution

### Prepare in App Store Connect

1. Go to <https://appstoreconnect.apple.com>
2. Create new app record
3. Fill in app metadata:
   - Name, subtitle, description
   - Keywords (for search)
   - Screenshots (required sizes)
   - App icon (1024x1024)
   - Privacy policy URL
   - Age rating questionnaire
   - Pricing and availability

### Export & Upload

```bash
# Export for App Store
xcodebuild -exportArchive \
  -archivePath "build/MobCrew.xcarchive" \
  -exportPath "build/AppStore" \
  -exportOptionsPlist "ExportOptions-AppStore.plist"

# Upload using xcrun
xcrun altool --upload-app \
  -f "build/AppStore/MobCrew.pkg" \
  -t macos \
  -u "your@apple.id"
```

Or use **Xcode Organizer**: Window → Organizer → Distribute App

### App Review

- Apps reviewed by Apple (typically 24-48 hours)
- Must comply with [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- Common rejection reasons: bugs, incomplete features, misleading metadata

---

## Step 5B: Direct Distribution (Outside App Store)

### Code Sign with Developer ID

```bash
codesign --force --options runtime \
  --sign "Developer ID Application: Your Name (TEAM_ID)" \
  "MobCrew.app"
```

### Notarization (Required since macOS 10.15)

Notarization is Apple's automated malware scanning service. Required for Gatekeeper to allow your app.

```bash
# Create a ZIP or DMG
ditto -c -k --keepParent "MobCrew.app" "MobCrew.zip"

# Submit for notarization
xcrun notarytool submit "MobCrew.zip" \
  --apple-id "your@apple.id" \
  --password "app-specific-password" \
  --team-id "TEAM_ID" \
  --wait

# Staple the ticket (attach notarization to app)
xcrun stapler staple "MobCrew.app"
```

### Create DMG for Distribution

```bash
# Create DMG
hdiutil create -volname "MobCrew" \
  -srcfolder "MobCrew.app" \
  -ov -format UDZO \
  "MobCrew.dmg"

# Sign the DMG
codesign --sign "Developer ID Application: Your Name (TEAM_ID)" \
  "MobCrew.dmg"

# Notarize the DMG
xcrun notarytool submit "MobCrew.dmg" \
  --apple-id "your@apple.id" \
  --password "app-specific-password" \
  --team-id "TEAM_ID" \
  --wait

# Staple the DMG
xcrun stapler staple "MobCrew.dmg"
```

---

## Step 6: Testing

### TestFlight (App Store path)

- Upload build to App Store Connect
- Add internal testers (team members)
- Invite external testers (up to 10,000)
- Collect crash reports and feedback

### Direct Testing

- Share notarized app/DMG directly
- Test on clean machines (without your dev certificates)
- Verify Gatekeeper allows installation

---

## Distribution Comparison

| Feature | App Store | Direct (Developer ID) |
|---------|-----------|----------------------|
| Apple Review | Yes | No (just notarization) |
| Automatic Updates | Yes (via App Store) | Manual or Sparkle |
| Payment Processing | Apple handles | You handle |
| Apple's 15-30% cut | Yes | No |
| Sandbox Required | Yes | No (recommended) |
| Reach | App Store discovery | Your own marketing |
| Refunds | Apple handles | You handle |

---

## Quick Checklist for MobCrew

- [ ] Enroll in Apple Developer Program ($99/year)
- [ ] Create Bundle ID in developer portal
- [ ] Configure Xcode project with proper signing
- [ ] Enable Hardened Runtime
- [ ] Create app icon (1024x1024 + all sizes)
- [ ] Build and archive
- [ ] Choose distribution method:
  - [ ] **App Store**: Create App Store Connect record → Upload → Submit for review
  - [ ] **Direct**: Sign with Developer ID → Notarize → Create DMG → Distribute
- [ ] Set up update mechanism (App Store auto-updates or Sparkle for direct)

---

## Useful Resources

- [Apple Developer Program](https://developer.apple.com/programs/)
- [App Store Connect](https://appstoreconnect.apple.com)
- [Notarizing macOS Software](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Human Interface Guidelines - macOS](https://developer.apple.com/design/human-interface-guidelines/macos)
- [Sparkle (auto-updater for direct distribution)](https://sparkle-project.org/)
