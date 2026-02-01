# macOS Accessibility Permissions Research

## Summary

This document captures research on how macOS accessibility permissions work, focusing on the behavior when apps request accessibility access and how to provide the best user experience.

## Key Findings

### 1. When Apps Auto-Appear in Accessibility List

- Apps appear in the list when `AXIsProcessTrustedWithOptions` is called with `kAXTrustedCheckOptionPrompt: true`
- The system prompt ("App would like to control this computer") only shows **once per app identity**
- Subsequent calls silently open System Settings → Privacy & Security → Accessibility
- App identity is determined by **code signature**, not bundle ID or file path

### 2. Debug Builds vs Release Builds

| Build Type | Signing | Accessibility Behavior |
|------------|---------|----------------------|
| Debug (unsigned) | Ad-hoc | Permissions reset each build |
| Debug (signed with Dev cert) | Development | Permissions persist between builds |
| Release (Developer ID) | Developer ID | Permissions persist for end users |

**Key insight**: The TCC database tracks apps by their code signing requirement (`csreq` column). Consistent signing = consistent identity = persistent permissions.

### 3. Code Signing Requirements for Accessibility

To maintain accessibility permissions across builds:

1. **In Xcode's Signing & Capabilities**:
   - Set a **Team** (requires Apple Developer account)
   - Set **Signing Certificate** to "Development" (not "Sign to Run Locally")
   
2. **Verify signing** with:
   ```bash
   codesign -d -vv /path/to/App.app
   ```
   
   Look for:
   - `Authority = Apple Development: ...`
   - `TeamIdentifier = ...`

### 4. Sandboxing and Accessibility

**Important**: Sandboxed apps can request accessibility but with limitations:
- Need `com.apple.security.accessibility` entitlement (private, may not be available)
- Most accessibility apps (Alt-Tab, Raycast, etc.) are **NOT sandboxed**
- App Store apps cannot access Accessibility API without special entitlement from Apple

**For MobCrew**: Consider disabling sandbox if accessibility (global hotkeys) is a core feature.

### 5. Best Practices for Permission UX

1. **Don't rely on system prompt** - it only shows once
2. **Provide clear manual instructions**:
   - Explain user needs to click + button
   - Show path to the app
   - Explain they need to enable the toggle
3. **Poll `AXIsProcessTrusted()`** after opening Settings
   - Auto-enable features when permission granted
   - Use 0.5-1 second interval
4. **Handle "already denied" case** gracefully
5. **Consider blocking UI** until permission granted (like Alt-Tab)

### 6. Implementation Patterns from Other Apps

#### Alt-Tab-macOS Pattern
```swift
class SystemPermissions {
    static var timer: DispatchSourceTimer!
    
    static func ensurePermissionsAreGranted() {
        timer = DispatchSource.makeTimerSource(...)
        timer.setEventHandler(handler: checkPermissionsOnTimer)
        timer.schedule(deadline: .now(), repeating: 0.5)
        timer.resume()
    }
    
    private static func checkPermissionsOnTimer() {
        if AXIsProcessTrusted() {
            // Permission granted - continue app launch
            timer.schedule(deadline: .now() + 5, repeating: 5)  // Slow down polling
            continueAppLaunch()
        } else {
            // Show permissions window
            showPermissionsWindow()
        }
    }
}
```

#### Auto-Clicker Pattern
```swift
final class PermissionsService: ObservableObject {
    @Published var isTrusted: Bool = AXIsProcessTrusted()
    
    func pollAccessibilityPrivileges() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isTrusted = AXIsProcessTrusted()
            if !self.isTrusted {
                self.pollAccessibilityPrivileges()
            }
        }
    }
    
    static func acquireAccessibilityPrivileges() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true]
        AXIsProcessTrustedWithOptions(options)
    }
}
```

### 7. Recommended Alert Message for Manual Add

When the system prompt won't show (already prompted before):

```
Accessibility Permission Required

MobCrew needs Accessibility permission to register global hotkeys.

To grant permission:
1. Click "Open System Settings" below
2. Click the + button at the bottom of the list
3. Navigate to: /Applications/MobCrew.app
4. Enable the toggle next to MobCrew

The app will automatically detect when permission is granted.
```

### 8. Testing Accessibility During Development

**Reset TCC for fresh testing**:
```bash
# Reset for specific app
tccutil reset Accessibility com.colmarius.MobCrew

# Reset all accessibility permissions
tccutil reset Accessibility
```

**Check current permission state**:
```bash
# Requires SIP disabled (not recommended for normal use)
sqlite3 "/Library/Application Support/com.apple.TCC/TCC.db" \
  "SELECT * FROM access WHERE service='kTCCServiceAccessibility';"
```

## References

- [jano.dev - Accessibility Permission in macOS](https://jano.dev/apple/macos/swift/2025/01/08/Accessibility-Permission.html)
- [Stack Overflow - Persist accessibility permissions between builds](https://stackoverflow.com/questions/72312351/persist-accessibility-permissions-between-builds-in-xcode-13)
- [Alt-Tab-macOS source code](https://github.com/lwouis/alt-tab-macos/blob/master/src/logic/SystemPermissions.swift)
- [Auto-Clicker source code](https://github.com/othyn/macos-auto-clicker/blob/v1.3.0/auto-clicker/Services/PermissionsService.swift)
