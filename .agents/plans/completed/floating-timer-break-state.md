# Plan: Floating Timer Break State Support

## Problem

During break time, the main app correctly shows "Break Time!" with countdown and "Skip Break" button, but the floating widget continues to display Driver/Navigator roles with a regular play/pause button. This creates a confusing inconsistency.

## Goal

Update `FloatingTimerView` to reflect break state, matching the main app's break screen behavior.

## Tasks

- [x] **Task 1: Add break state conditional to FloatingTimerView**
  - Scope: `MobCrew/Features/FloatingTimer/FloatingTimerView.swift`
  - Depends on: none
  - Acceptance:
    - `FloatingTimerView.body` checks `appState.isOnBreak`
    - When on break, displays break-specific UI instead of roles
    - When not on break, displays current behavior unchanged
  - Notes: Use similar structure to `ContentView.swift` which conditionally renders `BreakScreenView`

- [x] **Task 2: Create compact break view for floating timer**
  - Scope: `MobCrew/Features/FloatingTimer/FloatingTimerView.swift`
  - Depends on: Task 1
  - Acceptance:
    - Shows "Break" label or icon to indicate break state
    - Shows countdown timer (reuse existing `displayTime` from timerState)
    - Shows "Skip" button that calls `appState.skipBreak()`
    - Maintains compact size appropriate for floating widget
    - Uses teal/blue gradient or accent to visually distinguish from normal timer
  - Notes: Keep it minimal - no need for full BreakScreenView, just essential info

- [x] **Task 3: Add preview for break state**
  - Scope: `MobCrew/Features/FloatingTimer/FloatingTimerView.swift`
  - Depends on: Task 2
  - Acceptance:
    - Add `#Preview` showing FloatingTimerView in break state
    - Existing preview continues to show normal state
  - Notes: Follow pattern from `BreakScreenView` preview

- [x] **Task 4: Test break state in floating timer**
  - Scope: `MobCrewTests/Features/FloatingTimer/`
  - Depends on: Task 2
  - Acceptance:
    - Build succeeds: `./scripts/build-release.sh`
    - All existing tests pass: `./scripts/test.sh`
    - Manual verification: trigger break, confirm floating widget shows break UI
  - Notes: May need to create test directory if it doesn't exist

## Out of Scope

- Menu bar status item changes during break (separate concern)
- Break notification sounds/alerts
- Customizable break widget appearance
