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
}
