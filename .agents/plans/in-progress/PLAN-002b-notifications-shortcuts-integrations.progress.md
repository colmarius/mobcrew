# Progress: PLAN-002b Notifications, Shortcuts & Integrations

Started: 2026-02-01
Plan: [PLAN-002b](./PLAN-002b-notifications-shortcuts-integrations.md)

---

## Task 1: Create NotificationService

**Thread**: https://ampcode.com/threads/T-019c1b37-fdd8-711a-936f-98148214a6c3
**Status**: completed
**Iteration**: 1

### Changes

- `MobCrew/MobCrew/Core/Services/NotificationService.swift` - Created with UNUserNotificationCenter, requestPermission(), sendTimerComplete(), sendBreakStarted()

### Commands Run

- `./scripts/test.sh` ✓ (all tests pass)

### Next

- Task 2: Request notification permission on first use

---

## Task 2: Request notification permission on first use

**Thread**: https://ampcode.com/threads/T-019c1b37-fdd8-711a-936f-98148214a6c3
**Status**: completed
**Iteration**: 1

### Changes

- `MobCrew/MobCrew/Core/AppState.swift` - Added NotificationService dependency, requestNotificationPermissionIfNeeded() called on toggleTimer()
- `MobCrew/MobCrew.xcodeproj/project.pbxproj` - Added NotificationService.swift to build

### Commands Run

- `./scripts/test.sh` ✓ (all tests pass)

### Next

- Task 3: Wire notifications to timer events

---

## Task 3: Wire notifications to timer events

**Thread**: https://ampcode.com/threads/T-019c1b37-fdd8-711a-936f-98148214a6c3
**Status**: completed
**Iteration**: 1

### Changes

- `MobCrew/MobCrew/Core/AppState.swift` - Added sendTimerCompleteNotification() and wired to handleTimerComplete(), added break notification to triggerBreak()

### Commands Run

- `./scripts/test.sh` ✓ (all tests pass)

### Next

- Task 4: Add NotificationService tests

---

## Task 4: Add NotificationService tests

**Thread**: https://ampcode.com/threads/T-019c1b37-fdd8-711a-936f-98148214a6c3
**Status**: completed
**Iteration**: 1

### Changes

- `MobCrew/MobCrew/Core/Services/NotificationService.swift` - Added NotificationCenterProtocol for testability
- `MobCrew/MobCrewTests/Core/Services/NotificationServiceTests.swift` - Created with 4 tests for notification content and permission
- `MobCrew/MobCrew.xcodeproj/project.pbxproj` - Added test file to build

### Commands Run

- `./scripts/test.sh` ✓ (all tests pass)

### Learnings

- UNUserNotificationCenter cannot be easily subclassed; use protocol abstraction for testability

### Next

- Task 5: Add Cmd+Enter shortcut for start/stop

---

## Task 5: Add Cmd+Enter shortcut for start/stop

**Thread**: https://ampcode.com/threads/T-019c1b3d-38d3-74b8-b4a1-983ab280a140
**Status**: completed
**Iteration**: 1

### Changes

- `MobCrew/MobCrew/ContentView.swift` - Changed start/stop button shortcut from `.space` to `.return, modifiers: .command` (Cmd+Enter)

### Commands Run

- `./scripts/test.sh` ✓ (all tests pass)

### Next

- Task 6: Add Cmd+Shift+S shortcut for skip turn

---

## Task 6: Add Cmd+Shift+S shortcut for skip turn

**Thread**: https://ampcode.com/threads/T-019c1b3d-38d3-74b8-b4a1-983ab280a140
**Status**: completed
**Iteration**: 1

### Changes

- `MobCrew/MobCrew/ContentView.swift` - Changed skip button shortcut from Cmd+RightArrow to Cmd+Shift+S to avoid Cmd+S conflict with system save

### Commands Run

- `./scripts/test.sh` ✓ (all tests pass)

### Notes

- Used Cmd+Shift+S instead of Cmd+S to avoid conflicts with common save shortcut

### Next

- Task 7: Create GlobalHotkeyService

---

## Task 7: Create GlobalHotkeyService

**Thread**: https://ampcode.com/threads/T-019c1b3d-38d3-74b8-b4a1-983ab280a140
**Status**: completed
**Iteration**: 1

### Changes

- `MobCrew/MobCrew/Core/Services/GlobalHotkeyService.swift` - Created using Carbon RegisterEventHotKey API for Cmd+Shift+L global hotkey
- `MobCrew/MobCrew.xcodeproj/project.pbxproj` - Added GlobalHotkeyService.swift to build

### Commands Run

- `./scripts/test.sh` ✓ (all tests pass)

### Notes

- Uses Carbon API (RegisterEventHotKey) for reliable global hotkey registration
- Includes hasAccessibilityPermission check and requestAccessibilityPermission() for permission handling

### Next

- Task 8: Add accessibility permission handling

---

## Task 8: Add accessibility permission handling

**Thread**: https://ampcode.com/threads/T-019c1b3d-38d3-74b8-b4a1-983ab280a140
**Status**: completed
**Iteration**: 1

### Changes

- `MobCrew/MobCrew/App/AppDelegate.swift` - Added checkAccessibilityPermission() that shows alert on app launch if permission not granted, with option to open System Settings

### Commands Run

- `./scripts/test.sh` ✓ (all tests pass)

### Next

- Task 9: Wire global hotkey to floating timer toggle

---

