# Progress: Accessibility Permission Flow

## Session Started
- **Date**: 2026-02-01
- **Starting Task**: Task 1

---

## Progress Log

### Task 1: Research macOS accessibility permission behavior
**Status**: ✅ Completed  
**Date**: 2026-02-01

#### Key Findings

**1. When apps auto-appear in Accessibility list:**
- Apps appear automatically when `AXIsProcessTrustedWithOptions` is called with `kAXTrustedCheckOptionPrompt: true`
- BUT this prompt only works **once per app identity** - subsequent calls open System Settings instead
- App identity is determined by **code signature**, not bundle ID or file path

**2. Debug builds vs Release builds:**
- **Debug builds**: Each build changes the app signature (unless signed with a development certificate)
- **Release builds with proper signing**: Maintain consistent identity, permissions persist across updates
- **Solution for development**: Sign with "Development" certificate in Xcode's Signing & Capabilities
- The TCC database tracks apps by their code signing requirement (`csreq` column)

**3. App identity/signing requirements:**
- Unsigned apps get a different identity each build → permissions reset every time
- Apps signed with Development certificate maintain identity between builds
- Release builds signed with Developer ID maintain identity for end users
- The key is consistent code signature, not file location

**4. How other apps handle this:**

**Alt-Tab-macOS approach:**
- Uses a `PermissionsWindow` that blocks app use until permissions granted
- Polls `AXIsProcessTrusted()` on a timer (0.5s frequent, 5s infrequent)
- Automatically continues app launch when permission detected
- Restarts app if permission revoked while running

**Auto-Clicker approach:**
- `PermissionsService` class with `@Published var isTrusted`
- Polls every 1 second with `asyncAfter`
- Shows blocking PermissionsView until granted
- Uses build script to reset TCC during development: `tccutil reset Accessibility $PRODUCT_BUNDLE_IDENTIFIER`

**5. Best practices for UX:**
- Don't rely on the system prompt appearing (it only works once)
- Provide clear instructions for manual add via + button
- Poll `AXIsProcessTrusted()` after opening Settings to auto-detect when granted
- Consider showing app path in instructions
- Handle "already denied" case (permission was previously denied)

**6. The system alert behavior:**
- First time: Shows "App would like to control this computer" dialog
- Subsequent times: Silently opens System Settings > Privacy > Accessibility
- Apps don't auto-add to list - user must click + and find the app
- For signed apps, the app appears with proper name after first prompt

---

### Task 2: Test code-signed release build
**Status**: ⚠️ Documented - requires manual action  
**Date**: 2026-02-01

#### Current State

The release build is currently **ad-hoc signed** (not properly signed):

```
Signature=adhoc
TeamIdentifier=not set
```

This means:
- App identity changes between builds
- Accessibility permissions don't persist
- App won't auto-appear in Accessibility list on subsequent runs

#### Solution Required

To enable proper signing:

1. **Open Xcode** → MobCrew project → Signing & Capabilities tab
2. **Set Team**: Select your Apple Developer account team
3. **Set Signing Certificate**: "Development" (for dev) or "Developer ID Application" (for release)

After signing, verify with:
```bash
codesign -d -vv build/Release/MobCrew.app
```

Should show:
- `Authority = Apple Development: Your Name (XXXXXXXX)`
- `TeamIdentifier = XXXXXXXXXX`

#### Additional Finding: Sandbox Conflict

The current entitlements enable sandboxing:
```xml
<key>com.apple.security.app-sandbox</key>
<true/>
```

**Potential issue**: Sandboxed apps have limited accessibility capabilities. Most accessibility apps (Alt-Tab, Raycast, Rectangle) are **not sandboxed**.

**Recommendation**: For MobCrew's global hotkey feature to work reliably, consider:
1. Disabling sandbox (set to `false` or remove the entitlement)
2. This means the app cannot be distributed on the Mac App Store
3. Distribute via direct download, Homebrew, or similar

#### Research Document Created

See: `.agents/research/accessibility-permissions.md` for detailed reference.

