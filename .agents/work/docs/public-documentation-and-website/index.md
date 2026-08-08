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

Phases 1 and 2 are complete for all Linux-feasible work. Public facts and install guidance are
corrected; the static site is dependency-free, accessible, responsive, image-optimized, metadata-rich,
and covered by deterministic Pages validation. Released-artifact architecture, signatures,
notarization, Gatekeeper behavior, clean-Mac qualification, and real-app screenshot recapture remain
explicit unverified macOS gates. Phase 3 is next and still separates local release hardening from
credential-dependent signing and separately authorized release operations. The scope excludes
unrelated app features and does not authorize publishing, deleting, merging, or deploying releases.

## Artifacts

- Research: [Audit findings](research.md)
- PRD: none
- Plan: [Ordered plan index](plans/index.md) — Phase 3 refinement is next
- Progress: [Execution evidence](progress.md)
- Decisions: none
- Handoffs: none

## Next Action

- Refine [Phase 3](plans/03-release-and-distribution-hardening.md) against the implemented
  documentation/trust state, then execute its feasible non-credential local hardening tasks.

## Open Questions

- [ ] Is Apple Developer Program access available and intended for MobCrew? This affects only Phase
      3's conditional signing/notarization extension; all other planned work can proceed.
