import Foundation
import Synchronization
@testable import Temizlikci

/// Keeps archives in memory so tests never write to the real Application Support folder.
nonisolated final class InMemoryScanCache: ScanCaching {
    private let stored = Mutex<[String: Data]>([:])

    var savedLocations: [String] { stored.withLock { Array($0.keys) } }

    func save(root: FileNode, scannedAt: Date, locationPath: String) throws {
        let data = ScanArchive.encode(root: root, scannedAt: scannedAt, locationPath: locationPath)
        stored.withLock { $0[locationPath] = data }
    }

    func load(locationPath: String) throws -> ScanArchive.Archived? {
        guard let data = stored.withLock({ $0[locationPath] }) else { return nil }
        return try ScanArchive.decode(data)
    }

    func remove(locationPath: String) throws {
        stored.withLock { $0[locationPath] = nil }
    }
}
