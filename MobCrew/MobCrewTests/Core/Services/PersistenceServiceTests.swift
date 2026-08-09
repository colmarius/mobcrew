import Testing
import Foundation
@testable import MobCrew

@MainActor
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

    @Test("normalizes malformed negative driver index while loading")
    func normalizesNegativeLoadedDriverIndex() throws {
        let defaults = makeTestUserDefaults()
        let service = PersistenceService(userDefaults: defaults)
        let mobsters = [Mobster(name: "Alice"), Mobster(name: "Bob"), Mobster(name: "Charlie")]
        let persisted = PersistedRoster(
            activeMobsters: mobsters,
            inactiveMobsters: [],
            nextDriverIndex: -1
        )
        defaults.set(try JSONEncoder().encode(persisted), forKey: "mobcrew.roster")

        let loaded = service.loadRoster()

        #expect(loaded.nextDriverIndex == 2)
        #expect(loaded.driver?.id == mobsters[2].id)
    }

    @Test("normalizes malformed oversized driver index while loading")
    func normalizesOversizedLoadedDriverIndex() throws {
        let defaults = makeTestUserDefaults()
        let service = PersistenceService(userDefaults: defaults)
        let mobsters = [Mobster(name: "Alice"), Mobster(name: "Bob"), Mobster(name: "Charlie")]
        let persisted = PersistedRoster(
            activeMobsters: mobsters,
            inactiveMobsters: [],
            nextDriverIndex: 8
        )
        defaults.set(try JSONEncoder().encode(persisted), forKey: "mobcrew.roster")

        let loaded = service.loadRoster()

        #expect(loaded.nextDriverIndex == 2)
        #expect(loaded.driver?.id == mobsters[2].id)
    }

    @Test("normalized roster remains stable across persistence round trips")
    func normalizedRosterRoundTrip() {
        let defaults = makeTestUserDefaults()
        let service = PersistenceService(userDefaults: defaults)
        let mobsters = [Mobster(name: "Alice"), Mobster(name: "Bob"), Mobster(name: "Charlie")]
        let roster = Roster(activeMobsters: mobsters, nextDriverIndex: -4)

        service.saveRoster(roster)
        let loaded = service.loadRoster()

        #expect(roster.nextDriverIndex == 2)
        #expect(loaded.nextDriverIndex == 2)
        #expect(loaded.driver?.id == mobsters[2].id)
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

    // MARK: - Break Settings Persistence

    @Test("saves and loads break interval")
    func breakIntervalRoundTrip() {
        let defaults = makeTestUserDefaults()
        let service = PersistenceService(userDefaults: defaults)

        service.saveBreakInterval(3)
        let loaded = service.loadBreakInterval()

        #expect(loaded == 3)
    }

    @Test("returns nil for break interval when no data exists")
    func breakIntervalReturnsNilWhenNoData() {
        let defaults = makeTestUserDefaults()
        let service = PersistenceService(userDefaults: defaults)

        let loaded = service.loadBreakInterval()

        #expect(loaded == nil)
    }

    @Test("saves and loads break duration")
    func breakDurationRoundTrip() {
        let defaults = makeTestUserDefaults()
        let service = PersistenceService(userDefaults: defaults)

        service.saveBreakDuration(600)
        let loaded = service.loadBreakDuration()

        #expect(loaded == 600)
    }

    @Test("returns nil for break duration when no data exists")
    func breakDurationReturnsNilWhenNoData() {
        let defaults = makeTestUserDefaults()
        let service = PersistenceService(userDefaults: defaults)

        let loaded = service.loadBreakDuration()

        #expect(loaded == nil)
    }

    @Test("saves and loads whether breaks are enabled")
    func breaksEnabledRoundTrip() {
        let defaults = makeTestUserDefaults()
        let service = PersistenceService(userDefaults: defaults)

        service.saveBreaksEnabled(false)
        #expect(service.loadBreaksEnabled() == false)

        service.saveBreaksEnabled(true)
        #expect(service.loadBreaksEnabled() == true)
    }

    @Test("returns nil for breaks enabled when no setting exists")
    func breaksEnabledReturnsNilWhenNoData() {
        let defaults = makeTestUserDefaults()
        let service = PersistenceService(userDefaults: defaults)

        #expect(service.loadBreaksEnabled() == nil)
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

    // MARK: - Session Snapshot Persistence

    @Test("session snapshots round-trip every authoritative phase")
    func sessionSnapshotRoundTripsEveryPhase() {
        let defaults = makeTestUserDefaults()
        let service = PersistenceService(userDefaults: defaults)
        let deadline = Date(timeIntervalSinceReferenceDate: 2_000)

        for phase in SessionPhase.allCases {
            let timing: PersistedSessionTiming = phase.isRunning
                ? .running(wallDeadline: deadline)
                : .frozen(exactRemaining: 42.25)
            let snapshot = PersistedSessionSnapshot(
                version: PersistedSessionSnapshot.currentVersion,
                phase: phase,
                cycleID: UUID(),
                totalSeconds: 60,
                timing: timing,
                turnsSinceBreak: 3
            )

            #expect(service.saveSessionSnapshot(snapshot))
            guard case .current(let loaded) = service.loadSessionSnapshot() else {
                Issue.record("Expected current session snapshot for \(phase)")
                continue
            }
            #expect(loaded == snapshot)
        }
    }

    @Test("session snapshot loader distinguishes missing corrupt and unknown newer data")
    func sessionSnapshotLoadClassification() throws {
        let defaults = makeTestUserDefaults()
        let service = PersistenceService(userDefaults: defaults)

        guard case .missing = service.loadSessionSnapshot() else {
            Issue.record("Expected missing snapshot")
            return
        }

        defaults.set(Data("not json".utf8), forKey: "mobcrew.sessionSnapshot")
        guard case .invalid = service.loadSessionSnapshot() else {
            Issue.record("Expected invalid snapshot")
            return
        }

        let newerData = try JSONSerialization.data(withJSONObject: [
            "version": PersistedSessionSnapshot.currentVersion + 1,
            "future": "preserve me"
        ])
        defaults.set(newerData, forKey: "mobcrew.sessionSnapshot")
        guard case .unknownNewer(let rawData) = service.loadSessionSnapshot() else {
            Issue.record("Expected unknown newer snapshot")
            return
        }
        #expect(rawData == newerData)
    }

    @Test("session snapshot loader rejects missing timing and unknown phase")
    func sessionSnapshotRejectsIncompleteOrUnknownState() throws {
        let defaults = makeTestUserDefaults()
        let service = PersistenceService(userDefaults: defaults)
        let cycleID = UUID().uuidString
        let invalidPayloads: [[String: Any]] = [
            [
                "version": PersistedSessionSnapshot.currentVersion,
                "phase": "regularRunning",
                "cycleID": cycleID,
                "totalSeconds": 60,
                "turnsSinceBreak": 0
            ],
            [
                "version": PersistedSessionSnapshot.currentVersion,
                "phase": "futurePhase",
                "cycleID": cycleID,
                "totalSeconds": 60,
                "timing": ["frozen": ["exactRemaining": 60]],
                "turnsSinceBreak": 0
            ]
        ]

        for payload in invalidPayloads {
            defaults.set(
                try JSONSerialization.data(withJSONObject: payload),
                forKey: "mobcrew.sessionSnapshot"
            )
            guard case .invalid = service.loadSessionSnapshot() else {
                Issue.record("Expected invalid snapshot for payload \(payload)")
                continue
            }
        }
    }

    @Test("roster receipt round-trips and remains optional for old data")
    func rosterReceiptRoundTripsAndRemainsOptional() throws {
        let defaults = makeTestUserDefaults()
        let service = PersistenceService(userDefaults: defaults)
        let cycleID = UUID()
        let roster = Roster(
            activeMobsters: [Mobster(name: "Alice"), Mobster(name: "Bob")],
            lastRegularCycleResolution: RegularCycleResolutionReceipt(
                cycleID: cycleID,
                resolution: .completed
            )
        )

        service.saveRoster(roster)
        #expect(service.loadRoster().lastRegularCycleResolution?.cycleID == cycleID)

        let oldRosterJSON: [String: Any] = [
            "activeMobsters": [],
            "inactiveMobsters": [],
            "nextDriverIndex": 0
        ]
        defaults.set(
            try JSONSerialization.data(withJSONObject: oldRosterJSON),
            forKey: "mobcrew.roster"
        )
        #expect(service.loadRoster().lastRegularCycleResolution == nil)
    }

    @Test("malformed optional receipt does not erase a valid roster")
    func malformedOptionalReceiptDoesNotEraseValidRoster() throws {
        let defaults = makeTestUserDefaults()
        let service = PersistenceService(userDefaults: defaults)
        let roster = Roster(activeMobsters: [Mobster(name: "Alice")])
        service.saveRoster(roster)
        let data = defaults.data(forKey: "mobcrew.roster")!
        var json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        json["lastRegularCycleResolution"] = ["resolution": "unknown"]
        defaults.set(
            try JSONSerialization.data(withJSONObject: json),
            forKey: "mobcrew.roster"
        )

        let loaded = service.loadRoster()

        #expect(loaded.activeMobsters.map(\.name) == ["Alice"])
        #expect(loaded.lastRegularCycleResolution == nil)
    }
}
