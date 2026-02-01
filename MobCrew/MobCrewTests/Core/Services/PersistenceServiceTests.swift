import Testing
import Foundation
@testable import MobCrew

@Suite("PersistenceService Tests")
struct PersistenceServiceTests {
    
    private func makeTestUserDefaults() -> UserDefaults {
        let suiteName = "com.mobcrew.tests.\(UUID().uuidString)"
        return UserDefaults(suiteName: suiteName)!
    }
    
    // MARK: - Roster Persistence
    
    @Test("saves and loads roster round-trip")
    func rosterRoundTrip() {
        let defaults = makeTestUserDefaults()
        let service = PersistenceService(userDefaults: defaults)
        
        let roster = Roster(
            activeMobsters: [Mobster(name: "Alice"), Mobster(name: "Bob")],
            inactiveMobsters: [Mobster(name: "Charlie")],
            nextDriverIndex: 1
        )
        
        service.saveRoster(roster)
        let loaded = service.loadRoster()
        
        #expect(loaded.activeMobsters.count == 2)
        #expect(loaded.activeMobsters[0].name == "Alice")
        #expect(loaded.activeMobsters[1].name == "Bob")
        #expect(loaded.inactiveMobsters.count == 1)
        #expect(loaded.inactiveMobsters[0].name == "Charlie")
        #expect(loaded.nextDriverIndex == 1)
    }
    
    @Test("loads empty roster when no data exists")
    func loadsEmptyRosterWhenNoData() {
        let defaults = makeTestUserDefaults()
        let service = PersistenceService(userDefaults: defaults)
        
        let loaded = service.loadRoster()
        
        #expect(loaded.activeMobsters.isEmpty)
        #expect(loaded.inactiveMobsters.isEmpty)
        #expect(loaded.nextDriverIndex == 0)
    }
    
    @Test("preserves mobster IDs across save/load")
    func preservesMobsterIds() {
        let defaults = makeTestUserDefaults()
        let service = PersistenceService(userDefaults: defaults)
        
        let mobster = Mobster(name: "Alice")
        let originalId = mobster.id
        let roster = Roster(activeMobsters: [mobster])
        
        service.saveRoster(roster)
        let loaded = service.loadRoster()
        
        #expect(loaded.activeMobsters[0].id == originalId)
    }
    
    // MARK: - Timer Duration Persistence
    
    @Test("saves and loads timer duration")
    func timerDurationRoundTrip() {
        let defaults = makeTestUserDefaults()
        let service = PersistenceService(userDefaults: defaults)
        
        service.saveTimerDuration(420)
        let loaded = service.loadTimerDuration()
        
        #expect(loaded == 420)
    }
    
    @Test("returns nil for timer duration when no data exists")
    func timerDurationReturnsNilWhenNoData() {
        let defaults = makeTestUserDefaults()
        let service = PersistenceService(userDefaults: defaults)
        
        let loaded = service.loadTimerDuration()
        
        #expect(loaded == nil)
    }
    
    // MARK: - Edge Cases
    
    @Test("handles empty roster")
    func handlesEmptyRoster() {
        let defaults = makeTestUserDefaults()
        let service = PersistenceService(userDefaults: defaults)
        
        let roster = Roster()
        
        service.saveRoster(roster)
        let loaded = service.loadRoster()
        
        #expect(loaded.activeMobsters.isEmpty)
        #expect(loaded.inactiveMobsters.isEmpty)
        #expect(loaded.nextDriverIndex == 0)
    }
    
    @Test("overwrites existing roster data")
    func overwritesExistingRoster() {
        let defaults = makeTestUserDefaults()
        let service = PersistenceService(userDefaults: defaults)
        
        let roster1 = Roster(activeMobsters: [Mobster(name: "Alice")])
        service.saveRoster(roster1)
        
        let roster2 = Roster(activeMobsters: [Mobster(name: "Bob"), Mobster(name: "Charlie")])
        service.saveRoster(roster2)
        
        let loaded = service.loadRoster()
        
        #expect(loaded.activeMobsters.count == 2)
        #expect(loaded.activeMobsters[0].name == "Bob")
    }
}
