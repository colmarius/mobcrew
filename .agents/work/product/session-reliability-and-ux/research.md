# Audit Findings: Session Reliability and UX

## Baseline and method

- Audited revision: `main` at merge commit `03fb0ea169c545ab8f1e7cee86e91d7503eb846a`.
- Re-evaluated revision: `origin/main` at `50659f0fc5b5d5ed1b5f5452ad4cbc8c24e6c5c2`
  after rebasing on 2026-08-09. The range from the audited revision changed no `MobCrew/` app source
  or tests; it changed public documentation, release tooling, and release evidence.
- Scope: `AGENTS.md`, `README.md`, `TESTING.md`, landing-page claims, the complete
  `MobCrew/MobCrew` source tree, project settings and entitlements, and all tests.
- Environment limitation: the audit ran in a Linux orb without Xcode, so native macOS UI behavior,
  Accessibility Inspector output, sleep/wake behavior, and Xcode tests remain unobserved.
- Comparison baseline: the original `dillonkearns/mobster` was used only for concrete lessons about
  reversible rotation and optional break prompts. Feature parity is not a goal.

## Executive finding

MobCrew is a credible compact MVP, but it is not yet a dependable session instrument. The highest
value comes from making every control surface obey one phase-aware session contract, measuring
elapsed time correctly, preserving recoverable state, and reducing first-launch/system-integration
friction. Adding broad features before this stabilization would amplify existing inconsistencies.

## Findings worth addressing

| Priority | Finding | Confidence | Primary evidence | Planned response |
| --- | --- | --- | --- | --- |
| P0 | Menu-bar Skip corrupts an active break by starting a regular timer while `isOnBreak` remains true. | Confirmed | `MobCrew/MobCrew/App/MobCrewApp.swift:29-40`; `MobCrew/MobCrew/Core/AppState.swift:83-97,157-163` | Task 1 |
| P0 | Countdown subtracts delivered ticks rather than deriving remaining time from elapsed time. | Confirmed architecture; Mac behavior unobserved | `MobCrew/MobCrew/Core/Services/TimerEngine.swift:33-43,60-70` | Task 4 |
| P0 | Running/paused timer, break phase, remaining time, and break cadence are discarded on relaunch. | Confirmed | `MobCrew/MobCrew/Core/AppState.swift:26-28,55-72`; `MobCrew/MobCrew/Core/Services/PersistenceService.swift:12-19` | Task 6 |
| P0 | Permanent active-roster deletion bypasses driver-index repair and can change the driver unexpectedly. | Confirmed | `MobCrew/MobCrew/Features/Roster/RosterView.swift:141-149`; `MobCrew/MobCrew/Core/Models/Roster.swift:37-42,60-69` | Task 2 |
| P1 | Main-window and Settings duration changes have contradictory behavior; paused and idle are not distinguishable. | Confirmed | `MobCrew/MobCrew/ContentView.swift:125-145`; `MobCrew/MobCrew/Features/Settings/SettingsView.swift:40-52`; `MobCrew/MobCrew/Core/AppState.swift:138-149` | Task 3 |
| P1 | A blocking Accessibility alert appears at launch, “Not Now” is not remembered, and permission may be unnecessary for Carbon hotkey registration. | Confirmed flow; permission need unverified | `MobCrew/MobCrew/App/AppDelegate.swift:16-18,36-96`; `MobCrew/MobCrew/Core/Services/GlobalHotkeyService.swift:28-87,106-159` | Task 7 |
| P1 | Automatic breaks cannot be disabled, start without a Take/Skip decision, and end without feedback. | Confirmed | `MobCrew/MobCrew/Core/AppState.swift:15-28,83-127`; `MobCrew/MobCrew/Features/Settings/SettingsView.swift:113-147` | Task 5 |
| P1 | Notification and Launch at Login toggles can claim success while macOS denied or failed the operation. | Confirmed | `MobCrew/MobCrew/Core/Services/NotificationService.swift:22-30`; `MobCrew/MobCrew/Core/Services/LaunchAtLoginService.swift:10-24`; `MobCrew/MobCrew/Features/Settings/SettingsView.swift:27-38,54-57` | Task 8 |
| P1 | Roster persistence is scene-observed, not model-owned: saves fire only from SwiftUI `.onChange` observers, and `skipTurn()`/timer completion never call `saveRoster()` directly. | Confirmed | `MobCrew/MobCrew/App/MobCrewApp.swift:19-27`; `MobCrew/MobCrew/Core/AppState.swift:83-97,129-136,157-163` | Tasks 2, 6 |
| P1 | Roster correction and ordering are destructive or pointer-first: no rename, removal Undo, or Move Up/Down. | Confirmed absence; interaction quality needs Mac observation | `MobCrew/MobCrew/Features/Roster/RosterView.swift:45-58,78-117`; `MobCrew/MobCrew/Features/Roster/MobsterRow.swift:10-44` | Tasks 9, 12 |
| P1 | Critical controls lack explicit contextual accessibility semantics and transition announcements. | Confirmed absence; exact VoiceOver output unobserved | `MobCrew/MobCrew/ContentView.swift:97-122`; `MobCrew/MobCrew/Features/Break/BreakProgressView.swift:7-15`; `MobCrew/MobCrew/Features/Roster/MobsterRow.swift:24-56` | Task 9 |
| P2 | The floating timer is forced open, only hideable by hotkey, and repositioned on every show. | Confirmed | `MobCrew/MobCrew/App/MobCrewApp.swift:29-41,48-53` (menu bar exposes no show/hide action); `MobCrew/MobCrew/App/AppDelegate.swift:21-34` (toggle wired only to the global hotkey; `hide()` only at termination); `MobCrew/MobCrew/Features/FloatingTimer/FloatingTimerController.swift:19-25,54-66` | Task 11 |

## Work completed on latest main

The public-documentation and release-hardening work merged after the original audit resolved the
current-state documentation defects without changing app behavior:

- `README.md` and `docs/index.html` now describe the actual ⌘⇧L floating-timer action, in-window
  break presentation, optional programming quotations, fixed shortcuts, local persistence, and
  current permission behavior.
- `TESTING.md` now records the 7-minute default, both currently inconsistent duration ranges, roster
  edge states, breaks, fixed shortcuts, permission refusal, notifications, menu/floating/login flows,
  persistence, keyboard/VoiceOver, display, Spaces, and release-artifact qualification.
- `scripts/validate-docs.py` and the release workflow provide a reusable static documentation gate.

This completes the old “repair stale public/manual documentation” work. It does **not** satisfy any
app-behavior task, prove the manual checklist was executed, or remove the need to update documentation
when Tasks 1-9 intentionally change session semantics. Task 10 is therefore retained as a final delta
and observed-validation gate rather than a website rewrite.

## Confirmed defects and smallest corrections

### Break-state corruption

During a break, menu-bar Skip calls `skipTurn()`. That method advances the roster, resets the timer
to the regular duration, and starts it without clearing break mode. The next completion is then
misclassified as break completion. Route the action to `skipBreak()` in break mode and guard
`skipTurn()` at the AppState boundary. The same menu-bar Skip is also enabled with zero or one
active participant while the main window disables it below two, so guards must live in shared
AppState capabilities rather than per-surface `disabled` modifiers.

### Roster mutation invariants

Benching adjusts `nextDriverIndex`, but permanent deletion mutates the active array directly. Add a
model-owned removal operation that preserves current-driver identity when possible. Normalize loaded
indices so malformed negative or oversized values cannot crash or select surprising roles. Ordinary
reordering should preserve the current driver; shuffle may deliberately select the first shuffled
participant.

### Duration and lifecycle ambiguity

The main stepper resets whenever `isRunning` is false, including paused timers. Settings changes only
the configured value, leaving an idle display stale. The two surfaces also disagree on range: the
main stepper allows 1–30 minutes (`ContentView.swift:138`) while Settings allows 1–60
(`SettingsView.swift:44`). Introduce the smallest explicit lifecycle that
distinguishes idle, running, and paused, then route both steppers through one operation. Idle changes
apply immediately; running and paused changes apply to the next turn unless the user explicitly
resets.

### Clock and recovery

The publisher should refresh display, not define elapsed time. A running timer needs a deadline;
pausing converts that deadline to a remaining duration. Use an injected monotonic clock for
in-process elapsed time and an injected wall clock only to reconcile a persisted deadline across
relaunch. Persist a versioned snapshot separately from roster/settings so corrupt runtime state
cannot erase roster data. On recovery after an expired deadline, process at most one idempotent
completion, stop for human handoff, and never simulate multiple missed rotations.

Ordered roster-then-snapshot writes are unenforceable today because roster persistence is owned by
SwiftUI scene `.onChange` observers rather than the model: `skipTurn()` and timer completion mutate
the roster and update the active-mobsters file but rely on view-layer observation for the durable
save. Recovery work must first move roster persistence into the model mutation path.

### First launch and system integrations

Do not request powerful permission merely because the app launched. First determine on real Macs
whether Carbon registration works without Accessibility permission. Prior platform evidence points
to "not required": Accessibility (TCC) gates CGEventTap and NSEvent global monitors, while Carbon
`RegisterEventHotKey` has historically worked without it; the Mac check confirms this on supported
releases rather than exploring an open question. If permission is genuinely
required, request it contextually, remember dismissal, bound polling, and show status in Settings.
Notification and login-item settings must distinguish user preference from macOS authorization or
registration state and offer recovery actions.

### Task 9 accessibility APIs

Apple's macOS 14+ `AccessibilityNotification.Announcement` provides the native cross-platform
announcement path and posts with `AccessibilityNotification.Announcement(message).post()`. The app
should call it only at semantic transitions, behind an injected closure for exact-once tests; timer
refreshes must only update displayed state. SwiftUI's named accessibility actions are the supported
way to expose reorder operations to VoiceOver and Switch Control, while ordinary `Button` controls
remain the Full Keyboard Access path. Native `List` and `Stepper` behavior should remain intact rather
than being replaced by nested custom scroll containers or a grouped static accessibility element.

Sources:

- [AccessibilityNotification.Announcement](https://developer.apple.com/documentation/accessibility/accessibilitynotification/announcement)
  — announcement purpose, macOS 14 availability, priority, and `.post()` usage.
- [accessibilityAction(named:_:)](https://developer.apple.com/documentation/swiftui/view/accessibilityaction(named:_:))
  — named assistive-technology actions.
- [Build accessible apps with SwiftUI and UIKit](https://developer.apple.com/videos/play/wwdc2023/10036/)
  — Apple examples for notifications, priority, and assistive interaction.

## Product recommendations

- Allow a timer with one active participant as an intentional solo fallback, but require at least two
  active participants to advance roles. Disable all session actions with an empty roster.
- Make breaks disable-able. Preserve the current enabled default for compatibility, but present a
  Take Break / Skip Break choice instead of auto-starting a break.
- Add break-complete feedback and an exact, same-session Undo contract for permanent roster removal.
  Defer role rewind until its effects on break cadence and recovered completion are defined. Avoid
  modal confirmation for routine session controls.
- Add roster rename while preserving the Mobster UUID, keyboard Move Up/Down alternatives, bounded
  scrolling, and person-specific action labels.
- Let users explicitly show/hide the floating panel and persist its position and visibility. Login
  launch should be quiet rather than opening all windows.
- Keep role identity textual as well as colored, standardize Driver/Navigator colors, and announce
  only meaningful transitions rather than every timer tick.

## Mac-only validation

1. Carbon hotkey registration with Accessibility denied on the current available macOS host.
2. Timer behavior across sleep, lock/unlock, App Nap, modal UI, and main-thread blockage.
3. Foreground/background notification presentation and sound for allowed and denied states.
4. `SMAppService` enabled, requires-approval, failed, and managed-account behavior.
5. VoiceOver and Full Keyboard Access names/actions for timer, roster, break, menu, and panel controls.
6. Floating-panel keyboard focus, fullscreen Spaces, multiple displays, long names, and increased text size.
7. Large roster behavior with active and benched participants in a normally sized window.
8. Launch-at-login window behavior and restoration of panel visibility/position.

### Observed Task 7 result: Carbon hotkey does not require Accessibility

On 2026-08-09, the logged-in Mac runner (macOS 26.5.2, arm64, Xcode 26.2) ran an
ad-hoc-signed AppKit/Carbon receiver with unique bundle ID
`local.mobcrew.task7.denied-receiver.20260809`. The receiver reported
`AXIsProcessTrusted=false`, then registered MobCrew's exact key code 37 plus `cmdKey | shiftKey`
with `RegisterEventHotKey` status `0` (`noErr`). An already-authorized, noninteractive CGEvent sender
posted ⌘⇧L, and the denied receiver observed one `kEventHotKeyPressed` callback before unregistering.
No TCC state, System Settings value, global shortcut, or user default was changed.

Duplicate registration inside one process returned `-9878` (`eventHotKeyExistsErr`), establishing a
registration failure distinct from TCC denial. On this OS, a separate process could register the same
chord concurrently, so cross-process exclusivity must not be inferred from Carbon registration alone.
No physical keypress was observed. The available Mac evidence selects Task 7's permission-unnecessary
branch: remove the AX launch prompt, dependency, and polling; surface Carbon registration state and
retry instead. On 2026-08-09 the owner accepted current-host coverage and removed older-macOS
repetition as a release/work-item gate.

The implemented branch was then qualified with `/Applications/Xcode.app` at Xcode 26.6 / Swift 6.3.
The ad-hoc-signed Debug app launched without an Accessibility dialog, Settings rendered ⌘⇧L,
“Toggle floating timer,” and live status “Active,” and two preflight-authorized synthetic deliveries
made the real floating panel transition onscreen → hidden → onscreen. App-specific AX denial and a
physical keypress were not independently observed; the denied-receiver experiment above establishes
the permission result without changing TCC state.

### Observed Task 9 result: responsive accessible roster layout

On 2026-08-09, the logged-in Mac runner (macOS 26.5.2, arm64, Xcode 26.6, Swift 6.3.3)
tested exact commit `5b0e88937efdd71ed8c6741dc3dea122a00142fa` with an isolated 12-active,
8-benched roster. `AppStateTests` and `RosterTests` passed 85/85. At 600×450 content the split panes
measured 299/300 points and the roster outline 268×378; at 1000×700 they measured 499/500 and
468×628. A real pointer drag moved the splitter and reallocated the panes without changing height.

One AX roster outline owned all 20 long-name participants and 64 person-specific Move, Bench,
Activate, and Remove action titles in complete minimum and expanded snapshots. Increased-text checks
kept all main controls, 22 outline rows, and actions reachable at both sizes. The floating panel's AX
children remained in bounds; visible long-name ellipsis at its intentional 180-point width is recorded
for non-blocking Task 11 rather than expanding release-critical scope. AXPress on Skip emitted one
contextual handoff announcement. User inspection of the expanded normal-text app confirmed both panes
and the List filled available space with readable long names and no visible overlap. Spoken VoiceOver,
Increase Contrast, Differentiate Without Color, and break-complete announcement checks remain interactive
gates; current-host evidence is sufficient and older-macOS repetition is not required.

The first Full Keyboard Access attempt found that Tab skipped the borderless participant buttons inside
the native List. Explicit `.focusable(..., interactions: .activate)` enrollment preserves button style,
pointer behavior, VoiceOver actions, and excludes unavailable boundary moves. It compiled under Xcode
26.6 and passed all 85 focused AppState/Roster tests. After the owner enabled Full Keyboard Access, an
unlocked-session screenshot showed the native focus ring inside the roster and keyboard selection on an
Active row; the owner reported keyboard behavior working. The isolated app/worktree/defaults were then
removed and all Task 9 verification threads archived.

## Explicit deferrals

- Do not implement a forced full-screen break solely to satisfy stale marketing copy.
- Do not change the global shortcut to rotate/start solely because README currently says so.
- Do not auto-start every next turn after natural completion without observed demand.
- Do not add saved teams, cloud sync, roster import/export, or payment/tip-jar work in this item.
- Do not reject duplicate participant names; real teams may contain them.
- Do not persist a raw decrementing counter without deadline reconciliation.

## Test gaps

- Current async timer tests rely on wall-clock sleeps instead of an injected clock.
- No transition matrix covers phase × roster size × action.
- No test invokes Skip during a break.
- No model path or tests exist for permanent removal.
- Tests codify one-person Skip starting a timer and reorder resetting the driver to index zero; those
  expectations should change with the product contract.
- AppState tests inject isolated UserDefaults but still default to the shared notification service.
- No test proves a roster mutation reaches durable storage; production saving depends on SwiftUI
  scene observation that unit tests cannot exercise.
- No tests cover session restoration, corrupt snapshots, permission status, launch-item failure, or
  accessibility/UI behavior.
- `TESTING.md` now covers the current-state journeys broadly, but its unchecked items are planned
  manual checks rather than observed evidence. It must be updated with Tasks 1-9 and executed on a
  logged-in Mac; deadline recovery and the new break-due state do not exist yet.

## Oracle plan review

An Oracle stress test reviewed the initial work-item plan against the implementation. The final plan
incorporates its required changes:

- Authoritative regular/break and idle/running/paused state now belongs to Task 1 rather than being
  deferred until duration work.
- Break-due policy is finalized before the session snapshot persists that state model.
- Deadline work explicitly separates monotonic in-process time from wall-clock relaunch recovery and
  requires a synchronous refresh seam for deterministic tests.
- Overdue recovery has exact per-phase outcomes, explicit persistence boundaries, and an idempotence
  requirement anchored to the started cycle/driver or an equivalent durable token.
- Core accessibility/reachability, richer roster correction, and floating-panel ownership are split
  into coherent tasks; P2 panel/login behavior does not block the stabilization release.
- Notification and `SMAppService` status acceptance criteria use the actual platform enum states.
