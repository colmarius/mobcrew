# PLAN-002c: Test Coverage Improvements

| Field | Value |
|-------|-------|
| Status | in-progress |
| Date | 2026-02-01 |
| PRD | N/A (technical debt) |
| Depends on | PLAN-001 |

## Overview

Add missing test coverage for core components: AppState integration tests, Roster.shuffle tests, and edge cases. This improves confidence before adding Phase 2 features.

---

## Tasks

### AppState Tests

- [x] **Task 1: Create AppStateTests**
  - Scope: `MobCrew/MobCrewTests/Core/AppStateTests.swift`
  - Depends on: none
  - Acceptance:
    - Test file created with test suite structure
    - Uses mock/test PersistenceService with isolated UserDefaults
    - Build succeeds

- [x] **Task 2: Test timer completion advances turn**
  - Scope: `MobCrew/MobCrewTests/Core/AppStateTests.swift`
  - Depends on: Task 1
  - Acceptance:
    - When timer completes, `roster.advanceTurn()` is called
    - Driver changes to next mobster
    - Timer resets to configured duration

- [x] **Task 3: Test skipTurn behavior**
  - Scope: `MobCrew/MobCrewTests/Core/AppStateTests.swift`
  - Depends on: Task 1
  - Acceptance:
    - `skipTurn()` advances turn
    - Timer resets to configured duration
    - Timer starts automatically after skip

- [ ] **Task 4: Test timer duration persistence**
  - Scope: `MobCrew/MobCrewTests/Core/AppStateTests.swift`
  - Depends on: Task 1
  - Acceptance:
    - Changing `timerDuration` triggers save to persistence
    - Duration persists across AppState instances

- [ ] **Task 5: Test roster changes trigger save**
  - Scope: `MobCrew/MobCrewTests/Core/AppStateTests.swift`
  - Depends on: Task 1
  - Acceptance:
    - Verify `saveRoster()` can be called
    - Consider adding observation-based auto-save test
  - Notes: Current implementation requires explicit `saveRoster()` calls

### Roster Shuffle Tests

- [ ] **Task 6: Add shuffle tests to RosterTests**
  - Scope: `MobCrew/MobCrewTests/Core/Models/RosterTests.swift`
  - Depends on: none
  - Acceptance:
    - Test shuffle randomizes order (run multiple times, verify at least one change)
    - Test shuffle resets nextDriverIndex to 0
    - Test shuffle with 0 mobsters is no-op
    - Test shuffle with 1 mobster is no-op (order unchanged)
    - Test inactive mobsters are not affected by shuffle

### Edge Case Tests

- [ ] **Task 7: Add addMobster edge case tests**
  - Scope: `MobCrew/MobCrewTests/Core/Models/RosterTests.swift`
  - Depends on: none
  - Acceptance:
    - Test adding mobster with empty name (should add or reject?)
    - Test adding mobster with whitespace-only name
    - Test adding duplicate name (allowed, different IDs)

- [ ] **Task 8: Add benchMobster edge cases for driver adjustment**
  - Scope: `MobCrew/MobCrewTests/Core/Models/RosterTests.swift`
  - Depends on: none
  - Acceptance:
    - Test benching current driver moves to next
    - Test benching last active mobster results in no driver
    - Test benching with nextDriverIndex at end wraps correctly

### Verification

- [ ] **Task 9: Run full test suite and verify coverage**
  - Scope: `MobCrew/`
  - Depends on: Tasks 1-8
  - Acceptance:
    - `xcodebuild test` succeeds
    - All new tests pass
    - No regressions in existing tests
