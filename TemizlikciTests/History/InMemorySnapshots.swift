import Foundation
import Synchronization
@testable import Temizlikci

/// Keeps snapshots in memory so tests never write to the real Application Support folder.
nonisolated final class InMemorySnapshots: SnapshotStoring {
    private let stored = Mutex<[ScanSnapshot]>([])

    var all: [ScanSnapshot] { stored.withLock { $0 } }

    func recent(forLocation path: String, limit: Int) throws -> [ScanSnapshot] {
        stored.withLock { Array($0.filter { $0.locationPath == path }.suffix(limit).reversed()) }
    }

    func save(_ snapshot: ScanSnapshot) throws {
        stored.withLock { $0.append(snapshot) }
    }

    func prune(location path: String, keeping count: Int) throws {
        stored.withLock { snapshots in
            let mine = snapshots.filter { $0.locationPath == path }
            let drop = Set(mine.dropLast(count).map(\.date))
            snapshots.removeAll { $0.locationPath == path && drop.contains($0.date) }
        }
    }
}
