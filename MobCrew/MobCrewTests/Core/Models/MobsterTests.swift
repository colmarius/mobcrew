import Testing
import Foundation
@testable import MobCrew

@Suite("Mobster Tests")
struct MobsterTests {
    @Test("Codable round-trip encoding/decoding")
    func codableRoundTrip() throws {
        let original = Mobster(name: "Alice")
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(Mobster.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.name == original.name)
    }

    @Test("Codable preserves custom UUID")
    func codablePreservesCustomUUID() throws {
        let customID = UUID()
        let original = Mobster(id: customID, name: "Bob")
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(Mobster.self, from: data)

        #expect(decoded.id == customID)
        #expect(decoded.name == "Bob")
    }

    @Test("Hashable conformance")
    func hashableConformance() {
        let id = UUID()
        let mobster1 = Mobster(id: id, name: "Charlie")
        let mobster2 = Mobster(id: id, name: "Charlie")

        #expect(mobster1.hashValue == mobster2.hashValue)

        var set = Set<Mobster>()
        set.insert(mobster1)
        #expect(set.contains(mobster2))
    }

    @Test("Default UUID is generated")
    func defaultUUIDGenerated() {
        let mobster1 = Mobster(name: "Dave")
        let mobster2 = Mobster(name: "Dave")

        #expect(mobster1.id != mobster2.id)
    }
}
