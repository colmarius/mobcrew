# Progress

## Current Slice

Implementation and verification are complete. The user explicitly waived transfer and independent
review of the generated demo video and frames on 2026-08-17.

## Observed Evidence

- Native reproduction: dragging the floating panel from `(1312,646)` to `(942,670)`, then hiding and
  showing it from Finder with global `⌘⇧L`, moved it back to `(1312,651)`.
- Root cause: `FloatingTimerController.show()` positioned the window on every reveal.
- Integrated fix: position the panel only when creating it; subsequent reveals preserve its origin.
- Corrected native interaction: after dragging to `(942,696)`, two Finder `⌘⇧L` toggles preserved
  `(942,696)`.
- Focused `FloatingTimerControllerTests` and the full native suite passed on macOS 26.5.2 with Xcode
  26.6 / Swift 6.3.3. The full run reported 12 suites and 178 passing test-case lines.
- The fixed 180×160 panel was not clipped: Take, Pause, Resume, and Skip Break controls were visible,
  inside the AX geometry, and interactive.

## Remaining Verification

- Demo-video transfer and frame review were skipped at the user's request.
- Launch at Login and notification delivery remain unverified because the native audit intentionally
  did not mutate login state or system permissions.
