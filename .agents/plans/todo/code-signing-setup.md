# Plan: Code Signing Setup

## Overview

Set up proper code signing for MobCrew so accessibility permissions persist between builds.

## Background

From accessibility permission research (Task 2 of accessibility-permission-flow):
- App is currently ad-hoc signed
- This causes accessibility permissions to reset each build
- Proper signing maintains consistent app identity

## Tasks

- [ ] **Task 1: Configure Xcode code signing** (manual-verify)
  - Scope: Xcode project settings
  - Depends on: none
  - Acceptance:
    - Team is set to Apple Developer account in Signing & Capabilities
    - Signing Certificate is set to "Development" or "Developer ID Application"
    - Running `codesign -d -vv build/Release/MobCrew.app` shows valid Authority and TeamIdentifier
  - Notes:
    1. Open Xcode → MobCrew project → Signing & Capabilities tab
    2. Set **Team** to your Apple Developer account
    3. Set **Signing Certificate** to "Development" (for dev) or "Developer ID Application" (for release)

- [ ] **Task 2: Evaluate sandbox removal** (manual-verify)
  - Scope: `MobCrew.entitlements`
  - Depends on: Task 1
  - Acceptance:
    - Decision made on whether to disable sandbox for accessibility features
    - If disabling: `com.apple.security.app-sandbox` set to `false` or removed
    - Global hotkey works reliably after change
  - Notes:
    - Sandboxed apps have limited accessibility capabilities
    - Most accessibility apps (Alt-Tab, Raycast, Rectangle) are not sandboxed
    - Disabling sandbox means no Mac App Store distribution
