import Foundation

struct RegularCycleResolutionReceipt: Codable, Equatable {
    enum Resolution: String, Codable, Equatable {
        case completed
        case skipped
    }

    let cycleID: UUID
    let resolution: Resolution
}

struct PersistedRoster: Codable {
    let activeMobsters: [Mobster]
    let inactiveMobsters: [Mobster]
    let nextDriverIndex: Int
    let lastRegularCycleResolution: RegularCycleResolutionReceipt?

    init(
        activeMobsters: [Mobster],
        inactiveMobsters: [Mobster],
        nextDriverIndex: Int,
        lastRegularCycleResolution: RegularCycleResolutionReceipt? = nil
    ) {
        self.activeMobsters = activeMobsters
        self.inactiveMobsters = inactiveMobsters
        self.nextDriverIndex = nextDriverIndex
        self.lastRegularCycleResolution = lastRegularCycleResolution
    }

    private enum CodingKeys: String, CodingKey {
        case activeMobsters
        case inactiveMobsters
        case nextDriverIndex
        case lastRegularCycleResolution
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        activeMobsters = try container.decode([Mobster].self, forKey: .activeMobsters)
        inactiveMobsters = try container.decode([Mobster].self, forKey: .inactiveMobsters)
        nextDriverIndex = try container.decode(Int.self, forKey: .nextDriverIndex)
        lastRegularCycleResolution = try? container.decode(
            RegularCycleResolutionReceipt.self,
            forKey: .lastRegularCycleResolution
        )
    }
}

enum PersistedSessionTiming: Codable, Equatable {
    case frozen(exactRemaining: TimeInterval)
    case running(wallDeadline: Date)
}

struct PersistedSessionSnapshot: Codable, Equatable {
    static let currentVersion = 1
    static let maximumCycleSeconds = 60 * 60

    let version: Int
    let phase: SessionPhase
    let cycleID: UUID
    let totalSeconds: Int
    let timing: PersistedSessionTiming
    let turnsSinceBreak: Int
}

enum SessionSnapshotLoadResult {
    case missing
    case current(PersistedSessionSnapshot)
    case unknownNewer(rawData: Data)
    case invalid
}

@MainActor
protocol PersistenceServiceProtocol {
    @discardableResult
    func saveRoster(_ roster: Roster) -> Bool
    func loadRoster() -> Roster
    func saveTimerDuration(_ duration: Int)
    func loadTimerDuration() -> Int?
    func saveBreakInterval(_ interval: Int)
    func loadBreakInterval() -> Int?
    func saveBreakDuration(_ duration: Int)
    func loadBreakDuration() -> Int?
    func saveBreaksEnabled(_ enabled: Bool)
    func loadBreaksEnabled() -> Bool?
    func saveNotificationsEnabled(_ enabled: Bool)
    func loadNotificationsEnabled() -> Bool?
    func saveShowTips(_ show: Bool)
    func loadShowTips() -> Bool?
    @discardableResult
    func saveSessionSnapshot(_ snapshot: PersistedSessionSnapshot) -> Bool
    func loadSessionSnapshot() -> SessionSnapshotLoadResult
}

@MainActor
final class PersistenceService: PersistenceServiceProtocol {
    private let userDefaults: UserDefaults
    
    private enum Keys {
        static let roster = "mobcrew.roster"
        static let timerDuration = "mobcrew.timerDuration"
        static let breakInterval = "mobcrew.breakInterval"
        static let breakDuration = "mobcrew.breakDuration"
        static let breaksEnabled = "mobcrew.breaksEnabled"
        static let notificationsEnabled = "mobcrew.notificationsEnabled"
        static let showTips = "mobcrew.showTips"
        static let sessionSnapshot = "mobcrew.sessionSnapshot"
    }
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    // MARK: - Roster Persistence
    
    @discardableResult
    func saveRoster(_ roster: Roster) -> Bool {
        let persisted = PersistedRoster(
            activeMobsters: roster.activeMobsters,
            inactiveMobsters: roster.inactiveMobsters,
            nextDriverIndex: roster.nextDriverIndex,
            lastRegularCycleResolution: roster.lastRegularCycleResolution
        )
        
        do {
            let data = try JSONEncoder().encode(persisted)
            userDefaults.set(data, forKey: Keys.roster)
            return true
        } catch {
            print("Failed to save roster: \(error)")
            return false
        }
    }
    
    func loadRoster() -> Roster {
        guard let data = userDefaults.data(forKey: Keys.roster) else {
            return Roster()
        }
        
        do {
            let persisted = try JSONDecoder().decode(PersistedRoster.self, from: data)
            return Roster(
                activeMobsters: persisted.activeMobsters,
                inactiveMobsters: persisted.inactiveMobsters,
                nextDriverIndex: persisted.nextDriverIndex,
                lastRegularCycleResolution: persisted.lastRegularCycleResolution
            )
        } catch {
            print("Failed to load roster: \(error)")
            return Roster()
        }
    }
    
    // MARK: - Timer Duration Persistence
    
    func saveTimerDuration(_ duration: Int) {
        userDefaults.set(duration, forKey: Keys.timerDuration)
    }
    
    func loadTimerDuration() -> Int? {
        let value = userDefaults.integer(forKey: Keys.timerDuration)
        return value > 0 ? value : nil
    }
    
    // MARK: - Break Settings Persistence
    
    func saveBreakInterval(_ interval: Int) {
        userDefaults.set(interval, forKey: Keys.breakInterval)
    }
    
    func loadBreakInterval() -> Int? {
        let value = userDefaults.integer(forKey: Keys.breakInterval)
        return value > 0 ? value : nil
    }
    
    func saveBreakDuration(_ duration: Int) {
        userDefaults.set(duration, forKey: Keys.breakDuration)
    }
    
    func loadBreakDuration() -> Int? {
        let value = userDefaults.integer(forKey: Keys.breakDuration)
        return value > 0 ? value : nil
    }

    func saveBreaksEnabled(_ enabled: Bool) {
        userDefaults.set(enabled, forKey: Keys.breaksEnabled)
    }

    func loadBreaksEnabled() -> Bool? {
        guard userDefaults.object(forKey: Keys.breaksEnabled) != nil else {
            return nil
        }
        return userDefaults.bool(forKey: Keys.breaksEnabled)
    }
    
    // MARK: - Notifications Settings Persistence
    
    func saveNotificationsEnabled(_ enabled: Bool) {
        userDefaults.set(enabled, forKey: Keys.notificationsEnabled)
    }
    
    func loadNotificationsEnabled() -> Bool? {
        if userDefaults.object(forKey: Keys.notificationsEnabled) == nil {
            return nil
        }
        return userDefaults.bool(forKey: Keys.notificationsEnabled)
    }
    
    // MARK: - Tips Settings Persistence
    
    func saveShowTips(_ show: Bool) {
        userDefaults.set(show, forKey: Keys.showTips)
    }
    
    func loadShowTips() -> Bool? {
        if userDefaults.object(forKey: Keys.showTips) == nil {
            return nil
        }
        return userDefaults.bool(forKey: Keys.showTips)
    }

    // MARK: - Session Snapshot Persistence

    @discardableResult
    func saveSessionSnapshot(_ snapshot: PersistedSessionSnapshot) -> Bool {
        do {
            let data = try JSONEncoder().encode(snapshot)
            userDefaults.set(data, forKey: Keys.sessionSnapshot)
            return true
        } catch {
            print("Failed to save session snapshot: \(error)")
            return false
        }
    }

    func loadSessionSnapshot() -> SessionSnapshotLoadResult {
        guard let data = userDefaults.data(forKey: Keys.sessionSnapshot) else {
            return .missing
        }

        struct VersionEnvelope: Decodable {
            let version: Int
        }

        guard let envelope = try? JSONDecoder().decode(VersionEnvelope.self, from: data) else {
            return .invalid
        }
        if envelope.version > PersistedSessionSnapshot.currentVersion {
            return .unknownNewer(rawData: data)
        }
        guard envelope.version == PersistedSessionSnapshot.currentVersion else {
            return .invalid
        }
        guard let snapshot = try? JSONDecoder().decode(PersistedSessionSnapshot.self, from: data) else {
            return .invalid
        }
        return .current(snapshot)
    }
}
