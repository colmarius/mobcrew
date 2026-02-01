# MobCrew

A native macOS mob programming timer app, inspired by [mobster](https://github.com/dillonkearns/mobster).

## Features

- Timer with configurable turn duration
- Roster management with driver/navigator rotation
- Bench inactive mobsters

## Download

Get the latest release from [GitHub Releases](https://github.com/colmarius/mobcrew/releases).

## Requirements

- macOS 14.0+
- Xcode 15+ (for development)

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

## Manual Testing

See [TESTING.md](TESTING.md) for the full checklist.

## Releasing

Prerequisites: `gh` CLI and Node.js (`brew install gh node && gh auth login`)

```bash
./scripts/release.sh <version>
```

See [docs/RELEASING.md](docs/RELEASING.md) for the full release process.

## License

MIT
