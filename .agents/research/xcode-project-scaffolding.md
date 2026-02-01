# MobCrew Xcode Project Scaffolding Guide

**Date:** 2026-02-01
**Status:** Complete
**Tags:** xcode, project-setup, swiftui, macos, scaffolding

## Summary

Step-by-step guide for creating the MobCrew Xcode project with the recommended architecture from our Ghostty patterns research. Covers project creation, folder structure, Swift Package dependencies, and initial configuration.

## Key Learnings

- Use Xcode's "App" template for macOS with SwiftUI interface
- Target macOS 14+ (Sonoma) for `@Observable` and `MenuBarExtra`
- Feature-based folder organization provides maintainability
- AppKit integration via `@NSApplicationDelegateAdaptor`
- Swift Package Manager for all dependencies

---

## 1. Create Xcode Project

### Step 1.1: New Project

1. Open Xcode
2. File → New → Project (⌘⇧N)
3. Select **macOS** tab → **App** template → Next

### Step 1.2: Project Configuration

| Setting | Value |
|---------|-------|
| Product Name | `MobCrew` |
| Team | Your Apple Developer Team |
| Organization Identifier | `com.colmarius` |
| Bundle Identifier | Auto-generated: `com.colmarius.MobCrew` |
| Interface | **SwiftUI** |
| Language | **Swift** |
| Storage | None |
| Include Tests | ✅ (recommended) |

### Step 1.3: Deployment Target

In Project Settings → General → Minimum Deployments:

- **macOS**: 14.0 (Sonoma)

**Rationale**: macOS 14 provides:

- `@Observable` macro (cleaner than `ObservableObject`)
- `MenuBarExtra` for menu bar apps
- Latest SwiftUI improvements

---

## 2. Folder Structure

Create the following folder structure in Xcode (right-click → New Group):

```text
MobCrew/
├── App/
│   ├── MobCrewApp.swift         # @main App struct
│   └── AppDelegate.swift        # NSApplicationDelegate for AppKit bridge
├── Core/
│   ├── Models/
│   │   ├── Mobster.swift        # Person in the mob
│   │   ├── Roster.swift         # Active/inactive lists
│   │   └── TimerState.swift     # Timer model
│   ├── Services/
│   │   ├── TimerEngine.swift    # Timer logic
│   │   └── PersistenceService.swift  # UserDefaults + file I/O
│   └── Settings.swift           # App configuration model
├── Features/
│   ├── FloatingTimer/
│   │   ├── FloatingTimerController.swift
│   │   ├── FloatingTimerWindow.swift
│   │   └── FloatingTimerView.swift
│   ├── MenuBar/
│   │   └── MenuBarView.swift
│   ├── Hotkeys/
│   │   └── HotkeyService.swift
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   └── SettingsStore.swift
│   └── Roster/
│       ├── RosterView.swift
│       ├── MobsterRow.swift
│       └── RosterStore.swift
├── Helpers/
│   ├── Extensions/
│   └── Weak.swift               # Weak reference wrapper
├── Resources/
│   └── Assets.xcassets
└── Preview Content/
    └── Preview Assets.xcassets
```

### Creating Groups in Xcode

```text
Right-click MobCrew folder → New Group → name it "App"
Repeat for: Core, Features, Helpers, Resources
Create subgroups as shown above
```

---

## 3. Swift Package Dependencies

### 3.1 Add Dependencies

File → Add Package Dependencies... (⌘⇧,)

| Package | URL | Version | Purpose |
|---------|-----|---------|---------|
| KeyboardShortcuts | `https://github.com/sindresorhus/KeyboardShortcuts` | 2.4.0+ | Global hotkeys |
| LaunchAtLogin | `https://github.com/sindresorhus/LaunchAtLogin` | 5.0.0+ | Launch at login |
| Defaults | `https://github.com/sindresorhus/Defaults` | 8.0.0+ | Type-safe UserDefaults |
| Sparkle | `https://github.com/sparkle-project/Sparkle` | 2.6.0+ | Auto-updates (Phase 3) |

### 3.2 Adding a Package

1. File → Add Package Dependencies
2. Enter package URL in search field
3. Select version rule: "Up to Next Major Version"
4. Click "Add Package"
5. Select library products to add to MobCrew target

### 3.3 Dependency Priorities

| Phase | Dependencies |
|-------|--------------|
| MVP (Phase 1) | None required (can add Defaults for convenience) |
| Phase 2 | KeyboardShortcuts |
| Phase 3 | LaunchAtLogin, Sparkle |

---

## 4. Initial File Templates

### 4.1 MobCrewApp.swift

```swift
import SwiftUI

@main
struct MobCrewApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)  // Optional: for minimal chrome

        Settings {
            SettingsView()
        }

        MenuBarExtra("MobCrew", systemImage: "person.3.fill") {
            MenuBarView()
        }
    }
}
```

### 4.2 AppDelegate.swift

```swift
import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var floatingTimerController: FloatingTimerController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup that requires AppKit
        setupHotkeys()
        setupNotifications()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup
    }

    private func setupHotkeys() {
        // Will integrate KeyboardShortcuts here
    }

    private func setupNotifications() {
        // Notification observers
    }

    @objc func toggleFloatingTimer() {
        floatingTimerController?.toggle()
    }
}
```

### 4.3 Mobster.swift (Core Model)

```swift
import Foundation

struct Mobster: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}
```

### 4.4 Roster.swift (Core Model)

```swift
import Foundation
import Observation

@Observable
class Roster {
    var activeMobsters: [Mobster] = []
    var inactiveMobsters: [Mobster] = []
    var nextDriverIndex: Int = 0

    var driver: Mobster? {
        guard !activeMobsters.isEmpty else { return nil }
        return activeMobsters[nextDriverIndex % activeMobsters.count]
    }

    var navigator: Mobster? {
        guard activeMobsters.count > 1 else { return nil }
        return activeMobsters[(nextDriverIndex + 1) % activeMobsters.count]
    }

    func advanceTurn() {
        guard !activeMobsters.isEmpty else { return }
        nextDriverIndex = (nextDriverIndex + 1) % activeMobsters.count
    }

    func addMobster(name: String) {
        let mobster = Mobster(name: name)
        activeMobsters.append(mobster)
    }

    func benchMobster(at index: Int) {
        guard activeMobsters.indices.contains(index) else { return }
        let mobster = activeMobsters.remove(at: index)
        inactiveMobsters.append(mobster)
        adjustDriverIndex(afterRemovalAt: index)
    }

    func rotateIn(at index: Int) {
        guard inactiveMobsters.indices.contains(index) else { return }
        let mobster = inactiveMobsters.remove(at: index)
        activeMobsters.append(mobster)
    }

    func shuffle() {
        activeMobsters.shuffle()
        nextDriverIndex = 0
    }

    private func adjustDriverIndex(afterRemovalAt index: Int) {
        if activeMobsters.isEmpty {
            nextDriverIndex = 0
        } else if index <= nextDriverIndex {
            nextDriverIndex = max(0, nextDriverIndex - 1)
        }
        nextDriverIndex = nextDriverIndex % max(1, activeMobsters.count)
    }
}
```

### 4.5 TimerState.swift

```swift
import Foundation
import Observation

enum TimerType {
    case regular
    case breakTimer
}

@Observable
class TimerState {
    var secondsRemaining: Int = 0
    var totalSeconds: Int = 0
    var timerType: TimerType = .regular
    var isRunning: Bool = false

    var displayTime: String {
        let minutes = secondsRemaining / 60
        let seconds = secondsRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - secondsRemaining) / Double(totalSeconds)
    }
}
```

---

## 5. Info.plist Configuration

Add these keys via Project Settings → Info or directly in Info.plist:

### 5.1 Required Keys

| Key | Type | Value | Purpose |
|-----|------|-------|---------|
| `LSUIElement` | Boolean | `YES` | Hide dock icon (menu bar app) |
| `NSHumanReadableCopyright` | String | `Copyright © 2026` | Copyright notice |

### 5.2 Optional Keys (for later phases)

| Key | Type | Value | Purpose |
|-----|------|-------|---------|
| `SUPublicEDKey` | String | (Sparkle key) | Sparkle updates |
| `SUEnableAutomaticChecks` | Boolean | `NO` | Disable auto-check initially |

### 5.3 Setting LSUIElement

To make MobCrew a menu bar app (no dock icon):

1. Select project in Navigator
2. Select MobCrew target
3. Go to "Info" tab
4. Add row: `Application is agent (UIElement)` = `YES`

**Note**: You can toggle this. During development, keep dock icon visible for easier debugging.

---

## 6. Entitlements

Create `MobCrew.entitlements` if not exists:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
</dict>
</plist>
```

### 6.1 Entitlements Needed Per Feature

| Feature | Entitlement | Notes |
|---------|-------------|-------|
| File writing (active-mobsters) | `com.apple.security.files.user-selected.read-write` | Or use App Group |
| Network (Sparkle updates) | `com.apple.security.network.client` | Phase 3 |

---

## 7. Git Setup

### 7.1 Initialize Repository

```bash
cd /Users/marius/Projects/mobcrew
# Create MobCrew directory for Xcode project
mkdir -p MobCrew
```

### 7.2 .gitignore Additions

Add to existing `.gitignore`:

```gitignore
# Xcode
MobCrew/**/*.xcodeproj/project.xcworkspace/
MobCrew/**/*.xcodeproj/xcuserdata/
MobCrew/**/xcuserdata/
MobCrew/**/*.xcworkspace/xcuserdata/
MobCrew/DerivedData/
MobCrew/.build/
MobCrew/Packages/
MobCrew/*.moved-aside
MobCrew/**/build/

# SPM
MobCrew/.swiftpm/
```

---

## 8. Build & Run Verification

### 8.1 Initial Build

1. Select "My Mac" as destination
2. Product → Build (⌘B)
3. Verify no errors

### 8.2 Run

1. Product → Run (⌘R)
2. Verify:
   - App launches
   - Menu bar icon appears (if configured)
   - Window displays

---

## 9. Development Workflow

### 9.1 Recommended Xcode Settings

**Preferences → Behaviors:**

- Build starts: Show navigator → Issues
- Build fails: Navigate to first issue

**Editor:**

- Enable "Wrap lines"
- Show line numbers

### 9.2 Preview Support

For SwiftUI previews, ensure Preview Content has sample data:

```swift
// Preview Content/PreviewData.swift
import Foundation

extension Roster {
    static var preview: Roster {
        let roster = Roster()
        roster.addMobster(name: "Alice")
        roster.addMobster(name: "Bob")
        roster.addMobster(name: "Charlie")
        return roster
    }
}

extension TimerState {
    static var preview: TimerState {
        let state = TimerState()
        state.totalSeconds = 300
        state.secondsRemaining = 180
        state.isRunning = true
        return state
    }
}
```

---

## 10. Next Steps After Scaffolding

1. **Implement Core Models** - Mobster, Roster, TimerState, Settings
2. **Create Basic Views** - ContentView, RosterView, TimerView
3. **Add Floating Timer** - NSPanel-based floating window
4. **Menu Bar Integration** - MenuBarExtra with quick controls
5. **Persistence** - Save roster and settings to UserDefaults

---

## Sources

- [Apple: Creating an Xcode project for an app](https://developer.apple.com/documentation/xcode/creating-an-xcode-project-for-an-app)
- [Apple: Creating a macOS app (SwiftUI Tutorial)](https://developer.apple.com/tutorials/swiftui/creating-a-macos-app)
- [Apple: Adding package dependencies](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app)
- [sindresorhus/KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts)
- [Ghostty macOS Sources](https://github.com/ghostty-org/ghostty/tree/main/macos/Sources)

---

## Related Research

- [ghostty-patterns-for-mobcrew.md](ghostty-patterns-for-mobcrew.md) - Architecture patterns
- [mobster-native-macos-research.md](mobster-native-macos-research.md) - Original app analysis
- [feature-prioritization.md](feature-prioritization.md) - MVP scope
