import Foundation
@testable import MobCrew

enum TestHelpers {
    static func makeMobster(name: String = "Test Mobster") -> Mobster {
        Mobster(name: name)
    }

    static func makeRoster(mobsterNames: [String] = []) -> Roster {
        let roster = Roster()
        for name in mobsterNames {
            roster.addMobster(name: name)
        }
        return roster
    }
}
