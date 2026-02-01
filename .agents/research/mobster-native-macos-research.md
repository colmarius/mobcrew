# Mobster Native macOS App Research

## Executive Summary

This document provides comprehensive research for porting [dillonkearns/mobster](https://github.com/dillonkearns/mobster) - an Elm/Electron mob programming timer - to a **native macOS application** using Swift and SwiftUI/AppKit.

---

## 1. Original Mobster Application Analysis

### 1.1 Technology Stack (Current)

| Component | Technology |
|-----------|------------|
| Frontend UI | Elm 0.18 |
| Desktop Framework | Electron |
| Backend/IPC | TypeScript |
| Styling | style-elements (Elm) |
| Platform | Cross-platform (macOS, Windows, Linux) |

### 1.2 Core Features

#### Timer System

- **Regular Timer**: Configurable 1-180 minute mob sessions
- **Break Timer**: Automatic break suggestion after N intervals
- **Timer Display**: Minimal, transparent, always-on-top overlay window (150×130px)
- **Position**: Bottom-right corner, toggles to left on hover
- **Display Format**: `MM:SS` countdown with Driver/Navigator names

#### Roster Management

- **Active Mobsters**: Currently in rotation (draggable, reorderable)
- **Inactive Mobsters**: Benched members (click to rotate in)
- **Operations**: Add, remove, bench, rotate in, reorder, shuffle
- **Quick Rotate**: Fuzzy search to quickly find and rotate members
- **Automatic Rotation**: Driver → Navigator → next person per turn

#### Break System

- Configurable intervals before break (0-20, 0 = disabled)
- Break duration (1-180 minutes)
- Visual progress indicator (circles)
- Skip break option with analytics tracking
- 20-minute auto-reset timer for stale break data

#### RPG Mode (Gamification)

Port of [Willem Larsen's Mob Programming RPG](https://github.com/willemlarsen/mobprogrammingrpg):

| Role | Description |
|------|-------------|
| **Driver** | Types code, asks clarifying questions |
| **Navigator** | Directs driver, high-level intent |
| **Mobber** | Contributes ideas, listens intently |
| **Researcher** | Finds documentation, blog posts |
| **Sponsor** | Amplifies unheard voices, celebrates excellence |

- Goal tracking per role (completion counts)
- Badge system (awarded when role goals > 2)
- Checklist view before each turn
- Next-up view showing role assignments

#### Educational Content

- Random tips from Agile Manifesto and mob programming best practices
- Tips refresh on timer start

#### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Ctrl/Cmd+Enter | Start Timer |
| Alt+R | Go to Roster Configuration |
| Alt+T | Go to Tips Screen |
| Alt+S | Skip (advance turn) |
| Alt+1-9,0 | Rotate out active mobster (1-10) |
| Alt+A-P | Rotate in inactive mobster (1-16) |
| **Global Hotkey** | Cmd+Shift+L (customizable) - Show/hide window |

#### Persistence

- **Settings**: localStorage (JSON) for timer duration, break settings, roster
- **Active Mobsters File**: `~/Library/Application Support/mobster/active-mobsters`
  - Comma-separated names for shell script integration
  - Updated on every roster change

### 1.3 UI Screens

1. **Configuration Screen**: Settings + roster management
2. **Continue Screen**: Break progress, current Driver/Navigator, step controls
3. **Break Screen**: Coffee icon, break countdown, skip option
4. **RPG Mode**: Goal checklist + next-up role assignments
5. **Timer Window**: Floating overlay (separate process)

### 1.4 Architecture Pattern

```text
┌─────────────────────────────────────────────────────────────┐
│                    Main Process (Electron)                   │
│  - Window management                                         │
│  - Global shortcuts                                          │
│  - File I/O (active mobsters)                               │
│  - System tray                                               │
│  - Auto-updater                                              │
└─────────────────────────────────────────────────────────────┘
         │ IPC                              │ IPC
         ▼                                  ▼
┌─────────────────────────┐    ┌─────────────────────────────┐
│  Setup Renderer (Elm)   │    │   Timer Renderer (Elm)      │
│  - Config/Continue UI   │    │   - Countdown display       │
│  - Roster management    │    │   - Transparent overlay     │
│  - Settings persistence │    │   - Always-on-top           │
│  - RPG mode             │    │                             │
└─────────────────────────┘    └─────────────────────────────┘
```

---

## 2. Native macOS Development Alternatives

### 2.1 Framework Comparison

| Framework | Pros | Cons | Recommendation |
|-----------|------|------|----------------|
| **SwiftUI** | Modern declarative syntax, less code, Apple's future direction, great for new projects | macOS gaps (menu bar, some window controls), may need AppKit fallback | ✅ **Primary choice** |
| **AppKit** | Full control, mature, complete feature set, extensive documentation | Verbose, imperative, steeper learning curve | Use as fallback for SwiftUI gaps |
| **SwiftUI + AppKit Hybrid** | Best of both worlds, SwiftUI for UI, AppKit for system integration | Complexity of bridging | ✅ **Recommended approach** |

### 2.2 Recommended Stack

```text
┌─────────────────────────────────────────────────────────────┐
│                    Swift + SwiftUI + AppKit                  │
├─────────────────────────────────────────────────────────────┤
│  UI Layer:           SwiftUI (primary)                      │
│  Menu Bar:           AppKit (NSStatusBar) + SwiftUI views   │
│  Floating Timer:     NSWindow (transparent, always-on-top)  │
│  Global Hotkeys:     Carbon HotKey API or MASShortcut       │
│  Persistence:        UserDefaults + Codable                 │
│  State Management:   SwiftUI @Observable / @Published       │
│  Notifications:      UserNotifications framework            │
│  Timer:              Foundation.Timer or Combine            │
└─────────────────────────────────────────────────────────────┘
```

### 2.3 Key macOS APIs Required

| Feature | API/Framework |
|---------|---------------|
| Menu Bar App | `NSStatusBar`, `NSStatusItem`, `NSPopover` |
| Floating Timer Window | `NSWindow` with `level: .floating`, `styleMask: [.borderless]` |
| Always-on-Top | `window.level = .floating` or `.statusBar` |
| Transparent Window | `window.isOpaque = false`, `backgroundColor = .clear` |
| Global Hotkeys | `MASShortcut` library or Carbon `RegisterEventHotKey` |
| System Notifications | `UNUserNotificationCenter` |
| Drag & Drop | SwiftUI `onDrag`/`onDrop` or AppKit `NSDraggingDestination` |
| File Writing | `FileManager` to `~/Library/Application Support/` |
| App Lifecycle | `NSApplicationDelegate`, `@main` App struct |

### 2.4 Third-Party Libraries to Consider

| Library | Purpose | Source |
|---------|---------|--------|
| **LaunchAtLogin** | Login item functionality | [sindresorhus/LaunchAtLogin](https://github.com/sindresorhus/LaunchAtLogin) |
| **KeyboardShortcuts** | Global hotkey registration | [sindresorhus/KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) |
| **Defaults** | Type-safe UserDefaults | [sindresorhus/Defaults](https://github.com/sindresorhus/Defaults) |
| **Sparkle** | Auto-updates | [sparkle-project/Sparkle](https://github.com/sparkle-project/Sparkle) |

---

## 3. Proposed Native Architecture

### 3.1 Application Structure

```text
MobsterNative/
├── App/
│   ├── MobsterNativeApp.swift      # @main entry point
│   └── AppDelegate.swift           # NSApplicationDelegate for menu bar
├── Models/
│   ├── Mobster.swift               # Person in the mob
│   ├── Roster.swift                # Active/inactive lists
│   ├── Settings.swift              # App configuration
│   ├── TimerState.swift            # Timer model
│   ├── RPGData.swift               # RPG goals and badges
│   └── Break.swift                 # Break tracking
├── ViewModels/
│   ├── MobsterViewModel.swift      # Main app state (@Observable)
│   └── TimerViewModel.swift        # Timer logic
├── Views/
│   ├── MainWindow/
│   │   ├── ConfigureView.swift     # Roster + settings
│   │   ├── ContinueView.swift      # Between-turn screen
│   │   ├── BreakView.swift         # Break screen
│   │   └── RPGView.swift           # RPG mode screens
│   ├── TimerWindow/
│   │   └── FloatingTimerView.swift # Minimal timer overlay
│   ├── Components/
│   │   ├── MobsterRow.swift        # Draggable roster item
│   │   ├── BreakProgress.swift     # Circle indicators
│   │   └── RoleIcon.swift          # Driver/Navigator icons
│   └── MenuBar/
│       └── StatusBarView.swift     # Menu bar popover
├── Services/
│   ├── PersistenceService.swift    # UserDefaults + file I/O
│   ├── NotificationService.swift   # System notifications
│   └── HotkeyService.swift         # Global hotkey registration
└── Resources/
    ├── Assets.xcassets
    └── Localizable.strings
```

### 3.2 Data Models (Swift)

```swift
// Mobster.swift
struct Mobster: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var rpgData: RPGData
}

// Roster.swift
@Observable
class Roster {
    var activeMobsters: [Mobster] = []
    var inactiveMobsters: [Mobster] = []
    var nextDriverIndex: Int = 0

    var driver: Mobster? { ... }
    var navigator: Mobster? { ... }

    func advanceTurn() { ... }
    func rotateOut(at index: Int) { ... }
    func rotateIn(at index: Int) { ... }
    func shuffle() { ... }
}

// Settings.swift
struct Settings: Codable {
    var timerDurationMinutes: Int = 5
    var breakDurationMinutes: Int = 5
    var intervalsPerBreak: Int = 5
    var globalHotkeyModifiers: NSEvent.ModifierFlags = [.command, .shift]
    var globalHotkeyKey: String = "L"
}

// TimerState.swift
enum TimerType {
    case regular(driver: String, navigator: String)
    case breakTimer
}

@Observable
class TimerState {
    var secondsRemaining: Int = 0
    var totalSeconds: Int = 0
    var timerType: TimerType = .regular(driver: "", navigator: "")
    var isRunning: Bool = false

    var displayTime: String { ... }
    var progress: Double { ... }
}
```

### 3.3 Window Management

```swift
// Main window: Standard SwiftUI Window
@main
struct MobsterNativeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        // Menu bar extra
        MenuBarExtra("Mobster", systemImage: "person.3.fill") {
            MenuBarView()
        }
    }
}

// Floating timer: Custom NSWindow
class FloatingTimerWindowController: NSWindowController {
    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 150, height: 100),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]

        super.init(window: window)

        window.contentView = NSHostingView(rootView: FloatingTimerView())
    }
}
```

---

## 4. Feature Mapping: Mobster → Native

| Original Feature | Native Implementation |
|-----------------|----------------------|
| Elm Model/Update | SwiftUI `@Observable` / `@State` |
| Elm View | SwiftUI Views |
| Electron IPC | Direct Swift method calls |
| localStorage | `UserDefaults` + `Codable` |
| Multiple windows | `WindowGroup` + custom `NSWindow` |
| Transparent overlay | `NSWindow.isOpaque = false` |
| Always-on-top | `NSWindow.level = .floating` |
| Global hotkey | `KeyboardShortcuts` library |
| System tray | `MenuBarExtra` (SwiftUI) |
| Drag & drop | SwiftUI `.draggable()` / `.dropDestination()` |
| Analytics | Remove or use TelemetryDeck |
| Auto-updater | Sparkle framework |
| Notifications | `UNUserNotificationCenter` |

---

## 5. Implementation Phases

### Phase 1: Core Infrastructure

- [ ] Project setup with SwiftUI app lifecycle
- [ ] Data models (Mobster, Roster, Settings, TimerState)
- [ ] Persistence service (UserDefaults + active-mobsters file)
- [ ] Basic app window with navigation

### Phase 2: Roster Management

- [ ] Active/inactive mobster lists
- [ ] Add, remove, bench, rotate operations
- [ ] Drag-and-drop reordering
- [ ] Quick rotate search
- [ ] Shuffle with animation

### Phase 3: Timer System

- [ ] Timer logic with Combine/Foundation.Timer
- [ ] Floating timer window (transparent, always-on-top)
- [ ] Timer display with Driver/Navigator
- [ ] Break detection and break timer

### Phase 4: Menu Bar Integration

- [ ] Menu bar icon and popover
- [ ] Quick controls (start/stop, skip)
- [ ] Status display

### Phase 5: Advanced Features

- [ ] Global hotkey registration
- [ ] System notifications on timer complete
- [ ] RPG mode with goal tracking
- [ ] Tips/educational content
- [ ] Keyboard shortcuts

### Phase 6: Polish

- [ ] Animations (shuffle, transitions)
- [ ] Dark mode support
- [ ] Accessibility
- [ ] Auto-update with Sparkle
- [ ] App icon and branding

---

## 6. Technical Considerations

### 6.1 SwiftUI Limitations to Work Around

1. **Menu Bar Apps**: Use `MenuBarExtra` (macOS 13+) or fall back to AppKit `NSStatusBar`
2. **Borderless Windows**: Must use AppKit `NSWindow` for floating timer
3. **Global Hotkeys**: No native SwiftUI support, use third-party library
4. **Always-on-Top**: Requires `NSWindow.level` manipulation
5. **Window Positioning**: Use `NSWindow` frame manipulation

### 6.2 macOS Version Target

- **Recommended**: macOS 14+ (Sonoma) for latest SwiftUI features
- **Minimum**: macOS 13 (Ventura) for `MenuBarExtra` and `@Observable`

### 6.3 Deployment

- **Distribution**: Mac App Store or direct download with notarization
- **Code Signing**: Required for notarization
- **Sandbox**: May need exceptions for file access

---

## 7. References

- [Mobster GitHub Repository](https://github.com/dillonkearns/mobster)
- [Mob Programming RPG](https://github.com/willemlarsen/mobprogrammingrpg)
- [Apple SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Apple AppKit Documentation](https://developer.apple.com/documentation/appkit)
- [KeyboardShortcuts Library](https://github.com/sindresorhus/KeyboardShortcuts)
- [Sparkle Update Framework](https://sparkle-project.org)
