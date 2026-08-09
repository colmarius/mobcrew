# Session Reliability and UX Execution Progress

Updated: 2026-08-09

## Current Slice

- Tasks 1-6 are implemented, natively tested, checked off in the active plan, and pushed.
- Task 7 is next: establish on the logged-in Mac whether the Carbon global hotkey actually requires
  Accessibility permission, then preserve or remove the permission flow based on observed evidence.

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
- The project specifies Xcode 26.6+ / Swift 6.3, so the exact-toolchain rerun remains unverified and
  must be repeated before final qualification. No manual UI or accessibility behavior was claimed.
