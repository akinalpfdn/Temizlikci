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
        /// Used space on the volume that no scanned folder accounts for (system volume, snapshots,
        /// purgeable files). Only added to whole-volume results.
        case unattributed
        /// Space not measured yet while a scan is running.
        case pending
    }

    let url: URL
    let kind: Kind
    /// Space on disk in bytes (allocated size, not logical length). Hard links count once.
    let allocatedSize: Int64
    /// Number of files at or below this node.
    let fileCount: Int
    let modificationDate: Date?
    /// Sorted by `allocatedSize`, largest first.
    let children: [FileNode]

    var isContainer: Bool { kind == .directory }

    /// Derived from the URL rather than stored: a scan holds hundreds of thousands of nodes, and a
    /// second copy of every path was a large share of the memory (Lore knownIssue 101).
    var id: String {
        let path = url.path(percentEncoded: false)
        switch kind {
        case .directory, .file, .inaccessible: return path
        case .smallerFiles: return path + "\u{0}smaller-files"
        case .unattributed: return path + "\u{0}unattributed"
        case .pending: return path + "\u{0}pending"
        }
    }

    /// The path without a trailing slash, for comparing nodes across scans.
    var path: String {
        var path = url.path(percentEncoded: false)
        if path.count > 1, path.hasSuffix("/") { path.removeLast() }
        return path
    }

    /// The item's file name; empty for aggregate entries, which get their titles from the view model.
    var name: String {
        switch kind {
        case .directory, .file, .inaccessible: url.lastPathComponent
        case .smallerFiles, .unattributed, .pending: ""
        }
    }
}

extension FileNode {
    nonisolated static func file(url: URL, allocatedSize: Int64, modificationDate: Date?) -> FileNode {
        FileNode(
            url: url,
            kind: .file,
            allocatedSize: allocatedSize,
            fileCount: 1,
            modificationDate: modificationDate,
            children: []
        )
    }

    nonisolated static func smallerFiles(in directory: URL, count: Int, allocatedSize: Int64) -> FileNode {
        FileNode(
            url: directory,
            kind: .smallerFiles(count: count),
            allocatedSize: allocatedSize,
            fileCount: count,
            modificationDate: nil,
            children: []
        )
    }

    nonisolated static func inaccessible(url: URL) -> FileNode {
        FileNode(
            url: url,
            kind: .inaccessible,
            allocatedSize: 0,
            fileCount: 0,
            modificationDate: nil,
            children: []
        )
    }

    nonisolated static func unattributed(on volume: URL, allocatedSize: Int64) -> FileNode {
        FileNode(
            url: volume,
            kind: .unattributed,
            allocatedSize: allocatedSize,
            fileCount: 0,
            modificationDate: nil,
            children: []
        )
    }

    nonisolated static func pending(in root: URL, allocatedSize: Int64) -> FileNode {
        FileNode(
            url: root,
            kind: .pending,
            allocatedSize: allocatedSize,
            fileCount: 0,
            modificationDate: nil,
            children: []
        )
    }

    /// A copy of this directory with one more child, re-sorted and re-totalled.
    nonisolated func adding(_ child: FileNode) -> FileNode {
        .directory(url: url, modificationDate: modificationDate, children: children + [child])
    }

    nonisolated static func directory(url: URL, modificationDate: Date?, children: [FileNode]) -> FileNode {
        let sorted = children.sorted { $0.allocatedSize > $1.allocatedSize }
        return FileNode(
            url: url,
            kind: .directory,
            allocatedSize: sorted.reduce(0) { $0 + $1.allocatedSize },
            fileCount: sorted.reduce(0) { $0 + $1.fileCount },
            modificationDate: modificationDate,
            children: sorted
        )
    }
}
