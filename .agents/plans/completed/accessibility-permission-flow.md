# Plan: Accessibility Permission Flow (Completed)

## Overview

Improve the accessibility permission request flow for MobCrew's global hotkey feature.

## Completed: 2026-02-01

---

## Tasks

- [x] **Task 1: Research macOS accessibility permission behavior**
  - Scope: Research
  - Acceptance:
    - Documented when apps auto-appear in Accessibility list
    - Documented debug vs release build behavior
    - Documented app identity/signing requirements
    - Documented how other apps handle this
  - Result: Created `.agents/research/accessibility-permissions.md`

- [x] **Task 2: Test code-signed release build** (manual-verify)
  - Scope: Build process
  - Acceptance:
    - Documented current signing state (ad-hoc)
    - Documented solution requirements
  - Result: Extracted to separate plan `todo/code-signing-setup.md`

- [x] **Task 3: Improve permission UX**
  - Scope: `AppDelegate.swift`
  - Acceptance:
    - First-time users see simpler message explaining system prompt
    - Repeat users see step-by-step manual add instructions
    - Uses symbolic hotkey display (⌘⇧L)
  - Result: Implemented with `hasRequestedPermissionBefore` UserDefaults flag

- [x] **Task 4: Add permission status polling**
  - Scope: `GlobalHotkeyService.swift`, `AppDelegate.swift`
  - Acceptance:
    - App polls `AXIsProcessTrusted()` after user opens Settings
    - Automatically detects when permission is granted
    - Enables hotkey and shows confirmation
  - Result: Implemented with 0.5s polling using DispatchSourceTimer

---

## Summary

- **Research**: Documented macOS accessibility permission behavior
- **UX**: Improved alert messaging with context-aware instructions
- **Polling**: Auto-detect permission grants and enable hotkey
- **Signing**: Manual setup task extracted to separate plan
