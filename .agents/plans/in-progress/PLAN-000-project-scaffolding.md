# PLAN-000: Project Scaffolding

| Field | Value |
|-------|-------|
| Status | todo |
| Date | 2026-02-01 |
| PRD | `../../prds/PRD-000-project-scaffolding.md` |

## Overview

Create MobCrew Xcode project with feature-based folder structure, core model stubs, and SwiftUI app lifecycle.

---

## Tasks

- [x] **Task 1: Create Xcode project**
  - Scope: `MobCrew/MobCrew.xcodeproj`
  - Depends on: none
  - Acceptance:
    - macOS App template with SwiftUI interface created
    - Bundle ID: `com.colmarius.MobCrew`
    - Deployment target: macOS 14.0
    - Test target included
  - Notes: Use `xcodebuild` or create via Xcode CLI tools. Include MobCrewTests target.

- [x] **Task 2: Create folder structure**
  - Scope: `MobCrew/MobCrew/`
  - Depends on: Task 1
  - Acceptance:
    - `App/` folder with MobCrewApp.swift, AppDelegate.swift
    - `Core/Models/` folder exists
    - `Core/Services/` folder exists
    - `Features/FloatingTimer/`, `Features/MenuBar/`, `Features/Roster/`, `Features/Settings/` exist
    - `Helpers/Extensions/` folder exists
    - `Resources/Assets.xcassets` exists
  - Notes: Create placeholder files where needed to maintain folder structure.

- [x] **Task 3: Create MobCrewApp.swift with AppDelegate adaptor**
  - Scope: `MobCrew/MobCrew/App/MobCrewApp.swift`
  - Depends on: Task 2
  - Acceptance:
    - Uses `@main` and `@NSApplicationDelegateAdaptor(AppDelegate.self)`
    - Defines `WindowGroup` with placeholder ContentView
    - Builds without errors
  - Notes: See research/xcode-project-scaffolding.md for template.

- [x] **Task 4: Create AppDelegate.swift stub**
  - Scope: `MobCrew/MobCrew/App/AppDelegate.swift`
  - Depends on: Task 2
  - Acceptance:
    - Implements `NSApplicationDelegate`
    - Has `applicationDidFinishLaunching` stub
    - Builds without errors

- [x] **Task 5: Create Mobster model**
  - Scope: `MobCrew/MobCrew/Core/Models/Mobster.swift`
  - Depends on: Task 2
  - Acceptance:
    - Struct with `id: UUID` and `name: String`
    - Conforms to `Identifiable`, `Codable`, `Hashable`
    - Has initializer with default UUID
  - Notes: Simple value type, no RPG data in MVP.

- [x] **Task 6: Create Roster model**
  - Scope: `MobCrew/MobCrew/Core/Models/Roster.swift`
  - Depends on: Task 5
  - Acceptance:
    - Uses `@Observable` macro
    - Has `activeMobsters: [Mobster]`, `inactiveMobsters: [Mobster]`, `nextDriverIndex: Int`
    - Computed properties: `driver`, `navigator`
    - Methods: `advanceTurn()`, `addMobster(name:)`, `benchMobster(at:)`, `rotateIn(at:)`, `shuffle()`
    - Private `adjustDriverIndex(afterRemovalAt:)` helper
  - Notes: Core rotation logic from research doc.

- [x] **Task 7: Create TimerState model**
  - Scope: `MobCrew/MobCrew/Core/Models/TimerState.swift`
  - Depends on: Task 2
  - Acceptance:
    - Uses `@Observable` macro
    - Has `secondsRemaining: Int`, `totalSeconds: Int`, `isRunning: Bool`
    - Computed `displayTime: String` returns MM:SS format
    - Computed `progress: Double` returns 0.0-1.0
  - Notes: Include `TimerType` enum (regular/breakTimer).

- [x] **Task 8: Create ContentView placeholder**
  - Scope: `MobCrew/MobCrew/ContentView.swift`
  - Depends on: Task 2
  - Acceptance:
    - Simple SwiftUI view with "MobCrew" text
    - Builds and displays in window

- [x] **Task 9: Update .gitignore for Xcode artifacts**
  - Scope: `.gitignore`
  - Depends on: Task 1
  - Acceptance:
    - Ignores `xcuserdata/`, `DerivedData/`, `.build/`, `.swiftpm/`
    - Ignores `project.xcworkspace/` user data
    - Existing entries preserved

- [x] **Task 10: Create MobCrewTests folder structure**
  - Scope: `MobCrew/MobCrewTests/`
  - Depends on: Task 1
  - Acceptance:
    - `Core/Models/` subfolder exists
    - `Helpers/TestHelpers.swift` exists with placeholder
  - Notes: Mirror main target structure for organization.

- [ ] **Task 11: Create MobsterTests**
  - Scope: `MobCrew/MobCrewTests/Core/Models/MobsterTests.swift`
  - Depends on: Task 5, Task 10
  - Acceptance:
    - Uses Swift Testing framework (`import Testing`, `@Test`, `#expect`)
    - Tests Codable round-trip encoding/decoding
    - Tests Hashable conformance
    - All tests pass

- [ ] **Task 12: Create RosterTests**
  - Scope: `MobCrew/MobCrewTests/Core/Models/RosterTests.swift`
  - Depends on: Task 6, Task 10
  - Acceptance:
    - Uses Swift Testing framework
    - Tests `driver`/`navigator` computed properties
    - Tests `advanceTurn()` rotation logic
    - Tests `addMobster`, `benchMobster`, `rotateIn`
    - Tests driver index adjustment after removal
    - All tests pass

- [ ] **Task 13: Create TimerStateTests**
  - Scope: `MobCrew/MobCrewTests/Core/Models/TimerStateTests.swift`
  - Depends on: Task 7, Task 10
  - Acceptance:
    - Uses Swift Testing framework
    - Tests `displayTime` formatting (e.g., 125 seconds → "02:05")
    - Tests `progress` calculation
    - Tests edge cases (0 seconds, 0 total)
    - All tests pass

- [ ] **Task 14: Verify build and tests**
  - Scope: `MobCrew/`
  - Depends on: Tasks 1-13
  - Acceptance:
    - `xcodebuild build` succeeds without errors
    - `xcodebuild test` succeeds, all tests pass
    - App runs and shows placeholder window
