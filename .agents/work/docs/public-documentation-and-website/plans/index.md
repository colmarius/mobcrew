# Ordered implementation plans

These plans deliberately separate immediate truth/install work from broader presentation and
distribution changes. Treat the numbering as priority order. After Phase 1 stabilizes public facts,
Phase 2's static-site work and Phase 3's non-credential release hardening can proceed independently;
conditional/manual slices remain explicit gates.

All feasible local/static work across Phases 1-3 is complete. macOS-only Tasks 1.7 and 2.5, Phase 3
quarantined trust qualification, and the conditional Developer ID decision remain explicit gates.

| Order | Plan | State | Dependencies |
| --- | --- | --- | --- |
| 1 | [Public truth and installation](01-public-truth-and-installation.md) | Feasible work complete; Task 1.7 unverified | None |
| 2 | [Landing-page presentation and quality](02-landing-page-presentation-and-quality.md) | Feasible work complete; Task 2.5 unverified | Phase 1 message and install facts |
| 3 | [Release and distribution hardening](03-release-and-distribution-hardening.md) | Local hardening complete; manual trust/owner gates remain | Phase 1 release facts; Apple credentials only for the conditional signed extension |

## Sequencing rationale

- Phase 1 removes harmful contradictions and gives users a safe path through the release that exists
  today. It does not wait for a redesign or signing credentials.
- Phase 2 changes page structure and technical presentation only after the product message is
  accurate, avoiding polishing or amplifying false claims.
- Phase 3 changes release mechanics and shared remote state. It remains separately reviewable and
  requires explicit approval for publishing, credentials, or infrastructure changes. Local
  hardening does not wait for Apple credentials.

The work-item [index](../index.md) owns lifecycle status and the canonical next action.
