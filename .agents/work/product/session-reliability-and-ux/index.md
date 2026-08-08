# MobCrew Session Reliability and UX Stabilization

Status: planned
Category: product
Updated: 2026-08-08

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
Saved teams, cloud sync, forced full-screen breaks, and other speculative expansion are out of scope.

## Artifacts

- Research: [Audit findings](research.md)
- PRD: none
- Plan: [Session reliability and UX stabilization plan](plan.md)
- Progress: none
- Decisions: none
- Handoffs: none

## Next Action

- Implement [Task 1: Make session actions phase-aware and consistent](plan.md#task-1-make-session-actions-phase-aware-and-consistent).

## Open Questions

- [ ] Confirm on a logged-in Mac whether Carbon hotkey registration needs Accessibility permission
  on every supported macOS version; Task 7 uses the result as an implementation gate.
