# Execution evidence

## Current slice

Phases 1 and 2 are complete for all Linux-feasible work. Phase 3 requires its boundary refinement
before local, non-credential release hardening begins.

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

## Unverified manual gates

- The `v0.2.0` app bundle and outer DMG signatures, Developer ID identity, notarization/stapling,
  Gatekeeper assessment, and executable architectures require macOS inspection.
- Quarantined first launch, exact Privacy & Security recovery wording, permission/TCC behavior,
  clean-Mac qualification, and upgrade behavior require a compatible interactive Mac.
- Stronger real-app screenshot recapture requires macOS. Existing images have not been represented as
  new evidence.
- Developer ID signing/notarization remains conditional on an explicit owner decision and credentials;
  it is not authorized by this execution.
