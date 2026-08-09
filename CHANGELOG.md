# Changelog

All notable changes to MobCrew are documented in this file. This project follows
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2026-08-09

### Added

- Versioned session recovery for running, paused, and pending-break sessions, including safe
  reconciliation when a timer expired while the app was closed.
- Optional breaks with an explicit Take Break or Skip Break decision and a completion alert.
- Separate, live status for Notification authorization and Launch at Login registration, with
  recovery links when macOS requires user action.
- Accessible transition announcements, contextual control descriptions, keyboard roster ordering,
  and a scrollable, responsive roster for larger teams.

### Changed

- Unified the main window, menu bar, floating timer, and break screen around one phase-aware session
  model with consistent Start, Pause, Resume, Reset, Skip, and break behavior.
- Made countdowns deadline-based so delayed refreshes, sleep, and wake do not lose elapsed time.
- Duration changes while a timer is running or paused now apply to the next turn; idle changes apply
  immediately. Both duration controls use the same 1–60 minute range.
- Roster removal and reordering now preserve the current driver's identity when possible.
- The ⌘⇧L global shortcut no longer requests Accessibility permission; Settings reports Carbon
  registration failures and provides a retry action.
- Migrated the app and tests to Swift 6 and added deterministic coverage for session transitions,
  timer recovery, persistence, roster invariants, and macOS integration status.

### Fixed

- Skipping during a break no longer advances the roster or starts a regular timer inside break state.
- Delayed timer delivery no longer makes the countdown run slow or complete more than once.
- Corrupt, incompatible, or repeatedly restored session snapshots fall back safely without erasing
  the saved roster or settings.
- Notification and Launch at Login controls no longer imply success when macOS denied or failed an
  operation.

### Distribution notes

- MobCrew still requires macOS 14 or later.
- This release remains ad-hoc signed and is not Developer ID signed or notarized. macOS may require
  confirmation in System Settings → Privacy & Security on first launch.
- The release artifact's supported architectures must be confirmed and recorded during qualification.

## [0.2.0] - 2026-02-01

### Added

- Initial public release of the native macOS mob programming timer.
- Configurable turn timer with sound alerts.
- Driver and navigator roster management with drag-and-drop reordering.
- Floating always-on-top timer, break overlay, menu bar integration, global keyboard shortcut, and
  dark mode support.

[Unreleased]: https://github.com/colmarius/mobcrew/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/colmarius/mobcrew/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/colmarius/mobcrew/releases/tag/v0.2.0
