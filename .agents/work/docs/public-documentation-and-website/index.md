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

All feasible local/static work across Phases 1-3 is complete. Public facts and install guidance are
corrected; the static site is dependency-free, accessible, responsive, image-optimized,
metadata-rich, and covered by deterministic Pages validation. Release tooling now has strict
target/artifact/remote/qualification evidence, non-destructive resumable draft operations, a final
live publication gate, locked packaging dependencies, Linux/macOS state-machine tests, and a passing
pinned macOS build/package/verification run. Read-only inspection has now established the public
`v0.2.0` artifact's identity, architecture, and app/DMG trust states from a browser-quarantined
download. Clean-account first launch, real-app screenshot recapture, and the conditional Developer
ID owner decision remain blocked gates. The scope excludes unrelated app features and does not
authorize publishing, deleting, merging, or deploying releases.

## Artifacts

- Research: [Audit findings](research.md)
- PRD: none
- Plan: [Ordered plan index](plans/index.md) — feasible implementation complete; gates remain
- Progress: [Execution evidence](progress.md)
- Decisions: none
- Handoffs: none

## Next Action

- After this branch is reviewed and landed, obtain separate owner authorization before creating a
  draft. Then prepare the exact release from clean canonical `main`, verify the uploaded bytes, and
  finish Tasks 1.7/3.4 on a disposable clean account/Mac using the browser-downloaded quarantined
  DMG. Do not infer first-launch results from read-only artifact probes or the synthetic CI artifact.

## Open Questions

- [ ] Is Apple Developer Program access available and intended for MobCrew? This affects only Phase
      3's conditional signing/notarization extension; all other planned work can proceed.
