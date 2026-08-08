# Audit research: public documentation and website

## Scope and baseline

This research records a read-only audit performed on 2026-08-08 after PR #1. The local and remote
`main` branch both resolved to merge commit `03fb0ea169c545ab8f1e7cee86e91d7503eb846a`.
The deployed HTML at <https://mobcrew.team/> was byte-for-byte identical to `docs/index.html`, and
the corresponding GitHub Pages and Xcode CI runs completed successfully.

Sources reviewed:

- `AGENTS.md`
- `README.md`
- `TESTING.md`
- `docs/RELEASING.md`
- Every tracked file under `docs/`, including image assets
- Root and deployed `CNAME` files
- `.github/workflows/pages.yml` and relevant release/CI configuration
- App code needed to verify public feature, permission, persistence, and platform claims
- Release scripts and the public GitHub release state

Live checks used `agent-browser` at 1440x900 and 390x844. All five public links and all deployed
assets returned HTTP 200. Both primary calls to action reached the GitHub Releases page. The mobile
page had no horizontal overflow, and the semantic structure contained header/navigation/main/footer
landmarks with one `h1` and a logical heading hierarchy.

## Executive finding

MobCrew has a credible product and a polished hero screenshot, but the public funnel is not ready
for a cold visitor because the release trust/Gatekeeper path is unexplained and several concrete
product claims contradict the implementation. Accuracy and installation trust should be fixed
before a broader landing-page redesign or release automation effort.

## Verified product and release facts

### Implemented capabilities

The following public capabilities are implemented on `main`:

- Configurable turn timer and optional notifications
- Active and benched roster management, including drag-and-drop reordering
- Driver/navigator role calculation and automatic turn advancement
- Always-on-top floating timer
- In-window break screen and configurable break cadence
- Menu-bar controls
- Launch at login
- Local persistence for roster and settings

Relevant implementation locations include:

- `MobCrew/MobCrew/Core/AppState.swift`
- `MobCrew/MobCrew/Core/Models/Roster.swift`
- `MobCrew/MobCrew/Features/FloatingTimer/`
- `MobCrew/MobCrew/Features/MenuBar/`
- `MobCrew/MobCrew/Features/Settings/SettingsView.swift`
- `MobCrew/MobCrew/Core/Services/PersistenceService.swift`

### Contradictory public claims

1. **Global shortcut and action**
   - Public claim: `⌘⇧M` rotates/starts the timer.
   - Implementation: `⌘⇧L` toggles the floating timer.
   - Evidence: `README.md:14`, `docs/index.html:114`,
     `MobCrew/MobCrew/Core/Services/GlobalHotkeyService.swift:28-87`, and
     `MobCrew/MobCrew/App/AppDelegate.swift:21-34`.

2. **Break presentation**
   - Public claim: a full-screen break overlay.
   - Implementation: `BreakScreenView` replaces the normal content inside the main application
     window; the shipped screenshot visibly includes a normal window title bar.
   - Evidence: `README.md:13`, `docs/index.html:103-107`, `docs/SCREENSHOTS.md:48-62`,
     `MobCrew/MobCrew/ContentView.swift:6-20`.

3. **Tips**
   - Public claim: a tip jar that supports development.
   - Implementation: optional programming-tip quotations displayed while the timer runs.
   - Evidence: `README.md:17`, `AGENTS.md:50`, `MobCrew/MobCrew/Features/Tips/`, and
     `MobCrew/MobCrew/ContentView.swift:35-39`.

4. **Hotkey customization**
   - Gallery caption/guide claim: users customize hotkeys.
   - Implementation: the Shortcuts settings tab lists fixed shortcuts; it has no editor.
   - Evidence: `docs/index.html:136`, `docs/SCREENSHOTS.md:84-97`, and
     `MobCrew/MobCrew/Features/Settings/SettingsView.swift:71-80`.

5. **Testing defaults**
   - `TESTING.md` says the timer defaults to 5 minutes; `AppState` defaults to 7 minutes.
   - `TESTING.md` describes a 1-30 minute range. The main window uses 1-30, while Settings uses
     1-60; the checklist should name both contexts instead of presenting one universal range.
   - Evidence: `TESTING.md:5-11`, `MobCrew/MobCrew/Core/AppState.swift:55-71`,
     `MobCrew/MobCrew/ContentView.swift:125-145`, and
     `MobCrew/MobCrew/Features/Settings/SettingsView.swift:40-52`.

### Distribution state

- Latest public release: `v0.2.0`, published 2026-02-01.
- Release asset: `MobCrew-0.2.0.dmg`, 3,593,226 bytes, with six recorded downloads at audit time.
- Asset SHA-256: `1d7f8daff797dd20876b4a9ab011a98e20d23bf931e98118a131e7ba9c4b99d4`.
- Current `main` is newer than the release tag; audited user-visible differences are primarily Swift
  6/runtime hardening rather than newly marketed features.
- `scripts/create-dmg.sh` always supplies `--no-code-sign` to the DMG tool, which means the outer DMG
  is not signed by that tool; this does not establish the app bundle's signature type.
- Xcode uses automatic signing and CI verifies the built app's signature structure. The downloaded
  `v0.2.0` app's actual identity/signature type was not inspected in the Linux audit environment.
- `README.md:21` publicly states the app is "currently ad-hoc signed" to explain Accessibility
  permission resets across rebuilds. That is plausible for local automatic-signing development
  builds without a team, but it is a specific signature-type claim about the app, and the released
  `v0.2.0` bundle was not inspected; Phase 1 must verify or qualify this claim rather than repeat it.
- The repository defines no Developer ID, hardened-runtime, notarization, or stapling workflow.
- The app is sandboxed. No app network-client APIs were found; roster/settings are stored with
  UserDefaults and an Application Support file.
- The public Apple-silicon claim was not verified against the released Mach-O binary in the Linux
  audit environment. CI explicitly tests `arch=arm64`, while release settings do not make the public
  artifact architecture self-evident. A future release gate must record `lipo -archs` output.

## Prioritized findings

| Priority | Finding | User impact | Confidence |
| --- | --- | --- | --- |
| P0 | Distribution trust, Gatekeeper expectations, and first-launch path are undisclosed | Very high | High |
| P0 | Published global shortcut and behavior are wrong | Very high | High |
| P0 | Hero does not explain audience, outcome, or release trust | High | High |
| P1 | Full-screen break, tip jar, and hotkey-customization claims are wrong | High | High |
| P1 | Draft-release documentation cannot be followed as written | High | High |
| P1 | Manual testing is stale and omits high-risk user journeys | High | High |
| P1 | Keyboard focus and normal-text contrast are insufficient | High | High |
| P2 | Gallery images do not prove their captions and are weak on mobile | Medium | High |
| P2 | Runtime Tailwind CDN and eager oversized imagery are avoidable | Medium | High |
| P2 | Social/search metadata and privacy/trust signals are minimal | Medium | High |
| P2 | Repeated product facts across documents invite maintenance drift | Medium | High |

## Documentation findings

### Installation and first run

The site and README link to GitHub Releases but do not explain:

- Opening the DMG and copying MobCrew to Applications
- The Gatekeeper behavior actually observed for the distributed artifact
- The safe System Settings > Privacy & Security > Open Anyway path
- Why Accessibility is requested and that the app otherwise remains usable
- Why Notifications are requested and that they are optional
- How updates are installed
- Where to get support

Xcode 26.6 appears in the same README Requirements list as macOS 14.0, which can imply that Xcode
is an end-user prerequisite. It is a development-only prerequisite.

### Release guide

`docs/RELEASING.md` says to create and test a draft, then rerun `release.sh` with the same version to
create the release. A draft created by `gh release create --draft` does not create the git tag, and
the rerun rebuilds a new artifact before calling `gh release create` again — so the documented step
publishes a rebuilt, untested artifact (or fails against existing release/tag state) and never
publishes the draft that was actually tested. The correct next step is to publish the tested draft.
The recovery guidance deletes both release and tag without distinguishing a draft (which has no tag
yet) from a previously published release.

The release script does not enforce a clean tree, expected branch/upstream, semantic version, tests,
or target commit before it creates remote state. DMG validation verifies container integrity but does
not mount and inspect the app or assess Gatekeeper. The `xcode-select --install` troubleshooting step
installs Command Line Tools, not the full Xcode version required by the project.

### Contributor/testing quality

`TESTING.md` is only a control checklist. It omits clean-install, permission denial/recovery,
shortcuts, settings, breaks, launch at login, multi-display/Spaces behavior, keyboard/VoiceOver,
upgrade, and release-artifact smoke testing. The repository also has no `CONTRIBUTING.md`,
`SECURITY.md`, `SUPPORT.md`, or changelog. These should be added only when ownership and maintenance
expectations are clear; the immediate need is a reliable README and manual-test path.

All existing Markdown links checked during the audit resolved successfully.

## Landing-page findings

### Comprehension and information architecture

The first screen says “Your Mob Programming Companion,” but does not state the job MobCrew performs:
keeping role rotations fair, visible, and on time without interrupting the session. “Mob programming”
is not explained for visitors arriving without prior context.

Recommended message direction:

- Eyebrow: native macOS app for pair, mob, and ensemble programming
- Outcome-led headline: keep driver rotations on time without interrupting the mob
- Supporting copy: track the roster, show driver/navigator, rotate roles, and keep the countdown
  visible
- Primary action while trust status remains non-Developer-ID/unverified: “View latest release,” not
  an implied frictionless direct download
- Trust row: macOS requirement, MIT license, no account, local data, and honest signing status

Recommended page order:

1. Header with internal anchors, GitHub, and latest release
2. Outcome-led hero and product proof
3. Three-step “How it works”
4. Core outcomes/features
5. Contextual screenshots
6. Install and first run
7. Permissions, privacy, architecture, updates, and support FAQ
8. Footer with license and concise Mobster attribution

The current Mobster attribution is appropriate but too prominent before install/trust/support content.

### Screenshot quality

- Hero screenshot is polished and communicates the main app successfully.
- Floating-timer screenshot lacks an editor or terminal background, so it does not prove the
  always-on-top behavior.
- Break screenshot contradicts “full-screen” by showing a normal title bar.
- Settings screenshot shows General while its caption claims hotkey customization.
- Screenshot text is not readable at 390px and images cannot be opened at full size.
- Desktop gallery images have inconsistent aspect ratios and framing.

## Accessibility and technical findings

### Accessibility

Positive findings:

- Correct landmark structure and heading order
- Logical five-link keyboard order
- No horizontal overflow at 390px
- Large hero CTA

Issues:

- Browser-computed focus style was a 1px near-black outline, effectively invisible around text links
  on the near-black page.
- Axe found the `<kbd>` badge at 4.05:1 rather than the required 4.5:1 for normal text.
- Manual calculations placed `gray-500` and blue inline-link text as low as 3.53:1 on the gradient.
- Decorative emoji/SVG icons are not explicitly hidden from assistive technology.
- The logo alt duplicates adjacent visible product text.
- Gallery alternatives label images without describing the useful state.
- Header targets are below Apple's typical 44px touch guidance, although they meet or approach the
  WCAG 2.2 24px minimum.

### Performance and resilience

One unthrottled audit run measured TTFB 8.7ms, FCP/LCP 164ms, and CLS 0, so the present page is fast
from a favorable edge. The implementation is nevertheless wasteful and fragile:

- Tailwind's browser CDN emits a production warning.
- The CDN response was 126KB compressed and 407KB decoded.
- First-party resource transfer was approximately 1.58MB.
- `break-overlay.png` alone is 1,336,176 bytes, about 85% of first-party resource bytes.
- All gallery images load eagerly and lack intrinsic dimensions.
- Failure of the Tailwind runtime removes most layout and color styling.

For this one-page site, a small static stylesheet is preferable to adding a frontend build system.

### Metadata and privacy

The deployed `<head>` includes title, description, viewport, and favicon only. It lacks canonical,
Open Graph/Twitter, social image, software schema, and Apple touch metadata. `robots.txt`, sitemap,
manifest, and touch icon returned 404; only robots/social metadata are immediately useful for this
site.

No app networking or telemetry code was found. A factual “no account; data stays on this Mac” trust
statement is supportable for the audited commit. The site itself contacts Tailwind's CDN, so
self-hosting CSS should precede any broader claim about third-party requests.

## Maintenance-drift findings

Changing product facts are repeated in README, landing-page HTML, screenshot instructions, testing,
release guidance, AGENTS, and existing release notes. The first phase should correct all current
copies; later release and Pages checks should fail on known stale claims and require a documentation
sync review without building an elaborate content-generation system.

Root `CNAME` duplicates `docs/CNAME`, while the Pages workflow uploads only `docs/`. Keep the deployed
copy as canonical unless another publishing mechanism needs the root file.

## Recommended sequence

1. Correct public truth and document successful installation with the existing release, qualifying
   signature/notarization and Gatekeeper details until the artifact is inspected on macOS.
2. Improve landing-page information architecture, accessibility, visual evidence, metadata, and
   performance once the factual message is stable.
3. Harden release mechanics and pursue signed/notarized distribution behind an explicit credential
   and product decision gate.

## Remaining uncertainty

- The released app could not be launched in this Linux orb, so observed Gatekeeper wording and
  clean-Mac behavior require macOS validation.
- The downloaded app bundle and outer DMG require separate `codesign`, `spctl`, and
  notarization/stapling inspection before assigning an exact signed/unsigned trust label.
- Released binary architectures require `lipo -archs` on macOS.
- Beta/stability labeling is a product decision; do not infer it from version `0.2.0` alone.
- Developer ID signing/notarization depends on Apple Developer Program access and secure credential
  handling.
