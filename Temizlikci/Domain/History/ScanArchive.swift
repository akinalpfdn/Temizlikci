import Foundation

/// Encodes and decodes a whole scan tree.
///
/// A scan holds hundreds of thousands of nodes, and every node's full path would dominate the file,
/// so the tree is written in pre-order with only each node's name; paths are rebuilt from the parent
/// on the way back in. Numbers are fixed-width little-endian, which keeps decoding to plain reads.
nonisolated enum ScanArchive {
    static let magic: [UInt8] = Array("TMZS".utf8)
    static let version: UInt32 = 1

    enum ArchiveError: Error, Equatable {
        case notAnArchive
        case unsupportedVersion(UInt32)
        case truncated
    }

    struct Archived: Sendable {
        let root: FileNode
        let scannedAt: Date
        let locationPath: String
    }

    // MARK: Encoding

    static func encode(root: FileNode, scannedAt: Date, locationPath: String) -> Data {
        var data = Data()
        data.append(contentsOf: magic)
        append(UInt32(version), to: &data)
        append(string: locationPath, to: &data)
        append(scannedAt.timeIntervalSince1970, to: &data)
        write(root, isRoot: true, to: &data)
        return data
    }

    private static func write(_ node: FileNode, isRoot: Bool, to data: inout Data) {
        switch node.kind {
        case .directory: data.append(0)
        case .file: data.append(1)
        case .smallerFiles(let count):
            data.append(2)
            append(UInt32(clamping: count), to: &data)
        case .inaccessible: data.append(3)
        case .unattributed: data.append(4)
        case .pending: data.append(5)
        }
        // Summed, unreadable-space and pending nodes stand for their parent folder and share its
        // URL, so they carry no name of their own.
        let name = if isRoot {
            node.url.path(percentEncoded: false)
        } else if Self.sharesParentURL(node.kind) {
            ""
        } else {
            node.url.lastPathComponent
        }
        append(string: name, to: &data)
        append(UInt64(bitPattern: node.allocatedSize), to: &data)
        append(UInt32(clamping: node.fileCount), to: &data)
        append(node.modificationDate?.timeIntervalSince1970 ?? .nan, to: &data)
        append(UInt32(clamping: node.children.count), to: &data)
        for child in node.children {
            write(child, isRoot: false, to: &data)
        }
    }

    private static func append(_ value: UInt32, to data: inout Data) {
        withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
    }

    private static func append(_ value: UInt64, to data: inout Data) {
        withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
    }

    private static func append(_ value: Double, to data: inout Data) {
        append(value.bitPattern, to: &data)
    }

    private static func append(string: String, to data: inout Data) {
        let bytes = Array(string.utf8)
        append(UInt32(clamping: bytes.count), to: &data)
        data.append(contentsOf: bytes)
    }

    // MARK: Decoding

    static func decode(_ data: Data) throws -> Archived {
        var reader = Reader(data: data)
        guard try reader.bytes(4) == magic else { throw ArchiveError.notAnArchive }
        let version = try reader.uint32()
        guard version == Self.version else { throw ArchiveError.unsupportedVersion(version) }
        let locationPath = try reader.string()
        let scannedAt = Date(timeIntervalSince1970: try reader.double())
        let root = try read(&reader, parent: nil)
        return Archived(root: root, scannedAt: scannedAt, locationPath: locationPath)
    }

    private static func read(_ reader: inout Reader, parent: URL?) throws -> FileNode {
        let tag = try reader.byte()
        let kind: FileNode.Kind = switch tag {
        case 0: .directory
        case 1: .file
        case 2: .smallerFiles(count: Int(try reader.uint32()))
        case 3: .inaccessible
        case 4: .unattributed
        case 5: .pending
        default: throw ArchiveError.truncated
        }
        let name = try reader.string()
        let size = Int64(bitPattern: try reader.uint64())
        let fileCount = Int(try reader.uint32())
        let modified = try reader.double()
        let childCount = Int(try reader.uint32())

        let isDirectoryLike = kind == .directory || kind == .inaccessible
        let url: URL = if let parent {
            Self.sharesParentURL(kind) ? parent : parent.appending(path: name, directoryHint: isDirectoryLike ? .isDirectory : .notDirectory)
        } else {
            URL(filePath: name, directoryHint: .isDirectory)
        }
        var children: [FileNode] = []
        children.reserveCapacity(childCount)
        for _ in 0..<childCount {
            children.append(try read(&reader, parent: url))
        }
        return FileNode(
            url: url, kind: kind, allocatedSize: size, fileCount: fileCount,
            modificationDate: modified.isNaN ? nil : Date(timeIntervalSince1970: modified),
            children: children
        )
    }

    /// True for nodes that describe their parent folder rather than an item of their own.
    private static func sharesParentURL(_ kind: FileNode.Kind) -> Bool {
        switch kind {
        case .smallerFiles, .unattributed, .pending: true
        case .directory, .file, .inaccessible: false
        }
    }

    private struct Reader {
        let data: Data
        var offset = 0

        mutating func bytes(_ count: Int) throws -> [UInt8] {
            guard offset + count <= data.count else { throw ArchiveError.truncated }
            defer { offset += count }
            return Array(data[data.startIndex + offset..<data.startIndex + offset + count])
        }

        mutating func byte() throws -> UInt8 {
            try bytes(1)[0]
        }

        mutating func uint32() throws -> UInt32 {
            let raw = try bytes(4)
            return raw.withUnsafeBytes { UInt32(littleEndian: $0.loadUnaligned(as: UInt32.self)) }
        }

        mutating func uint64() throws -> UInt64 {
            let raw = try bytes(8)
            return raw.withUnsafeBytes { UInt64(littleEndian: $0.loadUnaligned(as: UInt64.self)) }
        }

        mutating func double() throws -> Double {
            Double(bitPattern: try uint64())
        }

        mutating func string() throws -> String {
            let count = Int(try uint32())
            return String(decoding: try bytes(count), as: UTF8.self)
        }
    }
}

/// How old a saved scan may get before the app refreshes it by itself.
nonisolated enum RefreshPeriod: Int, Sendable, CaseIterable, Identifiable {
    case day = 1, threeDays = 3, week = 7, never = 0

    var id: Int { rawValue }

    /// Seconds, or `nil` when the app should never refresh on its own.
    var interval: TimeInterval? {
        rawValue == 0 ? nil : TimeInterval(rawValue) * 24 * 60 * 60
    }
}
