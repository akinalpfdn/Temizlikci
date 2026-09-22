import Foundation
import Synchronization
@testable import Temizlikci

/// Keeps snapshots in memory so tests never write to the real Application Support folder.
nonisolated final class InMemorySnapshots: SnapshotStoring {
    private let stored = Mutex<[ScanSnapshot]>([])

    var all: [ScanSnapshot] { stored.withLock { $0 } }

    func latest(forLocation path: String) throws -> ScanSnapshot? {
        stored.withLock { $0.last { $0.locationPath == path } }
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
