import Foundation

@MainActor
@Observable
final class Roster {
    private(set) var activeMobsters: [Mobster]
    private(set) var inactiveMobsters: [Mobster]
    private(set) var nextDriverIndex: Int
    private(set) var lastRegularCycleResolution: RegularCycleResolutionReceipt?
    private var onDidMutate: (() -> Void)?

    init(
        activeMobsters: [Mobster] = [],
        inactiveMobsters: [Mobster] = [],
        nextDriverIndex: Int = 0,
        lastRegularCycleResolution: RegularCycleResolutionReceipt? = nil
    ) {
        self.activeMobsters = activeMobsters
        self.inactiveMobsters = inactiveMobsters
        self.nextDriverIndex = Self.normalizedIndex(nextDriverIndex, count: activeMobsters.count)
        self.lastRegularCycleResolution = lastRegularCycleResolution
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
        onDidMutate?()
    }

    func addMobster(name: String) {
        let mobster = Mobster(name: name)
        activeMobsters.append(mobster)
        onDidMutate?()
    }

    func benchMobster(at index: Int) {
        guard let mobster = removeActiveMobsterStorage(at: index) else { return }
        inactiveMobsters.append(mobster)
        onDidMutate?()
    }

    func rotateIn(at index: Int) {
        guard inactiveMobsters.indices.contains(index) else { return }
        let currentDriverID = driver?.id
        let mobster = inactiveMobsters.remove(at: index)
        activeMobsters.append(mobster)
        restoreDriver(withID: currentDriverID)
        onDidMutate?()
    }

    @discardableResult
    func removeActiveMobster(at index: Int) -> Mobster? {
        guard let mobster = removeActiveMobsterStorage(at: index) else { return nil }
        onDidMutate?()
        return mobster
    }

    @discardableResult
    private func removeActiveMobsterStorage(at index: Int) -> Mobster? {
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
        let mobster = inactiveMobsters.remove(at: index)
        onDidMutate?()
        return mobster
    }

    func shuffle() {
        guard activeMobsters.count >= 2 else { return }
        activeMobsters.shuffle()
        nextDriverIndex = 0
        onDidMutate?()
    }
    
    func moveMobster(from source: IndexSet, to destination: Int) {
        guard !source.isEmpty else { return }
        guard source.allSatisfy({ activeMobsters.indices.contains($0) }) else { return }
        guard (0...activeMobsters.count).contains(destination) else { return }
        let currentDriverID = driver?.id
        activeMobsters.move(fromOffsets: source, toOffset: destination)
        restoreDriver(withID: currentDriverID)
        onDidMutate?()
    }

    func moveActiveMobster(at source: Int, to destination: Int) {
        guard activeMobsters.indices.contains(source) else { return }
        guard activeMobsters.indices.contains(destination) else { return }
        guard abs(source - destination) == 1 else { return }
        let currentDriverID = driver?.id
        activeMobsters.swapAt(source, destination)
        restoreDriver(withID: currentDriverID)
        onDidMutate?()
    }

    func setMutationHandler(_ handler: @escaping () -> Void) {
        onDidMutate = handler
    }

    func resolveRegularCycle(
        id cycleID: UUID,
        resolution: RegularCycleResolutionReceipt.Resolution,
        advanceRoles: Bool
    ) {
        if advanceRoles, activeMobsters.count >= 2 {
            nextDriverIndex = (nextDriverIndex + 1) % activeMobsters.count
        }
        lastRegularCycleResolution = RegularCycleResolutionReceipt(
            cycleID: cycleID,
            resolution: resolution
        )
        onDidMutate?()
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
