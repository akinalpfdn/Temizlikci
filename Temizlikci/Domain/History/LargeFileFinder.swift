import Foundation

/// A large file somewhere in a scan, with its path of IDs from the scan root (for trashing and navigation).
nonisolated struct LargeFile: Sendable, Identifiable {
    let node: FileNode
    let idPath: [String]
    var id: String { node.id }
}

/// Collects the largest individual files in a tree. The scanner keeps files of 10 MB or more as
/// their own nodes, so these are exactly the files worth listing.
nonisolated enum LargeFileFinder {
    static let limit = 200

    static func largest(in root: FileNode, limit: Int = limit) -> [LargeFile] {
        var found: [LargeFile] = []
        func visit(_ node: FileNode, idPath: [String]) {
            for child in node.children {
                switch child.kind {
                case .file:
                    let id = autoreleasepool { child.id }
                    found.append(LargeFile(node: child, idPath: idPath + [id]))
                case .directory:
                    let id = autoreleasepool { child.id }
                    visit(child, idPath: idPath + [id])
                case .smallerFiles, .inaccessible, .unattributed, .pending:
                    continue
                }
            }
        }
        visit(root, idPath: [root.id])
        return Array(found.sorted { $0.node.allocatedSize > $1.node.allocatedSize }.prefix(limit))
    }
}
