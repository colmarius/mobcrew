# MobCrew Session Reliability and UX Stabilization Plan

Stabilize the real-session experience in dependency order. The release-critical path establishes one
authoritative session model, protects roster invariants, corrects elapsed-time and recovery behavior,
then addresses break policy, permissions, system status, accessibility, and documentation. Confirmed
but lower-priority floating-panel and richer roster-correction work remains non-blocking follow-up.

## Re-evaluation after latest main

This branch was rebased onto `origin/main` at `50659f0` on 2026-08-09. Comparing that revision with
the audited merge commit found no changes under `MobCrew/`, so Tasks 1-9 and the non-blocking app
follow-ups remain unsatisfied. Main did complete a public-documentation, manual-checklist, and release
hardening effort. Task 10 now owns only documentation deltas caused by Tasks 1-9 plus final observed
validation; it must not recreate the website or treat unchecked manual steps as completed evidence.

## Goals

- Make main-window, menu-bar, and floating-panel actions obey one session-state contract.
- Preserve correct elapsed time and recover safely after sleep, suspension, crash, or relaunch.
- Keep driver assignment stable through ordinary roster changes.
- Reduce first-launch permission friction and accurately represent macOS integration status.
- Make core workflows operable and understandable with keyboard and VoiceOver.
- Reconcile public documentation and release validation with observed behavior.

## Release-critical tasks

### Task 1: Make session actions phase-aware and consistent

- [x] **Task 1: Make session actions phase-aware and consistent**
  - Scope: `MobCrew/MobCrew/Core/AppState.swift`, `MobCrew/MobCrew/Core/Models/TimerState.swift`,
    `MobCrew/MobCrew/App/MobCrewApp.swift`, `MobCrew/MobCrew/ContentView.swift`,
    `MobCrew/MobCrew/Features/MenuBar/MenuBarView.swift`, floating/break views, AppState/break tests
  - Depends on: none
  - Acceptance:
    - One externally read-only state representation distinguishes regular idle, regular running,
      regular paused, break due, break running, and break paused.
    - AppState commands are the only production path for starting, pausing, resuming, resetting,
      advancing a turn, taking a break, and skipping a break.
    - Menu-bar Skip during a break ends the break without advancing the roster or replacing the break countdown.
    - `skipTurn()` cannot mutate break state even if called directly.
    - Empty-roster Start is rejected at the AppState boundary; one-person Start is allowed; advancing
      roles requires at least two active participants.
    - Every surface consumes shared capabilities and phase-aware labels; pause is not labeled Stop.
    - Notification behavior is injected behind a protocol so transition tests never use the shared system center.
    - A transition matrix covers every reachable state × roster size 0/1/2 × supported command.
  - Notes: Prefer the smallest discriminated state and guarded commands over a broad reducer rewrite.
    Remove or derive `isOnBreak`, `isRunning`, `TimerType`, and `breakSecondsRemaining` so they cannot diverge.

### Task 2: Enforce roster mutation invariants

- [x] **Task 2: Enforce roster mutation invariants**
  - Scope: `MobCrew/MobCrew/Core/Models/Roster.swift`,
    `MobCrew/MobCrew/Features/Roster/RosterView.swift`, Roster and persistence tests
  - Depends on: none
  - Acceptance:
    - Active/inactive collections and driver index are externally read-only; all production mutation
      passes through Roster operations.
    - Permanent removal preserves the current driver's UUID when another participant is removed.
    - Removing the current driver selects the next active participant deterministically; removing the
      last active participant resets safely.
    - Ordinary reordering preserves current-driver identity; shuffle deliberately establishes a new first driver.
    - Negative and oversized loaded driver indices normalize into a safe range without crashing.
    - Tests cover removal before/current/after driver, removal to empty, reactivation, reorder, shuffle,
      malformed indices, and persistence round trips.
  - Notes: Do not forbid duplicate names. Keep UUID identity stable.

### Task 3: Unify configured duration and current-cycle semantics

- [x] **Task 3: Unify configured duration and current-cycle semantics**
  - Scope: `MobCrew/MobCrew/Core/Models/TimerState.swift`, `MobCrew/MobCrew/Core/AppState.swift`,
    `MobCrew/MobCrew/ContentView.swift`, `MobCrew/MobCrew/Features/Settings/SettingsView.swift`, timer/AppState tests
  - Depends on: Task 1
  - Acceptance:
    - Configured duration and the current cycle's total/remaining duration have distinct ownership.
    - Changing duration while regular idle updates configured and displayed duration.
    - Changing duration while regular running or paused applies to the next turn and does not discard current progress.
    - Explicit Reset applies the configured duration and returns to regular idle.
    - Main and Settings use one AppState operation and the same 1–60 minute range.
    - Tests cover duration changes in every regular lifecycle state and prove break duration is unaffected.
  - Notes: Lifecycle ownership comes from Task 1; do not introduce a second status model here.

### Task 4: Make countdown deadline-based and deterministic

- [x] **Task 4: Make countdown deadline-based and deterministic**
  - Scope: `MobCrew/MobCrew/Core/Services/TimerEngine.swift`, `MobCrew/MobCrew/Core/Models/TimerState.swift`, TimerEngine tests
  - Depends on: Tasks 1, 3
  - Acceptance:
    - In-process remaining time derives from an injected monotonic clock and deadline, not delivered publisher-event count.
    - Pausing freezes observed remaining duration; resuming establishes a fresh monotonic deadline.
    - A separately injected wall clock can encode/reconcile a running deadline across process relaunch.
    - Recovery converts a validated wall-clock remainder once into a fresh monotonic deadline; normal
      in-process ticks do not repeatedly use wall time.
    - Display rounding is defined as `max(0, ceil(deadline - now))`, and crossing zero completes exactly once.
    - A synchronous refresh seam or injected scheduler lets tests advance clocks without real sleeps.
    - Tests cover delayed refreshes, sleep-like jumps, pause/resume, sub-second boundaries, and exactly-once completion.
  - Notes: Persist current-cycle total plus wall deadline for running states; non-running states use
    remaining duration. Do not duplicate the global configured duration in the session snapshot.

### Task 5: Make breaks optional and finalize break transitions

- [x] **Task 5: Make breaks optional and finalize break transitions**
  - Scope: `MobCrew/MobCrew/Core/AppState.swift`, `MobCrew/MobCrew/Core/Services/PersistenceService.swift`,
    break/settings/main/floating/menu views, notification service, break/AppState tests
  - Depends on: Task 1
  - Acceptance:
    - A persisted `breaksEnabled` setting can disable automatic break prompts; absence of the new key
      decodes as enabled for backward compatibility.
    - Reaching the interval enters break due and presents Take Break / Skip Break without auto-starting a timer.
    - Taking, pausing, resuming, skipping, and completing a break all use Task 1's authoritative states.
    - Break completion produces one fixed cue through the existing notification preference and one
      accessible in-app transition; it does not add a new sound-preference subsystem.
    - Skip Break resets cadence and returns to regular idle without advancing roles.
    - Disabling breaks clears any pending break-due state, and turns completed while disabled do not
      accumulate cadence, so re-enabling can never trigger an immediate surprise break prompt.
    - Tests cover disabled breaks, due decisions, cadence while disabled and across re-enable, all
      break lifecycle transitions, and completion exactly once.
  - Notes: Keep breaks enabled by default now that due status no longer forcibly takes over the session.

### Task 6: Persist and recover a versioned session snapshot

- [ ] **Task 6: Persist and recover a versioned session snapshot**
  - Scope: `MobCrew/MobCrew/Core/Services/PersistenceService.swift`, `MobCrew/MobCrew/Core/AppState.swift`,
    `MobCrew/MobCrew/App/MobCrewApp.swift` (scene `.onChange` persistence removal), app lifecycle
    hooks, roster persistence integration, persistence/AppState tests
  - Depends on: Tasks 2, 4, 5
  - Acceptance:
    - A versioned snapshot stores authoritative session state, current-cycle total, remaining duration
      for non-running states or wall deadline for running states, break cadence, cycle identity, and
      started-driver anchor or equivalent idempotence token.
    - Future regular deadlines restore running with a fresh monotonic deadline; paused regular timers
      restore their stored remainder without subtracting relaunch time.
    - Expired regular deadlines process exactly one semantic completion, stop all timers, advance roles
      only when permitted, increment cadence once, and enter regular idle or break due.
    - Expired running breaks complete once, reset cadence, enter regular idle, and never advance roles.
    - Break due and paused-break states restore exactly without auto-starting.
    - Repeated construction from the same expired stored state cannot advance roles or cadence twice,
      including a simulated interruption between roster and snapshot writes.
    - A normalized snapshot is saved after every semantic transition; lifecycle hooks are backup
      flushes rather than the primary persistence path.
    - Roster persistence is triggered by model mutation operations rather than SwiftUI scene
      `.onChange` observation, so roster-then-snapshot write ordering is enforceable and roster
      changes persist without an open main window.
    - Recovery and any resulting roster change are persisted before a restored publisher is armed,
      and completion handling is configured before a restored timer can fire.
    - Missing, corrupt, unknown-newer-version, impossible-state, missing-deadline, non-positive/excessive
      duration, remaining-over-total, and negative-cadence snapshots fall back safely without erasing
      valid roster/settings.
  - Notes: Keep the snapshot separate from roster/settings. An old binary may ignore it and lose only
    in-flight state; a later roll-forward must not replay a stale completion.

### Task 7: Verify and correct global-hotkey permission setup

- [ ] (manual-verify) **Task 7: Verify and correct global-hotkey permission setup**
  - Scope: `MobCrew/MobCrew/App/AppDelegate.swift`,
    `MobCrew/MobCrew/Core/Services/GlobalHotkeyService.swift`, Settings shortcut UI, README/landing page,
    service tests and signed-app Mac validation
  - Depends on: none
  - Acceptance:
    - A logged-in Mac check records whether Carbon registration works with Accessibility denied on
      available supported macOS versions and whether failure is caused by permission or shortcut conflict.
    - If permission is unnecessary, the launch prompt, AX dependency, and permission polling are removed.
    - If permission is necessary, the request is contextual, dismissal is remembered, polling is bounded,
      and Settings exposes status and retry.
    - Registration conflict/failure is visible rather than console-only.
    - One app constant defines registered key/modifiers/action; a release check verifies static Settings,
      README, and landing-page text matches it.
  - Notes: Do not generate static documentation from Swift and do not change the action to rotate/start
    merely to match stale copy. The Mac result selects one implementation branch before coding it.

### Task 8: Represent Notification and Launch at Login status honestly

- [ ] **Task 8: Represent Notification and Launch at Login status honestly**
  - Scope: `MobCrew/MobCrew/Core/Services/NotificationService.swift`,
    `MobCrew/MobCrew/Core/Services/LaunchAtLoginService.swift`,
    `MobCrew/MobCrew/Features/Settings/SettingsView.swift`, service/AppState tests
  - Depends on: Task 1
  - Acceptance:
    - Notification preference is distinct from `UNAuthorizationStatus`; disabled preference never requests authorization.
    - Settings accurately presents not-determined, denied, authorized, provisional, and ephemeral states,
      with an Open Settings recovery action where useful.
    - Launch at Login accurately presents `SMAppService.Status` values: not registered, enabled,
      requires approval, and not found.
    - A thrown registration error is transient operation feedback followed by refreshing actual status;
      it is not stored as a fictional persistent status.
    - Failed operations revert or qualify the visible control and produce user-facing feedback.
    - AppState and service tests use injected system-service doubles.
  - Notes: Preserve UserNotifications and ServiceManagement as the runtime sources of truth.

### Task 9: Make core controls accessible and large rosters reachable

- [ ] **Task 9: Make core controls accessible and large rosters reachable**
  - Scope: `MobCrew/MobCrew/ContentView.swift`, roster views/model, break progress/view, menu and
    floating views, focused model/UI tests and Mac accessibility validation
  - Depends on: Tasks 1, 2
  - Acceptance:
    - Timer, reset, advance, break progress, and participant actions expose explicit contextual labels,
      values, and hints that include participant/role context where relevant.
    - Role badges expose Driver/Navigator text rather than only D/N, and role color semantics are
      consistent across surfaces and remain clear without color.
    - Move Up/Down actions provide a keyboard and accessibility alternative to dragging while preserving Task 2 invariants.
    - With at least 12 active and 8 benched participants in a 600×450 window, every row remains reachable.
    - Driver, break-due, and break-complete transitions announce once; timer ticks do not announce.
    - VoiceOver, Full Keyboard Access, Increase Contrast, Differentiate Without Color, and increased
      text-size results are recorded on a logged-in Mac.
  - Notes: Rename and Undo are separated into non-blocking Task 12 so this task remains a coherent accessibility slice.

### Task 10: Maintain documentation truth and run final validation

- [ ] **Task 10: Maintain documentation truth and run final validation**
  - Scope: `README.md`, `docs/index.html`, `TESTING.md`, relevant previews/UI tests, release notes if applicable
  - Depends on: Tasks 1-9
  - Acceptance:
    - Behavior-changing Tasks 1-9 update affected README, website, and manual checks in the same task;
      the completed current-state documentation overhaul is not recreated.
    - `python3 scripts/validate-docs.py` passes after final reconciliation, including default duration,
      range, hotkey key/action, break presentation, Tips behavior, and Settings claims.
    - `TESTING.md` describes the implemented phase model, break-due choice, deadline/sleep behavior,
      session recovery, system-status UI, large-roster behavior, keyboard operation, and VoiceOver checks.
    - A logged-in Mac release pass records Xcode build/test output and an explicit result for every
      applicable manual check; an unchecked checklist is not accepted as execution evidence.
    - No screenshot or marketing claim asserts behavior that was not observed.
  - Notes: Latest main already corrected the baseline public claims and expanded `TESTING.md`. This is
    the stabilization delta/release gate; Tasks 11-12 do not block it.

## Non-blocking follow-up tasks

### Task 11: Fix confirmed floating-panel ownership friction

- [ ] **Task 11: Fix confirmed floating-panel ownership friction**
  - Scope: floating timer controller/window/view, MenuBarView, separate UI-preference persistence,
    focused controller tests and Mac validation
  - Depends on: none
  - Acceptance:
    - The menu bar provides a discoverable Show/Hide Floating Timer action independent of the global shortcut.
    - `show()` preserves a user-moved position and only calculates a default on first creation or when
      the prior screen/position is unavailable.
    - Panel preferences use separate UI keys rather than the session snapshot.
    - Current normal-launch visibility behavior remains unchanged unless Mac observation supports a product change.
    - Keyboard focus, fullscreen Spaces, multiple displays, long names, and increased text size are observed
      and recorded before expanding scope to login-launch or focus-policy changes.
  - Notes: Quiet login launch, persisted visibility, and focus policy require a separate decision after
    observing a normally signed app; they are not implicit acceptance criteria here.

### Task 12: Add bounded roster correction

- [ ] **Task 12: Add bounded roster correction**
  - Scope: Roster model/views, AppState or undo integration, focused roster/AppState/UI tests
  - Depends on: Task 2
  - Acceptance:
    - Participants can be renamed without changing UUID, collection membership, order, or current role.
    - Permanent removal offers one in-memory Undo for the most recent removal, restoring exact active/
      benched membership, order, driver identity, and index.
    - Undo expires after another roster mutation or relaunch and is not represented as durable session history.
    - Person-specific Rename, Remove, and Undo actions are keyboard- and VoiceOver-operable.
  - Notes: Role-advance rewind is deferred until its effects on break cadence, notifications, and recovered
    completion are explicitly defined. Prefer this bounded Undo over modal confirmation.

## Implementation Notes

- Preserve behavior while changing state ownership: add focused failing tests, then make the smallest
  transition change that satisfies them.
- Keep UI surfaces thin. They render AppState capabilities and invoke commands rather than mutate
  roster or timer internals.
- Avoid parallel sources of truth. Authoritative state, timer lifecycle, current-cycle timing, and the
  persisted snapshot must be consolidated or derived.
- Use deterministic clocks and protocol-backed system services. Do not add real sleeps or shared
  notification-center effects to unit tests.
- Commit/review at task boundaries if implementation is authorized; avoid mixing timer semantics,
  persistence migration, and unrelated visual cleanup.
- Tasks 1-10 form the stabilization release path. Tasks 11-12 are independently valuable but do not
  delay release acceptance.
- Native verification requires a macOS runner or local Mac with Xcode 26.6+.

## Constraints / Decisions

- One active participant may run a timer; at least two are required to advance roles.
- Natural timer completion stops for human handoff; this item does not add continuous auto-start.
- Running or paused duration changes apply to the next turn; regular-idle changes apply immediately.
- Recovery processes at most one idempotent expired completion and never simulates repeated unattended rotations.
- Automatic breaks remain enabled when the new key is absent, but become disable-able and require a Take/Skip choice.
- Global shortcut behavior is not changed solely to match stale documentation.
- Duplicate participant names remain valid.
- Forced full-screen breaks, saved teams, cloud sync, import/export, payment features, and role-advance
  rewind are out of release-critical scope.

## Acceptance Criteria

- No user action can create contradictory regular/break or idle/running/paused state.
- Elapsed time remains correct after delayed refreshes and reconciles safely after wake or relaunch.
- Replaying the same persisted expired state cannot advance roles or break cadence twice.
- Roster edits cannot unexpectedly change an unaffected current driver.
- First launch is usable without granting unrelated permission, subject to the verified hotkey requirement.
- System-integration controls report actual macOS status and provide recovery paths.
- Core workflows are keyboard-operable and expose meaningful VoiceOver semantics.
- Public documentation and manual validation agree with observed app behavior.

## Verification

- On a macOS runner or local Mac:
  `xcodebuild test -project MobCrew/MobCrew.xcodeproj -scheme MobCrew -destination 'platform=macOS'`
- Run focused test classes while iterating, especially `RosterTests`, `TimerEngineTests`,
  `AppStateTests`, `BreakLogicTests`, `PersistenceServiceTests`, and service tests.
- Run deterministic clock tests without wall-clock sleeps and transition-matrix tests without system services.
- Simulate repeated recovery and interruption between snapshot and roster persistence writes.
- Run `python3 scripts/validate-docs.py` after any public/manual documentation change.
- Execute and record the Mac-only validation list in `research.md` before Task 10 is accepted.
- Inspect Accessibility Inspector/VoiceOver output and exercise Full Keyboard Access; screenshots alone are not proof.

## Deployment / Migration

- Add new UserDefaults/session-snapshot fields with versioned decoding and safe defaults.
- Decode absence of `breaksEnabled` as enabled; preserve existing roster and settings keys.
- Keep runtime snapshots isolated so rollback loses only in-flight state, never roster/settings.
- Prevent stale snapshots left by a rollback from replaying completion after a later roll-forward.
- Do not ship permission-flow or login-item changes until verified in a normally signed app on a logged-in Mac.
- Release, commit, push, and PR actions require separate authorization.
