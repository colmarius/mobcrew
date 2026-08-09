import Testing
import Foundation
@testable import MobCrew

@MainActor
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

    @Test("negative loaded driver index normalizes safely")
    func negativeDriverIndexNormalizes() {
        let alice = Mobster(name: "Alice")
        let bob = Mobster(name: "Bob")
        let charlie = Mobster(name: "Charlie")

        let roster = Roster(
            activeMobsters: [alice, bob, charlie],
            nextDriverIndex: -1
        )

        #expect(roster.nextDriverIndex == 2)
        #expect(roster.driver?.id == charlie.id)
        #expect(roster.navigator?.id == alice.id)
    }

    @Test("oversized loaded driver index normalizes safely")
    func oversizedDriverIndexNormalizes() {
        let alice = Mobster(name: "Alice")
        let bob = Mobster(name: "Bob")
        let charlie = Mobster(name: "Charlie")

        let roster = Roster(
            activeMobsters: [alice, bob, charlie],
            nextDriverIndex: 8
        )

        #expect(roster.nextDriverIndex == 2)
        #expect(roster.driver?.id == charlie.id)
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

    @Test("addMobster with empty name still adds mobster")
    func addMobsterEmptyNameAdds() {
        let roster = Roster()
        roster.addMobster(name: "")

        #expect(roster.activeMobsters.count == 1)
        #expect(roster.activeMobsters.first?.name == "")
    }

    @Test("addMobster with whitespace-only name still adds mobster")
    func addMobsterWhitespaceNameAdds() {
        let roster = Roster()
        roster.addMobster(name: "   ")

        #expect(roster.activeMobsters.count == 1)
        #expect(roster.activeMobsters.first?.name == "   ")
    }

    @Test("addMobster with duplicate name creates separate mobsters with different IDs")
    func addMobsterDuplicateNameCreatesSeparate() {
        let roster = Roster()
        roster.addMobster(name: "Alice")
        roster.addMobster(name: "Alice")

        #expect(roster.activeMobsters.count == 2)
        #expect(roster.activeMobsters[0].name == "Alice")
        #expect(roster.activeMobsters[1].name == "Alice")
        #expect(roster.activeMobsters[0].id != roster.activeMobsters[1].id)
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

    @Test("rotateIn preserves the current driver")
    func rotateInPreservesCurrentDriver() {
        let alice = Mobster(name: "Alice")
        let bob = Mobster(name: "Bob")
        let charlie = Mobster(name: "Charlie")
        let roster = Roster(
            activeMobsters: [alice, bob],
            inactiveMobsters: [charlie],
            nextDriverIndex: 1
        )

        roster.rotateIn(at: 0)

        #expect(roster.driver?.id == bob.id)
        #expect(roster.activeMobsters.map(\.id) == [alice.id, bob.id, charlie.id])
        #expect(roster.inactiveMobsters.isEmpty)
    }

    // MARK: - Permanent Removal

    @Test("removing before the current driver preserves driver identity")
    func removeBeforeCurrentDriver() {
        let alice = Mobster(name: "Alice")
        let bob = Mobster(name: "Bob")
        let charlie = Mobster(name: "Charlie")
        let dave = Mobster(name: "Dave")
        let roster = Roster(
            activeMobsters: [alice, bob, charlie, dave],
            nextDriverIndex: 2
        )

        roster.removeActiveMobster(at: 0)

        #expect(roster.activeMobsters.map(\.id) == [bob.id, charlie.id, dave.id])
        #expect(roster.driver?.id == charlie.id)
        #expect(roster.nextDriverIndex == 1)
    }

    @Test("removing the current driver selects the next active participant")
    func removeCurrentDriver() {
        let alice = Mobster(name: "Alice")
        let bob = Mobster(name: "Bob")
        let charlie = Mobster(name: "Charlie")
        let dave = Mobster(name: "Dave")
        let roster = Roster(
            activeMobsters: [alice, bob, charlie, dave],
            nextDriverIndex: 2
        )

        roster.removeActiveMobster(at: 2)

        #expect(roster.activeMobsters.map(\.id) == [alice.id, bob.id, dave.id])
        #expect(roster.driver?.id == dave.id)
        #expect(roster.nextDriverIndex == 2)
    }

    @Test("removing the last current driver wraps to the first participant")
    func removeLastCurrentDriver() {
        let alice = Mobster(name: "Alice")
        let bob = Mobster(name: "Bob")
        let charlie = Mobster(name: "Charlie")
        let roster = Roster(
            activeMobsters: [alice, bob, charlie],
            nextDriverIndex: 2
        )

        roster.removeActiveMobster(at: 2)

        #expect(roster.driver?.id == alice.id)
        #expect(roster.nextDriverIndex == 0)
    }

    @Test("removing after the current driver preserves driver identity")
    func removeAfterCurrentDriver() {
        let alice = Mobster(name: "Alice")
        let bob = Mobster(name: "Bob")
        let charlie = Mobster(name: "Charlie")
        let roster = Roster(
            activeMobsters: [alice, bob, charlie],
            nextDriverIndex: 1
        )

        roster.removeActiveMobster(at: 2)

        #expect(roster.activeMobsters.map(\.id) == [alice.id, bob.id])
        #expect(roster.driver?.id == bob.id)
        #expect(roster.nextDriverIndex == 1)
    }

    @Test("removing the only active participant resets safely")
    func removeOnlyActiveParticipant() {
        let roster = Roster(activeMobsters: [Mobster(name: "Alice")])

        roster.removeActiveMobster(at: 0)

        #expect(roster.activeMobsters.isEmpty)
        #expect(roster.driver == nil)
        #expect(roster.navigator == nil)
        #expect(roster.nextDriverIndex == 0)
    }

    @Test("removing an inactive participant does not affect active roles")
    func removeInactiveParticipant() {
        let alice = Mobster(name: "Alice")
        let bob = Mobster(name: "Bob")
        let charlie = Mobster(name: "Charlie")
        let roster = Roster(
            activeMobsters: [alice, bob],
            inactiveMobsters: [charlie],
            nextDriverIndex: 1
        )

        roster.removeInactiveMobster(at: 0)

        #expect(roster.inactiveMobsters.isEmpty)
        #expect(roster.driver?.id == bob.id)
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

    @Test("benchMobster benching current driver promotes next mobster to driver")
    func benchMobsterCurrentDriverPromotesNext() {
        let alice = Mobster(name: "Alice")
        let bob = Mobster(name: "Bob")
        let charlie = Mobster(name: "Charlie")
        let roster = Roster(activeMobsters: [alice, bob, charlie], nextDriverIndex: 0)

        #expect(roster.driver?.id == alice.id)

        roster.benchMobster(at: 0)

        #expect(roster.driver?.id == bob.id)
        #expect(roster.navigator?.id == charlie.id)
    }

    @Test("benchMobster benching last active mobster results in no driver")
    func benchMobsterLastActiveNoDriver() {
        let alice = Mobster(name: "Alice")
        let roster = Roster(activeMobsters: [alice])

        #expect(roster.driver?.id == alice.id)

        roster.benchMobster(at: 0)

        #expect(roster.driver == nil)
        #expect(roster.navigator == nil)
    }

    // MARK: - moveMobster

    @Test("moveMobster reorders active mobsters")
    func moveMobsterReordersActive() {
        let alice = Mobster(name: "Alice")
        let bob = Mobster(name: "Bob")
        let charlie = Mobster(name: "Charlie")
        let roster = Roster(activeMobsters: [alice, bob, charlie])

        roster.moveMobster(from: IndexSet(integer: 2), to: 0)

        #expect(roster.activeMobsters[0].id == charlie.id)
        #expect(roster.activeMobsters[1].id == alice.id)
        #expect(roster.activeMobsters[2].id == bob.id)
    }

    @Test("moveMobster preserves current driver identity")
    func moveMobsterPreservesCurrentDriver() {
        let alice = Mobster(name: "Alice")
        let bob = Mobster(name: "Bob")
        let charlie = Mobster(name: "Charlie")
        let roster = Roster(
            activeMobsters: [alice, bob, charlie],
            nextDriverIndex: 1
        )

        roster.moveMobster(from: IndexSet(integer: 2), to: 0)

        #expect(roster.activeMobsters.map(\.id) == [charlie.id, alice.id, bob.id])
        #expect(roster.driver?.id == bob.id)
        #expect(roster.nextDriverIndex == 2)
    }

    @Test("moveMobster updates navigator relative to preserved driver")
    func moveMobsterUpdatesNavigator() {
        let alice = Mobster(name: "Alice")
        let bob = Mobster(name: "Bob")
        let charlie = Mobster(name: "Charlie")
        let roster = Roster(
            activeMobsters: [alice, bob, charlie],
            nextDriverIndex: 1
        )

        roster.moveMobster(from: IndexSet(integer: 2), to: 0)

        #expect(roster.driver?.id == bob.id)
        #expect(roster.navigator?.id == charlie.id)
    }

    @Test("keyboard move up reorders one position and preserves driver identity")
    func moveActiveMobsterUpPreservesDriver() {
        let alice = Mobster(name: "Alice")
        let bob = Mobster(name: "Bob")
        let charlie = Mobster(name: "Charlie")
        let roster = Roster(
            activeMobsters: [alice, bob, charlie],
            nextDriverIndex: 1
        )

        roster.moveActiveMobster(at: 2, to: 1)

        #expect(roster.activeMobsters.map(\.id) == [alice.id, charlie.id, bob.id])
        #expect(roster.driver?.id == bob.id)
        #expect(roster.navigator?.id == alice.id)
    }

    @Test("keyboard move down reorders one position and preserves driver identity")
    func moveActiveMobsterDownPreservesDriver() {
        let alice = Mobster(name: "Alice")
        let bob = Mobster(name: "Bob")
        let charlie = Mobster(name: "Charlie")
        let roster = Roster(
            activeMobsters: [alice, bob, charlie],
            nextDriverIndex: 2
        )

        roster.moveActiveMobster(at: 0, to: 1)

        #expect(roster.activeMobsters.map(\.id) == [bob.id, alice.id, charlie.id])
        #expect(roster.driver?.id == charlie.id)
        #expect(roster.navigator?.id == bob.id)
    }

    @Test("keyboard move rejects non-adjacent and out-of-range destinations")
    func moveActiveMobsterRejectsInvalidDestinations() {
        let alice = Mobster(name: "Alice")
        let bob = Mobster(name: "Bob")
        let charlie = Mobster(name: "Charlie")
        let roster = Roster(activeMobsters: [alice, bob, charlie])

        roster.moveActiveMobster(at: 0, to: 2)
        roster.moveActiveMobster(at: 0, to: -1)
        roster.moveActiveMobster(at: 2, to: 3)

        #expect(roster.activeMobsters.map(\.id) == [alice.id, bob.id, charlie.id])
        #expect(roster.driver?.id == alice.id)
    }

    // MARK: - shuffle

    @Test("shuffle preserves members and establishes the first participant as driver")
    func shuffleEstablishesFirstDriver() {
        let mobsters = (1...10).map { Mobster(name: "Mobster \($0)") }
        let roster = Roster(activeMobsters: mobsters, nextDriverIndex: 5)

        roster.shuffle()

        #expect(Set(roster.activeMobsters.map(\.id)) == Set(mobsters.map(\.id)))
        #expect(roster.nextDriverIndex == 0)
        #expect(roster.driver?.id == roster.activeMobsters.first?.id)
    }

    @Test("shuffle resets nextDriverIndex to 0")
    func shuffleResetsDriverIndex() {
        let roster = Roster(activeMobsters: [Mobster(name: "Alice"), Mobster(name: "Bob")], nextDriverIndex: 1)

        roster.shuffle()

        #expect(roster.nextDriverIndex == 0)
    }

    @Test("shuffle with 0 mobsters is no-op")
    func shuffleEmptyIsNoOp() {
        let roster = Roster()

        roster.shuffle()

        #expect(roster.activeMobsters.isEmpty)
        #expect(roster.nextDriverIndex == 0)
    }

    @Test("shuffle with 1 mobster keeps order unchanged")
    func shuffleSingleMobsterKeepsOrder() {
        let alice = Mobster(name: "Alice")
        let roster = Roster(activeMobsters: [alice])

        roster.shuffle()

        #expect(roster.activeMobsters.count == 1)
        #expect(roster.activeMobsters.first?.id == alice.id)
    }

    @Test("shuffle does not affect inactive mobsters")
    func shuffleDoesNotAffectInactive() {
        let alice = Mobster(name: "Alice")
        let bob = Mobster(name: "Bob")
        let inactiveCharlie = Mobster(name: "Charlie")
        let inactiveDave = Mobster(name: "Dave")
        let roster = Roster(activeMobsters: [alice, bob], inactiveMobsters: [inactiveCharlie, inactiveDave])
        let inactiveOrderBefore = roster.inactiveMobsters.map(\.id)

        roster.shuffle()

        let inactiveOrderAfter = roster.inactiveMobsters.map(\.id)
        #expect(inactiveOrderAfter == inactiveOrderBefore, "Inactive mobsters should remain in same order")
    }

    // MARK: - Mutation Persistence Hook

    @Test("compound and invalid mutations notify once only after invariants are restored")
    func mutationHandlerObservesFinalStateOnce() {
        let alice = Mobster(name: "Alice")
        let bob = Mobster(name: "Bob")
        let roster = Roster(activeMobsters: [alice, bob])
        var observedStates: [([UUID], [UUID])] = []
        roster.setMutationHandler {
            observedStates.append((
                roster.activeMobsters.map(\.id),
                roster.inactiveMobsters.map(\.id)
            ))
        }

        roster.benchMobster(at: 0)
        roster.benchMobster(at: 99)

        #expect(observedStates.count == 1)
        #expect(observedStates[0].0 == [bob.id])
        #expect(observedStates[0].1 == [alice.id])
    }

    @Test("regular cycle resolution stores its receipt with the role advance")
    func regularCycleResolutionIsAtomicMutation() {
        let alice = Mobster(name: "Alice")
        let bob = Mobster(name: "Bob")
        let roster = Roster(activeMobsters: [alice, bob])
        let cycleID = UUID()
        var mutationCount = 0
        roster.setMutationHandler {
            mutationCount += 1
        }

        roster.resolveRegularCycle(
            id: cycleID,
            resolution: .completed,
            advanceRoles: true
        )

        #expect(mutationCount == 1)
        #expect(roster.driver?.id == bob.id)
        #expect(roster.lastRegularCycleResolution == RegularCycleResolutionReceipt(
            cycleID: cycleID,
            resolution: .completed
        ))
    }
}
