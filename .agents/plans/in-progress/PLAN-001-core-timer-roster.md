# PLAN-001: Core Timer & Roster

| Field | Value |
|-------|-------|
| Status | todo |
| Date | 2026-02-01 |
| PRD | `../../prds/PRD-001-core-timer-roster.md` |
| Depends on | PLAN-000 |

## Overview

Implement working mob timer with floating window, roster management, menu bar integration, and persistence. Delivers usable MVP for real mob sessions.

---

## Tasks

### Timer Engine

- [x] **Task 1: Create TimerEngine service**
  - Scope: `MobCrew/MobCrew/Core/Services/TimerEngine.swift`
  - Depends on: none
  - Acceptance:
    - Uses `@Observable` macro
    - Has `start()`, `stop()`, `reset(duration:)` methods
    - Uses `Timer.publish` or `DispatchSourceTimer` for countdown
    - Updates `TimerState.secondsRemaining` each second
    - Sets `isRunning` appropriately
    - Fires callback/notification when timer completes
  - Notes: Keep timer logic separate from UI. Consider using Combine.

- [x] **Task 2: Create TimerEngineTests**
  - Scope: `MobCrew/MobCrewTests/Core/Services/TimerEngineTests.swift`
  - Depends on: Task 1
  - Acceptance:
    - Tests start/stop/reset behavior
    - Tests countdown decrements correctly
    - Tests completion callback fires at 0
    - Tests pause/resume
    - All tests pass

### Floating Timer Window

- [x] **Task 3: Create FloatingTimerWindow (NSPanel)**
  - Scope: `MobCrew/MobCrew/Features/FloatingTimer/FloatingTimerWindow.swift`
  - Depends on: none
  - Acceptance:
    - Subclass of `NSPanel`
    - `styleMask: [.borderless, .nonactivatingPanel]`
    - `level = .floating`
    - `isOpaque = false`, `backgroundColor = .clear`
    - `collectionBehavior = [.canJoinAllSpaces, .stationary]`
    - Size: ~150×100px
  - Notes: NSPanel allows non-activating click behavior.

- [x] **Task 4: Create FloatingTimerView**
  - Scope: `MobCrew/MobCrew/Features/FloatingTimer/FloatingTimerView.swift`
  - Depends on: Task 3
  - Acceptance:
    - SwiftUI view showing MM:SS countdown
    - Shows Driver and Navigator names
    - Semi-transparent dark background
    - White text, minimal chrome
    - Start/Stop button

- [x] **Task 5: Create FloatingTimerController**
  - Scope: `MobCrew/MobCrew/Features/FloatingTimer/FloatingTimerController.swift`
  - Depends on: Task 3, Task 4
  - Acceptance:
    - Manages FloatingTimerWindow lifecycle
    - `show()`, `hide()`, `toggle()` methods
    - Positions window at bottom-right with 20px offset
    - Hosts FloatingTimerView via NSHostingView
  - Notes: Wire into AppDelegate.

### Menu Bar

- [x] **Task 6: Create MenuBarView**
  - Scope: `MobCrew/MobCrew/Features/MenuBar/MenuBarView.swift`
  - Depends on: none
  - Acceptance:
    - Shows current Driver/Navigator
    - Start/Stop timer button
    - Skip turn button
    - Link to open main window/settings
  - Notes: Will be used in MenuBarExtra.

- [x] **Task 7: Add MenuBarExtra to MobCrewApp**
  - Scope: `MobCrew/MobCrew/App/MobCrewApp.swift`
  - Depends on: Task 6
  - Acceptance:
    - `MenuBarExtra` with `person.3.fill` system image
    - Shows MenuBarView in popover
    - Menu bar icon visible when app runs

### Roster Management UI

- [x] **Task 8: Create RosterView**
  - Scope: `MobCrew/MobCrew/Features/Roster/RosterView.swift`
  - Depends on: none
  - Acceptance:
    - Shows active mobsters list with Driver/Navigator indicators
    - Shows inactive (benched) mobsters list
    - Add mobster text field + button
    - Visual distinction between active and inactive sections
  - Notes: Use existing Roster model.

- [x] **Task 9: Create MobsterRow**
  - Scope: `MobCrew/MobCrew/Features/Roster/MobsterRow.swift`
  - Depends on: none
  - Acceptance:
    - Displays mobster name
    - Shows role indicator if Driver or Navigator
    - Remove button (trash icon)
    - Bench/Activate button depending on list

- [x] **Task 10: Wire roster operations**
  - Scope: `MobCrew/MobCrew/Features/Roster/RosterView.swift`
  - Depends on: Task 8, Task 9
  - Acceptance:
    - Add mobster adds to active list
    - Remove deletes from roster
    - Bench moves to inactive list
    - Activate moves from inactive to active
    - Skip advances turn (Driver → Navigator → next)

### Persistence

- [x] **Task 11: Create PersistenceService**
  - Scope: `MobCrew/MobCrew/Core/Services/PersistenceService.swift`
  - Depends on: none
  - Acceptance:
    - Saves roster (active + inactive mobsters, nextDriverIndex) to UserDefaults
    - Saves timer duration setting to UserDefaults
    - Loads roster on app launch
    - Loads timer duration on app launch
    - Uses Codable for serialization

- [x] **Task 12: Create PersistenceServiceTests**
  - Scope: `MobCrew/MobCrewTests/Core/Services/PersistenceServiceTests.swift`
  - Depends on: Task 11
  - Acceptance:
    - Tests save/load round-trip for roster
    - Tests save/load for timer duration
    - Tests handling of empty/missing data
    - All tests pass
  - Notes: Use separate UserDefaults suite for tests.

- [x] **Task 13: Integrate persistence into app lifecycle**
  - Scope: `MobCrew/MobCrew/App/AppDelegate.swift`, `MobCrew/MobCrew/App/MobCrewApp.swift`
  - Depends on: Task 11
  - Acceptance:
    - Roster loaded on `applicationDidFinishLaunching`
    - Roster saved on changes (use observation or explicit save)
    - Timer duration persisted when changed

### Integration

- [x] **Task 14: Create shared AppState**
  - Scope: `MobCrew/MobCrew/Core/AppState.swift`
  - Depends on: Tasks 1-13
  - Acceptance:
    - Single `@Observable` class holding Roster, TimerState, TimerEngine
    - Injected into views via `@Environment` or passed directly
    - Connects timer completion to roster advanceTurn

- [ ] **Task 15: Wire up ContentView with real UI**
  - Scope: `MobCrew/MobCrew/ContentView.swift`
  - Depends on: Task 8, Task 14
  - Acceptance:
    - Shows RosterView
    - Shows timer display with controls
    - Functional start/stop/skip

- [ ] **Task 16: Initialize FloatingTimerController in AppDelegate**
  - Scope: `MobCrew/MobCrew/App/AppDelegate.swift`
  - Depends on: Task 5
  - Acceptance:
    - Creates and shows floating timer on launch
    - FloatingTimerController accessible for toggle

- [ ] **Task 17: Verify full integration**
  - Scope: `MobCrew/`
  - Depends on: Tasks 1-16
  - Acceptance:
    - Timer counts down from configured duration
    - Floating window shows countdown + Driver/Navigator
    - Can add/remove/bench/activate mobsters
    - Skip advances turn
    - Menu bar icon works with quick controls
    - Roster persists between app launches
    - All unit tests pass
    - `xcodebuild build` succeeds
    - `xcodebuild test` succeeds
