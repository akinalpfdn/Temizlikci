import Foundation

/// A compact record of one scan, kept so later scans can show what grew. Only sizes by path;
/// no file contents. Stored on this Mac only.
nonisolated struct ScanSnapshot: Codable, Sendable, Equatable {
    static let currentVersion = 1

    let version: Int
    let locationPath: String
    let date: Date
    /// Allocated bytes by item path (no trailing slash).
    let sizes: [String: Int64]
    /// Folders that couldn't be read in this scan; sizes at or below them aren't comparable.
    let unreadPaths: Set<String>
}

/// Chooses which items a snapshot records: everything near the top, anything large, every
/// developer artifact, and every path the previous snapshot recorded (so a missing path really means
/// the item is gone, not that it shrank below the recording threshold).
nonisolated enum SnapshotBuilder {
    static let alwaysRecordedDepth = 2
    static let minimumRecordedSize: Int64 = 100_000_000

    static func snapshot(of root: FileNode, locationPath: String, date: Date, alsoRecording extraPaths: Set<String>) -> ScanSnapshot {
        var ancestorsOfExtras = Set<String>()
        for path in extraPaths {
            var parent = (path as NSString).deletingLastPathComponent
            while parent.count > 1, ancestorsOfExtras.insert(parent).inserted {
                parent = (parent as NSString).deletingLastPathComponent
            }
        }

        var sizes: [String: Int64] = [:]
        var unread = Set<String>()
        func visit(_ node: FileNode, depth: Int) {
            let path: String? = autoreleasepool {
                switch node.kind {
                case .directory, .file: return node.path
                case .inaccessible:
                    unread.insert(node.path)
                    return nil
                case .smallerFiles, .unattributed, .pending: return nil
                }
            }
            guard let path else { return }
            let isLarge = node.allocatedSize >= minimumRecordedSize
            if depth <= alwaysRecordedDepth || isLarge || extraPaths.contains(path) {
                sizes[path] = node.allocatedSize
            }
            guard node.kind == .directory, depth < alwaysRecordedDepth || isLarge || ancestorsOfExtras.contains(path) else { return }
            for child in node.children { visit(child, depth: depth + 1) }
        }
        visit(root, depth: 0)
        return ScanSnapshot(version: ScanSnapshot.currentVersion, locationPath: locationPath, date: date, sizes: sizes, unreadPaths: unread)
    }
}
