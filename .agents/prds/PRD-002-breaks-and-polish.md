# PRD: Breaks & Polish

| Field | Value |
|-------|-------|
| Status | draft |
| Date | 2026-02-01 |
| Plans | [`PLAN-002a`](../plans/todo/PLAN-002a-break-system.md), [`PLAN-002b`](../plans/todo/PLAN-002b-notifications-shortcuts-integrations.md) |
| Depends on | PRD-001-core-timer-roster |

## Problem

Long mob sessions without breaks lead to fatigue and reduced effectiveness. Teams need automated break reminders integrated into the rotation cycle. Additionally, power users need keyboard shortcuts and system notifications to manage the timer without context-switching from their IDE.

## Goal

Add break intervals, system notifications, keyboard shortcuts, and workflow integrations to make MobCrew a complete, polished mob programming tool.

## Non-goals

- Quick rotate fuzzy search (Phase 3)
- Configurable hotkey UI (Phase 3)
- Auto-update system (Phase 3)
- Launch at login (Phase 3)
- RPG/gamification mode (Phase 4)

## Users / Use case

- **Mob teams in long sessions** who need periodic breaks (every N turns)
- **Keyboard-driven developers** who want hotkeys to control the timer without mouse
- **Git-integrated workflows** that read the active mobsters file for commit attribution

## Proposed change

### Break System

- Configurable break interval (every N turns, default 5)
- Configurable break duration (default 5 min)
- Visual progress indicator showing turns until next break
- Dedicated break countdown screen
- Option to skip break

### System Notifications

- macOS notification when timer completes
- Notification when break starts

### Keyboard Shortcuts

- Cmd+Enter: Start/stop timer
- Cmd+S: Skip turn
- Cmd+Shift+L: Global hotkey to show/hide floating timer

### Workflow Integrations

- Shuffle roster button to randomize order
- Write active mobsters to `~/Library/Application Support/MobCrew/active-mobsters` (comma-separated names for git integration)

## Acceptance criteria

- [ ] Break interval configurable (1-10 turns, default 5)
- [ ] Break duration configurable (1-30 min, default 5 min)
- [ ] Visual indicator shows progress toward next break (e.g., filled circles)
- [ ] Break screen displays with countdown when break triggers
- [ ] Can skip break and continue with rotation
- [ ] macOS notification fires when mob turn timer completes
- [ ] macOS notification fires when break starts
- [ ] Cmd+Enter starts/stops timer from main window
- [ ] Cmd+S skips turn from main window
- [ ] Cmd+Shift+L global hotkey toggles floating timer visibility
- [ ] Shuffle button randomizes active mobster order
- [ ] Active mobsters file written on roster changes
- [ ] Active mobsters file format: comma-separated names (e.g., `Jim Kirk, Spock, McCoy`)
- [ ] Unit tests pass for break tracking logic
- [ ] Unit tests pass for active mobsters file writing

## UX notes

- Break progress: row of circles below timer (filled = completed turns, empty = remaining)
- Break screen: prominent countdown, different color scheme (calming blue/green)
- Skip break button clearly visible but not prominent
- Global hotkey should work even when app is in background

## Open questions / Risks

- Should break notification include sound? (defer to system preference)
- Global hotkey conflict detection with other apps
- Whether to pause break timer if user interacts, or run continuously

## Research

- `../research/feature-prioritization.md` — Phase 2 scope
- `../research/mobster-native-macos-research.md` — original break implementation details
