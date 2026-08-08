# Public documentation and website improvements

Status: planned
Category: docs
Updated: 2026-08-08

## Why

Improve MobCrew's public documentation, website, installation funnel, and release trust using the
post-PR #1 audit as the evidence base. The work should first make public claims accurate and help a
new user install successfully, then improve presentation and distribution without obscuring the
current release-trust limitations.

## Summary

Research is complete and the three ordered plans have been reviewed and refined. Phase 1 is
implementation-ready; Phase 2 is queued behind stable public facts, and Phase 3 separates local
release hardening from credential-dependent signing and separately authorized release operations.
The scope excludes unrelated app features and does not authorize publishing or deleting releases.

## Artifacts

- Research: [Audit findings](research.md)
- PRD: none
- Plan: [Ordered plan index](plans/index.md) — Phase 1 is active
- Progress: none
- Decisions: none
- Handoffs: none

## Next Action

- Start [Phase 1, Task 1.1](plans/01-public-truth-and-installation.md#tasks): revalidate the audited
  implementation facts, then correct contradictory claims.

## Open Questions

- [ ] Is Apple Developer Program access available and intended for MobCrew? This affects only Phase
      3's conditional signing/notarization extension; all other planned work can proceed.
