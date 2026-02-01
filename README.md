# MobCrew

A native macOS mob programming timer app, inspired by [mobster](https://github.com/dillonkearns/mobster).

## Features

- Timer with configurable turn duration
- Roster management with driver/navigator rotation
- Bench inactive mobsters

## Requirements

- macOS 14.0+
- Xcode 15+

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
```

## Manual Testing

See [TESTING.md](TESTING.md) for the full checklist.

## License

MIT
