import Testing
import Foundation
@testable import MobCrew

@MainActor
private final class BreakNotificationSpy: NotificationServiceProtocol {
    enum Event: Equatable {
        case permissionRequested
        case timerCompleted
        case breakDue(duration: Int)
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
}

@MainActor
private final class BreakActiveMobstersWriterSpy: ActiveMobstersFileServiceProtocol {
    var writeCount = 0

    func writeActiveMobsters(_ roster: Roster) {
        writeCount += 1
    }
}

@MainActor
@Suite("Break Logic Tests")
struct BreakLogicTests {
    private struct Fixture {
        let appState: AppState
        let timerEngine: TimerEngine
        let notifications: BreakNotificationSpy
        let activeMobstersWriter: BreakActiveMobstersWriterSpy
    }

    private func makeFixture(
        breakInterval: Int = 1,
        breakDuration: Int = 60
    ) -> Fixture {
        let suiteName = "com.mobcrew.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let persistenceService = PersistenceService(userDefaults: defaults)
        persistenceService.saveTimerDuration(1)
        let timerEngine = TimerEngine()
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
            activeMobstersWriter: activeMobstersWriter
        )
    }

    private func completeRegularTurn(_ fixture: Fixture) {
        fixture.appState.startTimer()
        fixture.timerEngine.processTick()
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

            fixture.appState.skipBreak()

            #expect(fixture.appState.sessionPhase == .regularIdle)
            #expect(fixture.appState.roster.driver?.id == driverID)
            #expect(fixture.activeMobstersWriter.writeCount == writeCount)
            #expect(fixture.appState.turnsSinceBreak == 0)
            #expect(fixture.appState.timerState.secondsRemaining == fixture.appState.timerDuration)
            #expect(fixture.timerEngine.isRunning == false)
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

        fixture.timerEngine.processTick()
        fixture.timerEngine.processTick()

        #expect(fixture.appState.sessionPhase == .regularIdle)
        #expect(fixture.appState.turnsSinceBreak == 0)
        #expect(fixture.appState.roster.driver?.id == driverAfterRegularCompletion)
        #expect(fixture.activeMobstersWriter.writeCount == writesAfterRegularCompletion)
        #expect(fixture.appState.timerState.secondsRemaining == fixture.appState.timerDuration)
        #expect(fixture.timerEngine.isRunning == false)
    }

    @Test("ordinary completion notifies once and returns to regular idle")
    func ordinaryCompletion() {
        let fixture = makeFixture(breakInterval: 2)

        completeRegularTurn(fixture)
        fixture.timerEngine.processTick()

        #expect(fixture.appState.sessionPhase == .regularIdle)
        #expect(fixture.appState.turnsSinceBreak == 1)
        #expect(fixture.notifications.events == [
            .permissionRequested,
            .timerCompleted
        ])
    }
}
