# Plan: minimal verified improvements from adversarial review

Scope: only changes fully verifiable in a Linux orb. Swift-code follow-ups stay in index.md.

## Tasks

- [x] Wire html-validate: add a pinned `npx --yes html-validate@8 docs/index.html` step to the
      `docs` job in `.github/workflows/ci.yml` and the `build` job in `.github/workflows/pages.yml`
      (matching the existing duplication of `validate-docs.py` as the deploy gate), and add the
      command to README's development commands.
- [x] Delete stray `.gitkeep` files in the five non-empty source directories
      (`Core/Services`, `Features/FloatingTimer`, `Features/MenuBar`, `Features/Roster`,
      `Features/Settings`). Keep `Helpers/Extensions/.gitkeep` (its pbxproj group still exists).
- [x] Scope `ci.yml` `push` trigger to `branches: [main]` to stop duplicate macOS runs per PR;
      keep `pull_request` and `workflow_dispatch`.
- [x] (Added during execution) Ignore the generated `.amp/portal-proxy.mjs` next to the already
      ignored `.amp/portals/` manifests.

## Constraints

- No new dependencies in `package.json` (release lockfile is hashed into release manifests);
  html-validate runs via pinned npx in CI only.
- No Swift source changes (no compiler available here).
- No pushes or GitHub mutations.

## Verification

- `python3 scripts/validate-docs.py` passes after changes.
- `npx --yes html-validate@8 docs/index.html` exits 0 locally (same command CI will run).
- `./scripts/test-release-hardening.sh` still passes.
- Both workflow files parse as valid YAML; grep confirms trigger and new steps.
- `git status` shows only intended deletions/edits; `.gitkeep` files confirmed absent from
  `project.pbxproj` before deletion.

### Observed evidence (post-change, 2026-08-16, Linux orb, commit ab91d15)

- `python3 scripts/validate-docs.py` → "Documentation validation passed", exit 0.
- `npx --yes html-validate@8 docs/index.html` → exit 0 (identical command CI runs).
- `./scripts/test-release-hardening.sh` → "release hardening tests passed", exit 0.
- `npx --yes js-yaml` parses both edited workflow files without error.
- `git status` after commit shows only the intended files changed.
- Unverified here: GitHub Actions execution of the new CI steps (needs a push, which requires
  separate authority) and any Xcode build/test (Linux orb; no Swift sources were changed).

### Observed evidence (pre-change baseline, 2026-08-16, Linux orb)

- `validate-docs.py` → "Documentation validation passed", exit 0.
- `test-release-hardening.sh` → "release hardening tests passed (offline mock gh: ...)", exit 0.
- `npx --yes html-validate@8 docs/index.html` → exit 0 (latest html-validate needs Node ≥22;
  orb has Node 20, hence the @8 pin, which supports Node ≥16).
- Served docs via `amp orb services ensure`: HTTP 200 for `/`, `assets/styles.css`,
  `assets/images/social-preview.jpg`, `favicon.png`, `sitemap.xml`; browser screenshot at
  `.amp/in/artifacts/docs-site.png` shows correct render.
- `rg -n "gitkeep" MobCrew/MobCrew.xcodeproj/project.pbxproj` → no matches.
- `rg -n "advanceTurn" MobCrew/MobCrew --type swift` (excluding tests) → definition only.
