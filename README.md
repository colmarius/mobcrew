# MobCrew

A native macOS mob programming timer app, inspired by [mobster](https://github.com/dillonkearns/mobster).

Built with [Amp](https://ampcode.com) (~$60 in tokens) — see the [development thread](https://ampcode.com/threads/T-019c1ba0-b486-75bc-887b-14ddd6684695) for the full build history.

## Features

- **Timer** - Configurable turn duration with audio notifications
- **Roster management** - Driver/navigator rotation with drag-and-drop reordering
- **Bench** - Temporarily bench inactive mobsters
- **Floating timer** - Always-on-top window showing countdown
- **Break timer** - Full-screen break overlay with countdown
- **Global hotkey** - ⌘⇧M to rotate/start timer from anywhere (requires accessibility permission)
- **Menu bar** - Quick access from the menu bar
- **Auto-rotation** - Automatic driver/navigator swap when timer ends
- **Tips** - Support development via tip jar

## Known Limitations

- **Accessibility permissions reset on rebuild**: The app is currently ad-hoc signed, so macOS treats each build as a new app. You'll need to re-grant accessibility permission after rebuilding. See [code-signing-setup plan](.agents/plans/todo/code-signing-setup.md) for the fix.

## Download

Get the latest release from [GitHub Releases](https://github.com/colmarius/mobcrew/releases).

## Requirements

- macOS 14.0+
- Xcode 26.6+ (for development with the Swift 6.3 compiler)

## Development

```bash
# Build
xcodebuild -project MobCrew/MobCrew.xcodeproj -scheme MobCrew -destination 'platform=macOS' build

# Run tests
xcodebuild test -project MobCrew/MobCrew.xcodeproj -scheme MobCrew -destination 'platform=macOS'
```

Or open `MobCrew/MobCrew.xcodeproj` in Xcode and use ⌘B (build), ⌘R (run), ⌘U (test).

```bash
# Build and run
./scripts/run.sh

# Run tests
./scripts/test.sh

# Run specific test class
./scripts/test.sh RosterTests

# Serve docs locally
./scripts/serve-docs.sh
```

### Amp orbs

Fresh Linux orbs run [`.agents/setup`](.agents/setup), which validates the repository and starts
the landing page declared in [`.amp/services.yaml`](.amp/services.yaml). Run
`amp orb services ensure` to recreate the authenticated docs portal; [`.agents/resume`](.agents/resume)
checks the service again whenever an orb wakes.

MobCrew itself is a macOS-only Xcode target and uses AppKit, Carbon, and ServiceManagement. Linux
orbs cannot install Xcode, launch the app, or run Apple simulators. Build, test, and interact with
the app on a macOS Amp runner (or a local Mac) with Xcode 26.6+. The current project has no iOS target,
so running it in an iOS simulator would first require a separate iOS target and platform-specific
alternatives for the macOS APIs; the simulator would still need to run on macOS.

## Manual Testing

See [TESTING.md](TESTING.md) for the full checklist.

## Releasing

Prerequisites: `gh` CLI and Node.js 24+ (`brew install gh node && gh auth login`). The reproducible
development and CI runtime is exactly 24.19.0, selected by [`.nvmrc`](.nvmrc); local
release scripts accept compatible Node.js 24+ installations rather than rejecting newer versions.
DMGs use the repository-pinned `create-dmg` 8.1.0 release.

```bash
./scripts/release.sh <version>
```

See [docs/RELEASING.md](docs/RELEASING.md) for the full release process.

## Project Evolution

```mermaid
flowchart TB
    subgraph Phase1["Phase 1: Foundation & Research"]
        A[Agent Setup] --> B[Research]
        B --> C[PRDs & Planning]
    end

    subgraph Phase2["Phase 2: Project Scaffolding"]
        D[Xcode Project] --> E[Folder Structure]
        E --> F[Core Models]
        F --> G[Initial Tests]
    end

    subgraph Phase3["Phase 3: Core Features"]
        H[TimerEngine] --> I[FloatingTimer]
        I --> J[MenuBar UI]
        J --> K[Roster Management]
        K --> L[Persistence]
    end

    subgraph Phase4["Phase 4: Polish & Distribution"]
        M[Break System] --> N[Notifications]
        N --> O[Global Hotkeys]
        O --> P[Settings UI]
        P --> Q[Release Automation]
        Q --> R[Landing Page]
    end

    Phase1 --> Phase2
    Phase2 --> Phase3
    Phase3 --> Phase4
```

| Phase | Description |
|-------|-------------|
| **1. Foundation** | Agent setup, research (Ghostty patterns, Elm→Swift porting), PRD creation |
| **2. Scaffolding** | Xcode project, folder structure, core models (Mobster/Roster/TimerState), tests |
| **3. Core Features** | TimerEngine, FloatingTimer (NSPanel), MenuBar, RosterView, PersistenceService |
| **4. Polish** | UI improvements, breaks, notifications, global hotkeys, settings, release automation |

## License

MIT
