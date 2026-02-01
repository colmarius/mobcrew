# Ghostty Patterns for MobCrew

## Executive Summary

[Ghostty](https://github.com/ghostty-org/ghostty) is a high-quality, open-source terminal emulator with a native macOS app built in Swift/SwiftUI. This document analyzes patterns from Ghostty that can inform MobCrew's architecture.

**Key Recommendation**: Adopt Ghostty's **feature-based organization** and **floating window management patterns** while skipping the C/Zig core library complexity that isn't needed for MobCrew's simpler domain.

---

## 1. Ghostty Architecture Overview

### 1.1 High-Level Structure

```text
ghostty/
├── src/                    # Zig core (terminal emulator engine)
├── include/                # C API headers for libghostty
└── macos/                  # Native macOS app (Swift/SwiftUI)
    ├── Sources/
    │   ├── App/            # App lifecycle (AppDelegate, main.swift)
    │   ├── Features/       # Feature modules (one per major feature)
    │   ├── Ghostty/        # libghostty Swift bindings
    │   └── Helpers/        # Shared utilities, extensions, window helpers
    └── Assets.xcassets/
```

### 1.2 The Core/UI Split

Ghostty uses a **hybrid architecture**:

- **Core**: Written in Zig, compiled as `libghostty` C library
- **UI**: Native Swift/SwiftUI app that consumes `libghostty` via bridging header
- **Benefit**: Core logic is portable (Linux GTK app uses same library)
- **Cost**: Complexity of FFI, state synchronization, build system integration

**For MobCrew**: Skip this pattern. Our domain (timer, roster rotation) is simple enough for pure Swift. Cross-platform isn't a goal.

---

## 2. Patterns to Adopt

### 2.1 Feature-Based Directory Organization ✅

**Ghostty's approach**:

```text
Features/
├── About/                   # About window
├── ClipboardConfirmation/   # Clipboard paste confirmation
├── Command Palette/         # Fuzzy command search
├── Global Keybinds/         # CGEvent tap for global shortcuts
├── QuickTerminal/           # Floating terminal panel
├── Secure Input/            # Password mode
├── Services/                # macOS Services integration
├── Settings/                # Settings UI
├── Splits/                  # Split pane management
├── Terminal/                # Main terminal surface
└── Update/                  # Sparkle auto-update
```

Each feature directory contains:

- Controller(s)
- Views (SwiftUI or XIB)
- Feature-specific models/types
- Extensions relevant only to that feature

**Recommended MobCrew structure**:

```text
MobCrew/
├── App/
│   ├── AppDelegate.swift
│   └── MobCrewApp.swift
├── Features/
│   ├── FloatingTimer/
│   │   ├── FloatingTimerController.swift
│   │   ├── FloatingTimerWindow.swift
│   │   └── FloatingTimerView.swift
│   ├── MenuBar/
│   │   └── StatusBarController.swift
│   ├── Hotkeys/
│   │   └── GlobalHotkeyManager.swift
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   └── SettingsStore.swift
│   ├── Roster/
│   │   ├── RosterView.swift
│   │   ├── MobsterRow.swift
│   │   └── RosterStore.swift
│   └── RPG/
│       └── RPGModeView.swift
├── Core/
│   ├── Mobster.swift
│   ├── Roster.swift
│   ├── TimerEngine.swift
│   └── Persistence.swift
└── Helpers/
    ├── Extensions/
    └── WindowHelpers.swift
```

**Effort**: Low (~1h initial setup)
**Value**: High (maintainability, clear boundaries)

---

### 2.2 QuickTerminal Pattern for Floating Timer ✅

Ghostty's `QuickTerminal` is remarkably similar to what MobCrew needs for its floating timer window. Key patterns:

#### 2.2.1 NSPanel Subclass

From [QuickTerminalWindow.swift](file://.agents/reference/ghostty/macos/Sources/Features/QuickTerminal/QuickTerminalWindow.swift):

```swift
class QuickTerminalWindow: NSPanel {
    override var canBecomeKey: Bool { return true }
    override var canBecomeMain: Bool { return true }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.styleMask.remove(.titled)  // Borderless
        self.styleMask.insert(.nonactivatingPanel)  // Don't steal focus
        self.setAccessibilitySubrole(.floatingWindow)
    }
}
```

**For MobCrew's FloatingTimerWindow**:

```swift
class FloatingTimerWindow: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override init(contentRect: NSRect, styleMask: NSWindow.StyleMask,
                  backing: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.borderless, .nonactivatingPanel],
                   backing: backing, defer: flag)

        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.collectionBehavior = [.canJoinAllSpaces, .stationary]
        self.setAccessibilitySubrole(.floatingWindow)
    }
}
```

#### 2.2.2 Controller-Owned Window Management

From [QuickTerminalController.swift](file://.agents/reference/ghostty/macos/Sources/Features/QuickTerminal/QuickTerminalController.swift):

The controller owns:

- Window creation and configuration
- Show/hide animations
- Focus behavior (previous app restoration)
- Configuration sync

Key methods to emulate:

- `toggle()` - Show/hide with animation
- `animateIn()` / `animateOut()` - Smooth transitions
- `syncAppearance()` - Apply config changes

**For MobCrew**:

```swift
class FloatingTimerController: NSWindowController {
    private var visible: Bool = false

    func toggle() {
        if visible { animateOut() } else { animateIn() }
    }

    private func animateIn() {
        guard let window = self.window, let screen = NSScreen.main else { return }
        // Position at bottom-right
        let origin = CGPoint(
            x: screen.visibleFrame.maxX - window.frame.width - 20,
            y: screen.visibleFrame.minY + 20
        )
        window.setFrameOrigin(origin)
        window.alphaValue = 0
        window.orderFront(nil)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            window.animator().alphaValue = 1
        }
        visible = true
    }
}
```

**Effort**: Medium (1-3h for basic panel, 1-2 days with polish)
**Value**: High (this IS the core timer display)

---

### 2.3 Helpers Directory ✅

Ghostty's [Helpers/](file://.agents/reference/ghostty/macos/Sources/Helpers) contains reusable utilities:

| File | Purpose | MobCrew Relevance |
|------|---------|-------------------|
| `HostingWindow.swift` | Custom NSWindow for hosting SwiftUI | ✅ Useful |
| `Weak.swift` | Weak reference wrapper | ✅ Useful |
| `AppInfo.swift` | App bundle info access | ✅ Useful |
| `Backport.swift` | iOS version compatibility | ⚠️ Maybe |
| `MetalView.swift` | Metal rendering | ❌ Not needed |

**Recommended MobCrew Helpers**:

- `FloatingWindowHelpers.swift` - Window positioning utilities
- `Extensions/` - NSWindow, NSScreen extensions
- `Weak.swift` - For notification observers

---

### 2.4 AppDelegate Structure ✅ (Simplified)

Ghostty's [AppDelegate.swift](file://.agents/reference/ghostty/macos/Sources/App/macOS/AppDelegate.swift) is complex (~1300 lines) due to:

- XIB-based menu management with many IBOutlets
- Deep integration with libghostty
- Complex window restoration

**For MobCrew** (simplified):

```swift
class AppDelegate: NSObject, NSApplicationDelegate {
    let statusBarController = StatusBarController()
    let hotkeyManager = GlobalHotkeyManager()
    var floatingTimerController: FloatingTimerController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController.setup()
        hotkeyManager.register()
        setupNotifications()
    }

    @objc func toggleFloatingTimer(_ sender: Any) {
        floatingTimerController?.toggle()
    }
}
```

**Effort**: Low
**Value**: Medium (keeps lifecycle clean)

---

## 3. Patterns to Skip or Simplify

### 3.1 C/Zig Core Library ❌

**Why Ghostty has it**: Cross-platform (Linux GTK uses same core), performance-critical rendering
**Why MobCrew doesn't need it**: Simple domain, no cross-platform requirement, no performance constraints

**Alternative**: Keep all logic in Swift. If needed later, extract to a Swift Package first.

---

### 3.2 CGEvent Tap for Global Hotkeys ⚠️

Ghostty's [GlobalEventTap.swift](file://.agents/reference/ghostty/macos/Sources/Features/Global%20Keybinds/GlobalEventTap.swift) uses low-level CGEvent interception.

**Pros**:

- Can intercept any key combination
- Works even when app isn't focused

**Cons**:

- Requires Accessibility permissions
- More invasive (battery, privacy)
- Overkill for simple hotkeys

**Recommended for MobCrew**:
Use Carbon's `RegisterEventHotKey` or a library like [sindresorhus/KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts):

```swift
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleTimer = Self("toggleTimer")
}

// In setup:
KeyboardShortcuts.onKeyUp(for: .toggleTimer) {
    floatingTimerController.toggle()
}
```

**When to use CGEvent tap**: Only if you need double-tap modifier detection or other advanced behaviors.

---

### 3.3 XIB-Heavy Menu Management ❌

Ghostty uses `MainMenu.xib` with 50+ IBOutlet connections for menu items.

**Why they have it**: Complex menu state (enable/disable based on context), deep keyboard shortcut sync
**Why MobCrew doesn't need it**: Simple status bar menu with 5-6 items

**Recommended**: Programmatic `NSMenu` via status item:

```swift
class StatusBarController {
    private var statusItem: NSStatusItem?

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.image = NSImage(systemSymbolName: "person.3.fill", accessibilityDescription: nil)
        statusItem?.menu = buildMenu()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Start Timer", action: #selector(startTimer), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApp.terminate), keyEquivalent: "q"))
        return menu
    }
}
```

---

## 4. Implementation Recommendations

### 4.1 Phased Approach

| Phase | Focus | Ghostty Patterns Used |
|-------|-------|-----------------------|
| 1 | Project setup | Feature directories, Core module |
| 2 | Floating timer | QuickTerminal patterns (NSPanel, controller) |
| 3 | Menu bar | Simplified status item (not XIB) |
| 4 | Global hotkeys | KeyboardShortcuts library (not CGEvent tap) |
| 5 | Settings | SwiftUI settings with ObservableObject store |
| 6 | Roster | SwiftUI List with onMove/onDrag |

### 4.2 Quick Wins

1. **Copy Ghostty's feature directory structure** - Immediate organization benefit
2. **Adapt `QuickTerminalWindow` for `FloatingTimerWindow`** - Near-identical needs
3. **Use Ghostty's `Weak.swift` wrapper** - Clean notification observer patterns

### 4.3 Things to Avoid

1. **Don't build C/FFI infrastructure** - Swift is sufficient
2. **Don't use XIB for menus** - Programmatic is simpler for small menus
3. **Don't implement CGEvent tap first** - Try simpler hotkey APIs first

---

## 5. Code Snippets to Reference

### 5.1 Animation Pattern (from QuickTerminalController)

```swift
NSAnimationContext.runAnimationGroup({ context in
    context.duration = 0.2
    context.timingFunction = .init(name: .easeIn)
    window.animator().setFrame(targetFrame, display: true)
}, completionHandler: {
    window.orderOut(self)
})
```

### 5.2 Notification Observer Pattern (from AppDelegate)

```swift
NotificationCenter.default.addObserver(
    self,
    selector: #selector(configDidChange(_:)),
    name: .settingsDidChange,
    object: nil
)
```

### 5.3 Window Level Management

```swift
// Floating above normal windows
window.level = .floating

// Even above menu bar (use sparingly)
window.level = .popUpMenu

// Back to normal
window.level = .normal
```

---

## 6. References

- [Ghostty GitHub Repository](https://github.com/ghostty-org/ghostty)
- [Ghostty macOS Sources](https://github.com/ghostty-org/ghostty/tree/main/macos/Sources)
- [Ghostty HACKING.md](https://github.com/ghostty-org/ghostty/blob/main/HACKING.md)
- [KeyboardShortcuts Library](https://github.com/sindresorhus/KeyboardShortcuts)
- [MobCrew Research: Native macOS](mobster-native-macos-research.md)

---

## 7. Decision Summary

| Pattern | Adopt? | Effort | Notes |
|---------|--------|--------|-------|
| Feature directories | ✅ Yes | Low | High maintainability value |
| NSPanel floating window | ✅ Yes | Medium | Core requirement |
| Controller-owned window | ✅ Yes | Medium | Clean separation |
| Helpers directory | ✅ Yes | Low | Reusable utilities |
| C/Zig core library | ❌ No | N/A | Overkill for MobCrew |
| CGEvent tap hotkeys | ⚠️ Maybe | Medium | Try KeyboardShortcuts first |
| XIB menus | ❌ No | N/A | Programmatic is simpler |
| Sparkle updates | ✅ Yes | Low | Standard for macOS apps |
