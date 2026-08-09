# MobCrew

A native macOS timer for pair, mob, and ensemble programming. MobCrew keeps the roster, current
driver and navigator, and rotation countdown visible so the team can rotate on time without
interrupting the session.

[Website](https://mobcrew.team/) ·
[View the latest release](https://github.com/colmarius/mobcrew/releases/latest) ·
[Changelog](CHANGELOG.md) ·
[Report an issue](https://github.com/colmarius/mobcrew/issues)

## Features

- **Timer** - Configurable turn duration with audio notifications
- **Roster management** - Driver/navigator rotation with identity-preserving removal and reordering
- **Bench** - Temporarily bench inactive mobsters
- **Floating timer** - Always-on-top window showing countdown
- **Optional break timer** - Enable or disable in-window Take Break / Skip Break prompts with a
  pausable countdown and completion alert
- **Global hotkey** - ⌘⇧L toggles the floating timer from anywhere
- **Menu bar** - Quick access from the menu bar
- **Auto-rotation** - Automatic driver/navigator swap when timer ends
- **Session recovery** - Running, paused, and pending-break state survives relaunch
- **Honest system status** - General settings reports Notification authorization and Launch at Login
  registration separately from MobCrew preferences
- **Accessible session controls** - Contextual VoiceOver semantics, transition announcements, keyboard
  roster ordering, and scrolling for larger active and benched rosters
- **Programming tips** - Optional mob-programming quotations while the turn timer runs

## Requirements

- macOS 14.0 or later
- Apple silicon: the current `v0.3.0` release contains an `arm64` executable only

The current release does not contain an Intel (`x86_64`) executable.

## Install and first run

1. Open the [latest release](https://github.com/colmarius/mobcrew/releases/latest) and download its
   `MobCrew-<version>.dmg` asset.
2. Open the DMG and copy **MobCrew** to **Applications**, then eject the DMG.
3. Open MobCrew from Applications.
4. If macOS blocks this known download because it cannot verify the developer, open **System
   Settings → Privacy & Security**, review the blocked-app message, and choose **Open Anyway** only
   if the app is the MobCrew release you intended to download.

Direct inspection of the browser-downloaded `v0.3.0` artifact found a structurally valid ad-hoc app
signature, no Developer ID identity or hardened runtime, an unsigned outer DMG, and no stapled
tickets. Its exact downloaded bytes and quarantined first-launch path were qualified on Apple
silicon. Because the release is not Developer ID signed or notarized, macOS may still require the
extra Privacy & Security step. Do not disable Gatekeeper or remove quarantine attributes to install
the app.

### Optional permissions

- **Notifications:** requested when the timer is first started and used for optional turn and break
  alerts. The timer continues to work if notifications are denied, and alerts can also be disabled
  in MobCrew's General settings. General settings reports the current macOS authorization state and
  links to System Settings when access was denied. If alerts are disabled in MobCrew before the first
  timer starts, the app does not request authorization.

### Privacy, updates, and support

The current app code uses no account, telemetry, or network service. Roster, settings, and current
session state are stored locally in macOS user defaults, and the active roster is also written to
MobCrew's local Application Support folder.

MobCrew does not currently update itself. To update, download a newer release and replace the copy
in Applications. For help or bug reports, use [GitHub Issues](https://github.com/colmarius/mobcrew/issues).

## Development

Development requires a Mac with the full Xcode 26.6+ application and its Swift 6.3 compiler. Xcode
is not required just to install or run a release.

Built with [Amp](https://ampcode.com) (~$60 in tokens) — see the
[development thread](https://ampcode.com/threads/T-019c1ba0-b486-75bc-887b-14ddd6684695)
for the original build history.

Open `MobCrew/MobCrew.xcodeproj` in Xcode and use ⌘B (build), ⌘R (run), or ⌘U (test), or use the
repository scripts:

```bash
# Build and run the app
./scripts/run.sh

# Run all tests or one test class
./scripts/test.sh
./scripts/test.sh RosterTests

# Serve and validate the website
./scripts/serve-docs.sh
python3 scripts/validate-docs.py
```

MobCrew itself is a macOS-only Xcode target and uses AppKit, Carbon, and ServiceManagement. Linux
environments can validate and serve the website but cannot build or run the app.

## Manual Testing

See [TESTING.md](TESTING.md) for the full checklist.

## Releasing

Finalize the matching version in [CHANGELOG.md](CHANGELOG.md), then follow the canonical
[release procedure](docs/RELEASING.md). It defines the exact toolchain, preparation, draft,
qualification, and separately authorized publication gates.

## License

[MIT](LICENSE). Inspired by [Mobster](https://github.com/dillonkearns/mobster).
