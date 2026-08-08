# Public documentation and website improvements

Status: blocked
Category: docs
Updated: 2026-08-08

## Why

Improve MobCrew's public documentation, website, installation funnel, and release trust using the
post-PR #1 audit as the evidence base. The work should first make public claims accurate and help a
new user install successfully, then improve presentation and distribution without obscuring the
current release-trust limitations.

## Summary

All Linux-feasible work across Phases 1-3 is complete. Public facts and install guidance are
corrected; the static site is dependency-free, accessible, responsive, image-optimized,
metadata-rich, and covered by deterministic Pages validation. Release tooling now has strict
target/artifact/remote/qualification evidence, non-destructive resumable draft operations, a final
live publication gate, locked packaging dependencies, and offline state-machine tests. Pinned macOS
artifact execution, quarantined trust qualification, real-app screenshot recapture, and the
conditional Developer ID owner decision remain blocked gates. The scope excludes unrelated app
features and does not authorize publishing, deleting, merging, or deploying releases.

## Artifacts

- Research: [Audit findings](research.md)
- PRD: none
- Plan: [Ordered plan index](plans/index.md) — feasible implementation complete; gates remain
- Progress: [Execution evidence](progress.md)
- Decisions: none
- Handoffs: none

## Next Action

- Run the updated Xcode CI job on its pinned macOS runner and record whether Phase 3 Task 3.2's real
  build, DMG mount, signature-state inspection, and evidence generation pass. Do not infer Task 3.4's
  quarantined Gatekeeper result from CI.

## Open Questions

- [ ] Is Apple Developer Program access available and intended for MobCrew? This affects only Phase
      3's conditional signing/notarization extension; all other planned work can proceed.
