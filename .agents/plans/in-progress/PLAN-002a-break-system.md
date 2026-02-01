# PLAN-002a: Break System

| Field | Value |
|-------|-------|
| Status | in-progress |
| Date | 2026-02-01 |
| PRD | [`PRD-002`](../../prds/PRD-002-breaks-and-polish.md) |
| Depends on | PLAN-001 |

## Overview

Implement break intervals with configurable timing, visual progress indicator, and dedicated break countdown screen.

---

## Tasks

### Break State Model

- [x] **Task 1: Add BreakState to AppState**
  - Scope: `MobCrew/MobCrew/Core/AppState.swift`
  - Depends on: none
  - Acceptance:
    - Add `breakInterval: Int` (turns between breaks, default 5)
    - Add `breakDuration: Int` (seconds, default 300)
    - Add `turnsSinceBreak: Int` (counter, starts at 0)
    - Add `isOnBreak: Bool` flag
    - Add `breakSecondsRemaining: Int` for break countdown
  - Notes: Consider grouping break-related properties in a struct

- [x] **Task 2: Add break settings persistence**
  - Scope: `MobCrew/MobCrew/Core/Services/PersistenceService.swift`
  - Depends on: Task 1
  - Acceptance:
    - Save breakInterval to UserDefaults
    - Save breakDuration to UserDefaults
    - Load break settings on app launch
    - Add tests in PersistenceServiceTests

### Break Logic

- [ ] **Task 3: Implement break tracking in turn advancement**
  - Scope: `MobCrew/MobCrew/Core/AppState.swift`
  - Depends on: Task 1
  - Acceptance:
    - Increment `turnsSinceBreak` when `advanceTurn()` is called
    - When `turnsSinceBreak >= breakInterval`, trigger break
    - Reset `turnsSinceBreak` to 0 after break completes
    - Add `triggerBreak()` method that sets `isOnBreak = true`

- [ ] **Task 4: Create BreakTimer functionality**
  - Scope: `MobCrew/MobCrew/Core/Services/TimerEngine.swift`
  - Depends on: Task 3
  - Acceptance:
    - Add `startBreak(duration:)` method
    - Reuse existing timer countdown logic
    - Add `onBreakComplete` callback
    - When break completes, set `isOnBreak = false`

- [ ] **Task 5: Add break logic tests**
  - Scope: `MobCrew/MobCrewTests/Core/BreakLogicTests.swift`
  - Depends on: Tasks 3, 4
  - Acceptance:
    - Test turnsSinceBreak increments correctly
    - Test break triggers at correct interval
    - Test break countdown works
    - Test turnsSinceBreak resets after break
    - All tests pass

### Break UI

- [ ] **Task 6: Create BreakProgressView**
  - Scope: `MobCrew/MobCrew/Features/Break/BreakProgressView.swift`
  - Depends on: Task 1
  - Acceptance:
    - Row of circles equal to breakInterval count
    - Filled circles for completed turns (turnsSinceBreak)
    - Empty circles for remaining turns
    - Compact design suitable for timer panel
  - Notes: Use SF Symbols `circle.fill` and `circle`

- [ ] **Task 7: Create BreakScreenView**
  - Scope: `MobCrew/MobCrew/Features/Break/BreakScreenView.swift`
  - Depends on: Task 4
  - Acceptance:
    - Full-screen or prominent overlay
    - Shows "Break Time!" heading
    - MM:SS countdown for break duration
    - Calming color scheme (blue/green tones)
    - "Skip Break" button
    - "Break complete" transitions back to normal timer

- [ ] **Task 8: Integrate BreakProgressView into timer display**
  - Scope: `MobCrew/MobCrew/ContentView.swift`, `MobCrew/MobCrew/Features/FloatingTimer/FloatingTimerView.swift`
  - Depends on: Task 6
  - Acceptance:
    - BreakProgressView appears below main timer
    - Visible in both main window and floating timer
    - Updates as turns advance

- [ ] **Task 9: Integrate BreakScreenView into app flow**
  - Scope: `MobCrew/MobCrew/ContentView.swift`
  - Depends on: Task 7
  - Acceptance:
    - When `isOnBreak == true`, show BreakScreenView
    - Skip button calls `skipBreak()` and returns to normal view
    - Break completion returns to normal view automatically

### Break Settings UI

- [ ] **Task 10: Add break settings to settings view**
  - Scope: `MobCrew/MobCrew/Features/Settings/` (create if needed)
  - Depends on: Task 2
  - Acceptance:
    - Stepper or picker for break interval (1-10 turns)
    - Stepper or picker for break duration (1-30 minutes)
    - Settings persist when changed
    - Accessible from menu bar or main window

- [ ] **Task 11: Verify full break system integration**
  - Scope: `MobCrew/`
  - Depends on: Tasks 1-10
  - Acceptance:
    - Break triggers after configured number of turns
    - Break countdown displays correctly
    - Progress indicator shows correct state
    - Skip break works
    - Settings persist between launches
    - `xcodebuild build` succeeds
    - `xcodebuild test` succeeds
