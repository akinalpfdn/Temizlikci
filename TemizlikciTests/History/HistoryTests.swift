import Foundation
import Testing
@testable import Temizlikci

struct SnapshotBuilderTests {
    private let mb: Int64 = 1_000_000

    private func folder(_ path: String, _ children: [FileNode]) -> FileNode {
        .directory(url: URL(filePath: path, directoryHint: .isDirectory), modificationDate: nil, children: children)
    }

    private func file(_ path: String, _ size: Int64) -> FileNode {
        .file(url: URL(filePath: path), allocatedSize: size, modificationDate: nil)
    }

    @Test("should record the top levels, large items anywhere, requested paths, and unread folders")
    func recording() {
        let tree = folder("/R", [
            folder("/R/a", [folder("/R/a/b", [folder("/R/a/b/small", [file("/R/a/b/small/x", 5 * mb)]),
                                              folder("/R/a/b/big", [file("/R/a/b/big/y", 300 * mb)])])]),
            .inaccessible(url: URL(filePath: "/R/locked", directoryHint: .isDirectory)),
        ])

        let snapshot = SnapshotBuilder.snapshot(of: tree, locationPath: "/R", date: .now, alsoRecording: ["/R/a/b/small/x"])

        #expect(snapshot.sizes["/R"] != nil)
        #expect(snapshot.sizes["/R/a/b"] != nil)
        #expect(snapshot.sizes["/R/a/b/big"] == 300 * mb)
        #expect(snapshot.sizes["/R/a/b/small/x"] == 5 * mb)
        #expect(snapshot.sizes["/R/a/b/small"] == nil)
        #expect(snapshot.unreadPaths == ["/R/locked"])
    }
}

struct GrowthReportTests {
    private let mb: Int64 = 1_000_000

    private func snapshot(_ sizes: [String: Int64], unread: Set<String> = [], day: Int) -> ScanSnapshot {
        ScanSnapshot(version: 1, locationPath: "/R", date: Date(timeIntervalSince1970: TimeInterval(day * 86_400)), sizes: sizes, unreadPaths: unread)
    }

    @Test("should classify growth, shrinking, new, and removed items above the noise floor")
    func classification() {
        let before = snapshot(["/R/a": 100 * mb, "/R/b": 500 * mb, "/R/gone": 50 * mb, "/R/steady": 40 * mb], day: 1)
        let after = snapshot(["/R/a": 400 * mb, "/R/b": 200 * mb, "/R/new": 80 * mb, "/R/steady": 41 * mb], day: 2)

        let report = GrowthReport.compare(previous: before, current: after)

        #expect(report.change(forPath: "/R/a")?.kind == .grew)
        #expect(report.change(forPath: "/R/a")?.delta == 300 * mb)
        #expect(report.change(forPath: "/R/b")?.kind == .shrank)
        #expect(report.change(forPath: "/R/new")?.kind == .appeared)
        #expect(report.change(forPath: "/R/gone")?.kind == .removed)
        #expect(report.change(forPath: "/R/steady") == nil)
    }

    @Test("should ignore folders that were unread in either scan")
    func unreadIgnored() {
        let before = snapshot(["/R/Documents/x": 900 * mb], day: 1)
        let after = snapshot([:], unread: ["/R/Documents"], day: 2)

        #expect(GrowthReport.compare(previous: before, current: after).changes.isEmpty)
    }

    @Test("should list where growth happened, not every folder above it")
    func biggestChangesSkipExplainedParents() {
        let before = snapshot(["/R/Library": 1_000 * mb, "/R/Library/DerivedData": 100 * mb, "/R/Docs": 100 * mb], day: 1)
        let after = snapshot(["/R/Library": 1_950 * mb, "/R/Library/DerivedData": 1_000 * mb, "/R/Docs": 300 * mb], day: 2)

        let biggest = GrowthReport.compare(previous: before, current: after).biggestChanges()

        #expect(biggest.map(\.path) == ["/R/Library/DerivedData", "/R/Docs"])
    }
}

struct FileSnapshotStoreTests {
    @Test("should save, load the newest, and prune old snapshots per location")
    func roundTrip() throws {
        let tree = try FixtureTree()
        let store = FileSnapshotStore(directory: tree.root.appending(path: "Snapshots", directoryHint: .isDirectory))
        for day in 1...4 {
            try store.save(ScanSnapshot(version: 1, locationPath: "/R", date: Date(timeIntervalSince1970: TimeInterval(day * 86_400)),
                                        sizes: ["/R": Int64(day)], unreadPaths: ["/R/locked"]))
        }
        try store.save(ScanSnapshot(version: 1, locationPath: "/Other", date: .now, sizes: [:], unreadPaths: []))

        #expect(try store.latest(forLocation: "/R")?.sizes["/R"] == 4)
        #expect(try store.latest(forLocation: "/R")?.unreadPaths == ["/R/locked"])

        try store.prune(location: "/R", keeping: 2)
        let files = try FileManager.default.subpathsOfDirectory(atPath: store.directory.path(percentEncoded: false)).filter { $0.hasSuffix(".snapshot") }
        #expect(files.count == 3)
        #expect(try store.latest(forLocation: "/R")?.sizes["/R"] == 4)
        #expect(try store.latest(forLocation: "/Missing") == nil)
    }
}
