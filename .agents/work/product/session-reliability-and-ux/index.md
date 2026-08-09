# MobCrew Session Reliability and UX Stabilization

Status: completed
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
Tasks 1-8 are complete. Together they establish one phase-aware session contract, identity-preserving
roster mutations, unified duration semantics, monotonic deadline timing, optional break decisions,
idempotent versioned recovery, permission-free Carbon hotkey setup, and truthful Notification and
Launch at Login status. Task 9's implementation adds single-List roster reachability,
identity-preserving Move Up/Down paths, contextual semantics, one-shot transition announcements, a
responsive 600×450+ layout, and explicit activation focus. The latest production source passed all
177 native executions with Xcode 26.6 / Swift 6.3.3; logged-in geometry, Accessibility-tree,
increased-text, responsive-layout, and user Full Keyboard Access observations also pass.

An independent ultra review and coordinator source investigation at audit head `eff06df` found no
code blocker. They confirmed one Task 10 documentation omission: the manual checklist lacked an
in-process sleep-across-deadline journey. `TESTING.md` now includes that journey and static validation
passes. A final read-only Mac verifier found no new defect but could not complete the remaining direct
observations because VoiceOver, Increase Contrast, and Differentiate Without Color were off and the
verifier was not authorized to alter shared system settings. The owner accepted the implemented scope
and directed work-item closeout without treating those observations as passed. They remain explicit,
unchecked release-qualification journeys in `TESTING.md`; Tasks 11-12 remain explicitly deferred and
non-blocking. The exact final candidate passed all 177 native executions before closeout.

## Artifacts

- Research: [Audit findings](research.md)
- PRD: none
- Plan: [Session reliability and UX stabilization plan](plan.md)
- Progress: [Execution progress](progress.md)
- Decisions: none
- Handoffs: none

## Next Action

- None.
