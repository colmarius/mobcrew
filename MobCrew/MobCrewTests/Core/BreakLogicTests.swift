import Testing
import Foundation
@testable import MobCrew

@Suite("Break Logic Tests")
struct BreakLogicTests {

    private func makeTestUserDefaults() -> UserDefaults {
        let suiteName = "com.mobcrew.tests.\(UUID().uuidString)"
        return UserDefaults(suiteName: suiteName)!
    }

    private func makeAppState(breakInterval: Int = 5, breakDuration: Int = 300) -> AppState {
        let defaults = makeTestUserDefaults()
        let persistenceService = PersistenceService(userDefaults: defaults)
        let appState = AppState(persistenceService: persistenceService)
        appState.breakInterval = breakInterval
        appState.breakDuration = breakDuration
        return appState
    }

    // MARK: - Turn Counter Tests

    @Test("turnsSinceBreak increments when turn advances")
    func turnsSinceBreakIncrements() async throws {
        let appState = makeAppState(breakInterval: 10)
        appState.roster.addMobster(name: "Alice")
        appState.roster.addMobster(name: "Bob")

        #expect(appState.turnsSinceBreak == 0)

        appState.timerEngine.reset(duration: 1)
        appState.timerEngine.start()

        try await Task.sleep(for: .milliseconds(1500))

        #expect(appState.turnsSinceBreak == 1)
    }

    @Test("turnsSinceBreak accumulates across multiple turns")
    func turnsSinceBreakAccumulates() async throws {
        let appState = makeAppState(breakInterval: 10)
        appState.roster.addMobster(name: "Alice")
        appState.roster.addMobster(name: "Bob")

        for _ in 1...3 {
            appState.timerEngine.reset(duration: 1)
            appState.timerEngine.start()
            try await Task.sleep(for: .milliseconds(1500))
        }

        #expect(appState.turnsSinceBreak == 3)
    }

    // MARK: - Break Trigger Tests

    @Test("break triggers at correct interval")
    func breakTriggersAtInterval() async throws {
        let appState = makeAppState(breakInterval: 2, breakDuration: 60)
        appState.roster.addMobster(name: "Alice")
        appState.roster.addMobster(name: "Bob")

        #expect(appState.isOnBreak == false)

        appState.timerEngine.reset(duration: 1)
        appState.timerEngine.start()
        try await Task.sleep(for: .milliseconds(1500))

        #expect(appState.isOnBreak == false)
        #expect(appState.turnsSinceBreak == 1)

        appState.timerEngine.reset(duration: 1)
        appState.timerEngine.start()
        try await Task.sleep(for: .milliseconds(1500))

        #expect(appState.isOnBreak == true)
        #expect(appState.turnsSinceBreak == 2)

        appState.timerEngine.stop()
    }

    @Test("break sets breakSecondsRemaining to breakDuration")
    func breakSetsSecondsRemaining() {
        let appState = makeAppState(breakInterval: 1, breakDuration: 180)

        appState.triggerBreak()

        #expect(appState.breakSecondsRemaining == 180)
        #expect(appState.isOnBreak == true)

        appState.timerEngine.stop()
    }

    // MARK: - Break Countdown Tests

    @Test("break countdown uses timer engine")
    func breakCountdownUsesTimerEngine() {
        let appState = makeAppState(breakInterval: 1, breakDuration: 60)

        appState.triggerBreak()

        #expect(appState.timerState.secondsRemaining == 60)
        #expect(appState.timerState.totalSeconds == 60)
        #expect(appState.timerEngine.isRunning == true)

        appState.timerEngine.stop()
    }

    // MARK: - Break Completion Tests

    @Test("turnsSinceBreak resets after break completes")
    func turnsSinceBreakResetsAfterBreak() async throws {
        let appState = makeAppState(breakInterval: 1, breakDuration: 1)
        appState.roster.addMobster(name: "Alice")
        appState.roster.addMobster(name: "Bob")

        appState.timerEngine.reset(duration: 1)
        appState.timerEngine.start()
        try await Task.sleep(for: .milliseconds(1500))

        #expect(appState.isOnBreak == true)
        #expect(appState.turnsSinceBreak == 1)

        try await Task.sleep(for: .milliseconds(1500))

        #expect(appState.isOnBreak == false)
        #expect(appState.turnsSinceBreak == 0)
    }

    @Test("break completion restores normal timer duration")
    func breakCompletionRestoresNormalDuration() async throws {
        let appState = makeAppState(breakInterval: 1, breakDuration: 1)
        appState.roster.addMobster(name: "Alice")
        appState.timerDuration = 420

        appState.timerEngine.reset(duration: 1)
        appState.timerEngine.start()
        try await Task.sleep(for: .milliseconds(1500))

        #expect(appState.isOnBreak == true)
        #expect(appState.timerState.totalSeconds == 1)

        try await Task.sleep(for: .milliseconds(1500))

        #expect(appState.isOnBreak == false)
        #expect(appState.timerState.secondsRemaining == 420)
        #expect(appState.timerState.totalSeconds == 420)
    }

    // MARK: - Skip Break Tests

    @Test("skipBreak ends break immediately")
    func skipBreakEndsBreakImmediately() {
        let appState = makeAppState(breakInterval: 1, breakDuration: 300)

        appState.triggerBreak()
        #expect(appState.isOnBreak == true)

        appState.skipBreak()

        #expect(appState.isOnBreak == false)
        #expect(appState.turnsSinceBreak == 0)
        #expect(appState.timerEngine.isRunning == false)
    }

    @Test("skipBreak restores normal timer duration")
    func skipBreakRestoresNormalDuration() {
        let appState = makeAppState(breakInterval: 1, breakDuration: 300)
        appState.timerDuration = 600

        appState.triggerBreak()
        #expect(appState.timerState.totalSeconds == 300)

        appState.skipBreak()

        #expect(appState.timerState.secondsRemaining == 600)
        #expect(appState.timerState.totalSeconds == 600)
    }
}
