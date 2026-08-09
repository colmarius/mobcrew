# MobCrew Session Reliability and UX Stabilization

Status: in-progress
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
app source or unit tests, so Tasks 1-9 remain open; it did complete the current-state public
documentation overhaul, narrowing Task 10 to behavior-change deltas and final observed validation.
Saved teams, cloud sync, forced full-screen breaks, and other speculative expansion are out of scope.
Implementation began on the rebased audit branch. Task 1's authoritative session phase, guarded
commands, shared surface capabilities, and hermetic transition coverage are pushed but awaiting a
Mac test gate; independent Task 2 roster invariants are the current implementation slice.

## Artifacts

- Research: [Audit findings](research.md)
- PRD: none
- Plan: [Session reliability and UX stabilization plan](plan.md)
- Progress: [Execution progress](progress.md)
- Decisions: none
- Handoffs: none

## Next Action

- Run the focused Mac build/test gate for Tasks 1-2, fix any failures, record observed evidence, and
  check off only the accepted tasks before advancing to Task 3.

## Open Questions

- [ ] Confirm on a logged-in Mac whether Carbon hotkey registration needs Accessibility permission
  on every supported macOS version; Task 7 uses the result as an implementation gate.
