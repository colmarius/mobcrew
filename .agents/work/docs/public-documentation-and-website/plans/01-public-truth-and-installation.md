# Phase 1: Public truth and installation

Make MobCrew's current public documentation accurate and give a new user a complete, honest path
from discovery through first launch of the existing release. Preserve the current visual design
except for content needed to support that path, and qualify trust/Gatekeeper details until the
downloaded artifact is inspected on macOS.

## Goals

- Remove claims that contradict the shipping behavior.
- Explain download, installation, Gatekeeper, optional permissions, privacy, updates, and support.
- Separate end-user requirements from contributor prerequisites.
- Bring manual testing and release instructions in line with the current app and scripts.

## Tasks

- [x] **Task 1.1: Revalidate the audited implementation facts**
  - Scope: `README.md`, `TESTING.md`, `docs/index.html`, `docs/SCREENSHOTS.md`,
    `docs/RELEASING.md`, `AGENTS.md`, and the implementation files cited by `research.md`
  - Depends on: none
  - Acceptance:
    - The cited implementation is rechecked for global shortcut/action, break presentation, tips,
      timer defaults/ranges, platform requirement, permissions, persistence, and release tooling.
    - Only newly changed or unresolved facts are recorded in `research.md`; no duplicate canonical
      facts artifact is created.
    - Architecture, app-signature identity, notarization, Gatekeeper, and maturity remain qualified
      unless supported by direct artifact evidence or an explicit product decision.
    - No app behavior changes as part of this checkpoint.
  - Notes: Product facts belong in their owning user/contributor documents during the following
    tasks; the work item is evidence, not a shadow canonical product-data source.

- [x] **Task 1.2: Correct contradictory claims everywhere in scope**
  - Scope: `README.md`, `docs/index.html`, `docs/SCREENSHOTS.md`, `TESTING.md`, `AGENTS.md`
  - Depends on: Task 1.1
  - Acceptance:
    - Public copy describes `⌘⇧L` as toggling the floating timer.
    - Break copy says in-window break screen/overlay rather than full-screen.
    - Tips are described as programming tips, not payments or a tip jar.
    - Fixed shortcuts are not described as customizable.
    - Testing states the 7-minute default and distinguishes the main-window 1-30 range from the
      Settings 1-60 range.
    - A scoped search finds no stale contradictory strings outside durable historical research.
  - Notes: Existing GitHub release notes are historical public state and must not be edited or
    republished without separate approval; ensure the next release notes use corrected wording.

- [x] **Task 1.3: Rework the README's user journey**
  - Scope: `README.md`
  - Depends on: Task 1.1, Task 1.2
  - Acceptance:
    - The top of README communicates audience, outcome, website, and latest-release path before
      build-history material.
    - End-user requirements include macOS and verified architecture support only; Xcode is clearly
      development-only.
    - Installation covers DMG download, Applications copy, first launch, and the safe macOS Privacy
      & Security route, using qualified wording until Task 1.7 records actual artifact behavior.
    - Permissions explain that Accessibility is optional and used only for the global floating-timer
      shortcut, while Notifications are optional timer/break alerts.
    - Privacy accurately states local storage/no account/no telemetry for the audited code without
      promising future behavior.
    - Manual update and GitHub support paths are explicit.
    - Development, testing, releasing, history, and attribution remain discoverable without
      dominating the user path.
  - Notes: Omit a beta/maturity label unless the owner explicitly assigns one. The Known Limitations
    "ad-hoc signed" note is a signature-type claim: keep rebuild/permission guidance
    contributor-facing and keep released-artifact signature wording qualified until Task 1.7.

- [x] **Task 1.4: Add an in-page install and trust path without redesigning the site**
  - Scope: `docs/index.html`
  - Depends on: Task 1.1, Task 1.2
  - Acceptance:
    - The primary CTA points to the stable latest-release page and is labeled as viewing/getting the
      latest release rather than implying an immediate signed download.
    - Compatibility and the exact verified or explicitly qualified distribution trust state appear
      near the CTA in readable text.
    - A concise install/first-run section covers Applications, Gatekeeper, Accessibility,
      Notifications, and manual updates.
    - The page links to the repository/support path and does not claim a direct-download or update
      experience that does not exist.
    - Existing desktop/mobile layout remains functional pending Phase 2.
  - Notes: Keep this a thin content slice. Phase 2 owns structural redesign, styling, metadata, and
    performance work.

- [x] **Task 1.5: Correct and broaden app-level manual regression journeys**
  - Scope: `TESTING.md`
  - Depends on: Task 1.1, Task 1.2
  - Acceptance:
    - Defaults/ranges are correct and contextualized.
    - Timer, roster, zero/one/two/many-person roles, automatic rotation, breaks, fixed shortcuts,
      permission allow/deny/recovery, persistence, menu bar, launch at login, and floating-window
      behavior are covered as concise user journeys.
    - Keyboard-only, VoiceOver, contrast/zoom, multiple displays, Spaces, and full-screen-app
      interactions are grouped as extended manual UX checks rather than universal phase blockers.
    - Downloaded-DMG, Gatekeeper, upgrade, digest, architecture, and release-environment
      qualification are clearly assigned to the Phase 3 release checklist.
  - Notes: Mark checks that require a compatible macOS runner or interactive Mac; do not imply that
    unavailable OS/hardware combinations are unsupported.

- [x] **Task 1.6: Correct release documentation for today's repository-defined workflow**
  - Scope: `docs/RELEASING.md`
  - Depends on: Task 1.1, Task 1.2
  - Acceptance:
    - A tested draft is published rather than recreated with the same tag/version.
    - Failure recovery distinguishes safe draft cleanup from deleting a published release/tag.
    - Prerequisites state full Xcode requirements and do not present `xcode-select --install` as an
      Xcode installation fix.
    - The checklist names clean tree/branch/target verification, tests, bundle version,
      architecture inspection, DMG mount/content verification, checksum, and clean-Mac launch.
    - The document distinguishes app-bundle signing, outer-DMG signing, Developer ID, notarization,
      and observed Gatekeeper behavior; uninspected facts remain qualified.
    - Publishing, deleting, or changing remote release state remains an explicitly approved human
      action.
  - Notes: Phase 3 owns script/CI changes; this task documents the safest accurate process available
    before that automation exists.

- [ ] (manual-verify) **Task 1.7: Inspect the distributed artifact and first-launch behavior on macOS**
  - Scope: downloaded `v0.2.0` DMG, `research.md`, affected trust/install wording in `README.md`,
    `docs/index.html`, and `docs/RELEASING.md`
  - Depends on: Task 1.3, Task 1.4, Task 1.6
  - Acceptance:
    - App bundle and outer DMG signature states are inspected separately with appropriate
      `codesign` commands; Developer ID identity, notarization/stapling, and `spctl` assessment are
      recorded without conflating them.
    - `lipo -archs` records the released executable's actual architectures.
    - First launch from the downloaded/quarantined DMG is observed on a clean supported macOS
      account, including exact Gatekeeper wording and the safe user recovery path.
    - Public wording is made exact when evidence exists; if macOS access remains unavailable, docs
      retain qualified language and `research.md` explicitly records what remains unverified.
  - Notes: Lack of access is not evidence of unsupported hardware or OS behavior.
  - Execution state (2026-08-08): **unverified** in the Linux orb. No macOS screenshot
    recapture, signature/identity assessment, architecture inspection, quarantined first launch, or
    clean-Mac qualification was performed. Qualified public wording remains in place and this manual
    gate does not block unrelated static-site or local release-hardening work.

## Implementation Notes

- Preserve facts in canonical user documentation; do not introduce a content-generation framework
  solely to deduplicate a handful of strings.
- Prefer one detailed install/troubleshooting explanation and links from shorter contexts.
- Use Apple's user-facing System Settings route rather than shell commands that disable or remove
  quarantine as the primary Gatekeeper guidance.
- Treat current release notes as immutable historical evidence unless separately authorized.

## Constraints / Decisions

- No app behavior changes.
- No landing-page redesign, image recapture, CSS toolchain, or release-script changes in this phase.
- No release publication, deletion, retagging, issue creation, or deployment without explicit
  approval.
- State app/DMG signing, Developer ID, notarization, and Gatekeeper facts separately; do not infer
  “beta” from version `0.2.0`.

## Acceptance Criteria

- A new user can identify MobCrew's purpose, download the current release, install it safely, and
  understand both permission prompts using only public documentation.
- README, landing-page copy, screenshot guidance, manual testing, release guidance, and AGENTS agree
  on all audited changing product facts.
- Contributor guidance does not confuse end-user and development requirements.

## Verification

- Run a scoped case-insensitive `rg -i` check for `⌘⇧M`, `full-screen`, `tip jar`,
  `customize timer and hotkeys`, `default 5 min`, and `ad-hoc`; investigate every remaining match
  (existing copy includes capitalized variants such as `Full-screen`).
- Check all relative Markdown links and all landing-page links/assets.
- Serve the page locally and use `agent-browser` at 1440x900 and 390x844 to verify the CTA, install
  content, responsive layout, semantics, console, and link destinations.
- On macOS, follow the documented install and first-run path using the actual release DMG; record any
  app/DMG signature, architecture, notarization, or Gatekeeper result that differs from qualified
  draft documentation.

## Deployment / Migration

- Documentation can merge independently of a new release. GitHub Pages will deploy `docs/` on a
  main-branch push.
- Omit a maturity label by default; no product decision is required to merge accurate documentation.
- Task 1.7 may record qualified unverified results when no macOS environment is available; that does
  not block correcting known false claims or publishing honest limitations.
- Publishing a corrected future release and changing existing GitHub release notes are outside this
  phase and require separate approval.
