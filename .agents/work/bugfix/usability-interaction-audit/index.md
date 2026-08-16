# Usability and Interaction Audit

Status: blocked
Category: bugfix
Updated: 2026-08-16

## Why

Audit MobCrew's usability through representative native macOS interaction journeys, fix reproducible
interaction bugs, and provide inspected video evidence that the corrected journeys work.

## Summary

The macOS audit found and verified a floating-panel position bug; its exact fix and regression test
are integrated. Native tests and the corrected interaction passed. The runner disconnected before
the coordinating thread could transfer and independently inspect the recorded evidence.

## Artifacts

- Research: none
- PRD: none
- Plan: [plan.md](plan.md)
- Progress: [progress.md](progress.md)
- Decisions: none
- Handoffs: none

## Next Action

- Reconnect the macOS Amp runner, transfer the movie and contact sheet from [the native audit thread](https://ampcode.com/threads/T-01a00aeb-7fe6-7658-b8f4-62988266279a), and complete Task 3 in [plan.md](plan.md).

## Open Questions

- [ ] When will the macOS Amp runner be reconnected so its untracked evidence can be transferred?
