# Manual Testing Checklist

These checks require macOS 14 or later. Build and launch with `./scripts/run.sh` or ⌘R in Xcode.
Reset or use a fresh test account when a journey depends on first-run permissions or default values.

## Core timer and settings

- [ ] A fresh profile starts with a 7-minute turn duration.
- [ ] Start begins the countdown, Pause freezes it, Resume continues it, Reset restores the
      configured duration, and the progress bar tracks the remaining time.
- [ ] The main-window duration stepper accepts 1-30 minutes.
- [ ] **Settings → General → Turn duration** accepts 1-60 minutes, and the main-window value reflects
      the saved setting even when it is above the main stepper's adjustment range.
- [ ] Notification and programming-tip settings can be enabled and disabled.
- [ ] A programming tip appears while the timer runs only when **Show Tips** is enabled.

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
- [ ] Break duration and cadence accept their Settings ranges and persist.
- [ ] **Skip Break** and Esc leave the break screen, reset break progress, and restore the turn timer.
- [ ] Skip Turn is harmless in break-due, running-break, and paused-break states and never advances roles.

## Fixed keyboard shortcuts

- [ ] ⌘↩ starts, pauses, and resumes the turn timer.
- [ ] ⌘⇧S skips a turn when at least two active people are present.
- [ ] ⌘⇧L toggles the floating timer from outside MobCrew after Accessibility access is granted.
- [ ] ⌘, opens Settings.
- [ ] Esc dismisses the in-window break screen.

## Permissions

Use a fresh macOS account or reset only MobCrew's permission in System Settings before each first-run
path. Do not disable Gatekeeper or strip quarantine attributes as part of app-level testing.

- [ ] Deny or defer Accessibility access at first launch; timer, roster, menu-bar controls, and
      floating-window controls remain usable without the global shortcut.
- [ ] Grant MobCrew access later in **System Settings → Privacy & Security → Accessibility**; ⌘⇧L
      then toggles the floating timer.
- [ ] Deny Notifications when first starting the timer; timer and break behavior continue normally.
- [ ] Grant Notifications in System Settings and enable them in MobCrew; turn-complete and break-due
      alerts are delivered once per transition.
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

## Persistence

- [ ] Quit and relaunch after changing the active order, bench, current role, turn duration, break
      cadence/duration, Notifications, and Show Tips; those values are restored.
- [ ] The current active names are written locally to
      `~/Library/Application Support/MobCrew/active-mobsters` after roster/role changes.

## Extended interactive UX checks

These checks require interactive hardware or assistive-technology coverage. Record the macOS
version, display arrangement, and assistive technology used; a missing environment is an unverified
gate, not evidence that the configuration is unsupported.

- [ ] Complete the primary timer, roster, Settings, and break journeys using only the keyboard.
- [ ] With VoiceOver, controls have meaningful names, states, and a logical traversal order.
- [ ] At increased display scaling/zoom, text remains readable and controls do not overlap or clip.
- [ ] Important text and state indicators remain distinguishable in light and dark appearances.
- [ ] Move the main and floating windows between multiple displays and disconnect/reconnect a
      display; both windows remain reachable.
- [ ] Exercise normal Spaces and another app's full-screen Space; verify and record the floating
      timer's visibility and focus behavior.

## Release qualification

Downloaded-DMG integrity, bundle version, signatures, notarization, Gatekeeper, executable
architectures, clean-Mac launch, and upgrade behavior are release-artifact checks. Follow the
[release checklist](docs/RELEASING.md) against the exact draft artifact; do not infer those results
from a local debug build.

Download qualification DMGs in a browser so macOS applies quarantine, then record
`xattr -l MobCrew-<version>.dmg` before opening it. A CLI download is not assumed to preserve this
property. Record every matrix item as exactly **tested**, **unverified**, or
**unsupported-by-explicit-decision**. In particular, unavailable hardware/OS coverage is unverified,
Developer ID signing/notarization is deferred by owner decision, and quarantined clean-Mac behavior
remains unverified until observed. The release-critical integrity, Gatekeeper first launch, core
regression, permissions, upgrade, release notes, and publication approval rows must be tested before
publication.
