# Project Instructions

## Overview

**MobCrew** - Native macOS mob programming timer app, inspired by [dillonkearns/mobster](https://github.com/dillonkearns/mobster). Built with Swift/SwiftUI/AppKit.

## Tech Stack

- **Language**: Swift 6 (Swift 6.3 compiler in Xcode 26.6)
- **UI**: SwiftUI + AppKit (via `@NSApplicationDelegateAdaptor`)
- **Target**: macOS 14.0+
- **Architecture**: Feature-based folder structure

## Project Structure

```text
project/
├── AGENTS.md                    # This file - project instructions
├── README.md                    # Project overview
├── docs/                        # GitHub Pages landing page + RELEASING.md
├── scripts/                     # Build and release scripts
├── .github/workflows/           # Xcode CI + GitHub Pages deployment
├── .amp/
│   └── services.yaml            # Supervised docs preview + orb portal
├── .agents/
│   ├── setup                    # Fresh-orb prerequisite checks
│   ├── resume                   # Fast service repair after orb wake
│   ├── work/                    # Durable work items when continuity has value
│   ├── references/              # External repos (gitignored)
│   │   ├── mobster/             # Original dillonkearns/mobster clone
│   │   └── ghostty/             # Ghostty terminal app (Swift/SwiftUI patterns)
│   ├── research/                # Reusable cross-work findings
│   ├── plans/                   # Legacy implementation-plan archive
│   ├── prds/                    # Legacy product-requirements archive
│   ├── scripts/                 # dot-agents sync helpers
│   └── skills/                  # Repeatable agent workflows
└── MobCrew/                     # Xcode project
    ├── MobCrew/
    │   ├── App/                 # MobCrewApp.swift, AppDelegate.swift
    │   ├── Core/
    │   │   ├── Models/          # Mobster, Roster, TimerState
    │   │   ├── Services/        # HotkeyService, SoundService, etc.
    │   │   └── AppState.swift   # Global app state
    │   ├── Features/            # Feature-based UI modules
    │   │   ├── Break/           # Break timer overlay
    │   │   ├── FloatingTimer/   # Always-on-top timer window
    │   │   ├── MenuBar/         # Menu bar extra UI
    │   │   ├── Roster/          # Mobster list management
    │   │   ├── Settings/        # Preferences window
    │   │   └── Tips/            # Tip jar / support
    │   ├── Helpers/
    │   │   └── Extensions/      # Swift extensions
    │   ├── Resources/           # Assets, strings
    │   ├── ContentView.swift    # Main content view
    │   └── MobCrew.entitlements # App entitlements
    ├── MobCrew.xcodeproj/
    └── MobCrewTests/            # Unit tests (mirrors main structure)
```

## Agent Work

- Keep small, self-contained planning and implementation in the current conversation.
- Create a durable work item under `.agents/work/<category>/<slug>/` when resumption,
  coordination, handoff, auditability, durable decisions, or an explicit request makes repository
  context useful.
- Use the `agent-work` skill for durable requirements, planning, refinement, execution, and optional
  handoffs. Follow `.agents/work/AGENTS.md` for status, artifact, evidence, and closeout rules.
- Keep task-specific research in its work item. Use `.agents/research/` only for reusable findings.
- Implement in the current thread by default. Handoffs are optional and should be persisted only when
  reuse or durable transition context justifies them.
- On completion, promote reusable outcomes, commit the final completed work-item snapshot, then use
  `close-work.sh` to stage its removal. Git history is the archive.
- Existing `.agents/plans/` and `.agents/prds/` files are legacy project records; do not use their old
  lifecycle for new work.

## Commands

MobCrew is a macOS-only Xcode target. Run app builds, tests, and UI checks on a macOS Amp runner
or local Mac with Xcode 26.6+. Debian orbs cannot run Xcode or Apple simulators; the project does not
currently define an iOS target.

```bash
# Build
xcodebuild -project MobCrew/MobCrew.xcodeproj -scheme MobCrew -destination 'platform=macOS' build

# Run tests (fast, no simulator for macOS)
xcodebuild test -project MobCrew/MobCrew.xcodeproj -scheme MobCrew -destination 'platform=macOS'

# Run specific test class
xcodebuild test -project MobCrew/MobCrew.xcodeproj -scheme MobCrew -destination 'platform=macOS' -only-testing:MobCrewTests/RosterTests

# In Xcode: ⌘B (build), ⌘R (run), ⌘U (test)

# Build and run
./scripts/run.sh

# Run tests
./scripts/test.sh

# Run specific test class
./scripts/test.sh RosterTests

# Build release app (outputs to build/Release/MobCrew.app)
./scripts/build-release.sh [version]

# Create DMG package (outputs to build/MobCrew-<version>.dmg)
./scripts/create-dmg.sh <version>

# Full release: build + DMG + GitHub release + upload
# Prerequisites: brew install gh node && gh auth login
./scripts/release.sh <version> [--draft]

# Serve docs locally
./scripts/serve-docs.sh

# In an Amp orb: start/reconcile the supervised docs preview and portal
amp orb services ensure
```

## Git Workflow

```bash
git status
git add -A
git commit -m "Description of changes"
git push
```

### Commit Guidelines

- Write clear, descriptive commit messages
- Reference the durable work-item slug when one exists
- Commit after each logical step

## Maintenance

After making changes:

1. **Update AGENTS.md** - Keep project structure and commands current
2. **Update README.md** - Reflect user-facing changes
3. **Update durable context when used** - Keep the work-item index, plan, and evidence aligned with
   `.agents/work/AGENTS.md`
