# Progress: UI Improvements Phase 1

## Task 1: Remove redundant Skip Turn button from roster panel

**Thread**: https://ampcode.com/threads/T-019c1b00-b0c4-716f-bd09-48298500de35
**Status**: completed
**Iteration**: 1

### Changes

- `MobCrew/MobCrew/Features/Roster/RosterView.swift` - Removed skipButton usage and definition

### Commands Run

- `xcodebuild build` ✓

### Next

- Task 2: Improve toggle active/bench icons

---

## Task 2: Improve toggle active/bench icons

**Thread**: https://ampcode.com/threads/T-019c1b00-b0c4-716f-bd09-48298500de35
**Status**: completed
**Iteration**: 1

### Changes

- `MobCrew/MobCrew/Features/Roster/MobsterRow.swift` - Changed icons from arrow.down/up.circle to person.badge.minus/plus with semantic colors (orange/green)

### Commands Run

- `xcodebuild build` ✓

### Next

- Task 3: Add empty state for roster

---

## Task 3: Add empty state for roster

**Thread**: https://ampcode.com/threads/T-019c1b00-b0c4-716f-bd09-48298500de35
**Status**: completed
**Iteration**: 1

### Changes

- `MobCrew/MobCrew/Features/Roster/RosterView.swift` - Added emptyStateSection with icon, title, and helpful text

### Commands Run

- `xcodebuild build` ✓

### Next

- Task 4: Add drag-to-reorder for active mobsters

---

## Task 4: Add drag-to-reorder for active mobsters

**Thread**: https://ampcode.com/threads/T-019c1b00-b0c4-716f-bd09-48298500de35
**Status**: completed
**Iteration**: 1

### Changes

- `MobCrew/MobCrew/Core/Models/Roster.swift` - Added moveMobster(from:to:) method
- `MobCrew/MobCrew/Features/Roster/RosterView.swift` - Converted active section to List with onMove support
- `MobCrew/MobCrewTests/Core/Models/RosterTests.swift` - Added 3 tests for moveMobster

### Commands Run

- `xcodebuild build` ✓
- `xcodebuild test` ✓

### Next

- Task 5: Enhance role display in timer panel

---

## Task 5: Enhance role display in timer panel

**Thread**: https://ampcode.com/threads/T-019c1b00-b0c4-716f-bd09-48298500de35
**Status**: completed
**Iteration**: 1

### Changes

- `MobCrew/MobCrew/Features/FloatingTimer/FloatingTimerView.swift` - Changed layout from HStack to VStack, added full "Driver"/"Navigator" labels, driver now more prominent (larger font, brighter color)

### Commands Run

- `xcodebuild build` ✓
- `xcodebuild test` ✓

### Next

- All tasks complete!

---

