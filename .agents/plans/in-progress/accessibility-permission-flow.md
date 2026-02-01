# Plan: Investigate Accessibility Permission Flow

## Problem

When the user clicks "Open System Settings" from the accessibility permission alert:

1. The app doesn't automatically appear in the Accessibility list
2. `AXIsProcessTrustedWithOptions` with prompt only works once per app identity
3. User must manually add the app via the + button

## Tasks

- [x] **Task 1: Research macOS accessibility permission behavior**
  - Scope: Research
  - Depends on: none
  - Acceptance:
    - Understand when apps auto-appear in Accessibility list
    - Document difference between debug builds vs release builds
    - Understand app identity/signing requirements
  - Notes: Check how Mobster, Raycast, and other apps handle this

- [ ] (manual-verify) **Task 2: Test code-signed release build**
  - Scope: Build/signing configuration
  - Depends on: Task 1
  - Acceptance:
    - Create properly signed build
    - Verify if signed apps auto-appear in list
    - Document findings

- [ ] **Task 3: Improve permission UX**
  - Scope: `MobCrew/MobCrew/App/AppDelegate.swift`, `GlobalHotkeyService.swift`
  - Depends on: Task 1
  - Acceptance:
    - Clear instructions in alert when manual add is required
    - Consider showing path to app in alert message
    - Handle "already denied" case gracefully
  - Notes: May need different messaging for first-time vs repeat prompts

- [ ] **Task 4: Add permission status polling**
  - Scope: `MobCrew/MobCrew/Core/Services/GlobalHotkeyService.swift`
  - Depends on: Task 3
  - Acceptance:
    - Poll `AXIsProcessTrusted()` after opening Settings
    - Auto-enable hotkey when permission granted
    - Show confirmation to user
