# MobCrew Session Reliability and UX Stabilization

Status: blocked
Category: product
Updated: 2026-08-09

## Why

Turn the post-PR #1 product and engineering audit into a focused stabilization effort that makes
MobCrew trustworthy during real mob-programming sessions. Prioritize state correctness, elapsed-time
accuracy, safe roster changes, first-launch trust, accessibility, and recovery over new feature breadth.

## Summary

The audit of `main` at `03fb0ea169c545ab8f1e7cee86e91d7503eb846a` found a solid MVP with
several high-impact cross-surface state defects and product-friction risks. An Oracle stress test
refined the active plan so authoritative phase modeling and break policy precede deadline recovery,
while lower-confidence floating/login and richer roster correction remain non-blocking follow-ups.
A 2026-08-08 independent source-validated review confirmed all findings and citations, added the
scene-observed roster-persistence defect to Tasks 2/6, and fixed the break-cadence-while-disabled
ambiguity in Task 5.
The branch was rebased onto `origin/main` at `50659f0` on 2026-08-09. That mainline work changed no
app source or unit tests, so Tasks 1-9 were initially open; it did complete the current-state public
documentation overhaul, narrowing Task 10 to behavior-change deltas and final observed validation.
Saved teams, cloud sync, forced full-screen breaks, and other speculative expansion are out of scope.
Implementation is active on the rebased audit branch. Tasks 1-2 established the authoritative
session phase and identity-preserving roster operations; Task 3 then separated configured duration
from current-cycle progress and aligned both controls. Task 4 replaced delivered-tick subtraction
with deadline-based elapsed time, and Task 5 made explicit break prompts disable-able without hidden
cadence. Tasks 1-5 passed focused and full native tests on the available Mac runner. Task 6 versioned
session recovery now also passed focused and full native tests there. Task 7's logged-in Mac permission
gate proved Carbon registration and delivery do not require Accessibility on the available host; the
resulting AX-removal and registration-status implementation passed focused, full-suite, and signed-app
validation using Xcode 26.6 / Swift 6.3. Task 8 now has a service-backed implementation and focused
tests for truthful Notification and Launch at Login status; Xcode 26.6 focused/full tests and live
Settings inspection passed. Task 9 accessibility and large-roster reachability is now active.
The implementation now has single-List roster reachability, identity-preserving Move Up/Down paths,
contextual semantics across core surfaces, and injected one-shot transition announcements; exact
Xcode 26.6 focused/full tests pass. An isolated 20-person harness verified initial AX semantics and
announcement delivery. Manual inspection then found that both main panes retained intrinsic/fixed
widths when the window expanded, wasting available space and clipping long participant names. A
responsive layout correction is pushed and passed exact-toolchain focused tests plus native geometry,
AX, splitter, minimum/expanded-window, and increased-text checks. User inspection confirms the normal
expanded layout. Task 9 now awaits only interactive VoiceOver, Full Keyboard Access, and display-option
observations before acceptance. Task 10's preparatory truth audit corrected the remaining shortcut,
Tips, recovery, and local-session-data wording; its final native/manual gate still depends on Task 9.

## Artifacts

- Research: [Audit findings](research.md)
- PRD: none
- Plan: [Session reliability and UX stabilization plan](plan.md)
- Progress: [Execution progress](progress.md)
- Decisions: none
- Handoffs: none

## Next Action

- Finish [Task 9](plan.md#task-9-make-core-controls-accessible-and-large-rosters-reachable) against the
  open isolated app: activate one person-specific Move action with VoiceOver and Full Keyboard Access,
  confirm handoff/break announcements, and inspect Increase Contrast plus Differentiate Without Color.
  Then record the results and run Task 10's final full-suite/documentation gate. Older macOS coverage
  is not required.
