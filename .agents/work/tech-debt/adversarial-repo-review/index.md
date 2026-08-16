# Adversarial repository review

Status: completed
Category: tech-debt
Updated: 2026-08-16

## Why

User-requested adversarial review of code, GitHub workflows, features, site documentation, and
agent context, followed by minimal verified improvements. Goals: test end-to-end where possible,
remove rather than add, keep code easy to maintain, and record irrefutable proof.

## Summary

Review ran in a Linux orb, so Xcode builds/tests are unavailable; all Swift-code findings that need
compilation are recorded as macOS-verifiable follow-ups, not implemented blind. Everything
implementable was verified in this environment.

### Verified healthy (evidence in plan.md Verification)

- `python3 scripts/validate-docs.py` passes; its checks match current v0.3.0 claims.
- `./scripts/test-release-hardening.sh` (offline mock suite for release.sh gates) passes on Linux.
- Docs site serves end-to-end (HTTP 200 for page, CSS, images, favicon, sitemap) and renders
  correctly in a real browser via the orb portal.
- `html-validate@8 docs/index.html` passes with the repo `.htmlvalidate.json` config.
- README/CHANGELOG/TESTING/RELEASING claims are mutually consistent (arm64-only release, ⌘⇧L
  hotkey, break semantics, session recovery) and consistent with the Swift sources read.
- AGENTS.md guidance matches the actual repository layout, scripts, and canonical-doc ownership.

### Findings to fix here (verifiable on Linux)

1. `.htmlvalidate.json` exists but html-validate is not wired anywhere (no dependency, no CI step,
   no doc mention). The config works and the site passes. Fix: invoke it in the CI docs job and
   the Pages build gate, and mention it in README's development commands.
2. Five stray `.gitkeep` placeholders sit in directories that now contain source files
   (`Core/Services`, `Features/FloatingTimer`, `Features/MenuBar`, `Features/Roster`,
   `Features/Settings`). None are referenced by `project.pbxproj` (verified by grep). Fix: delete.
3. `ci.yml` triggers on every push **and** every pull_request with no branch filter, so each PR
   runs the expensive macOS/Xcode job twice. Fix: scope the push trigger to `main`
   (workflow_dispatch retained for ad-hoc branch runs).

### Findings recorded, deliberately not implemented (need a macOS run or owner decision)

- `Roster.advanceTurn()` is unused by production code (only tests exercise it) since
  `resolveRegularCycle` took over rotation. Removing it touches tests that cannot be run here.
- `Helpers/Extensions/` contains only `.gitkeep` and an empty pbxproj group; removing it means a
  hand pbxproj edit that only Xcode can prove safe.
- `SettingsView`/`ContentView` build manual `Binding(get:set:)` where `$appState.property` would
  do; cosmetic, needs compile proof.
- Root `CNAME` duplicates `docs/CNAME`; with actions-based Pages deployment neither file is what
  binds the domain (repo settings do). Left untouched: cannot inspect Pages settings from here.
- Services log failures with `print(...)`; `os.Logger` would be idiomatic but adds churn for a
  small app. Not worth the diff.

## Artifacts

- [plan.md](plan.md): implementation tasks and verification.

## Next Action

- None.
