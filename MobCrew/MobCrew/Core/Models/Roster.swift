import Foundation

@Observable
final class Roster {
    var activeMobsters: [Mobster]
    var inactiveMobsters: [Mobster]
    var nextDriverIndex: Int

    init(activeMobsters: [Mobster] = [], inactiveMobsters: [Mobster] = [], nextDriverIndex: Int = 0) {
        self.activeMobsters = activeMobsters
        self.inactiveMobsters = inactiveMobsters
        self.nextDriverIndex = nextDriverIndex
    }

    var driver: Mobster? {
        guard !activeMobsters.isEmpty else { return nil }
        let index = nextDriverIndex % activeMobsters.count
        return activeMobsters[index]
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
        guard activeMobsters.indices.contains(index) else { return }
        let mobster = activeMobsters.remove(at: index)
        inactiveMobsters.append(mobster)
        adjustDriverIndex(afterRemovalAt: index)
    }

    func rotateIn(at index: Int) {
        guard inactiveMobsters.indices.contains(index) else { return }
        let mobster = inactiveMobsters.remove(at: index)
        activeMobsters.append(mobster)
    }

    func shuffle() {
        activeMobsters.shuffle()
        nextDriverIndex = 0
    }
    
    func moveMobster(from source: IndexSet, to destination: Int) {
        activeMobsters.move(fromOffsets: source, toOffset: destination)
        nextDriverIndex = 0
    }

    private func adjustDriverIndex(afterRemovalAt removedIndex: Int) {
        guard !activeMobsters.isEmpty else {
            nextDriverIndex = 0
            return
        }
        if removedIndex < nextDriverIndex {
            nextDriverIndex -= 1
        }
        nextDriverIndex = nextDriverIndex % activeMobsters.count
    }
}
