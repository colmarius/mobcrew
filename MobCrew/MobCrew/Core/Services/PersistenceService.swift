import Foundation

struct PersistedRoster: Codable {
    let activeMobsters: [Mobster]
    let inactiveMobsters: [Mobster]
    let nextDriverIndex: Int
}

final class PersistenceService {
    private let userDefaults: UserDefaults
    
    private enum Keys {
        static let roster = "mobcrew.roster"
        static let timerDuration = "mobcrew.timerDuration"
    }
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    // MARK: - Roster Persistence
    
    func saveRoster(_ roster: Roster) {
        let persisted = PersistedRoster(
            activeMobsters: roster.activeMobsters,
            inactiveMobsters: roster.inactiveMobsters,
            nextDriverIndex: roster.nextDriverIndex
        )
        
        do {
            let data = try JSONEncoder().encode(persisted)
            userDefaults.set(data, forKey: Keys.roster)
        } catch {
            print("Failed to save roster: \(error)")
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
                nextDriverIndex: persisted.nextDriverIndex
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
}
