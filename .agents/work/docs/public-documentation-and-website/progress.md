# Execution evidence

## Current slice

Phase 1's Linux-feasible documentation changes are implemented and Phase 2 is active after its
required boundary refinement.

## Observed evidence

- Revalidated the shortcut/action, break presentation, tips, defaults/ranges, macOS deployment
  target, permissions, persistence, menu bar, launch at login, app sandbox, and release scripts at
  branch baseline `f78f1f3`; no material source facts changed from the audit.
- Scoped stale-copy search has no contradictory public matches. The remaining `full-screen` match in
  `TESTING.md` intentionally describes interaction with another app's full-screen Space.
- Four public/contributor Markdown files have no missing relative targets; all 14 local landing-page
  links/assets resolve; nine named external destinations returned HTTP 200 on 2026-08-08.
- `agent-browser` at 1440x900 found one `h1`, logical heading order, header/nav/main/footer landmarks,
  the latest-release CTA, complete install content, no page errors, and no horizontal overflow.
- `agent-browser` at 390x844 found no horizontal overflow and all five images loaded. Visual review
  found an initial crowded header; hiding the secondary GitHub link below the `sm` breakpoint fixed
  the overlap. The known Tailwind production warning remains assigned to Phase 2.

## Unverified manual gates

- The `v0.2.0` app bundle and outer DMG signatures, Developer ID identity, notarization/stapling,
  Gatekeeper assessment, and executable architectures require macOS inspection.
- Quarantined first launch, exact Privacy & Security recovery wording, permission/TCC behavior,
  clean-Mac qualification, and upgrade behavior require a compatible interactive Mac.
- Stronger real-app screenshot recapture requires macOS. Existing images have not been represented as
  new evidence.
- Developer ID signing/notarization remains conditional on an explicit owner decision and credentials;
  it is not authorized by this execution.
