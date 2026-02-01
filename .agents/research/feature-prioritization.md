# MobCrew Feature Prioritization

## Overview

Prioritized features for the MobCrew macOS app, derived from analysis of the original [dillonkearns/mobster](https://github.com/dillonkearns/mobster) Elm/Electron app.

---

## 🟢 MVP (Must Have) — Phase 1

Core functionality needed for a usable mob programming timer.

| Feature | Description | Complexity |
|---------|-------------|------------|
| **Timer Core** | Countdown timer (1-180 min, default 5 min) | Low |
| **Timer Display** | MM:SS countdown showing Driver/Navigator names | Low |
| **Floating Timer Window** | Transparent, always-on-top overlay (bottom-right) | Medium |
| **Basic Roster** | Add/remove mobsters by name | Low |
| **Active/Inactive Lists** | Move mobsters between active (in rotation) and bench | Low |
| **Turn Rotation** | Advance turn: Driver → Navigator → next | Low |
| **Driver/Navigator Display** | Show current Driver and Navigator on continue screen | Low |
| **Start/Stop/Skip Controls** | Basic timer controls | Low |
| **Persistence** | Save roster and settings between sessions | Low |
| **Menu Bar Icon** | Basic menu bar presence with quick controls | Medium |

**Deliverable**: A working mob timer you can actually use for a session.

---

## 🟡 Should Have — Phase 2

Features that significantly improve the experience.

| Feature | Description | Complexity |
|---------|-------------|------------|
| **Drag & Drop Reorder** | Reorder mobsters via drag-and-drop | Medium |
| **Break Timer** | Configurable break intervals (every N turns) | Low |
| **Break Screen** | Dedicated break countdown UI | Low |
| **Break Progress Indicator** | Visual circles showing progress toward break | Low |
| **Shuffle Roster** | Randomize mobster order | Low |
| **System Notifications** | Notify when timer completes | Low |
| **Global Hotkey** | Show/hide window (Cmd+Shift+L) | Medium |
| **Active Mobsters File** | Write to `~/Library/Application Support/MobCrew/active-mobsters` for git integration | Low |
| **Keyboard Shortcuts** | Ctrl/Cmd+Enter to start, Alt+S to skip | Medium |

**Deliverable**: Full-featured timer with polish and workflow integrations.

---

## 🔵 Nice to Have — Phase 3

Enhancement features for power users.

| Feature | Description | Complexity |
|---------|-------------|------------|
| **Quick Rotate Search** | Fuzzy search to quickly find/rotate mobsters | Medium |
| **Configurable Hotkey** | User can change global hotkey | Medium |
| **Timer Position Toggle** | Timer moves to left side on hover | Low |
| **Skip Break with Tracking** | Skip break option (no analytics needed) | Low |
| **Tips Display** | Random mob programming tips on timer start | Low |
| **Multiple Keyboard Shortcuts** | Alt+1-9 to rotate out, Alt+A-P to rotate in | Medium |
| **Launch at Login** | Start app automatically on login | Low |
| **Auto-Update** | Sparkle-based updates | Medium |
| **Dark Mode Support** | Proper dark/light mode theming | Low |

**Deliverable**: Power-user features and polish.

---

## 🔴 Low Priority / Future Consideration

Features that add complexity without core value.

| Feature | Description | Why Deprioritize |
|---------|-------------|------------------|
| **RPG Mode** | Full gamification with roles, goals, badges | High complexity, niche usage |
| **Role Assignments** | Driver/Navigator/Mobber/Researcher/Sponsor roles | Tied to RPG mode |
| **Badge System** | Award badges for role goals | RPG mode dependency |
| **Goal Checklists** | Pre-turn checklists from Mob Programming RPG | RPG mode dependency |
| **Analytics** | Usage tracking | Privacy concerns, unnecessary |
| **Cross-platform** | Windows/Linux support | Native macOS focus |

---

## Recommended PRD Order

1. **PRD-001: Core Timer & Roster** (MVP Phase 1)
   - Timer, roster management, floating window, menu bar, persistence

2. **PRD-002: Breaks & Polish** (Phase 2)
   - Break system, notifications, global hotkey, keyboard shortcuts

3. **PRD-003: Power User Features** (Phase 3)
   - Quick rotate, tips, auto-update, launch at login

4. **PRD-004: RPG Mode** (Future)
   - Only if community demand exists

---

## Technical Notes

From original implementation:

- **Settings defaults**: 5 min timer, 5 min break, 5 intervals per break
- **Roster structure**: `{ mobsters: [], inactiveMobsters: [], nextDriver: 0 }`
- **Active mobsters file format**: Comma-separated names: `Jim Kirk, Spock, McCoy`
- **Global hotkey default**: Cmd+Shift+L (configurable, stored as single letter "L")
