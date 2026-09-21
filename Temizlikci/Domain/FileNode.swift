import Foundation

/// One entry in a scan result. Directories keep their full structure; individual files are kept
/// only above `ScanConfiguration.individualFileThreshold`, and the rest of a directory's files are
/// folded into one `smallerFiles` child so multi-million-file volumes stay affordable in memory.
nonisolated struct FileNode: Sendable, Identifiable {
    enum Kind: Sendable, Equatable {
        case directory
        case file
        /// Files below the individual-file threshold, summed per directory.
        case smallerFiles(count: Int)
        /// A folder the scanner could not read, typically because it needs Full Disk Access.
        case inaccessible
    }

    let id: String
    let url: URL
    let name: String
    let kind: Kind
    /// Space on disk in bytes (allocated size, not logical length). Hard links count once.
    let allocatedSize: Int64
    /// Number of files at or below this node.
    let fileCount: Int
    let modificationDate: Date?
    /// Sorted by `allocatedSize`, largest first.
    let children: [FileNode]

    var isContainer: Bool { kind == .directory }
}

extension FileNode {
    nonisolated static func file(url: URL, allocatedSize: Int64, modificationDate: Date?) -> FileNode {
        FileNode(
            id: url.path(percentEncoded: false),
            url: url,
            name: url.lastPathComponent,
            kind: .file,
            allocatedSize: allocatedSize,
            fileCount: 1,
            modificationDate: modificationDate,
            children: []
        )
    }

    nonisolated static func smallerFiles(in directory: URL, count: Int, allocatedSize: Int64) -> FileNode {
        FileNode(
            id: directory.path(percentEncoded: false) + "\u{0}smaller-files",
            url: directory,
            name: "",
            kind: .smallerFiles(count: count),
            allocatedSize: allocatedSize,
            fileCount: count,
            modificationDate: nil,
            children: []
        )
    }

    nonisolated static func inaccessible(url: URL) -> FileNode {
        FileNode(
            id: url.path(percentEncoded: false),
            url: url,
            name: url.lastPathComponent,
            kind: .inaccessible,
            allocatedSize: 0,
            fileCount: 0,
            modificationDate: nil,
            children: []
        )
    }

    nonisolated static func directory(url: URL, modificationDate: Date?, children: [FileNode]) -> FileNode {
        let sorted = children.sorted { $0.allocatedSize > $1.allocatedSize }
        return FileNode(
            id: url.path(percentEncoded: false),
            url: url,
            name: url.lastPathComponent,
            kind: .directory,
            allocatedSize: sorted.reduce(0) { $0 + $1.allocatedSize },
            fileCount: sorted.reduce(0) { $0 + $1.fileCount },
            modificationDate: modificationDate,
            children: sorted
        )
    }
}
