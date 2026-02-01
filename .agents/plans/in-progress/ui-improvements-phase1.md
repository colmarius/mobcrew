# UI Improvements Phase 1

## Overview

Address usability and clarity improvements identified in UI review. Focus on reducing redundancy, improving iconography clarity, and enhancing empty states.

## Tasks

- [x] **Task 1: Remove redundant Skip Turn button from roster panel**
  - Scope: `MobCrew/Features/Roster/RosterView.swift`
  - Depends on: none
  - Acceptance:
    - Skip Turn button removed from RosterView
    - Skip functionality remains accessible via timer controls only
    - Build succeeds with no warnings
  - Notes: The timer panel already has skip control; roster skip is redundant

- [x] **Task 2: Improve toggle active/bench icons**
  - Scope: `MobCrew/Features/Roster/MobsterRow.swift`
  - Depends on: none
  - Acceptance:
    - Active mobsters show a "bench" icon (e.g., `person.badge.minus` or `arrow.down.to.line`)
    - Benched mobsters show an "activate" icon (e.g., `person.badge.plus` or `arrow.up.to.line`)
    - Icons are visually distinct and intuitive
    - Help text updated to match new icons
  - Notes: Current arrow.down.circle/arrow.up.circle not immediately clear

- [x] **Task 3: Add empty state for roster**
  - Scope: `MobCrew/Features/Roster/RosterView.swift`
  - Depends on: Task 1
  - Acceptance:
    - When no mobsters exist (active or inactive), show helpful placeholder
    - Placeholder includes text like "Add your first mobster above"
    - Placeholder is styled appropriately (secondary color, centered)
  - Notes: Currently shows nothing when roster is empty

- [ ] **Task 4: Add drag-to-reorder for active mobsters**
  - Scope: `MobCrew/Features/Roster/RosterView.swift`, `MobCrew/Core/Models/Roster.swift`
  - Depends on: Task 1
  - Acceptance:
    - Add `moveMobster(from:to:)` method to Roster model
    - Active mobsters can be reordered via drag and drop using `onMove`
    - Reordering updates the roster model correctly
    - Driver/Navigator roles update based on new positions
    - Add tests for `moveMobster` in `RosterTests.swift`
    - Build and tests pass
  - Notes: Use SwiftUI's `onMove` modifier with `ForEach`; need List or explicit EditMode for drag handles

- [ ] **Task 5: Enhance role display in timer panel**
  - Scope: `MobCrew/Features/FloatingTimer/FloatingTimerView.swift` or main ContentView
  - Depends on: none
  - Acceptance:
    - Driver shown with "Driver" label (not just badge)
    - Navigator shown with "Navigator" label (not just badge)
    - Clear visual hierarchy between Driver and Navigator
    - Current mobster (driver) is more prominent
  - Notes: Left panel currently shows both equally; driver should be emphasized

## Verification

```bash
xcodebuild -project MobCrew/MobCrew.xcodeproj -scheme MobCrew -destination 'platform=macOS' build
xcodebuild test -project MobCrew/MobCrew.xcodeproj -scheme MobCrew -destination 'platform=macOS'
```

## Success Criteria

- All tasks completed and verified
- No redundant UI elements
- Clearer iconography throughout
- Better guidance for new users (empty states)
- Drag reordering works smoothly
