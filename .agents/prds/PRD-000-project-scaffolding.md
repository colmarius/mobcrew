# PRD: Project Scaffolding

| Field | Value |
|-------|-------|
| Status | ready |
| Date | 2026-02-01 |
| Plan | `../plans/todo/PLAN-000-project-scaffolding.md` |

## Problem

Before implementing any features, we need a properly structured Xcode project with the recommended architecture, folder organization, and initial file templates. Without this foundation, feature development will be disorganized.

## Goal

Create a buildable Xcode project with feature-based folder structure, core model stubs, and SwiftUI app lifecycle ready for feature implementation.

## Non-goals

- Implementing actual timer logic
- Creating functional UI beyond placeholder views
- Adding Swift Package dependencies (added per-feature in later PRDs)
- App Store configuration

## Users / Use case

- **Developer** starting feature implementation needs a clean, organized project structure matching the Ghostty-inspired architecture.

## Proposed change

### Xcode Project

- Create MobCrew.xcodeproj with SwiftUI app template
- Target macOS 14+ (Sonoma)
- Bundle ID: com.colmarius.MobCrew

### Folder Structure

```text
MobCrew/
├── App/
│   ├── MobCrewApp.swift
│   └── AppDelegate.swift
├── Core/
│   ├── Models/
│   │   ├── Mobster.swift
│   │   ├── Roster.swift
│   │   └── TimerState.swift
│   └── Services/
│       └── (placeholder)
├── Features/
│   ├── FloatingTimer/
│   ├── MenuBar/
│   ├── Roster/
│   └── Settings/
├── Helpers/
│   └── Extensions/
└── Resources/
    └── Assets.xcassets

MobCrewTests/
├── Core/
│   ├── Models/
│   │   ├── MobsterTests.swift
│   │   ├── RosterTests.swift
│   │   └── TimerStateTests.swift
│   └── Services/
│       └── (placeholder)
└── Helpers/
    └── TestHelpers.swift
```

### Initial Files

- MobCrewApp.swift with @NSApplicationDelegateAdaptor
- AppDelegate.swift stub for AppKit bridge
- Core models: Mobster, Roster, TimerState (from research)
- ContentView.swift placeholder

### Test Files

- MobsterTests.swift with Codable/Hashable tests
- RosterTests.swift with driver/navigator rotation tests
- TimerStateTests.swift with displayTime/progress tests
- Use Swift Testing framework (`import Testing`, `@Test`, `#expect`)

### Configuration

- Info.plist: LSUIElement = NO (keep dock icon during development)
- Entitlements: app sandbox enabled

## Acceptance criteria

- [ ] Xcode project builds without errors (⌘B)
- [ ] App runs and shows placeholder window (⌘R)
- [ ] Folder structure matches specification above
- [ ] MobCrewApp.swift uses @NSApplicationDelegateAdaptor
- [ ] AppDelegate.swift exists with applicationDidFinishLaunching stub
- [ ] Mobster model is Identifiable, Codable, Hashable
- [ ] Roster model uses @Observable with activeMobsters, inactiveMobsters, nextDriverIndex
- [ ] TimerState model uses @Observable with secondsRemaining, totalSeconds, isRunning
- [ ] Deployment target is macOS 14.0
- [ ] .gitignore updated for Xcode artifacts
- [ ] Test target included with MobCrewTests folder structure
- [ ] Tests run and pass (⌘U)
- [ ] MobsterTests verifies Codable round-trip encoding
- [ ] RosterTests verifies driver/navigator rotation logic
- [ ] TimerStateTests verifies displayTime formatting (MM:SS)

## UX notes

N/A - infrastructure only

## Open questions / Risks

- None - straightforward project setup

## Research

- `../research/xcode-project-scaffolding.md` — complete scaffolding guide
- `../research/ghostty-patterns-for-mobcrew.md` — folder structure patterns
- `../research/testing-strategy.md` — testing approach and Swift Testing framework
