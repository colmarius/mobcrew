import Testing
import Foundation
@testable import MobCrew

@MainActor
private final class BreakNotificationSpy: NotificationServiceProtocol {
    enum Event: Equatable {
        case permissionRequested
        case timerCompleted
        case breakDue(duration: Int)
        case breakCompleted
    }

    var events: [Event] = []

    func requestPermission() {
        events.append(.permissionRequested)
    }

    func sendTimerComplete(driver: String, navigator: String) {
        events.append(.timerCompleted)
    }

    func sendBreakDue(duration: Int) {
        events.append(.breakDue(duration: duration))
    }

    func sendBreakComplete() {
        events.append(.breakCompleted)
    }
}

@MainActor
private final class BreakActiveMobstersWriterSpy: ActiveMobstersFileServiceProtocol {
    var writeCount = 0

    func writeActiveMobsters(_ roster: Roster) {
        writeCount += 1
    }
}

private final class BreakMonotonicClock: MonotonicClockProtocol {
    var now: TimeInterval = 0

    func advance(by duration: TimeInterval) {
        now += duration
    }
}

private final class BreakWallClock: WallClockProtocol {
    var now = Date(timeIntervalSinceReferenceDate: 1_000)
}

@MainActor
@Suite("Break Logic Tests")
struct BreakLogicTests {
    private struct Fixture {
        let appState: AppState
        let timerEngine: TimerEngine
        let notifications: BreakNotificationSpy
        let activeMobstersWriter: BreakActiveMobstersWriterSpy
        let monotonicClock: BreakMonotonicClock
    }

    private func makeFixture(
        breakInterval: Int = 1,
        breakDuration: Int = 60,
        breaksEnabled: Bool? = nil
    ) -> Fixture {
        let suiteName = "com.mobcrew.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let persistenceService = PersistenceService(userDefaults: defaults)
        persistenceService.saveTimerDuration(1)
        if let breaksEnabled {
            persistenceService.saveBreaksEnabled(breaksEnabled)
        }
        let monotonicClock = BreakMonotonicClock()
        let timerEngine = TimerEngine(
            monotonicClock: monotonicClock,
            wallClock: BreakWallClock()
        )
        let notifications = BreakNotificationSpy()
        let activeMobstersWriter = BreakActiveMobstersWriterSpy()
        let appState = AppState(
            persistenceService: persistenceService,
            notificationService: notifications,
            activeMobstersFileService: activeMobstersWriter,
            timerEngine: timerEngine
        )
        appState.breakInterval = breakInterval
        appState.breakDuration = breakDuration
        appState.roster.addMobster(name: "Alice")
        appState.roster.addMobster(name: "Bob")
        return Fixture(
            appState: appState,
            timerEngine: timerEngine,
            notifications: notifications,
            activeMobstersWriter: activeMobstersWriter,
            monotonicClock: monotonicClock
        )
    }

    private func elapse(_ duration: TimeInterval, in fixture: Fixture) {
        fixture.monotonicClock.advance(by: duration)
        fixture.timerEngine.refresh()
    }

    private func completeRegularTurn(_ fixture: Fixture) {
        fixture.appState.startTimer()
        elapse(1, in: fixture)
    }

    @Test("reaching cadence offers a prepared break without starting it")
    func breakBecomesDue() {
        let fixture = makeFixture(breakInterval: 1, breakDuration: 180)

        completeRegularTurn(fixture)

        #expect(fixture.appState.sessionPhase == .breakDue)
        #expect(fixture.appState.timerState.secondsRemaining == 180)
        #expect(fixture.appState.timerState.totalSeconds == 180)
        #expect(fixture.timerEngine.isRunning == false)
        #expect(fixture.appState.turnsSinceBreak == 1)
        #expect(fixture.notifications.events == [
            .permissionRequested,
            .breakDue(duration: 180)
        ])
    }

    @Test("disabled breaks do not accumulate cadence or prompt after re-enable")
    func disabledBreaksResetCadenceAcrossReEnable() {
        let fixture = makeFixture(breakInterval: 2)
        completeRegularTurn(fixture)
        #expect(fixture.appState.turnsSinceBreak == 1)

        fixture.appState.setBreaksEnabled(false)
        #expect(fixture.appState.turnsSinceBreak == 0)

        for _ in 0..<2 {
            completeRegularTurn(fixture)
            #expect(fixture.appState.sessionPhase == .regularIdle)
            #expect(fixture.appState.turnsSinceBreak == 0)
        }
        #expect(fixture.notifications.events.filter { event in
            if case .breakDue = event { return true }
            return false
        }.isEmpty)

        fixture.appState.setBreaksEnabled(true)
        #expect(fixture.appState.sessionPhase == .regularIdle)
        #expect(fixture.appState.turnsSinceBreak == 0)

        completeRegularTurn(fixture)
        #expect(fixture.appState.sessionPhase == .regularIdle)
        #expect(fixture.appState.turnsSinceBreak == 1)
        completeRegularTurn(fixture)
        #expect(fixture.appState.sessionPhase == .breakDue)
        #expect(fixture.appState.turnsSinceBreak == 2)
    }

    @Test("persisted disabled breaks suppress cadence from the first turn")
    func persistedDisabledBreaksSuppressCadence() {
        let fixture = makeFixture(breakInterval: 1, breaksEnabled: false)

        completeRegularTurn(fixture)

        #expect(fixture.appState.breaksEnabled == false)
        #expect(fixture.appState.sessionPhase == .regularIdle)
        #expect(fixture.appState.turnsSinceBreak == 0)
        #expect(fixture.notifications.events == [
            .permissionRequested,
            .timerCompleted
        ])
    }

    @Test("disabling breaks preserves a current regular cycle")
    func disablingBreaksPreservesRegularCycle() {
        for shouldPause in [false, true] {
            let fixture = makeFixture(breakInterval: 2)
            completeRegularTurn(fixture)
            fixture.appState.startTimer()
            fixture.monotonicClock.advance(by: 0.25)
            fixture.timerEngine.refresh()
            if shouldPause {
                fixture.appState.pauseTimer()
            }
            let phase = fixture.appState.sessionPhase
            let remaining = fixture.appState.timerState.secondsRemaining

            fixture.appState.setBreaksEnabled(false)

            #expect(fixture.appState.sessionPhase == phase)
            #expect(fixture.appState.timerState.secondsRemaining == remaining)
            #expect(fixture.timerEngine.isRunning == !shouldPause)
            #expect(fixture.appState.turnsSinceBreak == 0)
            fixture.appState.resetTimer()
        }
    }

    @Test("disabling a due break clears the prompt without completing or advancing")
    func disablingDueBreakReturnsToRegularIdle() {
        let fixture = makeFixture(breakDuration: 180)
        completeRegularTurn(fixture)
        let driverID = fixture.appState.roster.driver?.id
        let writeCount = fixture.activeMobstersWriter.writeCount
        fixture.notifications.events.removeAll()

        fixture.appState.setBreaksEnabled(false)

        #expect(fixture.appState.sessionPhase == .regularIdle)
        #expect(fixture.appState.turnsSinceBreak == 0)
        #expect(fixture.appState.timerState.totalSeconds == fixture.appState.timerDuration)
        #expect(fixture.appState.timerState.secondsRemaining == fixture.appState.timerDuration)
        #expect(fixture.timerEngine.isRunning == false)
        #expect(fixture.appState.roster.driver?.id == driverID)
        #expect(fixture.activeMobstersWriter.writeCount == writeCount)
        #expect(fixture.notifications.events.isEmpty)
    }

    @Test("disabling breaks preserves an accepted running or paused break")
    func disablingBreaksPreservesAcceptedBreak() {
        for shouldPause in [false, true] {
            let fixture = makeFixture(breakDuration: 180)
            completeRegularTurn(fixture)
            fixture.appState.takeBreak()
            if shouldPause {
                fixture.appState.pauseTimer()
            }
            let phase = fixture.appState.sessionPhase
            let remaining = fixture.appState.timerState.secondsRemaining
            fixture.notifications.events.removeAll()

            fixture.appState.setBreaksEnabled(false)

            #expect(fixture.appState.sessionPhase == phase)
            #expect(fixture.appState.timerState.secondsRemaining == remaining)
            #expect(fixture.timerEngine.isRunning == !shouldPause)
            #expect(fixture.appState.turnsSinceBreak == 0)

            if shouldPause {
                fixture.appState.resumeTimer()
                #expect(fixture.appState.sessionPhase == .breakRunning)
                fixture.appState.skipBreak()
                #expect(fixture.notifications.events.isEmpty)
            } else {
                elapse(180, in: fixture)
                #expect(fixture.appState.sessionPhase == .regularIdle)
                #expect(fixture.notifications.events == [.breakCompleted])
            }
        }
    }

    @Test("taking a due break starts the prepared countdown without notifying twice")
    func takeBreakStartsPreparedCountdown() {
        let fixture = makeFixture(breakInterval: 1, breakDuration: 180)
        completeRegularTurn(fixture)
        let eventsBeforeTakingBreak = fixture.notifications.events

        fixture.appState.takeBreak()

        #expect(fixture.appState.sessionPhase == .breakRunning)
        #expect(fixture.timerEngine.isRunning)
        #expect(fixture.appState.timerState.secondsRemaining == 180)
        #expect(fixture.notifications.events == eventsBeforeTakingBreak)
        fixture.appState.pauseTimer()
    }

    @Test("break pause and resume preserve remaining duration")
    func pauseAndResumeBreak() {
        let fixture = makeFixture(breakDuration: 180)
        completeRegularTurn(fixture)
        fixture.appState.takeBreak()

        fixture.appState.pauseTimer()
        let pausedRemaining = fixture.appState.timerState.secondsRemaining

        #expect(fixture.appState.sessionPhase == .breakPaused)
        #expect(fixture.timerEngine.isRunning == false)

        fixture.appState.resumeTimer()

        #expect(fixture.appState.sessionPhase == .breakRunning)
        #expect(fixture.timerEngine.isRunning)
        #expect(fixture.appState.timerState.secondsRemaining == pausedRemaining)
        fixture.appState.pauseTimer()
    }

    @Test("pausing a break at its deadline completes the break")
    func pauseAtBreakDeadlineCompletes() {
        let fixture = makeFixture(breakDuration: 1)
        completeRegularTurn(fixture)
        fixture.appState.takeBreak()
        fixture.notifications.events.removeAll()
        fixture.monotonicClock.advance(by: 1)

        fixture.appState.pauseTimer()

        #expect(fixture.appState.sessionPhase == .regularIdle)
        #expect(fixture.appState.turnsSinceBreak == 0)
        #expect(fixture.appState.timerState.secondsRemaining == fixture.appState.timerDuration)
        #expect(fixture.notifications.events == [.breakCompleted])
    }

    @Test("skipping every break phase never advances the roster")
    func skipBreakNeverAdvancesRoster() {
        for phase in [SessionPhase.breakDue, .breakRunning, .breakPaused] {
            let fixture = makeFixture(breakDuration: 180)
            completeRegularTurn(fixture)
            if phase != .breakDue {
                fixture.appState.takeBreak()
            }
            if phase == .breakPaused {
                fixture.appState.pauseTimer()
            }
            let driverID = fixture.appState.roster.driver?.id
            let writeCount = fixture.activeMobstersWriter.writeCount
            let eventCount = fixture.notifications.events.count

            fixture.appState.skipBreak()

            #expect(fixture.appState.sessionPhase == .regularIdle)
            #expect(fixture.appState.roster.driver?.id == driverID)
            #expect(fixture.activeMobstersWriter.writeCount == writeCount)
            #expect(fixture.appState.turnsSinceBreak == 0)
            #expect(fixture.appState.timerState.secondsRemaining == fixture.appState.timerDuration)
            #expect(fixture.timerEngine.isRunning == false)
            #expect(fixture.notifications.events.count == eventCount)
        }
    }

    @Test("direct skipTurn is a no-op in every break phase")
    func skipTurnCannotMutateBreakState() {
        for phase in [SessionPhase.breakDue, .breakRunning, .breakPaused] {
            let fixture = makeFixture(breakDuration: 180)
            completeRegularTurn(fixture)
            if phase != .breakDue {
                fixture.appState.takeBreak()
            }
            if phase == .breakPaused {
                fixture.appState.pauseTimer()
            }
            let driverID = fixture.appState.roster.driver?.id
            let remaining = fixture.appState.timerState.secondsRemaining
            let writes = fixture.activeMobstersWriter.writeCount

            fixture.appState.skipTurn()

            #expect(fixture.appState.sessionPhase == phase)
            #expect(fixture.appState.roster.driver?.id == driverID)
            #expect(fixture.appState.timerState.secondsRemaining == remaining)
            #expect(fixture.activeMobstersWriter.writeCount == writes)
        }
    }

    @Test("break completion resets cadence and never advances roles")
    func breakCompletion() {
        let fixture = makeFixture(breakDuration: 1)
        completeRegularTurn(fixture)
        let driverAfterRegularCompletion = fixture.appState.roster.driver?.id
        let writesAfterRegularCompletion = fixture.activeMobstersWriter.writeCount
        fixture.appState.takeBreak()
        fixture.notifications.events.removeAll()

        elapse(1, in: fixture)
        fixture.timerEngine.refresh()

        #expect(fixture.appState.sessionPhase == .regularIdle)
        #expect(fixture.appState.turnsSinceBreak == 0)
        #expect(fixture.appState.roster.driver?.id == driverAfterRegularCompletion)
        #expect(fixture.activeMobstersWriter.writeCount == writesAfterRegularCompletion)
        #expect(fixture.appState.timerState.secondsRemaining == fixture.appState.timerDuration)
        #expect(fixture.timerEngine.isRunning == false)
        #expect(fixture.notifications.events == [.breakCompleted])

        fixture.timerEngine.refresh()
        #expect(fixture.notifications.events == [.breakCompleted])
    }

    @Test("break completion cue follows the existing notification preference")
    func breakCompletionRespectsNotificationPreference() {
        let fixture = makeFixture(breakDuration: 1)
        completeRegularTurn(fixture)
        fixture.appState.takeBreak()
        fixture.notifications.events.removeAll()
        fixture.appState.notificationsEnabled = false

        elapse(1, in: fixture)

        #expect(fixture.appState.sessionPhase == .regularIdle)
        #expect(fixture.appState.turnsSinceBreak == 0)
        #expect(fixture.notifications.events.isEmpty)
    }

    @Test("ordinary completion notifies once and returns to regular idle")
    func ordinaryCompletion() {
        let fixture = makeFixture(breakInterval: 2)

        completeRegularTurn(fixture)
        fixture.timerEngine.refresh()

        #expect(fixture.appState.sessionPhase == .regularIdle)
        #expect(fixture.appState.turnsSinceBreak == 1)
        #expect(fixture.notifications.events == [
            .permissionRequested,
            .timerCompleted
        ])
    }
}
