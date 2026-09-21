import Foundation
@testable import Temizlikci

/// Builds small in-memory trees for view-model and layout tests.
nonisolated enum TreeBuilder {
    static let root = URL(filePath: "/Scan", directoryHint: .isDirectory)

    static func file(_ path: String, _ size: Int64) -> FileNode {
        .file(url: root.appending(path: path), allocatedSize: size, modificationDate: nil)
    }

    static func folder(_ path: String, _ children: [FileNode]) -> FileNode {
        .directory(url: root.appending(path: path, directoryHint: .isDirectory), modificationDate: nil, children: children)
    }

    /// /Scan
    /// ├── Apps (600): Big.app (500), Small.app (100)
    /// ├── Docs (300): Reports (200): q1.pdf (200); notes.txt (100)
    /// └── movie.mov (100)
    static func sample() -> FileNode {
        .directory(url: root, modificationDate: nil, children: [
            folder("Apps", [file("Apps/Big.app", 500), file("Apps/Small.app", 100)]),
            folder("Docs", [folder("Docs/Reports", [file("Docs/Reports/q1.pdf", 200)]), file("Docs/notes.txt", 100)]),
            file("movie.mov", 100),
        ])
    }
}
