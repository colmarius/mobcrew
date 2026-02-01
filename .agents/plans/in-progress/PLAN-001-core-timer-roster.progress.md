# PLAN-001 Progress Log

| Field | Value |
|-------|-------|
| Started | 2026-02-01 |
| Current Task | Task 4 |
| Tasks Completed | 3 |

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
