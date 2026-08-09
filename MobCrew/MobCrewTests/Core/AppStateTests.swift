import Testing
import Foundation
@testable import MobCrew

@MainActor
private final class AppStateNotificationSpy: NotificationServiceProtocol {
    enum Event: Equatable {
        case permissionRequested
        case timerCompleted(driver: String, navigator: String)
        case breakDue(duration: Int)
        case breakCompleted
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

    func sendBreakComplete() {
        events.append(.breakCompleted)
    }
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
private final class AppStateAccessibilityAnnouncementSpy {
    var messages: [String] = []

    func announce(_ message: String) {
        messages.append(message)
    }
}

@MainActor
private final class RecordingPersistenceService: PersistenceServiceProtocol {
    enum Event: Equatable {
        case roster
        case session
    }

    let base: PersistenceService
    var events: [Event] = []
    var failsRosterSave = false
    var failsSessionSave = false
    var onSessionSave: (() -> Void)?

    init(userDefaults: UserDefaults) {
        self.base = PersistenceService(userDefaults: userDefaults)
    }

    func saveRoster(_ roster: Roster) -> Bool {
        events.append(.roster)
        guard !failsRosterSave else { return false }
        return base.saveRoster(roster)
    }

    func loadRoster() -> Roster { base.loadRoster() }
    func saveTimerDuration(_ duration: Int) { base.saveTimerDuration(duration) }
    func loadTimerDuration() -> Int? { base.loadTimerDuration() }
    func saveBreakInterval(_ interval: Int) { base.saveBreakInterval(interval) }
    func loadBreakInterval() -> Int? { base.loadBreakInterval() }
    func saveBreakDuration(_ duration: Int) { base.saveBreakDuration(duration) }
    func loadBreakDuration() -> Int? { base.loadBreakDuration() }
    func saveBreaksEnabled(_ enabled: Bool) { base.saveBreaksEnabled(enabled) }
    func loadBreaksEnabled() -> Bool? { base.loadBreaksEnabled() }
    func saveNotificationsEnabled(_ enabled: Bool) { base.saveNotificationsEnabled(enabled) }
    func loadNotificationsEnabled() -> Bool? { base.loadNotificationsEnabled() }
    func saveShowTips(_ show: Bool) { base.saveShowTips(show) }
    func loadShowTips() -> Bool? { base.loadShowTips() }

    func saveSessionSnapshot(_ snapshot: PersistedSessionSnapshot) -> Bool {
        events.append(.session)
        onSessionSave?()
        guard !failsSessionSave else { return false }
        return base.saveSessionSnapshot(snapshot)
    }

    func loadSessionSnapshot() -> SessionSnapshotLoadResult {
        base.loadSessionSnapshot()
    }
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
        let accessibilityAnnouncements: AppStateAccessibilityAnnouncementSpy
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
        let accessibilityAnnouncements: [String]
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
        persistenceService.saveBreakInterval(breakInterval)
        persistenceService.saveBreakDuration(breakDuration)
        let monotonicClock = AppStateMonotonicClock()
        let wallClock = AppStateWallClock()
        let timerEngine = TimerEngine(
            monotonicClock: monotonicClock,
            wallClock: wallClock
        )
        let notifications = AppStateNotificationSpy()
        let activeMobstersWriter = ActiveMobstersWriterSpy()
        let accessibilityAnnouncements = AppStateAccessibilityAnnouncementSpy()
        let appState = AppState(
            persistenceService: persistenceService,
            notificationService: notifications,
            activeMobstersFileService: activeMobstersWriter,
            timerEngine: timerEngine,
            accessibilityAnnouncer: accessibilityAnnouncements.announce
        )
        return Fixture(
            appState: appState,
            timerEngine: timerEngine,
            notifications: notifications,
            activeMobstersWriter: activeMobstersWriter,
            monotonicClock: monotonicClock,
            wallClock: wallClock,
            accessibilityAnnouncements: accessibilityAnnouncements
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
        fixture.accessibilityAnnouncements.messages.removeAll()
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
            activeMobstersWriteCount: fixture.activeMobstersWriter.writeCount,
            accessibilityAnnouncements: fixture.accessibilityAnnouncements.messages
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

    @Test("disabled notification preference never requests system authorization")
    func disabledNotificationsDoNotRequestPermission() {
        let fixture = makeFixture()
        setActiveRosterSize(1, in: fixture.appState)
        fixture.notifications.events.removeAll()
        fixture.appState.notificationsEnabled = false

        fixture.appState.startTimer()

        #expect(fixture.appState.sessionPhase == .regularRunning)
        #expect(fixture.notifications.events.isEmpty)
        fixture.appState.pauseTimer()
    }

    @Test("timer accessibility semantics include phase, readable time, and role context")
    func timerAccessibilitySemantics() {
        let fixture = makeFixture(timerDuration: 125)
        fixture.appState.roster.addMobster(name: "Alice")
        fixture.appState.roster.addMobster(name: "Bob")

        #expect(fixture.appState.timerAccessibilityLabel == "Turn timer")
        #expect(fixture.appState.timerAccessibilityValue == "2 minutes, 5 seconds remaining")
        #expect(fixture.appState.timerAccessibilityHint.contains("Alice"))
        #expect(fixture.appState.timerAccessibilityHint.contains("Bob"))
        #expect(fixture.appState.primaryActionAccessibilityLabel == "Start turn timer")
        #expect(fixture.appState.skipActionAccessibilityLabel.contains("Bob"))

        fixture.appState.startTimer()
        #expect(fixture.appState.primaryActionAccessibilityLabel == "Pause turn timer")
        fixture.appState.pauseTimer()
        #expect(fixture.appState.primaryActionAccessibilityLabel == "Resume turn timer")

        let breakFixture = prepare(phase: .breakDue, rosterSize: 2)
        #expect(breakFixture.appState.timerAccessibilityLabel == "Break timer")
        #expect(breakFixture.appState.primaryActionAccessibilityLabel == "Take break")
        #expect(breakFixture.appState.skipActionAccessibilityLabel == "Skip break")
    }

    @Test("driver handoff announces once while ordinary timer ticks remain silent")
    func driverHandoffAnnouncement() {
        let fixture = makeFixture(timerDuration: 2, breakInterval: 5)
        fixture.appState.roster.addMobster(name: "Alice")
        fixture.appState.roster.addMobster(name: "Bob")
        fixture.appState.startTimer()
        fixture.accessibilityAnnouncements.messages.removeAll()

        elapse(1, in: fixture)
        #expect(fixture.accessibilityAnnouncements.messages.isEmpty)

        elapse(1, in: fixture)
        fixture.timerEngine.refresh()

        #expect(fixture.accessibilityAnnouncements.messages == [
            "Turn complete. Driver Bob. Navigator Alice."
        ])
    }

    @Test("break due and break complete each announce once")
    func breakTransitionAnnouncements() {
        let fixture = makeFixture(timerDuration: 1, breakInterval: 1, breakDuration: 1)
        fixture.appState.roster.addMobster(name: "Alice")
        fixture.appState.roster.addMobster(name: "Bob")
        fixture.appState.startTimer()
        fixture.accessibilityAnnouncements.messages.removeAll()

        elapse(1, in: fixture)
        fixture.timerEngine.refresh()

        #expect(fixture.accessibilityAnnouncements.messages == [
            "Break due. Driver Bob is next. Navigator Alice."
        ])

        fixture.accessibilityAnnouncements.messages.removeAll()
        fixture.appState.takeBreak()
        elapse(1, in: fixture)
        fixture.timerEngine.refresh()

        #expect(fixture.accessibilityAnnouncements.messages == [
            "Break complete. Driver Bob. Navigator Alice."
        ])
    }

    @Test("manual skip announces the new driver once")
    func skipTurnAnnouncement() {
        let fixture = makeFixture()
        fixture.appState.roster.addMobster(name: "Alice")
        fixture.appState.roster.addMobster(name: "Bob")
        fixture.appState.startTimer()
        fixture.accessibilityAnnouncements.messages.removeAll()

        fixture.appState.skipTurn()

        #expect(fixture.accessibilityAnnouncements.messages == [
            "Turn skipped. Driver Bob. Navigator Alice."
        ])
        fixture.appState.pauseTimer()
    }

    @Test("manual break skip does not announce a completion or role change")
    func skipBreakDoesNotAnnounce() {
        let fixture = prepare(phase: .breakDue, rosterSize: 2)

        fixture.appState.skipBreak()

        #expect(fixture.accessibilityAnnouncements.messages.isEmpty)
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
            fixture.activeMobstersWriter.writeCount = 0
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

    // MARK: - Session Snapshot Recovery

    @Test("start and pause persist one cycle with running then exact frozen timing")
    func startAndPausePersistCurrentCycle() {
        let defaults = makeTestUserDefaults()
        let service = PersistenceService(userDefaults: defaults)
        let fixture = makeFixture(userDefaults: defaults, timerDuration: 10)
        setActiveRosterSize(1, in: fixture.appState)

        fixture.appState.startTimer()
        guard case .current(let running) = service.loadSessionSnapshot() else {
            Issue.record("Expected running snapshot")
            return
        }
        #expect(running.phase == .regularRunning)
        guard case .running(let deadline) = running.timing else {
            Issue.record("Expected running timing")
            return
        }
        #expect(deadline == fixture.wallClock.now.addingTimeInterval(10))

        fixture.monotonicClock.advance(by: 0.25)
        fixture.appState.pauseTimer()
        guard case .current(let paused) = service.loadSessionSnapshot() else {
            Issue.record("Expected paused snapshot")
            return
        }
        #expect(paused.phase == .regularPaused)
        #expect(paused.cycleID == running.cycleID)
        guard case .frozen(let exactRemaining) = paused.timing else {
            Issue.record("Expected frozen timing")
            return
        }
        #expect(abs(exactRemaining - 9.75) < 0.000_001)
    }

    @Test("future regular deadline restores running from wall time")
    func futureRegularDeadlineRestoresRunning() {
        let defaults = makeTestUserDefaults()
        let service = PersistenceService(userDefaults: defaults)
        service.saveTimerDuration(10)
        service.saveRoster(Roster(activeMobsters: [Mobster(name: "Alice")]))
        let cycleID = UUID()
        service.saveSessionSnapshot(PersistedSessionSnapshot(
            version: 1,
            phase: .regularRunning,
            cycleID: cycleID,
            totalSeconds: 10,
            timing: .running(wallDeadline: Date(timeIntervalSinceReferenceDate: 1_005)),
            turnsSinceBreak: 2
        ))

        let fixture = makeFixture(userDefaults: defaults, timerDuration: nil)

        #expect(fixture.appState.sessionPhase == .regularRunning)
        #expect(fixture.appState.turnsSinceBreak == 2)
        #expect(fixture.appState.timerState.totalSeconds == 10)
        #expect(fixture.appState.timerState.secondsRemaining == 5)
        #expect(fixture.timerEngine.isRunning)
        guard case .current(let restored) = service.loadSessionSnapshot() else {
            Issue.record("Expected restored snapshot")
            return
        }
        #expect(restored.cycleID == cycleID)
        fixture.appState.pauseTimer()
    }

    @Test("future recovery persists normalized state before arming refresh delivery")
    func restoredPublisherArmsAfterPersistence() {
        let defaults = makeTestUserDefaults()
        let persistence = RecordingPersistenceService(userDefaults: defaults)
        persistence.base.saveTimerDuration(10)
        persistence.base.saveRoster(Roster(activeMobsters: [Mobster(name: "Alice")]))
        persistence.base.saveSessionSnapshot(PersistedSessionSnapshot(
            version: 1,
            phase: .regularRunning,
            cycleID: UUID(),
            totalSeconds: 10,
            timing: .running(wallDeadline: Date(timeIntervalSinceReferenceDate: 1_005)),
            turnsSinceBreak: 0
        ))
        let timerEngine = TimerEngine(
            monotonicClock: AppStateMonotonicClock(),
            wallClock: AppStateWallClock()
        )
        var publisherStatesDuringSessionSave: [Bool] = []
        persistence.onSessionSave = {
            publisherStatesDuringSessionSave.append(timerEngine.isRefreshPublisherArmed)
        }

        let appState = AppState(
            persistenceService: persistence,
            notificationService: AppStateNotificationSpy(),
            activeMobstersFileService: ActiveMobstersWriterSpy(),
            timerEngine: timerEngine
        )

        #expect(publisherStatesDuringSessionSave == [false])
        #expect(timerEngine.isRefreshPublisherArmed)
        appState.pauseTimer()
    }

    @Test("future running break restores without changing roles")
    func futureRunningBreakRestores() {
        let defaults = makeTestUserDefaults()
        let service = PersistenceService(userDefaults: defaults)
        service.saveTimerDuration(10)
        let alice = Mobster(name: "Alice")
        let bob = Mobster(name: "Bob")
        service.saveRoster(Roster(activeMobsters: [alice, bob]))
        service.saveSessionSnapshot(PersistedSessionSnapshot(
            version: 1,
            phase: .breakRunning,
            cycleID: UUID(),
            totalSeconds: 60,
            timing: .running(wallDeadline: Date(timeIntervalSinceReferenceDate: 1_005)),
            turnsSinceBreak: 5
        ))

        let fixture = makeFixture(userDefaults: defaults, timerDuration: nil)

        #expect(fixture.appState.sessionPhase == .breakRunning)
        #expect(fixture.appState.timerState.totalSeconds == 60)
        #expect(fixture.appState.timerState.secondsRemaining == 5)
        #expect(fixture.appState.roster.driver?.id == alice.id)
        #expect(fixture.timerEngine.isRefreshPublisherArmed)
        fixture.appState.pauseTimer()
    }

    @Test("paused regular and break states restore exact remainder without auto-starting")
    func frozenSessionPhasesRestoreWithoutStarting() {
        let cases: [(SessionPhase, TimeInterval, Bool)] = [
            (.regularPaused, 4.25, true),
            (.breakDue, 60, true),
            (.breakPaused, 30.25, false)
        ]

        for (phase, remaining, breaksEnabled) in cases {
            let defaults = makeTestUserDefaults()
            let service = PersistenceService(userDefaults: defaults)
            service.saveTimerDuration(10)
            service.saveBreaksEnabled(breaksEnabled)
            service.saveSessionSnapshot(PersistedSessionSnapshot(
                version: 1,
                phase: phase,
                cycleID: UUID(),
                totalSeconds: phase == .regularPaused ? 10 : 60,
                timing: .frozen(exactRemaining: remaining),
                turnsSinceBreak: 2
            ))

            let fixture = makeFixture(userDefaults: defaults, timerDuration: nil)

            #expect(fixture.appState.sessionPhase == phase)
            #expect(fixture.appState.timerState.secondsRemaining == Int(ceil(remaining)))
            #expect(fixture.timerEngine.isRunning == false)
        }
    }

    @Test("break due normalizes to regular idle when breaks are disabled")
    func disabledBreakDueSnapshotNormalizes() {
        let defaults = makeTestUserDefaults()
        let service = PersistenceService(userDefaults: defaults)
        service.saveTimerDuration(10)
        service.saveBreaksEnabled(false)
        service.saveSessionSnapshot(PersistedSessionSnapshot(
            version: 1,
            phase: .breakDue,
            cycleID: UUID(),
            totalSeconds: 60,
            timing: .frozen(exactRemaining: 60),
            turnsSinceBreak: 5
        ))

        let fixture = makeFixture(userDefaults: defaults, timerDuration: nil)

        #expect(fixture.appState.sessionPhase == .regularIdle)
        #expect(fixture.appState.turnsSinceBreak == 0)
        #expect(fixture.appState.timerState.totalSeconds == 10)
        #expect(fixture.appState.timerState.secondsRemaining == 10)
    }

    @Test("expired regular deadline completes and remains idempotent after reconstruction")
    func expiredRegularDeadlineCompletesOnce() {
        let defaults = makeTestUserDefaults()
        let service = PersistenceService(userDefaults: defaults)
        service.saveTimerDuration(10)
        service.saveBreakInterval(2)
        service.saveBreakDuration(60)
        let alice = Mobster(name: "Alice")
        let bob = Mobster(name: "Bob")
        service.saveRoster(Roster(activeMobsters: [alice, bob]))
        let cycleID = UUID()
        service.saveSessionSnapshot(PersistedSessionSnapshot(
            version: 1,
            phase: .regularRunning,
            cycleID: cycleID,
            totalSeconds: 10,
            timing: .running(wallDeadline: Date(timeIntervalSinceReferenceDate: 1_000)),
            turnsSinceBreak: 1
        ))

        let first = makeFixture(
            userDefaults: defaults,
            timerDuration: nil,
            breakInterval: 2,
            breakDuration: 60
        )

        #expect(first.appState.sessionPhase == .breakDue)
        #expect(first.appState.turnsSinceBreak == 2)
        #expect(first.appState.roster.driver?.id == bob.id)
        #expect(first.timerEngine.isRunning == false)
        #expect(first.notifications.events == [.breakDue(duration: 60)])
        #expect(first.accessibilityAnnouncements.messages.isEmpty)
        #expect(service.loadRoster().lastRegularCycleResolution == RegularCycleResolutionReceipt(
            cycleID: cycleID,
            resolution: .completed
        ))

        let second = makeFixture(
            userDefaults: defaults,
            timerDuration: nil,
            breakInterval: 2,
            breakDuration: 60
        )

        #expect(second.appState.sessionPhase == .breakDue)
        #expect(second.appState.turnsSinceBreak == 2)
        #expect(second.appState.roster.driver?.id == bob.id)
        #expect(second.notifications.events.isEmpty)
        #expect(second.accessibilityAnnouncements.messages.isEmpty)
    }

    @Test("receipt prevents duplicate advance across roster then snapshot interruption")
    func receiptReconcilesInterruptedRegularCompletion() {
        let defaults = makeTestUserDefaults()
        let service = PersistenceService(userDefaults: defaults)
        service.saveTimerDuration(10)
        service.saveBreakInterval(10)
        let alice = Mobster(name: "Alice")
        let bob = Mobster(name: "Bob")
        let charlie = Mobster(name: "Charlie")
        let cycleID = UUID()
        let roster = Roster(activeMobsters: [alice, bob, charlie])
        roster.resolveRegularCycle(
            id: cycleID,
            resolution: .completed,
            advanceRoles: true
        )
        service.saveRoster(roster)
        let staleSnapshot = PersistedSessionSnapshot(
            version: 1,
            phase: .regularRunning,
            cycleID: cycleID,
            totalSeconds: 10,
            timing: .running(wallDeadline: Date(timeIntervalSinceReferenceDate: 1_000)),
            turnsSinceBreak: 0
        )
        service.saveSessionSnapshot(staleSnapshot)

        let first = makeFixture(
            userDefaults: defaults,
            timerDuration: nil,
            breakInterval: 10
        )
        #expect(first.appState.roster.driver?.id == bob.id)
        #expect(first.appState.turnsSinceBreak == 1)

        service.saveSessionSnapshot(staleSnapshot)
        let second = makeFixture(
            userDefaults: defaults,
            timerDuration: nil,
            breakInterval: 10
        )
        #expect(second.appState.roster.driver?.id == bob.id)
        #expect(second.appState.turnsSinceBreak == 1)
    }

    @Test("completion receipts reconcile zero and one participant without replaying cadence")
    func receiptReconcilesSmallRosters() {
        for activeMobsters in [[], [Mobster(name: "Alice")]] {
            let defaults = makeTestUserDefaults()
            let service = PersistenceService(userDefaults: defaults)
            service.saveTimerDuration(10)
            service.saveBreakInterval(10)
            let cycleID = UUID()
            let roster = Roster(activeMobsters: activeMobsters)
            roster.resolveRegularCycle(
                id: cycleID,
                resolution: .completed,
                advanceRoles: false
            )
            service.saveRoster(roster)
            let staleSnapshot = PersistedSessionSnapshot(
                version: 1,
                phase: .regularRunning,
                cycleID: cycleID,
                totalSeconds: 10,
                timing: .running(wallDeadline: Date(timeIntervalSinceReferenceDate: 1_000)),
                turnsSinceBreak: 0
            )
            service.saveSessionSnapshot(staleSnapshot)

            let first = makeFixture(
                userDefaults: defaults,
                timerDuration: nil,
                breakInterval: 10
            )
            #expect(first.appState.roster.activeMobsters.map(\.id) == activeMobsters.map(\.id))
            #expect(first.appState.turnsSinceBreak == 1)

            service.saveSessionSnapshot(staleSnapshot)
            let second = makeFixture(
                userDefaults: defaults,
                timerDuration: nil,
                breakInterval: 10
            )
            #expect(second.appState.roster.activeMobsters.map(\.id) == activeMobsters.map(\.id))
            #expect(second.appState.turnsSinceBreak == 1)
        }
    }

    @Test("expired recovery advances the current roster after the starting driver was removed")
    func expiredRecoveryUsesCurrentRosterAssignment() {
        let defaults = makeTestUserDefaults()
        let service = PersistenceService(userDefaults: defaults)
        service.saveTimerDuration(10)
        service.saveBreakInterval(10)
        let bob = Mobster(name: "Bob")
        let charlie = Mobster(name: "Charlie")
        service.saveRoster(Roster(activeMobsters: [bob, charlie]))
        service.saveSessionSnapshot(PersistedSessionSnapshot(
            version: 1,
            phase: .regularRunning,
            cycleID: UUID(),
            totalSeconds: 10,
            timing: .running(wallDeadline: Date(timeIntervalSinceReferenceDate: 1_000)),
            turnsSinceBreak: 0
        ))

        let fixture = makeFixture(
            userDefaults: defaults,
            timerDuration: nil,
            breakInterval: 10
        )

        #expect(fixture.appState.roster.driver?.id == charlie.id)
        #expect(fixture.appState.turnsSinceBreak == 1)
    }

    @Test("interrupted skip receipt cannot replay as completion")
    func skipReceiptConsumesStaleSnapshotWithoutCompletion() {
        let defaults = makeTestUserDefaults()
        let service = PersistenceService(userDefaults: defaults)
        service.saveTimerDuration(10)
        let alice = Mobster(name: "Alice")
        let bob = Mobster(name: "Bob")
        let cycleID = UUID()
        let roster = Roster(activeMobsters: [alice, bob])
        roster.resolveRegularCycle(
            id: cycleID,
            resolution: .skipped,
            advanceRoles: true
        )
        service.saveRoster(roster)
        service.saveSessionSnapshot(PersistedSessionSnapshot(
            version: 1,
            phase: .regularIdle,
            cycleID: cycleID,
            totalSeconds: 10,
            timing: .frozen(exactRemaining: 10),
            turnsSinceBreak: 3
        ))

        let fixture = makeFixture(userDefaults: defaults, timerDuration: nil)

        #expect(fixture.appState.sessionPhase == .regularIdle)
        #expect(fixture.appState.roster.driver?.id == bob.id)
        #expect(fixture.appState.turnsSinceBreak == 3)
        #expect(fixture.notifications.events.isEmpty)
    }

    @Test("matching receipts cannot bypass invalid running deadlines")
    func receiptDoesNotBypassDeadlineValidation() {
        for resolution in [
            RegularCycleResolutionReceipt.Resolution.completed,
            .skipped
        ] {
            let defaults = makeTestUserDefaults()
            let service = PersistenceService(userDefaults: defaults)
            service.saveTimerDuration(10)
            let alice = Mobster(name: "Alice")
            let bob = Mobster(name: "Bob")
            let cycleID = UUID()
            let roster = Roster(activeMobsters: [alice, bob])
            roster.resolveRegularCycle(
                id: cycleID,
                resolution: resolution,
                advanceRoles: true
            )
            service.saveRoster(roster)
            service.saveSessionSnapshot(PersistedSessionSnapshot(
                version: 1,
                phase: .regularRunning,
                cycleID: cycleID,
                totalSeconds: 10,
                timing: .running(wallDeadline: Date(timeIntervalSinceReferenceDate: 1_011)),
                turnsSinceBreak: 4
            ))

            let fixture = makeFixture(userDefaults: defaults, timerDuration: nil)

            #expect(fixture.appState.sessionPhase == .regularIdle)
            #expect(fixture.appState.turnsSinceBreak == 0)
            #expect(fixture.appState.roster.driver?.id == bob.id)
            #expect(fixture.appState.timerState.secondsRemaining == 10)
            #expect(fixture.notifications.events.isEmpty)
        }
    }

    @Test("expired running break completes once without advancing roles")
    func expiredBreakCompletesOnce() {
        let defaults = makeTestUserDefaults()
        let service = PersistenceService(userDefaults: defaults)
        service.saveTimerDuration(10)
        let alice = Mobster(name: "Alice")
        let bob = Mobster(name: "Bob")
        service.saveRoster(Roster(activeMobsters: [alice, bob]))
        service.saveSessionSnapshot(PersistedSessionSnapshot(
            version: 1,
            phase: .breakRunning,
            cycleID: UUID(),
            totalSeconds: 60,
            timing: .running(wallDeadline: Date(timeIntervalSinceReferenceDate: 1_000)),
            turnsSinceBreak: 5
        ))

        let first = makeFixture(userDefaults: defaults, timerDuration: nil)

        #expect(first.appState.sessionPhase == .regularIdle)
        #expect(first.appState.turnsSinceBreak == 0)
        #expect(first.appState.roster.driver?.id == alice.id)
        #expect(first.notifications.events == [.breakCompleted])
        #expect(first.accessibilityAnnouncements.messages.isEmpty)

        let second = makeFixture(userDefaults: defaults, timerDuration: nil)
        #expect(second.appState.roster.driver?.id == alice.id)
        #expect(second.notifications.events.isEmpty)
        #expect(second.accessibilityAnnouncements.messages.isEmpty)
    }

    @Test("invalid session snapshots fall back without erasing roster or settings")
    func invalidSessionSnapshotsFallBackSafely() {
        let invalidSnapshots = [
            PersistedSessionSnapshot(
                version: 1,
                phase: .regularRunning,
                cycleID: UUID(),
                totalSeconds: 10,
                timing: .frozen(exactRemaining: 10),
                turnsSinceBreak: 0
            ),
            PersistedSessionSnapshot(
                version: 1,
                phase: .regularPaused,
                cycleID: UUID(),
                totalSeconds: 0,
                timing: .frozen(exactRemaining: 1),
                turnsSinceBreak: 0
            ),
            PersistedSessionSnapshot(
                version: 1,
                phase: .regularPaused,
                cycleID: UUID(),
                totalSeconds: PersistedSessionSnapshot.maximumCycleSeconds + 1,
                timing: .frozen(exactRemaining: 1),
                turnsSinceBreak: 0
            ),
            PersistedSessionSnapshot(
                version: 1,
                phase: .regularPaused,
                cycleID: UUID(),
                totalSeconds: 10,
                timing: .frozen(exactRemaining: 11),
                turnsSinceBreak: 0
            ),
            PersistedSessionSnapshot(
                version: 1,
                phase: .regularPaused,
                cycleID: UUID(),
                totalSeconds: 10,
                timing: .frozen(exactRemaining: 5),
                turnsSinceBreak: -1
            ),
            PersistedSessionSnapshot(
                version: 1,
                phase: .regularRunning,
                cycleID: UUID(),
                totalSeconds: 10,
                timing: .running(wallDeadline: Date(timeIntervalSinceReferenceDate: 1_011)),
                turnsSinceBreak: 0
            )
        ]

        for invalidSnapshot in invalidSnapshots {
            let defaults = makeTestUserDefaults()
            let service = PersistenceService(userDefaults: defaults)
            service.saveTimerDuration(10)
            service.saveRoster(Roster(activeMobsters: [Mobster(name: "Alice")]))
            service.saveSessionSnapshot(invalidSnapshot)

            let fixture = makeFixture(userDefaults: defaults, timerDuration: nil)

            #expect(fixture.appState.sessionPhase == .regularIdle)
            #expect(fixture.appState.timerState.totalSeconds == 10)
            #expect(fixture.appState.timerState.secondsRemaining == 10)
            #expect(fixture.appState.roster.activeMobsters.map(\.name) == ["Alice"])
            #expect(service.loadTimerDuration() == 10)
        }
    }

    @Test("unknown newer snapshot survives all writes by this older process")
    func unknownNewerSnapshotIsPreserved() throws {
        let defaults = makeTestUserDefaults()
        let service = PersistenceService(userDefaults: defaults)
        service.saveTimerDuration(10)
        let rawData = try JSONSerialization.data(withJSONObject: [
            "version": PersistedSessionSnapshot.currentVersion + 1,
            "futureState": "opaque"
        ])
        defaults.set(rawData, forKey: "mobcrew.sessionSnapshot")

        let fixture = makeFixture(userDefaults: defaults, timerDuration: nil)
        #expect(defaults.data(forKey: "mobcrew.sessionSnapshot") == rawData)

        fixture.appState.flushPersistence()
        #expect(defaults.data(forKey: "mobcrew.sessionSnapshot") == rawData)

        fixture.appState.resetTimer()
        fixture.appState.roster.addMobster(name: "Alice")
        #expect(defaults.data(forKey: "mobcrew.sessionSnapshot") == rawData)
        #expect(service.loadRoster().activeMobsters.map(\.name) == ["Alice"])
    }

    @Test("roster and completion writes always order roster before session without intermediates")
    func rosterThenSessionWriteOrdering() {
        let defaults = makeTestUserDefaults()
        let persistence = RecordingPersistenceService(userDefaults: defaults)
        persistence.saveTimerDuration(1)
        persistence.saveBreakInterval(10)
        let monotonicClock = AppStateMonotonicClock()
        let timerEngine = TimerEngine(
            monotonicClock: monotonicClock,
            wallClock: AppStateWallClock()
        )
        let appState = AppState(
            persistenceService: persistence,
            notificationService: AppStateNotificationSpy(),
            activeMobstersFileService: ActiveMobstersWriterSpy(),
            timerEngine: timerEngine
        )
        persistence.events.removeAll()

        appState.roster.addMobster(name: "Alice")
        #expect(persistence.events == [.roster, .session])

        persistence.events.removeAll()
        appState.roster.addMobster(name: "Bob")
        appState.startTimer()
        persistence.events.removeAll()
        monotonicClock.advance(by: 1)
        timerEngine.refresh()

        #expect(persistence.events == [.roster, .session])
    }

    @Test("failed roster write blocks later snapshots until the roster retry succeeds")
    func rosterWriteFailureStopsOrderedPersistence() {
        let defaults = makeTestUserDefaults()
        let persistence = RecordingPersistenceService(userDefaults: defaults)
        persistence.saveTimerDuration(1)
        persistence.saveBreakInterval(10)
        let monotonicClock = AppStateMonotonicClock()
        let timerEngine = TimerEngine(
            monotonicClock: monotonicClock,
            wallClock: AppStateWallClock()
        )
        let activeWriter = ActiveMobstersWriterSpy()
        let appState = AppState(
            persistenceService: persistence,
            notificationService: AppStateNotificationSpy(),
            activeMobstersFileService: activeWriter,
            timerEngine: timerEngine
        )
        appState.roster.addMobster(name: "Alice")
        appState.roster.addMobster(name: "Bob")
        appState.startTimer()
        guard case .current(let runningSnapshot) = persistence.loadSessionSnapshot() else {
            Issue.record("Expected running snapshot")
            return
        }
        persistence.events.removeAll()
        activeWriter.writeCount = 0
        persistence.failsRosterSave = true

        monotonicClock.advance(by: 1)
        timerEngine.refresh()

        #expect(persistence.events == [.roster])
        #expect(activeWriter.writeCount == 0)
        guard case .current(let stillPersisted) = persistence.loadSessionSnapshot() else {
            Issue.record("Expected prior running snapshot")
            return
        }
        #expect(stillPersisted == runningSnapshot)

        persistence.events.removeAll()
        appState.startTimer()
        #expect(persistence.events == [.roster])
        guard case .current(let blockedSnapshot) = persistence.loadSessionSnapshot() else {
            Issue.record("Expected prior running snapshot while roster remains pending")
            return
        }
        #expect(blockedSnapshot == runningSnapshot)

        persistence.events.removeAll()
        persistence.failsRosterSave = false
        appState.pauseTimer()
        #expect(persistence.events == [.roster, .session])
        #expect(activeWriter.writeCount == 1)
        let persistedRoster = persistence.loadRoster()
        #expect(persistedRoster.driver?.name == "Bob")
        #expect(persistedRoster.lastRegularCycleResolution?.resolution == .completed)
        guard case .current(let pausedSnapshot) = persistence.loadSessionSnapshot() else {
            Issue.record("Expected paused successor snapshot")
            return
        }
        #expect(pausedSnapshot.phase == .regularPaused)
        #expect(pausedSnapshot.turnsSinceBreak == 1)
        #expect(pausedSnapshot.cycleID != runningSnapshot.cycleID)
    }

    @Test("session write failure recovers a durable receipt without duplicate completion")
    func sessionWriteFailureReconcilesReceipt() {
        let defaults = makeTestUserDefaults()
        let persistence = RecordingPersistenceService(userDefaults: defaults)
        persistence.saveTimerDuration(1)
        persistence.saveBreakInterval(10)
        let monotonicClock = AppStateMonotonicClock()
        let timerEngine = TimerEngine(
            monotonicClock: monotonicClock,
            wallClock: AppStateWallClock()
        )
        let notifications = AppStateNotificationSpy()
        let activeWriter = ActiveMobstersWriterSpy()
        let appState = AppState(
            persistenceService: persistence,
            notificationService: notifications,
            activeMobstersFileService: activeWriter,
            timerEngine: timerEngine
        )
        appState.roster.addMobster(name: "Alice")
        appState.roster.addMobster(name: "Bob")
        appState.startTimer()
        persistence.events.removeAll()
        notifications.events.removeAll()
        activeWriter.writeCount = 0
        persistence.failsSessionSave = true

        monotonicClock.advance(by: 1)
        timerEngine.refresh()

        #expect(persistence.events == [.roster, .session])
        #expect(activeWriter.writeCount == 1)
        #expect(notifications.events.isEmpty)
        #expect(persistence.loadRoster().driver?.name == "Bob")
        guard case .current(let staleRunning) = persistence.loadSessionSnapshot() else {
            Issue.record("Expected stale running snapshot")
            return
        }
        #expect(staleRunning.phase == .regularRunning)

        persistence.failsSessionSave = false
        let recovered = makeFixture(
            userDefaults: defaults,
            timerDuration: nil,
            breakInterval: 10
        )
        #expect(recovered.appState.sessionPhase == .regularIdle)
        #expect(recovered.appState.turnsSinceBreak == 1)
        #expect(recovered.appState.roster.driver?.name == "Bob")
        #expect(recovered.notifications.events.count == 1)

        let repeated = makeFixture(
            userDefaults: defaults,
            timerDuration: nil,
            breakInterval: 10
        )
        #expect(repeated.appState.turnsSinceBreak == 1)
        #expect(repeated.appState.roster.driver?.name == "Bob")
        #expect(repeated.notifications.events.isEmpty)
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
