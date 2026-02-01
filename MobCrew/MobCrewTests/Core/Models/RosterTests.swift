import Testing
import Foundation
@testable import MobCrew

@Suite("Roster Tests")
struct RosterTests {
    
    // MARK: - Driver/Navigator Computed Properties
    
    @Test("driver returns nil when no active mobsters")
    func driverReturnsNilWhenEmpty() {
        let roster = Roster()
        #expect(roster.driver == nil)
    }
    
    @Test("driver returns first mobster at index 0")
    func driverReturnsFirstMobster() {
        let alice = Mobster(name: "Alice")
        let bob = Mobster(name: "Bob")
        let roster = Roster(activeMobsters: [alice, bob])
        
        #expect(roster.driver?.id == alice.id)
    }
    
    @Test("navigator returns nil when less than 2 active mobsters")
    func navigatorReturnsNilWhenTooFew() {
        let roster = Roster(activeMobsters: [Mobster(name: "Alice")])
        #expect(roster.navigator == nil)
    }
    
    @Test("navigator returns second mobster after driver")
    func navigatorReturnsSecondMobster() {
        let alice = Mobster(name: "Alice")
        let bob = Mobster(name: "Bob")
        let roster = Roster(activeMobsters: [alice, bob])
        
        #expect(roster.navigator?.id == bob.id)
    }
    
    @Test("driver and navigator wrap around correctly")
    func driverNavigatorWrapAround() {
        let alice = Mobster(name: "Alice")
        let bob = Mobster(name: "Bob")
        let charlie = Mobster(name: "Charlie")
        let roster = Roster(activeMobsters: [alice, bob, charlie], nextDriverIndex: 2)
        
        #expect(roster.driver?.id == charlie.id)
        #expect(roster.navigator?.id == alice.id)
    }
    
    // MARK: - advanceTurn()
    
    @Test("advanceTurn increments driver index")
    func advanceTurnIncrementsIndex() {
        let roster = Roster(activeMobsters: [Mobster(name: "Alice"), Mobster(name: "Bob")])
        #expect(roster.nextDriverIndex == 0)
        
        roster.advanceTurn()
        #expect(roster.nextDriverIndex == 1)
    }
    
    @Test("advanceTurn wraps around to 0")
    func advanceTurnWrapsAround() {
        let roster = Roster(activeMobsters: [Mobster(name: "Alice"), Mobster(name: "Bob")], nextDriverIndex: 1)
        
        roster.advanceTurn()
        #expect(roster.nextDriverIndex == 0)
    }
    
    @Test("advanceTurn does nothing when empty")
    func advanceTurnEmptyDoesNothing() {
        let roster = Roster()
        roster.advanceTurn()
        #expect(roster.nextDriverIndex == 0)
    }
    
    // MARK: - addMobster
    
    @Test("addMobster appends to active mobsters")
    func addMobsterAppendsToActive() {
        let roster = Roster()
        roster.addMobster(name: "Alice")
        
        #expect(roster.activeMobsters.count == 1)
        #expect(roster.activeMobsters.first?.name == "Alice")
    }
    
    // MARK: - benchMobster
    
    @Test("benchMobster moves mobster to inactive")
    func benchMobsterMovesToInactive() {
        let alice = Mobster(name: "Alice")
        let bob = Mobster(name: "Bob")
        let roster = Roster(activeMobsters: [alice, bob])
        
        roster.benchMobster(at: 0)
        
        #expect(roster.activeMobsters.count == 1)
        #expect(roster.inactiveMobsters.count == 1)
        #expect(roster.inactiveMobsters.first?.id == alice.id)
    }
    
    @Test("benchMobster with invalid index does nothing")
    func benchMobsterInvalidIndexDoesNothing() {
        let roster = Roster(activeMobsters: [Mobster(name: "Alice")])
        roster.benchMobster(at: 5)
        
        #expect(roster.activeMobsters.count == 1)
        #expect(roster.inactiveMobsters.isEmpty)
    }
    
    // MARK: - rotateIn
    
    @Test("rotateIn moves mobster from inactive to active")
    func rotateInMovesToActive() {
        let alice = Mobster(name: "Alice")
        let roster = Roster(inactiveMobsters: [alice])
        
        roster.rotateIn(at: 0)
        
        #expect(roster.activeMobsters.count == 1)
        #expect(roster.inactiveMobsters.isEmpty)
        #expect(roster.activeMobsters.first?.id == alice.id)
    }
    
    @Test("rotateIn with invalid index does nothing")
    func rotateInInvalidIndexDoesNothing() {
        let roster = Roster(inactiveMobsters: [Mobster(name: "Alice")])
        roster.rotateIn(at: 5)
        
        #expect(roster.inactiveMobsters.count == 1)
        #expect(roster.activeMobsters.isEmpty)
    }
    
    // MARK: - Driver Index Adjustment
    
    @Test("benchMobster adjusts driver index when removing before current driver")
    func benchMobsterAdjustsIndexBeforeCurrent() {
        let alice = Mobster(name: "Alice")
        let bob = Mobster(name: "Bob")
        let charlie = Mobster(name: "Charlie")
        let roster = Roster(activeMobsters: [alice, bob, charlie], nextDriverIndex: 2)
        
        roster.benchMobster(at: 0)
        
        #expect(roster.nextDriverIndex == 1)
        #expect(roster.driver?.id == charlie.id)
    }
    
    @Test("benchMobster adjusts driver index to 0 when all removed")
    func benchMobsterResetIndexWhenEmpty() {
        let roster = Roster(activeMobsters: [Mobster(name: "Alice")])
        roster.benchMobster(at: 0)
        
        #expect(roster.nextDriverIndex == 0)
        #expect(roster.activeMobsters.isEmpty)
    }
    
    @Test("benchMobster wraps driver index when at end")
    func benchMobsterWrapsIndexAtEnd() {
        let alice = Mobster(name: "Alice")
        let bob = Mobster(name: "Bob")
        let roster = Roster(activeMobsters: [alice, bob], nextDriverIndex: 1)
        
        roster.benchMobster(at: 1)
        
        #expect(roster.nextDriverIndex == 0)
    }
}
