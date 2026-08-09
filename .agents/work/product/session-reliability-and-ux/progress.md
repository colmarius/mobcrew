# Session Reliability and UX Execution Progress

Updated: 2026-08-09

## Current Slice

- Tasks 1-8 are implemented, natively tested, checked off in the active plan, and pushed.
- Task 9 implementation has core surfaces with contextual semantics,
  roster reordering has keyboard/VoiceOver actions, one native List owns active and benched scrolling,
  and injected announcements cover only meaningful session transitions. Xcode tests and initial native
  AX inspection pass. User inspection found the main panes did not consume expanded window space; the
  pushed responsive correction now passes native geometry, splitter, AX, and increased-text checks.
  Interactive VoiceOver, Full Keyboard Access, and display-option checks remain.
- Task 10's final documentation-truth audit is implemented, but its phase gate remains open until Task 9
  completes and the latest exact branch passes the full native suite/manual result reconciliation.

## Observed Evidence

- Branch `audit/session-reliability-work-item` starts at
  `b81ae36342d715d5c1bac52fb4a9ee29fcfac6be`; its merge base is current `origin/main` at
  `50659f0fc5b5d5ed1b5f5452ad4cbc8c24e6c5c2`.
- Baseline inspection reconfirmed that `isOnBreak` and `TimerState.isRunning` can diverge,
  `TimerType` is unused, menu Skip always routes to `skipTurn()`, and tests use the shared
  notification service plus real-time sleeps.
- Oracle review confirmed AppState as the correct phase owner, required phase-before-engine
  transition ordering and stale-publisher guards, and preserved manual Skip auto-start while
  natural completion stops for handoff.
- Task 1 implementation now routes every main-window, menu-bar, floating-panel, and break-screen
  session action through phase-guarded AppState commands. A synchronous engine tick seam covers
  the six phases × roster sizes 0/1/2 × seven commands without real sleeps or shared notifications.
- `python3 scripts/validate-docs.py` passed after reconciling README, landing-page, and manual-check
  language with the new break-due and Start/Pause/Resume behavior. `git diff --check` also passed.
- No live Mac runner was connected when checked after the Task 1 push, so no Xcode result has been
  inferred. Independent Task 2 implementation proceeded without changing the unverified Task 1 contract.
- Task 2 source inspection confirms all production active/inactive collection and driver-index
  writes now live inside `Roster`; `RosterView` permanent removal uses model-owned operations.
- The Mac runner protected an unrelated dirty checkout by testing in `/tmp/mobcrew-session-native-verify`
  from exact pushed commit `41119581cf31f849e5c9669850fdc198df44971b`.
- The first focused compile exposed a Swift 6 actor-isolation mismatch in the injected active-roster
  writer. Commit `ac2c6a51cb378cf8600cec9ad2040220a11c7019` isolated the protocol and its service tests to
  `@MainActor`; no product behavior changed.
- Focused `xcodebuild test` passed 87/87 across `AppStateTests`, `BreakLogicTests`,
  `TimerEngineTests`, `NotificationServiceTests`, `RosterTests`, and `PersistenceServiceTests`.
- Full `xcodebuild test -project MobCrew/MobCrew.xcodeproj -scheme MobCrew -destination 'platform=macOS'`
  passed 107/107 with 0 failures and 0 skips, including app/test build, link, and signing.
- Task 3 Linux inspection found no remaining production or test assignment to the now read-only
  configured duration outside AppState initialization/operation. Documentation validation passed
  after reconciling the shared range and lifecycle semantics in `TESTING.md`.
- Task 3 verification used detached temporary worktree `/tmp/mobcrew-task3-ZMAL5S` at exact commit
  `83e5e53e6b902ca2cc0bb04cd46a133eeda07de9`; the user's original checkout and untracked bundles
  remained unchanged, and the temporary worktree was removed after use.
- Focused Task 3 `xcodebuild test` passed 34/34 across `AppStateTests`, `TimerStateTests`, and
  `BreakLogicTests`. The full macOS suite passed 113/113 with 0 failures and 0 skips. No fix commit
  or temporary branch was needed.
- Task 4 tests now inject monotonic and wall clocks and cover delayed refresh, sleep-like jumps,
  sub-second `ceil` boundaries, exact fractional pause/resume, reset, restored wall deadlines, and
  exactly-once completion without real sleeps. AppState/break regressions cover pause at the exact
  regular or break deadline so completion cannot strand a paused `00:00` session.
- The engine keeps exact remaining duration privately, exposes only rounded UI state, and converts a
  validated restored wall-clock remainder once into a fresh monotonic deadline. Publisher arming is
  separate from restore establishment for Task 6 recovery ordering.
- Task 4 verification used a detached temporary Mac worktree at exact pushed commit `21401c78c8adb43962df05251fada5891b3a0e2d`.
  The initial focused run compiled and passed 52 tests but exposed one test-fixture precision failure:
  binary-inexact `1.2 - 0.2` correctly remained just above one second under exact `ceil` semantics.
- Commit `c6fb95d96b48ce77ad6f641b188b9773af676fb1` changed only that test to exactly
  representable `1.25`/`0.25` inputs. The focused `TimerEngineTests`, `AppStateTests`,
  `BreakLogicTests`, and `TimerStateTests` gate then passed 53/53 with 0 failures or skips.
- The full macOS suite passed 118/118 with 0 failures or skips. The disposable worktree was clean and
  removed; the user's primary checkout and its two unrelated untracked bundles remained unchanged.
  No temporary local or remote branch was created.
- Oracle review for Task 5 resolved disabled-state integration: a pending `breakDue` clears to regular
  idle, while an explicitly accepted running or paused break remains controllable. Disabling resets
  cadence and every disabled regular completion keeps it at zero; re-enable performs no immediate check.
- Task 5 tests cover missing-key enabled behavior, true/false persistence, initially disabled cadence,
  reset across disable/re-enable, regular and accepted-break preservation, due clearing, lifecycle
  transitions, completion cue idempotence, and the existing Notifications preference.
- Main and floating cadence indicators now hide when disabled; Settings keeps break configuration
  visible but disabled beneath an `Enable Breaks` toggle. Break completion returns through the
  authoritative regular-idle transition before sending one fixed local notification.
- Task 5 verification used detached temporary worktree `/tmp/mobcrew-task5-audit-8c2fd33` at exact
  commit `8c2fd3385e3e55fd7c0e6e4590f73f4bdf5e8b58`. Focused `BreakLogicTests`,
  `AppStateTests`, `PersistenceServiceTests`, and `NotificationServiceTests` passed 53/53 with no
  failures or skips; all 128 project tests passed with no failures or skips.
- Task 5 required no fixes. `git diff --check` and documentation validation passed. The disposable
  worktree and temporary logs were removed; the user's primary checkout and unrelated bundles were
  preserved exactly, and no temporary local or remote branch was created.
- Oracle review for Task 6 rejected driver identity alone as a recovery anchor. The implementation
  instead stores a regular-cycle UUID in the session snapshot and atomically stores its completed or
  skipped resolution receipt in the roster blob; recovery writes roster/receipt before session state.
- Session snapshot V1 stores the six-case phase, cycle UUID, cycle total, exact frozen remainder or
  running wall deadline, and break cadence. Running restoration converts wall time once to a fresh
  monotonic deadline, persists recovered state, and only then arms refresh delivery.
- Missing, corrupt, structurally impossible, and out-of-range current snapshots normalize to fresh
  regular idle without clearing valid roster/settings. Unknown newer snapshot bytes remain untouched
  by all writes from the older process while ordinary roster/settings persistence continues.
- Recovery tests cover future and expired deadlines, paused/due states, zero/one/multiple and edited
  rosters, repeated construction, interrupted roster/session ordering, write failure, break completion,
  malformed payloads, lifecycle flushes, and publisher-arm ordering; the focused native gate below passed.
- Rollback is intentionally documented without an impossible guarantee: a snapshot-unaware binary
  that changes session state but writes no compatibility marker cannot later be distinguished from a
  crash. Snapshot isolation still ensures rollback does not corrupt existing roster/settings.
- Oracle review of the Task 6 diff found two recovery blockers before checkpoint: later session-only
  writes could bypass a failed roster write, and matching receipts could bypass the running deadline's
  remaining-over-total validation. Pending roster durability now gates every snapshot write, and all
  running snapshots are clock-validated before receipt reconciliation; focused failure tests cover both.
- Task 6 verification used detached Mac worktree `/tmp/mobcrew-task6-verify.Tt8j8e` at exact pushed
  commit `5ec4714db97dda7d3ccb785f6a7b16b911c7fda9`. The initial focused compile found two test
  attributes missing function declarations; test-only commit `7730b224979aa2e1a98ba5859129db5846578908`
  supplied those declarations and changed no production behavior.
- Focused `AppStateTests`, `PersistenceServiceTests`, `TimerEngineTests`, `RosterTests`,
  `BreakLogicTests`, and `ActiveMobstersFileServiceTests` then passed 134/134 with no failures or
  skips. The full macOS suite passed 155/155 with no failures or skips; `git diff --check` passed.
- The Task 6 disposable worktree and logs were removed. The user's primary checkout and unrelated
  untracked bundles were preserved, and remote heads remained only the authorized audit branch and
  `main`; no temporary branch was created.
- Task 7's temporary ad-hoc-signed receiver on macOS 26.5.2 reported `AXIsProcessTrusted=false`,
  registered key code 37 with `cmdKey | shiftKey` at Carbon status `0`, and received one
  `kEventHotKeyPressed` callback from an already-authorized noninteractive sender. Same-process
  duplicate registration returned `-9878` (`eventHotKeyExistsErr`), distinct from TCC denial.
- The selected implementation removes launch-time AX prompting/imports/polling, publishes Carbon
  registration state, shows Active or the actual error plus Try Again in Shortcuts settings, and uses
  one Swift definition for key code, modifiers, display chord, and toggle action. README, testing,
  release guidance, and landing-page claims now match; the static docs check enforces that agreement.
- The Task 7 empirical probe changed no TCC or user setting, removed all temporary artifacts, preserved
  the user's primary checkout and bundles, and created no local or remote branch. A physical keypress
  remains unverified; the owner accepted current macOS coverage without an older-version follow-up.
- Task 7 native verification used Xcode 26.6 (17F113), Swift 6.3, and an ad-hoc-signed Debug app from
  exact commit `3575cdf6916d93c0e6efe224304ce2c6a04f19f5`. The initial focused compile found that Carbon's
  `eventHotKeyExistsErr` imported as `Int`; test-only commit
  `d5e5ba34b872ed21cb3754cfc2f2f3c8d36fcc38` added the explicit `OSStatus` conversion.
- Focused `GlobalHotkeyServiceTests` passed 2/2, and the full Xcode 26.6 suite passed 156/156 with no
  failures or skips. Static docs validation and `git diff --check` also passed.
- Live AX inspection found no Accessibility dialog; Shortcuts settings showed ⌘⇧L, Toggle floating
  timer, and Active. An already-authorized sender posted the exact chord twice, and the real floating
  panel changed onscreen → hidden → onscreen. App-specific TCC denial, a physical keypress, and safely
  induced registration-failure UI remain unverified; older-version repetition is not required.
- The Task 7 disposable worktree, app, DerivedData, helpers, logs, and processes were removed. The
  user's primary checkout and bundles remained unchanged, and no temporary branch was created.
- Task 8 source reinspection confirmed that the prior notification service inferred permission from
  an in-memory request flag and Launch at Login collapsed all `SMAppService.Status` values to a Boolean.
  Apple framework documentation confirms `getNotificationSettings` and `SMAppService.status` are the
  runtime sources of truth and lists five authorization and four launch-registration states.
- Task 8 now refreshes actual notification status before deciding whether to request, so disabled AppState
  preference never calls the authorization path and known denied/authorized/provisional/ephemeral states
  are not requested again. Settings displays all five states and links denied recovery to System Settings.
- Launch at Login now publishes the exact framework status through an injected system-service seam. Every
  register/unregister attempt rereads status even after a throw; Settings therefore reverts or qualifies
  the toggle from reality, shows transient errors, and links approval/unavailable recovery to Login Items.
- Deterministic tests cover all framework statuses, notification preference separation, authorization
  request gating and recovery, registration/unregistration status refresh, thrown operation feedback,
  external status changes, and injected System Settings actions.
- Task 8 exact-toolchain verification used Xcode 26.6 (17F113), Swift 6.3.3, Swift language mode 6,
  and a detached Mac worktree at pushed commit `787fcb140835513a485849238957a7be83393ba3`.
  The first focused compile found that the injected Notification settings closure had lost MainActor
  isolation and that direct `.ephemeral` source references are unavailable on macOS.
- Fix commit `fea58aef584f038ef57f33934e9f4a98b558aa44` changed only the closure annotation and
  represented authorization raw value 4 in tests. Focused Task 8 tests then passed 54/54 executed
  cases (51 logical tests), and the full suite passed 169/169 executed cases (166 logical tests), with
  no failures, skips, or expected failures. `git diff --check` passed.
- Read-only live Settings inspection observed Notification authorization **Denied in System Settings**
  while MobCrew's **Show notifications** preference remained on, and Launch at Login status
  **Unavailable for this app** with its toggle off and disabled. **Open Settings** and **Open Login
  Items** recovery controls were present and enabled; all General controls fit at 500×390 content size.
- No TCC, Notification, Login Item, or other shared system state was reset to force alternate states.
  Native `.requiresApproval`, register/unregister, operation-alert presentation, recovery destinations,
  and alternate notification states remain represented by deterministic injected-double tests rather
  than live mutation. The detached worktree and temporary files were removed, no temporary branch was
  created, and remote heads remained only `main` and the authorized audit branch.
- Task 9 source inspection reconfirmed that active List scrolling was disabled, benched rows sat outside
  any scroll container, row actions were generic icons, role badges exposed only D/N with reversed colors,
  duration accessibility grouping risked hiding native Stepper behavior, and no transition announcer existed.
- The implementation uses one native List with Active and Benched sections, preserving drag reorder while
  adding stable-UUID Move Up/Down buttons and named accessibility actions. The model allows only adjacent
  moves, preserves the current Driver UUID, recomputes Navigator relative to that Driver, and persists via
  the existing model-owned mutation handler.
- Driver/Navigator words are visible in roster badges and remain in participant semantics; all core timer,
  reset, skip, break, participant, menu, and floating controls now have contextual labels, values, hints,
  and role context. Driver remains blue and Navigator green across the main, roster, and floating surfaces.
- AppState posts macOS 14+ `AccessibilityNotification.Announcement` through one injected MainActor closure.
  Natural handoff, break due, break complete, and manual turn skip each emit one contextual message; ordinary
  ticks, manual break skip, and restoration reconciliation emit none. Deterministic tests cover these paths,
  readable timer state, and move invariants. Logged-in accessibility checks remain open.
- Task 9 native tests used Xcode 26.6 (17F113), Swift 6.3.3, Swift language mode 6, and a detached
  worktree at exact pushed commit `69132db345a10d8063ac8834c05377d89d708e4f`. Focused
  `AppStateTests` and `RosterTests` passed 85/85; the full suite passed 177/177 executed cases
  (174 logical tests), with no failures, skips, or expected failures. No fix commit was required.
- The native UI pass did not launch an app or claim visual/AX behavior. Its temporary isolated harness
  patch hit an executor lease-acknowledgement timeout and post-error inspection proved no patch applied.
  The agent stopped rather than retrying against real MobCrew data. The detached worktree stayed clean,
  was removed with all logs/DerivedData, and no preferences, roster/session data, active-roster file,
  accessibility setting, temporary branch, or remote ref changed.
- A second native pass successfully built a disposable uncommitted `MobCrewApp` launch-argument harness
  at exact commit `d612b5283669492a195d5e0b87226b794bee67c2`. It injected a unique UserDefaults
  suite and temporary active-roster path, seeded 12 active plus 8 benched long-name participants, and
  left production construction unchanged. The real defaults checksum and active-roster state matched
  before/after; the harness, suite, files, app, DerivedData, logs, and worktree were removed.
- The isolated app rendered a 600×450 content area (600×482 outer window). One AX outline contained the
  first through twelfth active participants and first through eighth benched participants. AX exposed
  Driver/Navigator and active/benched context, person-specific Move/Bench/Activate/Remove controls,
  conditional named Move actions, disabled first-row Move Up, enabled Move Down, contextual timer/control
  hints, and a native duration Stepper with `AXIncrement` and `AXDecrement`.
- Harness stdout observed exactly one manual-skip handoff and one break-due announcement, with no tick
  announcements. After the initial successful inspection, the runner's MobCrew AX windows exposed no
  descendants and screen capture failed, so it did not claim end-to-end scrolling, native Move activation,
  break-complete output, spoken VoiceOver behavior, Full Keyboard Access, colors, contrast/differentiation,
  or increased-text layout. Global accessibility settings remained unchanged.
- Remaining Task 9 acceptance is interactive user-assisted validation on the current Mac: activate
  Move Down/Up using spoken VoiceOver and Full Keyboard Access, complete the short break, and inspect
  Increase Contrast plus Differentiate Without Color. Current macOS 26.5.2 coverage is sufficient;
  no older-version repetition remains.
- Manual inspection of the retained isolated harness found an expanded main window still presented
  fixed-width content. The harness itself fixed the SwiftUI root at 600×450 rather than only setting the
  initial NSWindow size; production also capped the timer pane at 300 points and allowed the roster to
  keep an intrinsic width, leaving space unused while long names wrapped or truncated. Task 9 remains open.
- The correction removes the timer-pane maximum, gives both split panes and the single native List
  flexible width/height, and raises the minimum main content size to the acceptance baseline of
  600×450. Linux `git diff --check` and documentation validation pass.
- After reconnection, exact pushed commit `5b0e88937efdd71ed8c6741dc3dea122a00142fa`
  passed 85/85 focused `AppStateTests` and `RosterTests` using Xcode 26.6 (17F113), Swift 6.3.3,
  and Swift language mode 6. The isolated harness changed only launch-gated construction and preserved
  production `ContentView`/`RosterView` source exactly.
- At 600×450 content, the split panes measured 299/300 points and the roster outline 268×378. At
  1000×700 they measured 499/500 and 468×628, proving both hosted content and the single List consumed
  added width/height. A real splitter drag changed panes to 579/420 and the outline to 388 points wide.
- Complete minimum and expanded AX snapshots placed all 20 long-name participants and 64 person-specific
  actions under one roster outline. Increased-text checks retained all main controls, 22 outline rows,
  and all actions in bounds at both sizes; the 180×160 floating panel retained in-bounds AX children,
  with expected long-name ellipsis deferred to non-blocking Task 11 observation.
- AXPress on Skip produced one contextual handoff announcement. The user-inspected expanded screenshot
  shows both panes/List filling the window, readable long main-window names, and no visible overlap.
  The replacement harness now uses a valid one-minute turn seed, only sets the initial NSWindow content
  size, and remains open for interactive assistive-technology/display checks.
- Task 10 source/docs comparison found four residual wording defects: the Settings shortcut omitted
  Resume, Tips wording did not distinguish the turn timer, “Rotate and recover” omitted relaunch
  recovery, and the local-data answer omitted the session snapshot. The smallest text-only corrections
  now match implemented behavior; docs validation and the full native branch gate follow.

## Verification Status

- Tasks 1-2 passed their focused and full native test gates on macOS using Xcode 26.2 (build 17C52).
- Task 3 passed focused and full-suite regression coverage on the same Xcode 26.2 runner.
- Task 4 passed 53 focused and all 118 project tests on the same Xcode 26.2 runner, including Swift 6
  compilation of the actor-isolated Combine publisher path.
- Task 5 passed 53 focused and all 128 project tests on the same Xcode 26.2 runner, including Swift 6
  compilation of its AppState, notification protocol, persistence, Settings, and conditional cadence UI.
- Task 6 passed 134 focused and all 155 project tests on the same Xcode 26.2 runner, including Swift 6
  compilation of versioned Codable snapshots, actor-isolated roster persistence, recovery ordering,
  restored Combine publisher arming, and deterministic failure reconciliation.
- Task 7 passed 2 focused and all 156 project tests using the required Xcode 26.6 / Swift 6.3 toolchain,
  providing cumulative exact-toolchain compilation and regression coverage for Tasks 1-7.
- Task 8 passed 54 focused and all 169 executed project test cases using Xcode 26.6 / Swift 6.3.3;
  live Settings inspection also confirmed independent actual/preference status and unclipped recovery UI.
- Task 9 passed 85 focused and all 177 executed project test cases using Xcode 26.6 / Swift 6.3.3.
  The responsive follow-up also passed 85/85 focused tests and logged-in native geometry/AX/increased-text
  checks; interactive VoiceOver, Full Keyboard Access, and display-option acceptance awaits user assistance.
