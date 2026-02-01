# PLAN-002b: Notifications, Shortcuts & Integrations

| Field | Value |
|-------|-------|
| Status | in-progress |
| Date | 2026-02-01 |
| PRD | [`PRD-002`](../../prds/PRD-002-breaks-and-polish.md) |
| Depends on | PLAN-001, PLAN-002a |

## Overview

Add system notifications, keyboard shortcuts (local and global), shuffle roster, and active mobsters file export for git integration.

---

## Tasks

### System Notifications

- [x] **Task 1: Create NotificationService**
  - Scope: `MobCrew/MobCrew/Core/Services/NotificationService.swift`
  - Depends on: none
  - Acceptance:
    - Uses `UNUserNotificationCenter`
    - `requestPermission()` method
    - `sendTimerComplete(driver:navigator:)` method
    - `sendBreakStarted(duration:)` method
    - Notifications include app icon
  - Notes: Request permission on first timer start

- [x] **Task 2: Request notification permission on first use**
  - Scope: `MobCrew/MobCrew/App/AppDelegate.swift`
  - Depends on: Task 1
  - Acceptance:
    - Request notification permission when timer first starts
    - Handle permission granted/denied gracefully
    - Don't repeatedly prompt if denied

- [x] **Task 3: Wire notifications to timer events**
  - Scope: `MobCrew/MobCrew/Core/AppState.swift`
  - Depends on: Task 1
  - Acceptance:
    - Send timer complete notification when countdown reaches 0
    - Send break started notification when break triggers
    - Notification shows Driver/Navigator names

- [x] **Task 4: Add NotificationService tests**
  - Scope: `MobCrew/MobCrewTests/Core/Services/NotificationServiceTests.swift`
  - Depends on: Task 1
  - Acceptance:
    - Test notification content is formatted correctly
    - Tests pass (mock UNUserNotificationCenter if needed)

### Local Keyboard Shortcuts

- [x] **Task 5: Add Cmd+Enter shortcut for start/stop**
  - Scope: `MobCrew/MobCrew/ContentView.swift`
  - Depends on: none
  - Acceptance:
    - `.keyboardShortcut(.return, modifiers: .command)` on start/stop action
    - Works when main window is focused
    - Toggles timer state correctly

- [x] **Task 6: Add Cmd+Shift+S shortcut for skip turn**
  - Scope: `MobCrew/MobCrew/ContentView.swift`
  - Depends on: none
  - Acceptance:
    - `.keyboardShortcut("s", modifiers: .command)` on skip action
    - Works when main window is focused
    - Advances turn correctly
  - Notes: Consider if Cmd+S conflicts; may use Cmd+Shift+S or Cmd+K instead

### Global Hotkey

- [x] **Task 7: Create GlobalHotkeyService**
  - Scope: `MobCrew/MobCrew/Core/Services/GlobalHotkeyService.swift`
  - Depends on: none
  - Acceptance:
    - Uses `CGEvent.tapCreate` or `NSEvent.addGlobalMonitorForEvents`
    - Registers Cmd+Shift+L as global hotkey
    - Callback triggers when hotkey pressed
    - Handles accessibility permission requirement
  - Notes: May need to use Carbon `RegisterEventHotKey` API or HotKey library

- [ ] **Task 8: Add accessibility permission handling**
  - Scope: `MobCrew/MobCrew/App/AppDelegate.swift`, entitlements
  - Depends on: Task 7
  - Acceptance:
    - Check if accessibility permission granted
    - Show alert directing user to System Preferences if not
    - Gracefully degrade if permission denied

- [ ] **Task 9: Wire global hotkey to floating timer toggle**
  - Scope: `MobCrew/MobCrew/App/AppDelegate.swift`
  - Depends on: Tasks 7, 8
  - Acceptance:
    - Cmd+Shift+L toggles FloatingTimerController visibility
    - Works when app is in background
    - Works when other apps are focused

### Shuffle Roster

- [ ] **Task 10: Add shuffle button to RosterView**
  - Scope: `MobCrew/MobCrew/Features/Roster/RosterView.swift`
  - Depends on: none
  - Acceptance:
    - Shuffle button with `shuffle` SF Symbol
    - Located near roster header
    - Calls roster.shuffle() on tap (method already exists)
    - Only enabled when 2+ active mobsters
  - Notes: Roster.shuffle() already implemented; shuffle tests covered in PLAN-002c

### Active Mobsters File

- [ ] **Task 11: Create ActiveMobstersFileService**
  - Scope: `MobCrew/MobCrew/Core/Services/ActiveMobstersFileService.swift`
  - Depends on: none
  - Acceptance:
    - Writes to `~/Library/Application Support/MobCrew/active-mobsters`
    - Creates directory if needed
    - Format: comma-separated names (e.g., `Jim Kirk, Spock, McCoy`)
    - Only includes active mobsters in current order

- [ ] **Task 12: Wire file export to roster changes**
  - Scope: `MobCrew/MobCrew/Core/AppState.swift`
  - Depends on: Task 11
  - Acceptance:
    - File updated when mobster added/removed
    - File updated when mobster benched/activated
    - File updated when roster shuffled
    - File updated when turn advances

- [ ] **Task 13: Add ActiveMobstersFileService tests**
  - Scope: `MobCrew/MobCrewTests/Core/Services/ActiveMobstersFileServiceTests.swift`
  - Depends on: Task 11
  - Acceptance:
    - Test file created with correct path
    - Test comma-separated format
    - Test empty roster writes empty file
    - Use temporary directory for tests

### Final Verification

- [ ] **Task 14: Verify full integration**
  - Scope: `MobCrew/`
  - Depends on: Tasks 1-13
  - Acceptance:
    - Notification appears when timer completes
    - Notification appears when break starts
    - Cmd+Enter toggles timer in main window
    - Cmd+S (or alternative) skips turn in main window
    - Cmd+Shift+L toggles floating timer globally
    - Shuffle randomizes roster
    - Active mobsters file updates on roster changes
    - `xcodebuild build` succeeds
    - `xcodebuild test` succeeds
