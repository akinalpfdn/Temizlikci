import Foundation
import Observation

/// An item this app moved to the Trash, with what's needed to put it back.
struct TrashRecord: Identifiable {
    let id = UUID()
    let node: FileNode
    let originalURL: URL
    let trashedURL: URL
    let date: Date
    /// The scan location it came from, and the IDs of its folders from that scan's root to its parent.
    let locationURL: URL
    let ancestorIDs: [String]
}

/// Items moved to the Trash during this session, shared by every location and the Trash view.
@MainActor
@Observable
final class TrashLedger {
    private(set) var records: [TrashRecord] = []
    private let trash: Trashing

    init(trash: Trashing) {
        self.trash = trash
    }

    var totalSize: Int64 { records.reduce(0) { $0 + $1.node.allocatedSize } }

    func add(_ record: TrashRecord) {
        records.insert(record, at: 0)
    }

    func remove(_ record: TrashRecord) {
        records.removeAll { $0.id == record.id }
    }

    func showTrashInFinder() {
        trash.showTrashInFinder()
    }
}
