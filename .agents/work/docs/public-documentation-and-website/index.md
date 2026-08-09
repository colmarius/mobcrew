# Public documentation and website improvements

Status: completed
Category: docs
Updated: 2026-08-09

## Why

Improve MobCrew's public documentation, website, installation funnel, and release trust using the
post-PR #1 audit as the evidence base. The work should first make public claims accurate and help a
new user install successfully, then improve presentation and distribution without obscuring the
current release-trust limitations.

## Summary

All scoped implementation and verification across Phases 1-3 is complete. Public facts and install
guidance are corrected; the static site is dependency-free, accessible, responsive, image-optimized,
metadata-rich, and covered by deterministic validation. Release tooling has strict target/artifact/
remote/qualification evidence, non-destructive resumable draft operations bound to numeric release
IDs, a final live publication gate, locked packaging dependencies, Linux/macOS state-machine tests,
and passing pinned Xcode 26.6 build/package/verification and full-test evidence. Read-only inspection
also established the public `v0.2.0` artifact's identity, architecture, and app/DMG trust states from
a browser-quarantined download.

The owner explicitly deferred Developer ID signing/notarization, so the documented non-Developer-ID
path is the current supported release process. Clean-account launch qualification remains a required
future release-operation gate, and stronger screenshot recapture remains an optional future content
task; both procedures and their unverified state are preserved in canonical documentation rather
than retained as active work-item blockers. This completion does not publish, merge, or deploy.

## Artifacts

- Research: [Audit findings](research.md)
- PRD: none
- Plan: [Ordered plan index](plans/index.md) — implementation complete; deferred operations retained
- Progress: [Execution evidence](progress.md)
- Decisions: none
- Handoffs: none

## Next Action

- None.

## Open Questions

- [x] Developer ID signing/notarization is deferred. No Apple credentials or signing environment are
      required for the current non-Developer-ID release path.
