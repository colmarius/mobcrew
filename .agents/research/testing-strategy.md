# MobCrew Testing Strategy Research

**Date:** 2026-02-01
**Status:** Complete
**Tags:** testing, xctest, swift-testing, macos, swiftui

## Summary

Research on testing approaches for a macOS SwiftUI app. Focus on fast, valuable tests that cover core logic without simulator overhead.

---

## Test Types Comparison

| Type | Speed | Value | Simulator Required | When to Use |
|------|-------|-------|-------------------|-------------|
| **Unit Tests** | ⚡ Fast (~ms) | High | No (logic tests) | Models, services, business logic |
| **Integration Tests** | Medium (~100ms) | Medium-High | Depends | Service interactions, persistence |
| **UI Tests (XCUITest)** | 🐢 Slow (~15s+) | Medium | Yes | Critical user flows only |

## Recommendation: Logic-First Testing

For MobCrew, prioritize **unit tests** for core models and services:

### High-Value Test Targets

1. **Mobster model** - Codable encoding/decoding, Hashable
2. **Roster model** - driver/navigator rotation, add/bench/rotate operations
3. **TimerState model** - displayTime formatting, progress calculation
4. **TimerEngine** (service) - countdown logic, pause/resume
5. **PersistenceService** - save/load roster

### Low-Value (Skip Initially)

- UI layout tests (fragile, slow)
- Visual regression tests
- End-to-end flows

---

## Running Tests Without Simulator

### Option 1: Host Application = None (Recommended)

Configure test target to run without host app:

1. Select test target in Xcode
2. Build Settings → Test Host = (empty)
3. Build Settings → Bundle Loader = (empty)

This runs "logic tests" - pure Swift tests without launching the app.

**Limitation**: Cannot test AppKit/SwiftUI-dependent code.

### Option 2: macOS Platform Target

Since MobCrew is a macOS app, tests run on Mac directly without iOS simulator. This is already our situation - no simulator needed for macOS apps.

---

## Swift Testing vs XCTest

### XCTest (Traditional)

```swift
import XCTest
@testable import MobCrew

final class RosterTests: XCTestCase {
    func testDriverReturnsFirstActiveMobster() {
        let roster = Roster()
        roster.addMobster(name: "Alice")
        XCTAssertEqual(roster.driver?.name, "Alice")
    }
}
```

### Swift Testing (New in Swift 5.9+)

```swift
import Testing
@testable import MobCrew

@Suite struct RosterTests {
    @Test func driverReturnsFirstActiveMobster() {
        let roster = Roster()
        roster.addMobster(name: "Alice")
        #expect(roster.driver?.name == "Alice")
    }
}
```

**Recommendation**: Use **Swift Testing** for new tests:

- Better syntax (`#expect` vs `XCTAssert*`)
- Parameterized tests with `@Test(arguments:)`
- Parallel by default
- Works with Xcode 15.0+ (macOS 14 target is compatible)

---

## Testing @Observable Models

With `@Observable` (Observation framework), testing is straightforward:

```swift
@Test func advanceTurnRotatesDriver() {
    let roster = Roster()
    roster.addMobster(name: "Alice")
    roster.addMobster(name: "Bob")

    #expect(roster.driver?.name == "Alice")
    roster.advanceTurn()
    #expect(roster.driver?.name == "Bob")
}
```

No special handling needed - just test the public API.

---

## Testing Services with Dependencies

Use protocol-based dependency injection:

```swift
protocol TimerEngineProtocol {
    func start(duration: Int)
    func stop()
}

// In tests, use mock:
class MockTimerEngine: TimerEngineProtocol { ... }
```

---

## Folder Structure for Tests

```text
MobCrewTests/
├── Core/
│   ├── Models/
│   │   ├── MobsterTests.swift
│   │   ├── RosterTests.swift
│   │   └── TimerStateTests.swift
│   └── Services/
│       ├── TimerEngineTests.swift
│       └── PersistenceServiceTests.swift
└── Helpers/
    └── TestHelpers.swift
```

---

## Xcode Configuration for Fast Tests

### Test Plan Settings

1. Create test plan: Product → Test Plan → New Test Plan
2. Enable parallel execution
3. Disable code coverage if not needed (faster)

### Scheme Settings

Edit Scheme → Test → Options:

- ✅ Randomize execution order
- ✅ Execute in parallel

---

## Commands

```bash
# Run all tests from command line
xcodebuild test \
  -project MobCrew.xcodeproj \
  -scheme MobCrew \
  -destination 'platform=macOS'

# Run specific test class
xcodebuild test \
  -project MobCrew.xcodeproj \
  -scheme MobCrew \
  -destination 'platform=macOS' \
  -only-testing:MobCrewTests/RosterTests
```

---

## Test Coverage Goals

| Component | Coverage Target | Priority |
|-----------|-----------------|----------|
| Core/Models | 90%+ | High |
| Core/Services | 80%+ | High |
| Features/* | 50%+ | Medium |
| Helpers | As needed | Low |

---

## Action Items for PRD-000

Add to project scaffolding:

1. ✅ Include test target when creating project
2. Add `MobCrewTests/` folder structure
3. Configure test scheme for parallel execution
4. Add test file templates for core models
5. Document test commands in AGENTS.md

---

## Sources

- [Apple: Testing in Xcode](https://developer.apple.com/documentation/xcode/testing)
- [Swift Testing Framework](https://developer.apple.com/documentation/testing)
- [Swift Forums: Running unit tests without simulator](https://forums.swift.org/t/running-unit-test-without-simulator/53774)
- [SwiftUI Testing: A Pragmatic Approach](https://betterprogramming.pub/swiftui-testing-a-pragmatic-approach-aeb832107fe7)
