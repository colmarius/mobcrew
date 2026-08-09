# Manual Testing Checklist

These checks require macOS 14 or later. Build and launch with `./scripts/run.sh` or ⌘R in Xcode.
Reset or use a fresh test account when a journey depends on first-run permissions or default values.

## Core timer and settings

- [ ] A fresh profile starts with a 7-minute turn duration.
- [ ] Start begins the countdown, Pause freezes it, Resume continues it, Reset restores the
      configured duration, and the progress bar tracks the remaining time.
- [ ] The main-window and **Settings → General → Turn duration** steppers both accept 1-60 minutes
      and remain synchronized.
- [ ] Changing duration while idle updates the displayed countdown immediately; changing it while
      running or paused preserves current progress and applies to the next turn.
- [ ] Reset applies the configured duration and returns the turn timer to idle; duration changes
      never alter a due, running, or paused break countdown.
- [ ] Notification and programming-tip settings can be enabled and disabled.
- [ ] A programming tip appears while the turn timer runs only when **Show Tips** is enabled.

## Roster and role states

- [ ] Add, remove, reorder, and shuffle active mobsters.
- [ ] Bench an active mobster and rotate a benched mobster back into the active roster.
- [ ] With zero active people, neither Driver nor Navigator is shown, Start and Skip Turn are
      disabled, and Pause/Reset remain available if the roster became empty during a turn.
- [ ] With one active person, only Driver is shown and Skip remains disabled.
- [ ] With two active people, Driver and Navigator are distinct and swap after a turn.
- [ ] With three or more active people, repeated turns advance through the roster and wrap in order.
- [ ] Removing or benching someone before or after the current driver preserves that driver's identity.
- [ ] Removing or benching the current driver selects the next active person, wrapping safely at the end.
- [ ] Drag reordering preserves the current driver; Shuffle deliberately makes the shuffled first
      person the driver; restoring a benched person preserves the existing driver.

## Rotation and breaks

- [ ] Skip advances the roles, resets the turn timer, and starts the next turn.
- [ ] Timer completion advances roles only with at least two active people; it offers a break when
      one is due, otherwise it resets to the configured turn duration and remains idle.
- [ ] After the configured number of turns, the break screen replaces content inside the main
      window and offers **Take Break** / **Skip Break** without starting the countdown.
- [ ] Take Break starts the prepared countdown; Pause Break freezes it and Resume Break continues it.
- [ ] **Enable Breaks** defaults on; disabling it clears a pending break prompt, hides cadence dots,
      and prevents completed turns from accumulating break cadence.
- [ ] Re-enabling breaks starts cadence again from zero and does not immediately offer a surprise break.
- [ ] Disabling breaks during an accepted running or paused break preserves that break and its controls.
- [ ] Break duration, cadence, and enabled state accept their Settings controls and persist.
- [ ] A naturally completed break returns to regular idle and sends one **Break Complete** alert when
      Notifications are enabled; Skip Break and clearing a pending prompt do not send that alert.
- [ ] **Skip Break** and Esc leave the break screen, reset break progress, and restore the turn timer.
- [ ] Skip Turn is harmless in break-due, running-break, and paused-break states and never advances roles.

## Fixed keyboard shortcuts

- [ ] ⌘↩ starts, pauses, and resumes the turn timer.
- [ ] ⌘⇧S skips a turn when at least two active people are present.
- [ ] ⌘⇧L toggles the floating timer from outside MobCrew without Accessibility access.
- [ ] ⌘, opens Settings.
- [ ] Esc dismisses the in-window break screen.

## Permissions

Use a fresh macOS account or reset only the permission under test before each first-run path. Do not
disable Gatekeeper or strip quarantine attributes as part of app-level testing.

- [ ] Launch with MobCrew absent from or disabled in **Privacy & Security → Accessibility**; no
      Accessibility prompt appears, and ⌘⇧L still toggles the floating timer from another app.
- [ ] **Settings → Shortcuts** reports the global shortcut as Active. If registration fails, it shows
      the Carbon error and **Try Again** instead of claiming an Accessibility problem.
- [ ] Deny Notifications when first starting the timer; timer and break behavior continue normally.
- [ ] Before the first request, General settings reports Notifications as **Not requested**. After
      deny/allow changes it reports the current macOS state; denied status offers **Open Settings**.
- [ ] With Notifications disabled in MobCrew before starting a timer, no authorization prompt appears.
- [ ] Grant Notifications in System Settings and enable them in MobCrew; turn-complete, break-due,
      and break-complete alerts are delivered once per transition.
- [ ] Disable Notifications in MobCrew; no new turn or break alert is sent.

## Floating window, menu bar, and launch at login

- [ ] The floating timer appears on launch with the current countdown, Driver, and Navigator.
- [ ] Its Start/Pause/Resume control changes the same timer as the main window, and its break state
      offers phase-aware Take/Pause/Resume and Skip Break controls.
- [ ] It remains above normal windows, can be moved, and follows the app across Spaces as intended.
- [ ] The menu-bar item shows current roles; Start/Pause/Resume, phase-aware Skip Turn/Skip Break,
      and Settings act on the same app state.
- [ ] Enabling **Launch at Login** registers MobCrew; after logging out and back in, MobCrew starts.
- [ ] Disabling **Launch at Login** unregisters it and the next login does not start MobCrew.
- [ ] General settings reports Launch at Login as **Not registered**, **Enabled**, **Requires approval
      in System Settings**, or **Unavailable for this app** according to the observed macOS status.
      Approval/unavailable states offer **Open Login Items**; a failed change shows an error and the
      toggle continues to reflect the refreshed status rather than the requested value.

## Persistence

- [ ] Quit and relaunch after changing the active order, bench, current role, turn duration, break
      enabled state/cadence/duration, Notifications, and Show Tips; those values are restored.
- [ ] Start a turn, put the Mac to sleep until after its deadline, and wake it without relaunching;
      the cycle completes once, advances roles only when allowed, enters regular idle or break due,
      and does not advance roles or break cadence again after further refreshes.
- [ ] Quit during a running turn, wait briefly, and relaunch; the same cycle resumes with elapsed
      wall time deducted. Quit long enough for its deadline to pass; relaunch completes that cycle
      once, advances roles only when allowed, and does not repeat the advance on another relaunch.
- [ ] Quit during a paused turn or paused break; relaunch restores the exact displayed remainder
      without auto-starting or deducting time spent away.
- [ ] Quit while a break is due; relaunch restores **Take Break** / **Skip Break** without starting it.
- [ ] Quit during a running break long enough for its deadline to pass; relaunch returns to regular
      idle, resets cadence, does not rotate roles, and sends at most one enabled completion alert.
- [ ] The current active names are written locally to
      `~/Library/Application Support/MobCrew/active-mobsters` after roster/role changes.

## Extended interactive UX checks

These checks require interactive hardware or assistive-technology coverage. Record the macOS
version, display arrangement, and assistive technology used; a missing environment is an unverified
gate, not evidence that the configuration is unsupported.

- [ ] Complete the primary timer, roster, Settings, and break journeys using only the keyboard.
- [ ] At exactly 600×450 with at least 12 active and 8 benched participants, scroll to every row by
      mouse, keyboard, and VoiceOver; moving a row does not change the current Driver's identity.
- [ ] Resize that window wider and taller; both split panes and the roster List fill the available
      space, long participant names gain usable width, and all controls remain reachable.
- [ ] With Full Keyboard Access, activate participant Move Up/Down, bench/activate, and remove controls;
      with VoiceOver, verify person-specific labels and named Move Up/Down actions.
- [ ] With VoiceOver, timer, reset, skip, break progress, role, menu, and floating controls expose
      contextual names, values, hints, and a logical traversal order. The duration Stepper remains adjustable.
- [ ] With VoiceOver running, a Driver handoff, break due, and break completion each announce once;
      ordinary countdown ticks and restoration do not announce.
- [ ] With increased text size/display scaling, all names and action controls remain reachable without
      overlap or clipping, including the narrow roster pane and floating panel.
- [ ] Under Increase Contrast and Differentiate Without Color, Driver and Navigator remain distinguishable
      by visible words and consistent blue/green role semantics across main, roster, and floating surfaces.
- [ ] Important text and state indicators remain distinguishable in light and dark appearances.
- [ ] Move the main and floating windows between multiple displays and disconnect/reconnect a
      display; both windows remain reachable.
- [ ] Exercise normal Spaces and another app's full-screen Space; verify and record the floating
      timer's visibility and focus behavior.

## Release qualification

Use this file for the app-level core regression, permission, persistence, and interactive journeys.
Follow the canonical [release procedure](docs/RELEASING.md) for exact-draft integrity, quarantine,
signing, architecture, clean-Mac launch, upgrade, evidence, and publication gates. Never infer
release-artifact results from a local debug build.
