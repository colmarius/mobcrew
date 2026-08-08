# Audit Findings: Session Reliability and UX

## Baseline and method

- Audited revision: `main` at merge commit `03fb0ea169c545ab8f1e7cee86e91d7503eb846a`.
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
| P1 | A blocking Accessibility alert appears at launch, “Not Now” is not remembered, and the public shortcut/action are wrong. | Confirmed flow and mismatch; permission need unverified | `MobCrew/MobCrew/App/AppDelegate.swift:16-18,36-96`; `README.md:14`; `docs/index.html:110-115` | Task 7 |
| P1 | Automatic breaks cannot be disabled, start without a Take/Skip decision, and end without feedback. | Confirmed | `MobCrew/MobCrew/Core/AppState.swift:15-28,83-127`; `MobCrew/MobCrew/Features/Settings/SettingsView.swift:113-147` | Task 5 |
| P1 | Notification and Launch at Login toggles can claim success while macOS denied or failed the operation. | Confirmed | `MobCrew/MobCrew/Core/Services/NotificationService.swift:22-30`; `MobCrew/MobCrew/Core/Services/LaunchAtLoginService.swift:10-24`; `MobCrew/MobCrew/Features/Settings/SettingsView.swift:27-38,54-57` | Task 8 |
| P1 | Roster correction and ordering are destructive or pointer-first: no rename, removal Undo, or Move Up/Down. | Confirmed absence; interaction quality needs Mac observation | `MobCrew/MobCrew/Features/Roster/RosterView.swift:45-58,78-117`; `MobCrew/MobCrew/Features/Roster/MobsterRow.swift:10-44` | Tasks 9, 12 |
| P1 | Critical controls lack explicit contextual accessibility semantics and transition announcements. | Confirmed absence; exact VoiceOver output unobserved | `MobCrew/MobCrew/ContentView.swift:97-122`; `MobCrew/MobCrew/Features/Break/BreakProgressView.swift:7-15`; `MobCrew/MobCrew/Features/Roster/MobsterRow.swift:24-56` | Task 9 |
| P2 | The floating timer is forced open, only hideable by hotkey, and repositioned on every show. | Confirmed | `MobCrew/MobCrew/App/MobCrewApp.swift:48-53`; `MobCrew/MobCrew/Features/FloatingTimer/FloatingTimerController.swift:19-25,54-66` | Task 11 |
| P2 | Public and manual documentation is materially stale. | Confirmed | `README.md:9-17`; `TESTING.md:5-35`; `docs/index.html:79-115,133-137` | Tasks 5, 7, 10 |

## Confirmed defects and smallest corrections

### Break-state corruption

During a break, menu-bar Skip calls `skipTurn()`. That method advances the roster, resets the timer
to the regular duration, and starts it without clearing break mode. The next completion is then
misclassified as break completion. Route the action to `skipBreak()` in break mode and guard
`skipTurn()` at the AppState boundary.

### Roster mutation invariants

Benching adjusts `nextDriverIndex`, but permanent deletion mutates the active array directly. Add a
model-owned removal operation that preserves current-driver identity when possible. Normalize loaded
indices so malformed negative or oversized values cannot crash or select surprising roles. Ordinary
reordering should preserve the current driver; shuffle may deliberately select the first shuffled
participant.

### Duration and lifecycle ambiguity

The main stepper resets whenever `isRunning` is false, including paused timers. Settings changes only
the configured value, leaving an idle display stale. Introduce the smallest explicit lifecycle that
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

### First launch and system integrations

Do not request powerful permission merely because the app launched. First determine on real Macs
whether Carbon registration works without Accessibility permission. If permission is genuinely
required, request it contextually, remember dismissal, bound polling, and show status in Settings.
Notification and login-item settings must distinguish user preference from macOS authorization or
registration state and offer recovery actions.

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

1. Carbon hotkey registration with Accessibility denied on each supported macOS release.
2. Timer behavior across sleep, lock/unlock, App Nap, modal UI, and main-thread blockage.
3. Foreground/background notification presentation and sound for allowed and denied states.
4. `SMAppService` enabled, requires-approval, failed, and managed-account behavior.
5. VoiceOver and Full Keyboard Access names/actions for timer, roster, break, menu, and panel controls.
6. Floating-panel keyboard focus, fullscreen Spaces, multiple displays, long names, and increased text size.
7. Large roster behavior with active and benched participants in a normally sized window.
8. Launch-at-login window behavior and restoration of panel visibility/position.

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
- No tests cover session restoration, corrupt snapshots, permission status, launch-item failure, or
  accessibility/UI behavior.
- `TESTING.md` omits breaks, permission refusal, notifications, launch at login, sleep/wake, recovery,
  accessibility, and cross-surface action consistency.

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
