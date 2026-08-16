# Usability and Interaction Audit

Status: in-progress
Category: bugfix
Updated: 2026-08-16

## Why

Audit MobCrew's usability through representative native macOS interaction journeys, fix reproducible
interaction bugs, and provide inspected video evidence that the corrected journeys work.

## Summary

The Linux orb cannot run the macOS app, so native execution and recording will use a live macOS
runner in [the native audit thread](https://ampcode.com/threads/T-01a00aeb-7fe6-7658-b8f4-62988266279a).
This thread owns scope, source review, integration, and acceptance of the runner evidence.

## Artifacts

- Research: none
- PRD: none
- Plan: [plan.md](plan.md)
- Progress: none
- Decisions: none
- Handoffs: none

## Next Action

- Review the interaction ownership paths while the macOS runner executes Task 1 from [plan.md](plan.md).

## Open Questions

- None.
