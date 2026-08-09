# Phase 2: Landing-page presentation and quality

Restructure the landing page around the approved product message and install path, then improve
accessibility, screenshot evidence, performance, metadata, and deploy-time confidence without adding
an unnecessary frontend application stack.

## Phase-boundary refinement (2026-08-08)

- Phase 1 established `⌘⇧L`, an in-window break screen, optional programming tips, the 7-minute
  default, contextual timer ranges, macOS 14+, local data/no account/no telemetry, and manual updates
  as the public facts this phase must preserve.
- Subsequent read-only macOS inspection established the public `v0.2.0` artifact's `arm64`-only
  executable, ad-hoc app signature, absent Developer ID identity/hardened runtime/stapled tickets,
  and unsigned outer DMG. The hero and install/FAQ now use those exact historical facts while
  keeping notarization and clean-Mac Gatekeeper behavior explicitly unverified; they do not infer
  future artifact support.
- The README now owns detailed installation, permission, privacy, update, and support guidance under
  `#install-and-first-run`; this page should present a concise complete path and link there for more
  detail rather than repeat long troubleshooting copy.
- Existing screenshots remain the only real-app evidence. Task 2.5 stays an unchecked macOS manual
  gate; Tasks 2.4 and 2.6 may truthfully frame and optimize those existing files without recapture.
- A checked-in stylesheet and a small dependency-free validator are proportionate. No framework,
  runtime CSS compiler, package manager, or frontend build system is justified for this one page.
- Branch authority explicitly permits the Pages workflow validation change in Task 2.8, but not a
  merge or deployment.

## Goals

- Make audience, problem, outcome, and next action immediately understandable.
- Present product evidence and installation trust in a coherent information architecture.
- Meet practical keyboard, contrast, semantic, responsive, and performance standards.
- Improve search/social presentation and reduce third-party/runtime fragility.

## Tasks

- [x] **Task 2.1: Implement the approved information architecture and message hierarchy**
  - Scope: `docs/index.html`
  - Depends on: Phase 1 Tasks 1.1-1.4 (stable public message and install facts); incorporate Task
    1.7 evidence when it exists instead of blocking on macOS access
  - Acceptance:
    - Header links to How it works, Features, Install/FAQ, GitHub, and the latest release without
      becoming crowded at 390px.
    - Hero names the pair/mob/ensemble audience, timed-role-rotation outcome, native macOS platform,
      and honest release action.
    - Page order is hero/proof, how it works, core outcomes, contextual screenshots, install/first
      run, trust/FAQ, then attribution/footer.
    - Mobster attribution remains clear but no longer displaces install/trust/support content.
    - Copy does not duplicate long troubleshooting guidance when a stable README anchor is more
      maintainable.
  - Notes: This is an information-architecture and copy implementation, not a speculative visual
    redesign or JavaScript application.

- [x] **Task 2.2: Replace the Tailwind browser runtime with static production CSS**
  - Scope: `docs/index.html`, `docs/assets/` stylesheet as needed, Pages-serving scripts/config
  - Depends on: Task 2.1
  - Acceptance:
    - The page makes no request to `cdn.tailwindcss.com` and emits no Tailwind production warning.
    - Layout and visual hierarchy render without client-side style generation or JavaScript.
    - Styles are checked-in static CSS with no new package/build tool unless a separate decision
      records why one is necessary.
    - The existing dark color direction remains, and the tested viewports have no clipping or
      horizontal overflow.
    - A CDN failure cannot make page text or layout unreadable.
  - Notes: Preferred default for this one-page site is a small checked-in static stylesheet rather
    than introducing package management and a Tailwind build pipeline.

- [x] **Task 2.3: Fix keyboard, contrast, semantics, and touch ergonomics**
  - Scope: `docs/index.html`, landing-page CSS
  - Depends on: Task 2.1, Task 2.2
  - Acceptance:
    - Every interactive element has a clearly visible `:focus-visible` indicator with sufficient
      contrast on both dark and blue backgrounds.
    - Normal text meets 4.5:1 contrast and focus/non-text indicators meet applicable 3:1 criteria.
    - Decorative emoji/SVGs and the adjacent logo image do not create redundant announcements.
    - Informative screenshots have useful text alternatives or accessible adjacent descriptions.
    - Internal anchors have usable focus/scroll behavior and a skip link is provided when navigation
      warrants it.
    - Pointer targets meet WCAG 2.2's 24 CSS-pixel minimum or documented spacing exception without
      mobile overflow; 44px remains a preferred macOS/mobile design target, not a pass/fail gate.
  - Notes: Preserve the already-correct landmark and heading hierarchy. Record contrast ratios rather
    than relying on visual judgment alone.

- [x] **Task 2.4: Make the existing gallery truthful, responsive, and inspectable**
  - Scope: `docs/assets/images/`, `docs/SCREENSHOTS.md`, `docs/index.html`
  - Depends on: Task 2.1
  - Acceptance:
    - Existing break/settings/floating captions describe only what their current images and the app
      actually demonstrate.
    - Images use responsive containers and can be opened at full resolution on mobile using normal
      links rather than a JavaScript lightbox.
    - Useful adjacent descriptions or alternatives convey the visible product state; decorative
      duplication is avoided.
    - Intrinsic dimensions, below-fold loading behavior, and consistent framing are implemented
      without waiting for fresh captures.
    - Staged data contains no personal information and the screenshot guide records repeatable app
      state, appearance, viewport, version, and size targets.
  - Notes: This no-macOS slice should improve the current assets without presenting them as stronger
    evidence than they are.

- [ ] (deferred optional follow-up) **Task 2.5: Recapture stronger real-app evidence on macOS**
  - Scope: `docs/assets/images/`, `docs/SCREENSHOTS.md`, `docs/index.html`
  - Depends on: Task 2.4; current macOS app build
  - Acceptance:
    - Floating-timer image shows the panel over a realistic editor or terminal context.
    - Break image is framed/captioned as the in-window break screen unless app behavior changes.
    - Settings imagery shows the feature named by each caption; fixed shortcuts are not described as
      customization.
    - Captures follow the documented staged data, appearance, viewport, version, and privacy rules.
    - New captures are visually inspected at desktop, rendered gallery, and mobile/full-resolution
      sizes before replacing existing assets.
  - Notes: Requires macOS. Keep this queued rather than substituting invented mockups or blocking the
    rest of Phase 2.
  - Final disposition (2026-08-09): **deferred and unverified**. Existing captures were optimized and visually
    reviewed, but no replacement was represented as a new real-app capture. The available macOS
    account is not disposable: launching the real bundle identity would consult or alter its TCC
    state and the app uses standard user preferences/Application Support. No repository-supported
    isolated app identity exists, so recapture was not attempted. The current truthful images remain
    supported; the optional recapture procedure is retained in `docs/SCREENSHOTS.md`, and the
    unchecked box records that no new evidence was captured.

- [x] **Task 2.6: Optimize image loading and record performance change**
  - Scope: `docs/assets/images/`, `docs/index.html`
  - Depends on: Task 2.4
  - Acceptance:
    - The 1.336MB break asset is recompressed/reformatted or deferred so it no longer dominates the
      initial page transfer; before/after encoded bytes are recorded.
    - Below-fold images use lazy loading; all images declare intrinsic dimensions and sensible
      decoding behavior.
    - Optimized assets, including the hero, are visually reviewed at rendered desktop/mobile and
      full-resolution sizes, and intrinsic dimensions reserve the hero's aspect ratio before load.
    - Uncached transfer, LCP, and CLS are recorded under named browser/network conditions, with
      regressions investigated rather than compared to an arbitrary audit-wide budget.
  - Notes: Keep capture source only if there is a real future editing need; do not ship unoptimized
    and optimized duplicates without purpose. This task does not depend on Task 2.5.

- [x] **Task 2.7: Add core search and social metadata**
  - Scope: `docs/index.html`, `docs/favicon.png`, `docs/assets/images/`, optional static metadata files
  - Depends on: Task 2.1, Task 2.4
  - Acceptance:
    - Canonical URL, description, `og:title`, `og:description`, `og:url`, `og:image`, and
      corresponding Twitter fields describe MobCrew's macOS role-rotation use case.
    - A 1200x630 social image remains legible at preview size and does not rely on tiny app UI text.
    - Existing favicon metadata remains valid.
    - Local metadata and social-image paths resolve before deployment.
  - Notes: SoftwareApplication schema, a touch icon, and `robots.txt` are optional only when an
    appropriate asset/indexing decision makes them useful. Trust copy belongs to Task 2.1 page
    content, not metadata. External social-preview cache checks are post-deployment validation.

- [x] **Task 2.8: Add proportional deterministic Pages validation**
  - Scope: `.github/workflows/pages.yml`, `docs/`, validation script/config only if justified
  - Depends on: Task 2.2, Task 2.3, Task 2.7
  - Acceptance:
    - Before upload, Pages checks local `href`/`src` targets, the named Task 2.7 metadata fields,
      absence of `cdn.tailwindcss.com`, and the finite known stale-claim strings from Phase 1.
    - Validation does not depend on external-site availability or introduce a site framework.
    - Manual `agent-browser` accessibility/responsive checks remain documented where CI automation
      would add disproportionate complexity.
    - Any workflow change receives the required shared-infrastructure approval before it is applied.
  - Notes: Prefer a small deterministic check over a large framework or internet-wide link checker.
    Root `CNAME` cleanup is optional and separate; remove it only after confirming there is no other
    publishing consumer.

## Implementation Notes

- Preserve the current strong hero screenshot until a verified replacement is available.
- Wear one hat at a time: restructure content, verify, then change CSS/assets, verify again.
- Keep install facts established by Phase 1 intact through the presentation rewrite.
- Avoid analytics or dynamic GitHub API calls solely to display changing release statistics.

## Constraints / Decisions

- Static GitHub Pages remains the hosting model.
- No SPA framework, client-side routing, analytics, or runtime CSS compiler.
- No image generation or mockup substitution without explicit user direction; real app captures are
  preferred.
- The page must remain usable without JavaScript.

## Acceptance Criteria

- A new visitor can identify audience, value, platform, signing status, and next action from the first
  screen and immediate supporting content.
- Desktop and mobile layouts are coherent; screenshots prove their captions and can be inspected.
- Keyboard focus, contrast, semantics, and touch targets pass the planned checks.
- The page has no production console warning; before/after resource and rendering measurements are
  recorded under named conditions.
- Social previews and search metadata represent the product accurately.

## Verification

- Serve the site locally and test at 1440x900, 1280x800, 390x844, and 320px with
  `agent-browser`; verify no horizontal overflow and exercise every CTA/internal anchor.
- Run `agent-browser a11y` for WCAG 2 A/AA/2.1 AA/2.2 AA, then manually inspect tab order and
  focus visibility.
- Measure contrast for all text/focus tokens and record the minimum ratios.
- Check console, page errors, network requests, resource timing, Core Web Vitals, lazy loading, and
  image dimensions under an uncached/throttled run.
- Validate local assets/links and named metadata fields; inspect Open Graph/Twitter output with
  representative preview tooling after deployment.
- Run the Pages workflow/checks and confirm the deployed HTML matches the reviewed source.

## Deployment / Migration

- Screenshot capture requires a macOS machine; Task 2.5 can remain queued without blocking static
  gallery truthfulness, accessibility, optimization, metadata, or validation.
- Social image and metadata should land together to avoid broken public previews.
- Pages deploys automatically from `main`; deployment remains a separate shared-state action governed
  by the repository workflow and merge process.
