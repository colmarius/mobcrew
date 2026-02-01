import Testing
import Foundation
@testable import MobCrew

@Suite("ActiveMobstersFileService Tests")
struct ActiveMobstersFileServiceTests {
    
    private func makeTemporaryFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("MobCrewTests-\(UUID().uuidString)")
            .appendingPathComponent("active-mobsters")
    }
    
    @Test("creates file with correct path")
    func createsFileWithCorrectPath() throws {
        let fileURL = makeTemporaryFileURL()
        let service = ActiveMobstersFileService(fileURL: fileURL)
        let roster = Roster(activeMobsters: [Mobster(name: "Alice")])
        
        service.writeActiveMobsters(roster)
        
        #expect(FileManager.default.fileExists(atPath: fileURL.path))
        
        try FileManager.default.removeItem(at: fileURL.deletingLastPathComponent())
    }
    
    @Test("writes comma-separated format")
    func writesCommaSeparatedFormat() throws {
        let fileURL = makeTemporaryFileURL()
        let service = ActiveMobstersFileService(fileURL: fileURL)
        let roster = Roster(activeMobsters: [
            Mobster(name: "Jim Kirk"),
            Mobster(name: "Spock"),
            Mobster(name: "McCoy")
        ])
        
        service.writeActiveMobsters(roster)
        
        let content = service.readActiveMobsters()
        #expect(content == "Jim Kirk, Spock, McCoy")
        
        try FileManager.default.removeItem(at: fileURL.deletingLastPathComponent())
    }
    
    @Test("empty roster writes empty file")
    func emptyRosterWritesEmptyFile() throws {
        let fileURL = makeTemporaryFileURL()
        let service = ActiveMobstersFileService(fileURL: fileURL)
        let roster = Roster()
        
        service.writeActiveMobsters(roster)
        
        let content = service.readActiveMobsters()
        #expect(content == "")
        
        try FileManager.default.removeItem(at: fileURL.deletingLastPathComponent())
    }
    
    @Test("only includes active mobsters")
    func onlyIncludesActiveMobsters() throws {
        let fileURL = makeTemporaryFileURL()
        let service = ActiveMobstersFileService(fileURL: fileURL)
        let roster = Roster(
            activeMobsters: [Mobster(name: "Alice"), Mobster(name: "Bob")],
            inactiveMobsters: [Mobster(name: "Charlie")]
        )
        
        service.writeActiveMobsters(roster)
        
        let content = service.readActiveMobsters()
        #expect(content == "Alice, Bob")
        #expect(content?.contains("Charlie") == false)
        
        try FileManager.default.removeItem(at: fileURL.deletingLastPathComponent())
    }
}
