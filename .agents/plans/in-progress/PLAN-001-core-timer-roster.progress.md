# PLAN-001 Progress Log

| Field | Value |
|-------|-------|
| Started | 2026-02-01 |
| Current Task | Task 12 |
| Tasks Completed | 11 |

---

## Progress Entries

### 2026-02-01 — Session Start

- Moved plan from `todo/` to `in-progress/`
- Starting with Task 1: Create TimerEngine service

### Task 1: Create TimerEngine service ✅

- Created `MobCrew/MobCrew/Core/Services/TimerEngine.swift`
- Uses `@Observable` macro
- Implements `start()`, `stop()`, `reset(duration:)`, `toggle()` methods
- Uses `Timer.publish` with Combine for countdown
- Updates `TimerState.secondsRemaining` each second
- Fires callback on completion
- Build succeeded

### Task 2: Create TimerEngineTests ✅

- Created `MobCrew/MobCrewTests/Core/Services/TimerEngineTests.swift`
- Uses Swift Testing framework (`@Suite`, `@Test`, `#expect`)
- Tests initial state, reset, start/stop, toggle, pause/resume
- Async tests for countdown decrement and completion callback
- All tests pass

### Task 3: Create FloatingTimerWindow (NSPanel) ✅

- Created `MobCrew/MobCrew/Features/FloatingTimer/FloatingTimerWindow.swift`
- NSPanel subclass with borderless, nonactivatingPanel style
- level = .floating (always on top)
- Transparent background (isOpaque = false, backgroundColor = .clear)
- collectionBehavior = [.canJoinAllSpaces, .stationary]
- isMovableByWindowBackground = true for dragging
- Build succeeded

### Task 4: Create FloatingTimerView ✅

- Created `MobCrew/MobCrew/Features/FloatingTimer/FloatingTimerView.swift`
- SwiftUI view showing MM:SS countdown
- Shows Driver (D) and Navigator (N) names with role indicators
- Semi-transparent dark background with rounded corners
- White text, minimal chrome
- Start/Stop button (play/pause icon)
- Build succeeded

### Task 5: Create FloatingTimerController ✅

- Created `MobCrew/MobCrew/Features/FloatingTimer/FloatingTimerController.swift`
- Manages FloatingTimerWindow lifecycle
- show(), hide(), toggle() methods
- Positions window at bottom-right with 20px offset
- Hosts FloatingTimerView via NSHostingView
- updateView() method for refreshing state
- Build succeeded

### Paused after 5 tasks for review

Next task: Task 6 - Create MenuBarView

### Task 6: Create MenuBarView ✅

- Created `MobCrew/MobCrew/Features/MenuBar/MenuBarView.swift`
- Shows current Driver/Navigator with role labels
- Start/Stop timer button with keyboard shortcut (Space)
- Skip turn button with keyboard shortcut (⌘→)
- Link to open settings with keyboard shortcut (⌘,)
- Clean layout with dividers
- Build succeeded

### Task 7: Add MenuBarExtra to MobCrewApp ✅

- Updated `MobCrew/MobCrew/App/MobCrewApp.swift`
- Added MenuBarExtra with `person.3.fill` system image
- Shows MenuBarView in popover
- Connected to roster and timer state
- Added files from Tasks 1-6 to Xcode project (pbxproj)
- Build succeeded, all tests pass

### Task 8: Create RosterView ✅

- Created `MobCrew/MobCrew/Features/Roster/RosterView.swift`
- Shows active mobsters list with Driver/Navigator indicators
- Shows inactive (benched) mobsters list
- Add mobster text field + button
- Visual distinction between active and inactive sections
- Build succeeded

### Task 9: Create MobsterRow ✅

- Created `MobCrew/MobCrew/Features/Roster/MobsterRow.swift`
- Displays mobster name with role indicator if Driver or Navigator
- Remove button (trash icon)
- Bench/Activate button depending on list
- Build succeeded

### Task 10: Wire roster operations ✅

- All operations wired in RosterView:
  - Add mobster adds to active list
  - Remove deletes from roster
  - Bench moves to inactive list
  - Activate moves from inactive to active
  - Skip advances turn (Driver → Navigator → next)
- Build succeeded

### Task 11: Create PersistenceService ✅

- Created `MobCrew/MobCrew/Core/Services/PersistenceService.swift`
- Uses Codable PersistedRoster struct for roster serialization
- saveRoster/loadRoster with JSONEncoder/JSONDecoder to UserDefaults
- saveTimerDuration/loadTimerDuration for timer settings
- Supports custom UserDefaults suite for testing
- Build succeeded
