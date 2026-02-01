# PLAN-003: Power User Essentials

**PRD Reference**: PRD-003 (Phase 3 - Nice to Have)
**Status**: TODO
**Priority**: Low
**Estimated Effort**: 1-2 days

## Overview

Implement low-effort, high-value Phase 3 features that enhance the user experience without adding significant complexity.

## Scope

Features included:
- Launch at Login
- Tips Display
- Dark Mode verification/polish

Features explicitly excluded (too complex for value):
- Configurable Hotkey
- Timer Position Toggle
- Multiple Keyboard Shortcuts (Alt+1-9)
- Auto-Update (Sparkle)
- Quick Rotate Search

---

## Tasks

- [ ] **Task 1: Launch at Login**
  - Scope: `App/`, new `LaunchAtLoginService`
  - Depends on: none
  - Acceptance:
    - Settings has "Launch at Login" toggle
    - Uses `SMAppService` (macOS 13+) or `LSSharedFileList` for login item registration
    - Setting persists across app restarts
    - Toggle reflects actual system state
  - Notes: Use modern `SMAppService.mainApp` API

- [ ] **Task 2: Tips Display**
  - Scope: `Features/Tips/`, `ContentView.swift`
  - Depends on: none
  - Acceptance:
    - Shows random mob programming tip when timer starts
    - Tips displayed in main window (not floating timer)
    - At least 10 tips included (source from mobster repo)
    - Tip changes on each timer start
  - Notes: Check `.agents/reference/mobster/` for original tips

- [ ] **Task 3: Dark Mode Verification**
  - Scope: All UI views
  - Depends on: none
  - Acceptance:
    - All views render correctly in light and dark mode
    - No hardcoded colors that break in either mode
    - Floating timer remains visible in both modes
    - Document any issues found and fixed
  - Notes: SwiftUI should handle most cases; verify floating timer transparency

---

## Verification

```bash
# Build and run
./scripts/run.sh

# Manual testing checklist:
# - [ ] Launch at Login toggle works in Settings
# - [ ] App appears in System Settings → Login Items after enabling
# - [ ] Tips appear when starting timer
# - [ ] Tips rotate/change between timer starts
# - [ ] UI looks correct in System Settings → Appearance → Light
# - [ ] UI looks correct in System Settings → Appearance → Dark
```

## Notes

- All three tasks are independent and can be done in parallel
- Launch at Login requires entitlements for sandboxed apps (if ever sandboxed)
