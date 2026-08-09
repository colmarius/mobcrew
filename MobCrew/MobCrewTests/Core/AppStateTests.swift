import Testing
import Foundation
@testable import MobCrew

@MainActor
private final class AppStateNotificationSpy: NotificationServiceProtocol {
    enum Event: Equatable {
        case permissionRequested
        case timerCompleted(driver: String, navigator: String)
        case breakDue(duration: Int)
    }

    var events: [Event] = []

    func requestPermission() {
        events.append(.permissionRequested)
    }

    func sendTimerComplete(driver: String, navigator: String) {
        events.append(.timerCompleted(driver: driver, navigator: navigator))
    }

    func sendBreakDue(duration: Int) {
        events.append(.breakDue(duration: duration))
    }

    func sendBreakComplete() {}
}

@MainActor
private final class ActiveMobstersWriterSpy: ActiveMobstersFileServiceProtocol {
    var writeCount = 0

    func writeActiveMobsters(_ roster: Roster) {
        writeCount += 1
    }
}

private final class AppStateMonotonicClock: MonotonicClockProtocol {
    var now: TimeInterval = 0

    func advance(by duration: TimeInterval) {
        now += duration
    }
}

private final class AppStateWallClock: WallClockProtocol {
    var now = Date(timeIntervalSinceReferenceDate: 1_000)
}

@MainActor
@Suite("AppState Tests")
struct AppStateTests {
    private struct Fixture {
        let appState: AppState
        let timerEngine: TimerEngine
        let notifications: AppStateNotificationSpy
        let activeMobstersWriter: ActiveMobstersWriterSpy
        let monotonicClock: AppStateMonotonicClock
        let wallClock: AppStateWallClock
    }

    private enum Command: CaseIterable {
        case start
        case pause
        case resume
        case reset
        case skipTurn
        case takeBreak
        case skipBreak
    }

    private struct StateSnapshot: Equatable {
        let phase: SessionPhase
        let secondsRemaining: Int
        let totalSeconds: Int
        let activeIDs: [UUID]
        let inactiveIDs: [UUID]
        let driverID: UUID?
        let turnsSinceBreak: Int
        let tipID: UUID
        let notificationEvents: [AppStateNotificationSpy.Event]
        let activeMobstersWriteCount: Int
    }

    private func makeTestUserDefaults() -> UserDefaults {
        let suiteName = "com.mobcrew.tests.\(UUID().uuidString)"
        return UserDefaults(suiteName: suiteName)!
    }

    private func makeFixture(
        userDefaults: UserDefaults? = nil,
        timerDuration: Int? = 420,
        breakInterval: Int = 5,
        breakDuration: Int = 300
    ) -> Fixture {
        let defaults = userDefaults ?? makeTestUserDefaults()
        let persistenceService = PersistenceService(userDefaults: defaults)
        if let timerDuration {
            persistenceService.saveTimerDuration(timerDuration)
        }
        let monotonicClock = AppStateMonotonicClock()
        let wallClock = AppStateWallClock()
        let timerEngine = TimerEngine(
            monotonicClock: monotonicClock,
            wallClock: wallClock
        )
        let notifications = AppStateNotificationSpy()
        let activeMobstersWriter = ActiveMobstersWriterSpy()
        let appState = AppState(
            persistenceService: persistenceService,
            notificationService: notifications,
            activeMobstersFileService: activeMobstersWriter,
            timerEngine: timerEngine
        )
        appState.breakInterval = breakInterval
        appState.breakDuration = breakDuration
        return Fixture(
            appState: appState,
            timerEngine: timerEngine,
            notifications: notifications,
            activeMobstersWriter: activeMobstersWriter,
            monotonicClock: monotonicClock,
            wallClock: wallClock
        )
    }

    private func elapse(_ duration: TimeInterval, in fixture: Fixture) {
        fixture.monotonicClock.advance(by: duration)
        fixture.timerEngine.refresh()
    }

    private func setActiveRosterSize(_ count: Int, in appState: AppState) {
        while appState.roster.activeMobsters.count < count {
            appState.roster.addMobster(name: "Person \(appState.roster.activeMobsters.count + 1)")
        }
        while appState.roster.activeMobsters.count > count {
            appState.roster.benchMobster(at: appState.roster.activeMobsters.count - 1)
        }
    }

    private func prepare(
        phase: SessionPhase,
        rosterSize: Int
    ) -> Fixture {
        let fixture = makeFixture(timerDuration: 1, breakInterval: 1, breakDuration: 60)
        let setupRosterSize: Int
        switch phase {
        case .regularIdle:
            setupRosterSize = rosterSize
        case .regularRunning, .regularPaused, .breakDue, .breakRunning, .breakPaused:
            setupRosterSize = max(1, rosterSize)
        }
        setActiveRosterSize(setupRosterSize, in: fixture.appState)

        switch phase {
        case .regularIdle:
            break
        case .regularRunning:
            fixture.appState.startTimer()
        case .regularPaused:
            fixture.appState.startTimer()
            fixture.appState.pauseTimer()
        case .breakDue:
            fixture.appState.startTimer()
            elapse(1, in: fixture)
        case .breakRunning:
            fixture.appState.startTimer()
            elapse(1, in: fixture)
            fixture.appState.takeBreak()
        case .breakPaused:
            fixture.appState.startTimer()
            elapse(1, in: fixture)
            fixture.appState.takeBreak()
            fixture.appState.pauseTimer()
        }

        setActiveRosterSize(rosterSize, in: fixture.appState)
        fixture.notifications.events.removeAll()
        fixture.activeMobstersWriter.writeCount = 0
        #expect(fixture.appState.sessionPhase == phase)
        return fixture
    }

    private func snapshot(_ fixture: Fixture) -> StateSnapshot {
        StateSnapshot(
            phase: fixture.appState.sessionPhase,
            secondsRemaining: fixture.appState.timerState.secondsRemaining,
            totalSeconds: fixture.appState.timerState.totalSeconds,
            activeIDs: fixture.appState.roster.activeMobsters.map(\.id),
            inactiveIDs: fixture.appState.roster.inactiveMobsters.map(\.id),
            driverID: fixture.appState.roster.driver?.id,
            turnsSinceBreak: fixture.appState.turnsSinceBreak,
            tipID: fixture.appState.currentTip.id,
            notificationEvents: fixture.notifications.events,
            activeMobstersWriteCount: fixture.activeMobstersWriter.writeCount
        )
    }

    private func perform(_ command: Command, on appState: AppState) {
        switch command {
        case .start:
            appState.startTimer()
        case .pause:
            appState.pauseTimer()
        case .resume:
            appState.resumeTimer()
        case .reset:
            appState.resetTimer()
        case .skipTurn:
            appState.skipTurn()
        case .takeBreak:
            appState.takeBreak()
        case .skipBreak:
            appState.skipBreak()
        }
    }

    private func expectedPhase(
        after command: Command,
        from phase: SessionPhase,
        rosterSize: Int
    ) -> SessionPhase? {
        switch command {
        case .start:
            return phase == .regularIdle && rosterSize >= 1 ? .regularRunning : nil
        case .pause:
            switch phase {
            case .regularRunning: return .regularPaused
            case .breakRunning: return .breakPaused
            default: return nil
            }
        case .resume:
            if phase == .regularPaused && rosterSize >= 1 { return .regularRunning }
            if phase == .breakPaused { return .breakRunning }
            return nil
        case .reset:
            return phase.isRegular ? .regularIdle : nil
        case .skipTurn:
            return phase.isRegular && rosterSize >= 2 ? .regularRunning : nil
        case .takeBreak:
            return phase == .breakDue ? .breakRunning : nil
        case .skipBreak:
            return phase.isBreak ? .regularIdle : nil
        }
    }

    // MARK: - Initial State

    @Test("initial state is regular idle with default duration")
    func initialStateIsRegularIdle() {
        let fixture = makeFixture()

        #expect(fixture.appState.timerDuration == 420)
        #expect(fixture.appState.breaksEnabled)
        #expect(fixture.appState.sessionPhase == .regularIdle)
        #expect(fixture.appState.timerState.secondsRemaining == 420)
        #expect(fixture.appState.roster.activeMobsters.isEmpty)
        #expect(fixture.appState.roster.inactiveMobsters.isEmpty)
    }

    @Test("stored disabled breaks load across AppState instances")
    func breaksEnabledPersistsAcrossInstances() {
        let defaults = makeTestUserDefaults()
        let first = makeFixture(userDefaults: defaults)
        first.appState.setBreaksEnabled(false)

        let second = makeFixture(userDefaults: defaults, timerDuration: nil)

        #expect(first.appState.breaksEnabled == false)
        #expect(second.appState.breaksEnabled == false)
    }

    // MARK: - Transition Matrix

    @Test("every phase and roster size guards every session command")
    func commandTransitionMatrix() {
        for phase in SessionPhase.allCases {
            for rosterSize in 0...2 {
                for command in Command.allCases {
                    let fixture = prepare(phase: phase, rosterSize: rosterSize)
                    let before = snapshot(fixture)

                    perform(command, on: fixture.appState)

                    if let expectedPhase = expectedPhase(
                        after: command,
                        from: phase,
                        rosterSize: rosterSize
                    ) {
                        #expect(
                            fixture.appState.sessionPhase == expectedPhase,
                            "\(command) from \(phase) with \(rosterSize) participants"
                        )

                        if command == .skipTurn {
                            #expect(fixture.appState.roster.driver?.id != before.driverID)
                            #expect(fixture.activeMobstersWriter.writeCount == 1)
                        } else {
                            #expect(fixture.appState.roster.driver?.id == before.driverID)
                        }

                        if command == .skipBreak || command == .reset || command == .skipTurn {
                            #expect(fixture.appState.timerState.secondsRemaining == fixture.appState.timerDuration)
                            #expect(fixture.appState.timerState.totalSeconds == fixture.appState.timerDuration)
                        }

                        if command == .skipBreak {
                            #expect(fixture.appState.turnsSinceBreak == 0)
                        }
                    } else {
                        #expect(
                            snapshot(fixture) == before,
                            "\(command) must be a complete no-op from \(phase) with \(rosterSize) participants"
                        )
                    }
                }
            }
        }
    }

    @Test("capabilities and labels derive from phase and roster size")
    func capabilityMatrix() {
        let expectedPrimary: [SessionPhase: (SessionPrimaryAction, String)] = [
            .regularIdle: (.start, "Start"),
            .regularRunning: (.pause, "Pause"),
            .regularPaused: (.resume, "Resume"),
            .breakDue: (.takeBreak, "Take Break"),
            .breakRunning: (.pause, "Pause Break"),
            .breakPaused: (.resume, "Resume Break")
        ]

        for phase in SessionPhase.allCases {
            for rosterSize in 0...2 {
                let fixture = prepare(phase: phase, rosterSize: rosterSize)
                let appState = fixture.appState
                let expected = expectedPrimary[phase]!

                #expect(appState.primaryAction == expected.0)
                #expect(appState.primaryActionLabel == expected.1)
                #expect(appState.canPerformPrimaryAction == (
                    phase != .regularIdle && phase != .regularPaused || rosterSize >= 1
                ))
                #expect(appState.canResetTimer == phase.isRegular)
                #expect(appState.canSkipTurn == (phase.isRegular && rosterSize >= 2))
                #expect(appState.canSkipBreak == phase.isBreak)
                #expect(appState.skipActionLabel == (phase.isBreak ? "Skip Break" : "Skip Turn"))
                #expect(appState.canPerformSkipAction == (
                    phase.isBreak || phase.isRegular && rosterSize >= 2
                ))
            }
        }
    }

    @Test("primary and skip dispatchers use phase-aware commands")
    func sharedActionDispatchers() {
        let regular = prepare(phase: .regularIdle, rosterSize: 1)
        regular.appState.performPrimaryAction()
        #expect(regular.appState.sessionPhase == .regularRunning)
        regular.appState.performPrimaryAction()
        #expect(regular.appState.sessionPhase == .regularPaused)
        regular.appState.performPrimaryAction()
        #expect(regular.appState.sessionPhase == .regularRunning)

        let breakFixture = prepare(phase: .breakDue, rosterSize: 2)
        let driverID = breakFixture.appState.roster.driver?.id
        breakFixture.appState.performPrimaryAction()
        #expect(breakFixture.appState.sessionPhase == .breakRunning)
        breakFixture.appState.performSkipAction()
        #expect(breakFixture.appState.sessionPhase == .regularIdle)
        #expect(breakFixture.appState.roster.driver?.id == driverID)
    }

    // MARK: - Completion

    @Test("regular completion advances only when at least two participants remain")
    func regularCompletionRosterGuards() {
        for rosterSize in 0...2 {
            let fixture = makeFixture(timerDuration: 1, breakInterval: 10)
            setActiveRosterSize(max(1, rosterSize), in: fixture.appState)
            fixture.appState.startTimer()
            setActiveRosterSize(rosterSize, in: fixture.appState)
            let driverBeforeCompletion = fixture.appState.roster.driver?.id

            elapse(1, in: fixture)

            #expect(fixture.appState.sessionPhase == .regularIdle)
            #expect(fixture.appState.turnsSinceBreak == 1)
            if rosterSize == 2 {
                #expect(fixture.appState.roster.driver?.id != driverBeforeCompletion)
                #expect(fixture.activeMobstersWriter.writeCount == 1)
            } else {
                #expect(fixture.appState.roster.driver?.id == driverBeforeCompletion)
                #expect(fixture.activeMobstersWriter.writeCount == 0)
            }
        }
    }

    @Test("paused or already completed publishers cannot complete a cycle")
    func stalePublisherDeliveryIsIgnored() {
        let fixture = makeFixture(timerDuration: 1, breakInterval: 10)
        setActiveRosterSize(2, in: fixture.appState)
        let initialDriverID = fixture.appState.roster.driver?.id
        fixture.appState.startTimer()
        fixture.appState.pauseTimer()

        fixture.monotonicClock.advance(by: 1)
        fixture.timerEngine.refresh()

        #expect(fixture.appState.sessionPhase == .regularPaused)
        #expect(fixture.appState.timerState.secondsRemaining == 1)
        #expect(fixture.appState.roster.driver?.id == initialDriverID)
        #expect(fixture.appState.turnsSinceBreak == 0)

        fixture.appState.resumeTimer()
        elapse(1, in: fixture)
        fixture.timerEngine.refresh()

        #expect(fixture.appState.sessionPhase == .regularIdle)
        #expect(fixture.appState.turnsSinceBreak == 1)
    }

    @Test("pausing at the deadline completes instead of stranding paused at zero")
    func pauseAtDeadlineCompletesCurrentTurn() {
        let fixture = makeFixture(timerDuration: 1, breakInterval: 10)
        setActiveRosterSize(2, in: fixture.appState)
        let driverBeforeCompletion = fixture.appState.roster.driver?.id
        fixture.appState.startTimer()
        fixture.monotonicClock.advance(by: 1)

        fixture.appState.pauseTimer()

        #expect(fixture.appState.sessionPhase == .regularIdle)
        #expect(fixture.appState.timerState.secondsRemaining == fixture.appState.timerDuration)
        #expect(fixture.appState.roster.driver?.id != driverBeforeCompletion)
        #expect(fixture.appState.turnsSinceBreak == 1)
    }

    // MARK: - Timer Duration Persistence

    @Test("changing configured duration while idle updates the displayed cycle and persistence")
    func idleDurationChangeAppliesImmediately() {
        let defaults = makeTestUserDefaults()
        let service = PersistenceService(userDefaults: defaults)
        let fixture = makeFixture(userDefaults: defaults)

        fixture.appState.setTimerDuration(minutes: 15)

        #expect(service.loadTimerDuration() == 900)
        #expect(fixture.appState.timerDuration == 900)
        #expect(fixture.appState.timerState.totalSeconds == 900)
        #expect(fixture.appState.timerState.secondsRemaining == 900)
        #expect(fixture.appState.sessionPhase == .regularIdle)
    }

    @Test("changing configured duration while running preserves current progress")
    func runningDurationChangeAppliesNextCycle() {
        let fixture = makeFixture(timerDuration: 300)
        setActiveRosterSize(1, in: fixture.appState)
        fixture.appState.startTimer()
        elapse(1, in: fixture)

        fixture.appState.setTimerDuration(minutes: 10)

        #expect(fixture.appState.timerDuration == 600)
        #expect(fixture.appState.timerState.totalSeconds == 300)
        #expect(fixture.appState.timerState.secondsRemaining == 299)
        #expect(fixture.appState.sessionPhase == .regularRunning)
        fixture.appState.pauseTimer()
    }

    @Test("changing configured duration while paused preserves current progress")
    func pausedDurationChangeAppliesNextCycle() {
        let fixture = makeFixture(timerDuration: 300)
        setActiveRosterSize(1, in: fixture.appState)
        fixture.appState.startTimer()
        elapse(1, in: fixture)
        fixture.appState.pauseTimer()

        fixture.appState.setTimerDuration(minutes: 10)

        #expect(fixture.appState.timerDuration == 600)
        #expect(fixture.appState.timerState.totalSeconds == 300)
        #expect(fixture.appState.timerState.secondsRemaining == 299)
        #expect(fixture.appState.sessionPhase == .regularPaused)
    }

    @Test("explicit reset applies configured duration from running and paused")
    func resetAppliesConfiguredDuration() {
        for shouldPause in [false, true] {
            let fixture = makeFixture(timerDuration: 300)
            setActiveRosterSize(1, in: fixture.appState)
            fixture.appState.startTimer()
            elapse(1, in: fixture)
            if shouldPause {
                fixture.appState.pauseTimer()
            }
            fixture.appState.setTimerDuration(minutes: 10)

            fixture.appState.resetTimer()

            #expect(fixture.appState.sessionPhase == .regularIdle)
            #expect(fixture.appState.timerState.totalSeconds == 600)
            #expect(fixture.appState.timerState.secondsRemaining == 600)
        }
    }

    @Test("next turn uses a configured duration changed during the current turn")
    func nextTurnUsesConfiguredDuration() {
        let fixture = makeFixture(timerDuration: 300)
        setActiveRosterSize(2, in: fixture.appState)
        fixture.appState.startTimer()
        elapse(1, in: fixture)
        fixture.appState.setTimerDuration(minutes: 10)

        fixture.appState.skipTurn()

        #expect(fixture.appState.sessionPhase == .regularRunning)
        #expect(fixture.appState.timerState.totalSeconds == 600)
        #expect(fixture.appState.timerState.secondsRemaining == 600)
        fixture.appState.pauseTimer()
    }

    @Test("configured duration changes do not alter any break countdown")
    func durationChangeDoesNotAffectBreak() {
        for phase in [SessionPhase.breakDue, .breakRunning, .breakPaused] {
            let fixture = prepare(phase: phase, rosterSize: 2)
            let totalBeforeChange = fixture.appState.timerState.totalSeconds
            let remainingBeforeChange = fixture.appState.timerState.secondsRemaining

            fixture.appState.setTimerDuration(minutes: 10)

            #expect(fixture.appState.timerDuration == 600)
            #expect(fixture.appState.sessionPhase == phase)
            #expect(fixture.appState.timerState.totalSeconds == totalBeforeChange)
            #expect(fixture.appState.timerState.secondsRemaining == remainingBeforeChange)
            if phase == .breakRunning {
                fixture.appState.pauseTimer()
            }
        }
    }

    @Test("configured duration rejects values outside the shared range")
    func durationRangeIsEnforcedAtAppStateBoundary() {
        let fixture = makeFixture(timerDuration: 420)

        fixture.appState.setTimerDuration(minutes: 0)
        fixture.appState.setTimerDuration(minutes: 61)

        #expect(fixture.appState.timerDuration == 420)
        #expect(fixture.appState.timerState.totalSeconds == 420)
        #expect(fixture.appState.timerState.secondsRemaining == 420)
    }

    @Test("timer duration persists across AppState instances")
    func timerDurationPersistsAcrossInstances() {
        let defaults = makeTestUserDefaults()
        let first = makeFixture(userDefaults: defaults)
        first.appState.setTimerDuration(minutes: 20)

        let second = makeFixture(userDefaults: defaults, timerDuration: nil)

        #expect(second.appState.timerDuration == 1200)
        #expect(second.appState.timerState.totalSeconds == 1200)
        #expect(second.appState.timerState.secondsRemaining == 1200)
    }

    // MARK: - Roster Persistence

    @Test("saveRoster persists roster state")
    func saveRosterPersistsState() {
        let defaults = makeTestUserDefaults()
        let service = PersistenceService(userDefaults: defaults)
        let fixture = makeFixture(userDefaults: defaults)
        fixture.appState.roster.addMobster(name: "Alice")
        fixture.appState.roster.addMobster(name: "Bob")

        fixture.appState.saveRoster()

        let loadedRoster = service.loadRoster()
        #expect(loadedRoster.activeMobsters.map(\.name) == ["Alice", "Bob"])
    }

    @Test("roster persists across AppState instances")
    func rosterPersistsAcrossInstances() {
        let defaults = makeTestUserDefaults()
        let first = makeFixture(userDefaults: defaults)
        first.appState.roster.addMobster(name: "Charlie")
        first.appState.saveRoster()

        let service = PersistenceService(userDefaults: defaults)
        let second = AppState(
            persistenceService: service,
            notificationService: AppStateNotificationSpy(),
            activeMobstersFileService: ActiveMobstersWriterSpy(),
            timerEngine: TimerEngine()
        )

        #expect(second.roster.activeMobsters.map(\.name) == ["Charlie"])
    }
}
