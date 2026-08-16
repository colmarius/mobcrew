# Progress

## Current Slice

Task 3 is blocked only on transferring the generated movie and contact sheet from the disconnected
macOS runner for independent coordinator inspection.

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
- The runner reports a 74-second H.264 movie with 148 decoded frames and an all-frame visual review,
  but this coordinating thread has not accepted that delegated evidence without the actual files.

## Remaining Verification

- Transfer `.amp/in/artifacts/usability-demo.mov` and
  `.amp/in/artifacts/usability-demo-contact-sheet.png` after the macOS runner reconnects.
- Verify checksums and metadata, extract all 148 decoded frames locally, and inspect them before
  completing the work item.
