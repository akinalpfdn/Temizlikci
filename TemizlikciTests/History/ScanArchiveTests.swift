import Foundation
import Testing
@testable import Temizlikci

@Suite("Scan archive")
struct ScanArchiveTests {
    private let scannedAt = Date(timeIntervalSince1970: 1_790_000_000)

    private func sampleTree() -> FileNode {
        let root = URL(filePath: "/Scan", directoryHint: .isDirectory)
        return .directory(url: root, modificationDate: Date(timeIntervalSince1970: 1_700_000_000), children: [
            .directory(url: root.appending(path: "Apps", directoryHint: .isDirectory), modificationDate: nil, children: [
                .file(url: root.appending(path: "Apps/Big.app"), allocatedSize: 500, modificationDate: Date(timeIntervalSince1970: 1_600_000_000)),
                .smallerFiles(in: root.appending(path: "Apps", directoryHint: .isDirectory), count: 42, allocatedSize: 99),
            ]),
            .inaccessible(url: root.appending(path: "Private", directoryHint: .isDirectory)),
            .unattributed(on: root, allocatedSize: 1_000),
        ])
    }

    /// Compares trees node by node, including the rebuilt URLs.
    private func same(_ a: FileNode, _ b: FileNode) -> Bool {
        a.url == b.url && a.kind == b.kind && a.allocatedSize == b.allocatedSize
            && a.fileCount == b.fileCount && a.modificationDate == b.modificationDate
            && a.children.count == b.children.count
            && zip(a.children, b.children).allSatisfy { same($0, $1) }
    }

    @Test("should restore the whole tree, including kinds, sizes, dates and rebuilt paths")
    func roundTrip() throws {
        let tree = sampleTree()

        let archived = try ScanArchive.decode(ScanArchive.encode(root: tree, scannedAt: scannedAt, locationPath: "/Scan"))

        #expect(archived.locationPath == "/Scan")
        #expect(archived.scannedAt == scannedAt)
        #expect(same(archived.root, tree))
        // Children are ordered by size, so find the folder by name rather than by position.
        let apps = archived.root.children.first { $0.name == "Apps" }
        #expect(apps?.children.contains { $0.path == "/Scan/Apps/Big.app" } == true)
        #expect(apps?.children.contains { $0.kind == .smallerFiles(count: 42) } == true)
    }

    @Test("should refuse data that isn't an archive or comes from another version")
    func rejectsBadData() {
        #expect(throws: ScanArchive.ArchiveError.notAnArchive) { try ScanArchive.decode(Data("not an archive".utf8)) }
        var wrongVersion = ScanArchive.encode(root: sampleTree(), scannedAt: scannedAt, locationPath: "/Scan")
        wrongVersion[4] = 99
        #expect(throws: ScanArchive.ArchiveError.unsupportedVersion(99)) { try ScanArchive.decode(wrongVersion) }
        let truncated = ScanArchive.encode(root: sampleTree(), scannedAt: scannedAt, locationPath: "/Scan").prefix(20)
        #expect(throws: ScanArchive.ArchiveError.truncated) { try ScanArchive.decode(Data(truncated)) }
    }

    @Test("should save and load a location's scan, and ignore a cache written for another folder")
    func cacheRoundTrip() throws {
        let fixture = try FixtureTree()
        let cache = FileScanCache(directory: fixture.root.appending(path: "Scans", directoryHint: .isDirectory))

        try cache.save(root: sampleTree(), scannedAt: scannedAt, locationPath: "/Scan")

        let loaded = try #require(try cache.load(locationPath: "/Scan"))
        #expect(same(loaded.root, sampleTree()))
        let other = try cache.load(locationPath: "/Other")
        #expect(other == nil)

        try cache.remove(locationPath: "/Scan")
        let afterRemove = try cache.load(locationPath: "/Scan")
        #expect(afterRemove == nil)
    }
}
