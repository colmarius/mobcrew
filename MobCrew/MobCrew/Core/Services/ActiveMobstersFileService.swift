import Foundation

protocol FileManagerProtocol {
    func fileExists(atPath path: String) -> Bool
    func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey: Any]?) throws
}

extension FileManager: FileManagerProtocol {}

final class ActiveMobstersFileService {
    private let fileManager: FileManagerProtocol
    private let fileURL: URL
    
    static var defaultFileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let mobcrewDir = appSupport.appendingPathComponent("MobCrew", isDirectory: true)
        return mobcrewDir.appendingPathComponent("active-mobsters")
    }
    
    init(fileManager: FileManagerProtocol = FileManager.default, fileURL: URL? = nil) {
        self.fileManager = fileManager
        self.fileURL = fileURL ?? Self.defaultFileURL
    }
    
    func writeActiveMobsters(_ roster: Roster) {
        let names = roster.activeMobsters.map { $0.name }
        let content = names.joined(separator: ", ")
        
        do {
            let directory = fileURL.deletingLastPathComponent()
            if !fileManager.fileExists(atPath: directory.path) {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            }
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to write active mobsters file: \(error)")
        }
    }
    
    func readActiveMobsters() -> String? {
        try? String(contentsOf: fileURL, encoding: .utf8)
    }
}
