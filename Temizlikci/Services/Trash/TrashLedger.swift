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

    /// Drops records whose items are no longer in the Trash (emptied, or deleted there in Finder).
    /// Cheap: one file-system lookup per record, and only this session's records are checked.
    func reconcile() async {
        let checked = records
        guard !checked.isEmpty else { return }
        let presence = await trash.presence(of: checked.map(\.trashedURL))
        let gone = Set(zip(checked, presence).filter { $0.1 == .gone }.map { $0.0.id })
        guard !gone.isEmpty else { return }
        records.removeAll { gone.contains($0.id) }
    }
}
