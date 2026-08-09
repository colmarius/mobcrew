import Foundation

@Observable
final class Roster {
    private(set) var activeMobsters: [Mobster]
    private(set) var inactiveMobsters: [Mobster]
    private(set) var nextDriverIndex: Int

    init(activeMobsters: [Mobster] = [], inactiveMobsters: [Mobster] = [], nextDriverIndex: Int = 0) {
        self.activeMobsters = activeMobsters
        self.inactiveMobsters = inactiveMobsters
        self.nextDriverIndex = Self.normalizedIndex(nextDriverIndex, count: activeMobsters.count)
    }

    var driver: Mobster? {
        guard !activeMobsters.isEmpty else { return nil }
        return activeMobsters[nextDriverIndex]
    }

    var navigator: Mobster? {
        guard activeMobsters.count >= 2 else { return nil }
        let index = (nextDriverIndex + 1) % activeMobsters.count
        return activeMobsters[index]
    }

    func advanceTurn() {
        guard !activeMobsters.isEmpty else { return }
        nextDriverIndex = (nextDriverIndex + 1) % activeMobsters.count
    }

    func addMobster(name: String) {
        let mobster = Mobster(name: name)
        activeMobsters.append(mobster)
    }

    func benchMobster(at index: Int) {
        guard let mobster = removeActiveMobster(at: index) else { return }
        inactiveMobsters.append(mobster)
    }

    func rotateIn(at index: Int) {
        guard inactiveMobsters.indices.contains(index) else { return }
        let currentDriverID = driver?.id
        let mobster = inactiveMobsters.remove(at: index)
        activeMobsters.append(mobster)
        restoreDriver(withID: currentDriverID)
    }

    @discardableResult
    func removeActiveMobster(at index: Int) -> Mobster? {
        guard activeMobsters.indices.contains(index) else { return nil }
        let currentDriverID = driver?.id
        let removingCurrentDriver = activeMobsters[index].id == currentDriverID
        let mobster = activeMobsters.remove(at: index)

        guard !activeMobsters.isEmpty else {
            nextDriverIndex = 0
            return mobster
        }

        if removingCurrentDriver {
            nextDriverIndex = Self.normalizedIndex(index, count: activeMobsters.count)
        } else {
            restoreDriver(withID: currentDriverID)
        }
        return mobster
    }

    @discardableResult
    func removeInactiveMobster(at index: Int) -> Mobster? {
        guard inactiveMobsters.indices.contains(index) else { return nil }
        return inactiveMobsters.remove(at: index)
    }

    func shuffle() {
        activeMobsters.shuffle()
        nextDriverIndex = 0
    }
    
    func moveMobster(from source: IndexSet, to destination: Int) {
        guard !source.isEmpty else { return }
        guard source.allSatisfy({ activeMobsters.indices.contains($0) }) else { return }
        guard (0...activeMobsters.count).contains(destination) else { return }
        let currentDriverID = driver?.id
        activeMobsters.move(fromOffsets: source, toOffset: destination)
        restoreDriver(withID: currentDriverID)
    }

    private func restoreDriver(withID driverID: UUID?) {
        guard let driverID else {
            nextDriverIndex = 0
            return
        }
        if let index = activeMobsters.firstIndex(where: { $0.id == driverID }) {
            nextDriverIndex = index
        } else {
            nextDriverIndex = Self.normalizedIndex(nextDriverIndex, count: activeMobsters.count)
        }
    }

    private static func normalizedIndex(_ index: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        let remainder = index % count
        return remainder >= 0 ? remainder : remainder + count
    }
}
