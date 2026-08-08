# Execution evidence

## Current slice

All feasible local/static implementation and read-only public-artifact inspection across Phases 1-3
is complete. Remaining work requires a disposable clean account/Mac for launch-sensitive evidence,
separate release-operation authority, or an owner decision and credentials.

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
- During Phase 1, `agent-browser` at 390×844 found no horizontal overflow and all five original
  images loaded. Its initial thin-slice header fix and Tailwind warning were both superseded and
  resolved by Phase 2's static redesign.

### Phase 2 static-site evidence

- Replaced Tailwind's browser runtime with a 12,925-byte static stylesheet and no JavaScript. A cold
  headless Chromium session at 1440×900 over the unthrottled orb portal requested only the document,
  stylesheet, logo, hero WebP, and favicon initially: 87,197 transferred bytes including navigation.
  It recorded TTFB 2ms, FCP/LCP 304ms (the `h1`), and CLS 0 under those named conditions.
- Converted the four real-app PNG screenshots from 1,547,558 total bytes to 71,396 total WebP bytes
  (95.4% smaller). The break image fell from 1,336,176 to 21,990 bytes (98.4% smaller). Side-by-side
  visual review found no lost text, state, gradients, colors, or visible compression artifacts.
  Gallery files and the footer logo remain lazy; the hero reserves its 1800×1204 aspect ratio and is
  the only eager screenshot.
- Added and visually approved a 1200×630, 89,036-byte JPEG social preview plus canonical, Open Graph,
  Twitter, robots, sitemap, favicon, and theme metadata. Local social paths resolve; external cache
  rendering remains post-deployment validation.
- `agent-browser` passed 1440×900, 1280×800, 390×844, and 320px layouts with no horizontal overflow
  or header overlap. Full-page desktop/mobile visual reviews passed after forcing lazy gallery images
  into view. All four internal header anchors settled 16px from the viewport top; CTA and full-size
  image targets resolve.
- Axe 4.12.1 reported zero WCAG 2 A/AA, 2.1 A/AA, and 2.2 AA violations. It left one contrast item
  incomplete because of gradients; manual token calculations found a 6.16:1 minimum text ratio
  (primary button) and much higher normal-text ratios. Keyboard traversal follows skip link, brand,
  internal navigation, GitHub, then latest release, with a computed 3px white focus outline. All
  non-inline targets meet 24px; isolated inline prose links use the WCAG inline exception.
- `scripts/validate-docs.py` passes links/assets/fragments, required metadata, image alternatives and
  dimensions, runtime-Tailwind absence, and finite stale-copy checks. A temporary injected
  five-minute-default claim correctly failed the validator. Python compilation, HTML validation,
  workflow Prettier parsing, Markdown relative links, six external page destinations, and
  `git diff --check` also pass.

### Phase 3 release-hardening evidence

- Pinned Node 24.19.0 and the complete `create-dmg` 8.1.0 dependency graph. `create-dmg` remains
  packaging-only tooling; the static site has no framework or build system.
- Split release work into `check`, `prepare`, `create-draft`, read-only `status`, `verify-draft`, and
  separately authorized `publish` operations. Strict never-sourced schemas bind the canonical repo,
  full target SHA, artifact/version/build/architectures, local evidence, numeric release/asset IDs,
  remote bytes, and manual qualification hashes.
- Independent Ultra review found a blocker in the initial implementation: GitHub's release-by-tag
  endpoint returns 404 for drafts, so it could not safely discover and resume an existing draft.
  The corrected implementation lists all release pages, selects drafts by exact tag, rejects
  duplicates, creates missing metadata with a REST `POST` and exact `target_commitish`, captures the
  numeric release ID, and revalidates that identity before upload.
- The draft state machine resumes an exact partial draft, leaves a matching asset untouched, and
  aborts on conflicting metadata/state/assets without delete, overwrite, clobber, or retag recovery.
  Publication confirms first, then freshly verifies the numeric draft and downloaded asset, checks
  canonical tag absence as the final read, patches only `draft=false`, and verifies post-state/tag.
- `scripts/verify-release-artifact.sh` defines the shared read-only DMG mount, bundle/version/build,
  Applications symlink, architecture, app structural signature, Developer ID/hardened-runtime,
  app/DMG stapled-ticket, spctl, outer-DMG signature, raw-log, and strict evidence checks. These are
  implemented checks, not observed macOS results.
- `./scripts/test-release-hardening.sh` passes in the Linux orb and, after the draft-discovery
  correction, on macOS/BSD tools using a temporary repository and stateful mocked `gh`. It covers
  strict SemVer, dirty/wrong branch/upstream/origin, shallow and behind/diverged history, local/API
  tag conflicts, tool/auth/repo/permission failures, paginated draft discovery, release-by-tag 404
  behavior for drafts, duplicate rejection, create/retry/partial-resume paths, matching/conflicting
  assets, downloaded-byte evidence, schema mutation, a post-confirmation tag race, and numeric-ID-only
  publication. The mock also requires the exact paginated selector and full typed REST-create payload,
  including `target_commitish` and `.id` extraction. It never contacts GitHub.
- `bash -n scripts/*.sh`, `python3 scripts/validate-docs.py`, HTML validation, both workflow Prettier
  checks, and `git diff --check` pass. Linux `npm ci` stops with the expected `EBADPLATFORM` because
  locked `appdmg` is macOS-only; pinned macOS CI installed the same lockfile successfully with its
  required native install script.
- [Pinned macOS CI run 31276077780](https://github.com/colmarius/mobcrew/actions/runs/31276077780)
  passed Node 24.19.0 installation, the full offline release-hardening test under macOS/BSD tools,
  Xcode 26.6 / Swift 6.3 release build, DMG creation/mount/verification, 100 app tests, and evidence
  retention. The synthetic `0.0.0` artifact was 2,997,188 bytes with SHA-256
  `4d3f933e7ffac0e7df32045a9d05796019bbf1d1ead65c2abdd4fd488d17966a`.
- That CI artifact recorded build 167, `arm64`, an ad-hoc app signature, no Developer ID identity,
  no hardened runtime, an unsigned outer DMG, and non-accepted stapled-ticket/spctl probes. The two
  independent verifier runs produced identical strict evidence hashes. These are actual facts about
  the synthetic CI artifact only, not `v0.2.0`, a future release, or quarantined Gatekeeper behavior.

### Public v0.2.0 macOS artifact evidence

- On macOS 26.5.2 (25F84), arm64, the `agent-browser` real-browser workflow downloaded GitHub asset
  ID `349260554` from public release `v0.2.0`. Before opening or mounting, the 3,593,226-byte DMG had
  SHA-256 `1d7f8daff797dd20876b4a9ab011a98e20d23bf931e98118a131e7ba9c4b99d4`, matching GitHub's
  published digest, and `com.apple.quarantine=0081;6a77a2dc;Google Chrome for Testing;`.
- `hdiutil verify` reported a valid image checksum. A temporary read-only mount contained
  `MobCrew.app`, the `/Applications` symlink, bundle ID `com.colmarius.MobCrew`, version/build
  `0.2.0`/`146`, executable `MobCrew`, and a thin `arm64` Mach-O. The mount detached cleanly; no
  MobCrew volume remained, and the downloaded DMG retained quarantine.
- `codesign --verify --deep --strict` passed for the app. Detailed inspection recorded an ad-hoc
  signature, no Developer ID authority, `TeamIdentifier=not set`, and no hardened-runtime flag. The
  outer DMG was unsigned. Stapler found no ticket on app or DMG (exit 65); app and DMG `spctl`
  probes were not accepted (exit 3). These are exact artifact/probe facts, not proof of notarization
  status or the exact Gatekeeper result on launch.
- The app was not launched, copied to Applications, or installed. No TCC, login-item, MobCrew data,
  or preferences were changed. A clean-account first launch was not safe on this user's existing
  account, so Tasks 1.7/3.4 remain unchecked.
- Supplemental local checks passed with Xcode 26.2 on this host: all 100 app tests used isolated
  DerivedData. After integrating the corrected draft-discovery implementation, the expanded offline
  release-hardening state-machine suite also passed under macOS/BSD tools. This is additional
  compatibility evidence, not a replacement for the pinned Xcode 26.6 / Swift 6.3 CI result.

## Unverified manual gates

- Quarantined first launch, exact Privacy & Security recovery wording, permission/TCC behavior,
  clean-Mac qualification, and upgrade behavior require a compatible interactive Mac.
- Stronger real-app screenshot recapture requires a disposable account or an isolated app identity.
  The current app launches under the real bundle identity, consults TCC state, and uses standard
  preferences/Application Support; existing images have not been represented as new evidence.
- Developer ID signing/notarization remains conditional on an explicit owner decision and credentials;
  it is not authorized by this execution.
- No real draft, upload, qualification run, tag, or publication was created. Those remain separately
  authorized operations; the mocked state-machine result is not remote-release evidence.
