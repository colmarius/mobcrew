# Public documentation and website improvements

Status: in-progress
Category: docs
Updated: 2026-08-08

## Why

Improve MobCrew's public documentation, website, installation funnel, and release trust using the
post-PR #1 audit as the evidence base. The work should first make public claims accurate and help a
new user install successfully, then improve presentation and distribution without obscuring the
current release-trust limitations.

## Summary

Phase 1's feasible documentation work is complete and Phase 2 is active after refinement against the
corrected public facts. Released-artifact architecture, signatures, notarization, Gatekeeper
behavior, clean-Mac qualification, and real-app screenshot recapture remain explicit unverified
macOS gates and do not block the static site. Phase 3 continues to separate local release hardening
from credential-dependent signing and separately authorized release operations. The scope excludes
unrelated app features and does not authorize publishing, deleting, merging, or deploying releases.

## Artifacts

- Research: [Audit findings](research.md)
- PRD: none
- Plan: [Ordered plan index](plans/index.md) — Phase 2 is active
- Progress: [Execution evidence](progress.md)
- Decisions: none
- Handoffs: none

## Next Action

- Implement [Phase 2, Task 2.1](plans/02-landing-page-presentation-and-quality.md#tasks): restructure
  the landing page around the now-stable message and qualified install facts.

## Open Questions

- [ ] Is Apple Developer Program access available and intended for MobCrew? This affects only Phase
      3's conditional signing/notarization extension; all other planned work can proceed.
