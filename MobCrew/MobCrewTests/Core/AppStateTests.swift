import Testing
import Foundation
@testable import MobCrew

@Suite("AppState Tests")
struct AppStateTests {

    private func makeTestUserDefaults() -> UserDefaults {
        let suiteName = "com.mobcrew.tests.\(UUID().uuidString)"
        return UserDefaults(suiteName: suiteName)!
    }

    private func makeAppState(userDefaults: UserDefaults? = nil) -> AppState {
        let defaults = userDefaults ?? makeTestUserDefaults()
        let persistenceService = PersistenceService(userDefaults: defaults)
        return AppState(persistenceService: persistenceService)
    }

    // MARK: - Initial State

    @Test("initial state has default timer duration")
    func initialStateHasDefaultDuration() {
        let appState = makeAppState()

        #expect(appState.timerDuration == 420) // 7 minutes default
    }

    @Test("initial state has empty roster")
    func initialStateHasEmptyRoster() {
        let appState = makeAppState()

        #expect(appState.roster.activeMobsters.isEmpty)
        #expect(appState.roster.inactiveMobsters.isEmpty)
    }

    @Test("initial state has timer not running")
    func initialStateTimerNotRunning() {
        let appState = makeAppState()

        #expect(appState.timerState.isRunning == false)
    }

    // MARK: - Timer Completion (Task 2)

    @Test("timer completion advances turn")
    func timerCompletionAdvancesTurn() async throws {
        let appState = makeAppState()
        appState.roster.addMobster(name: "Alice")
        appState.roster.addMobster(name: "Bob")

        let initialDriver = appState.roster.driver
        #expect(initialDriver?.name == "Alice")

        appState.timerEngine.reset(duration: 1)
        appState.timerEngine.start()

        try await Task.sleep(for: .milliseconds(1500))

        #expect(appState.roster.driver?.name == "Bob")
    }

    @Test("timer completion resets timer to configured duration")
    func timerCompletionResetsTimer() async throws {
        let appState = makeAppState()
        appState.roster.addMobster(name: "Alice")
        appState.timerDuration = 300

        appState.timerEngine.reset(duration: 1)
        appState.timerEngine.start()

        try await Task.sleep(for: .milliseconds(1500))

        #expect(appState.timerState.secondsRemaining == 300)
        #expect(appState.timerState.totalSeconds == 300)
    }

    @Test("timer completion stops timer")
    func timerCompletionStopsTimer() async throws {
        let appState = makeAppState()
        appState.roster.addMobster(name: "Alice")

        appState.timerEngine.reset(duration: 1)
        appState.timerEngine.start()

        try await Task.sleep(for: .milliseconds(1500))

        #expect(appState.timerEngine.isRunning == false)
    }

    // MARK: - SkipTurn (Task 3)

    @Test("skipTurn advances turn")
    func skipTurnAdvancesTurn() {
        let appState = makeAppState()
        appState.roster.addMobster(name: "Alice")
        appState.roster.addMobster(name: "Bob")

        #expect(appState.roster.driver?.name == "Alice")

        appState.skipTurn()

        #expect(appState.roster.driver?.name == "Bob")
    }

    @Test("skipTurn resets timer to configured duration")
    func skipTurnResetsTimer() {
        let appState = makeAppState()
        appState.roster.addMobster(name: "Alice")
        appState.timerDuration = 600

        appState.timerEngine.reset(duration: 100)

        appState.skipTurn()

        #expect(appState.timerState.secondsRemaining == 600)
        #expect(appState.timerState.totalSeconds == 600)
    }

    @Test("skipTurn starts timer automatically")
    func skipTurnStartsTimer() {
        let appState = makeAppState()
        appState.roster.addMobster(name: "Alice")

        #expect(appState.timerEngine.isRunning == false)

        appState.skipTurn()

        #expect(appState.timerEngine.isRunning == true)

        appState.timerEngine.stop()
    }

    // MARK: - Timer Duration Persistence (Task 4)

    @Test("changing timer duration triggers save")
    func changingTimerDurationTriggersSave() {
        let defaults = makeTestUserDefaults()
        let service = PersistenceService(userDefaults: defaults)
        let appState = AppState(persistenceService: service)

        appState.timerDuration = 900

        let savedDuration = service.loadTimerDuration()
        #expect(savedDuration == 900)
    }

    @Test("timer duration persists across AppState instances")
    func timerDurationPersistsAcrossInstances() {
        let defaults = makeTestUserDefaults()

        let service1 = PersistenceService(userDefaults: defaults)
        let appState1 = AppState(persistenceService: service1)
        appState1.timerDuration = 1200

        let service2 = PersistenceService(userDefaults: defaults)
        let appState2 = AppState(persistenceService: service2)

        #expect(appState2.timerDuration == 1200)
    }

    // MARK: - Roster Persistence (Task 5)

    @Test("saveRoster persists roster state")
    func saveRosterPersistsState() {
        let defaults = makeTestUserDefaults()
        let service = PersistenceService(userDefaults: defaults)
        let appState = AppState(persistenceService: service)

        appState.roster.addMobster(name: "Alice")
        appState.roster.addMobster(name: "Bob")
        appState.saveRoster()

        let loadedRoster = service.loadRoster()
        #expect(loadedRoster.activeMobsters.count == 2)
        #expect(loadedRoster.activeMobsters[0].name == "Alice")
        #expect(loadedRoster.activeMobsters[1].name == "Bob")
    }

    @Test("roster persists across AppState instances")
    func rosterPersistsAcrossInstances() {
        let defaults = makeTestUserDefaults()

        let service1 = PersistenceService(userDefaults: defaults)
        let appState1 = AppState(persistenceService: service1)
        appState1.roster.addMobster(name: "Charlie")
        appState1.saveRoster()

        let service2 = PersistenceService(userDefaults: defaults)
        let appState2 = AppState(persistenceService: service2)

        #expect(appState2.roster.activeMobsters.count == 1)
        #expect(appState2.roster.activeMobsters[0].name == "Charlie")
    }
}
