# PRD: Core Timer & Roster

| Field | Value |
|-------|-------|
| Status | ready |
| Date | 2026-02-01 |
| Plan | `../plans/todo/PLAN-001-core-timer-roster.md` |
| Depends on | PRD-000-project-scaffolding |

## Problem

Mob programming teams need a simple, unobtrusive timer to manage turn rotations. Existing solutions like dillonkearns/mobster are Electron-based, consuming unnecessary resources. macOS users deserve a native app that's lightweight, always visible, and integrates with the system.

## Goal

Deliver a working mob timer that teams can use for real sessions: start a timer, see who's driving/navigating, rotate turns, and persist state between sessions.

## Non-goals

- RPG/gamification mode (Phase 4)
- Break system with intervals (Phase 2)
- Global hotkeys (Phase 2)
- Drag-and-drop roster reordering (Phase 2)
- Auto-updates (Phase 3)
- Cross-platform support

## Users / Use case

- **Mob programming teams** (2-6 developers) who need a visible countdown timer showing current Driver and Navigator, with simple controls to start/stop/skip turns.

## Proposed change

### Timer

- Countdown timer (1-180 minutes, default 5 min)
- MM:SS display with current Driver/Navigator names
- Start, stop, skip (advance turn) controls

### Floating Timer Window

- Transparent, always-on-top overlay (~150×100px)
- Positioned at bottom-right of screen
- Shows countdown + Driver/Navigator
- NSPanel-based (borderless, non-activating)

### Roster Management

- Add mobsters by name
- Remove mobsters from roster
- Move between active (in rotation) and inactive (benched) lists
- Turn rotation: Driver → Navigator → next person

### Menu Bar

- Status bar icon with basic controls
- Quick access to start/stop timer
- Show current Driver/Navigator

### Persistence

- Save roster (active + inactive mobsters, driver index) to UserDefaults
- Save timer duration setting
- Restore state on app launch

## Acceptance criteria

- [ ] Timer counts down from configured duration (default 5 min)
- [ ] Timer displays MM:SS format with Driver and Navigator names
- [ ] Floating window is transparent, borderless, always-on-top, bottom-right
- [ ] Can add mobster by name to active roster
- [ ] Can remove mobster from roster
- [ ] Can bench mobster (move to inactive list)
- [ ] Can rotate in mobster (move from inactive to active)
- [ ] Skip advances turn: Driver → Navigator → next
- [ ] Start/stop controls work from floating window
- [ ] Menu bar icon appears with person.3.fill symbol
- [ ] Menu bar shows quick start/stop and current Driver/Navigator
- [ ] Roster persists between app launches
- [ ] Timer duration setting persists between app launches
- [ ] App targets macOS 14+ (Sonoma)

## UX notes

- Floating timer: semi-transparent dark background, white text, minimal chrome
- Timer window should not steal focus when clicked
- Menu bar popover for roster management and settings access

## Open questions / Risks

- Should floating timer have a close button or only hide via menu bar?
- Exact positioning offset from screen edge (20px suggested)
- Whether to show main window on first launch for onboarding

## Research

- `../research/mobster-native-macos-research.md` — original app analysis, data models
- `../research/feature-prioritization.md` — MVP scope definition
- `../research/ghostty-patterns-for-mobcrew.md` — NSPanel floating window patterns
- `../research/xcode-project-scaffolding.md` — project structure, SwiftUI setup
