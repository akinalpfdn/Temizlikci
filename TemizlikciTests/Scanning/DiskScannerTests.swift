import Foundation
import Testing
@testable import Temizlikci

/// Scanner behavior on real temporary file trees (never on real user folders).
@Suite(.serialized)
struct DiskScannerTests {
    private static let smallThreshold = ScanConfiguration(individualFileThreshold: 1024 * 1024, parallelDepth: 2, progressInterval: .milliseconds(1))

    private func scan(_ root: URL, configuration: ScanConfiguration = smallThreshold) async throws -> (result: ScanResult, progress: [ScanProgress]) {
        var progress: [ScanProgress] = []
        for try await event in FileSystemScanner(configuration: configuration).scan(root) {
            switch event {
            case .progress(let snapshot): progress.append(snapshot)
            case .finished(let result): return (result, progress)
            }
        }
        throw CancellationError()
    }

    private func child(_ name: String, of node: FileNode) -> FileNode? {
        node.children.first { $0.name == name && !isAggregate($0) }
    }

    private func isAggregate(_ node: FileNode) -> Bool {
        if case .smallerFiles = node.kind { return true }
        return false
    }

    @Test("should total nested folders to the sum of their files' space on disk")
    func nestedTotals() async throws {
        let tree = try FixtureTree()
        let files = [
            try tree.file("a/one.bin", bytes: 100_000),
            try tree.file("a/b/two.bin", bytes: 2_000_000),
            try tree.file("c/three.bin", bytes: 50_000),
            try tree.file("top.bin", bytes: 10_000),
        ]

        let (result, _) = try await scan(tree.root)

        #expect(result.root.allocatedSize == files.map(FixtureTree.allocatedSize(of:)).reduce(0, +))
        #expect(result.root.fileCount == 4)
        #expect(result.fileCount == 4)
        let a = try #require(child("a", of: result.root))
        #expect(a.allocatedSize == FixtureTree.allocatedSize(of: files[0]) + FixtureTree.allocatedSize(of: files[1]))
        #expect(result.root.children.map(\.allocatedSize) == result.root.children.map(\.allocatedSize).sorted(by: >))
    }

    @Test("should count a hard-linked file once")
    func hardLinksCountOnce() async throws {
        let tree = try FixtureTree()
        let original = try tree.file("x/data.bin", bytes: 3_000_000)
        try tree.folder("y")
        try tree.hardLink("y/data-link.bin", to: original)

        let (result, _) = try await scan(tree.root)

        #expect(result.root.allocatedSize == FixtureTree.allocatedSize(of: original))
    }

    @Test("should not follow symbolic links, including links that loop")
    func symbolicLinksNotFollowed() async throws {
        let tree = try FixtureTree()
        let payload = try tree.file("real/payload.bin", bytes: 2_000_000)
        try tree.symbolicLink("loop", to: tree.root)
        try tree.symbolicLink("alias", to: tree.root.appending(path: "real"))
        let linkSizes = ["loop", "alias"].map { FixtureTree.allocatedSize(of: tree.root.appending(path: $0)) }.reduce(0, +)

        let (result, _) = try await scan(tree.root)

        #expect(result.root.allocatedSize == FixtureTree.allocatedSize(of: payload) + linkSizes)
    }

    @Test("should record an unreadable folder as inaccessible and finish the scan")
    func unreadableFolder() async throws {
        let tree = try FixtureTree()
        let readable = try tree.file("open/visible.bin", bytes: 1_500_000)
        try tree.file("locked/hidden.bin", bytes: 1_500_000)
        tree.lock(tree.root.appending(path: "locked", directoryHint: .isDirectory))

        let (result, _) = try await scan(tree.root)

        #expect(result.inaccessibleCount == 1)
        #expect(child("locked", of: result.root)?.kind == .inaccessible)
        #expect(result.root.allocatedSize == FixtureTree.allocatedSize(of: readable))
    }

    @Test("should keep large files as nodes and fold smaller files into one entry per folder")
    func smallerFilesAggregate() async throws {
        let tree = try FixtureTree()
        let big = try tree.file("big.bin", bytes: 2_000_000)
        let small = [try tree.file("s1.txt", bytes: 10_000), try tree.file("s2.txt", bytes: 20_000)]

        let (result, _) = try await scan(tree.root)

        #expect(result.root.children.count == 2)
        let bigNode = try #require(result.root.children.first { $0.kind == .file })
        #expect(bigNode.name == "big.bin")
        #expect(bigNode.allocatedSize == FixtureTree.allocatedSize(of: big))
        let aggregate = try #require(result.root.children.first(where: isAggregate))
        #expect(aggregate.kind == .smallerFiles(count: 2))
        #expect(aggregate.allocatedSize == small.map(FixtureTree.allocatedSize(of:)).reduce(0, +))
    }

    @Test("should skip mounted volumes inside the scanned folder")
    func mountedVolumesSkipped() async throws {
        let tree = try FixtureTree()
        let local = try tree.file("local.bin", bytes: 1_200_000)
        let mountPoint = try tree.mountImage(at: "Volumes/iOS_Fixture")
        try Data(repeating: 0xA5, count: 2_000_000).write(to: mountPoint.appending(path: "inside-image.bin"))

        let (result, _) = try await scan(tree.root)

        #expect(result.root.allocatedSize == FixtureTree.allocatedSize(of: local))
        let volumes = try #require(child("Volumes", of: result.root))
        #expect(volumes.children.isEmpty)
    }

    @Test("should leave unread folders unopened and report them as needing access")
    func unreadFoldersNotOpened() async throws {
        let tree = try FixtureTree()
        let work = try tree.file("work/report.bin", bytes: 1_300_000)
        try tree.file("Music/library.bin", bytes: 2_500_000)
        var configuration = Self.smallThreshold
        configuration.unreadFolders = [ScanConfiguration.comparablePath(of: tree.root.appending(path: "Music", directoryHint: .isDirectory))]

        let (result, _) = try await scan(tree.root, configuration: configuration)

        #expect(child("Music", of: result.root)?.kind == .inaccessible)
        #expect(result.inaccessibleCount == 1)
        #expect(result.root.allocatedSize == FixtureTree.allocatedSize(of: work))
    }

    @Test("should publish progress that never exceeds the final totals, then finish")
    func progressThenFinish() async throws {
        let tree = try FixtureTree()
        for index in 0..<40 {
            try tree.file("dir\(index)/nested/file.bin", bytes: 64_000)
        }

        let (result, progress) = try await scan(tree.root)

        #expect(result.root.fileCount == 40)
        for snapshot in progress {
            #expect(snapshot.allocatedSize <= result.root.allocatedSize)
            #expect(snapshot.completedTopLevel.count <= 40)
        }
    }

    @Test("should stop promptly when the consuming task is cancelled")
    func cancellationStopsScan() async throws {
        let tree = try FixtureTree()
        for top in 0..<30 {
            for inner in 0..<60 {
                try tree.file("t\(top)/i\(inner)/f.bin", bytes: 4_096)
            }
        }
        let scanner = FileSystemScanner(configuration: Self.smallThreshold)
        let clock = ContinuousClock()
        let start = clock.now

        let consumer = Task {
            for try await event in scanner.scan(tree.root) {
                if case .finished = event { return true }
            }
            return false
        }
        consumer.cancel()
        let finished = (try? await consumer.value) ?? false

        #expect(finished == false)
        #expect(start.duration(to: clock.now) < .seconds(2))
    }

    @Test("should reject a missing root")
    func missingRoot() async {
        let missing = URL(filePath: "/nonexistent-\(UUID().uuidString)", directoryHint: .isDirectory)

        await #expect(throws: ScanError.rootNotFound(missing)) {
            _ = try await scan(missing)
        }
    }

    @Test("should reject a root that is a file")
    func fileRoot() async throws {
        let tree = try FixtureTree()
        let file = try tree.file("plain.txt", bytes: 10)

        await #expect(throws: ScanError.rootNotFolder(file)) {
            _ = try await scan(file)
        }
    }

    @Test("should explain scan errors with the item's name and a next step")
    func errorMessages() {
        let error = ScanError.rootUnreadable(URL(filePath: "/Users/someone/Private", directoryHint: .isDirectory))

        #expect(error.errorDescription?.contains("Private") == true)
        #expect(error.recoverySuggestion?.isEmpty == false)
    }
}

struct VolumeUsageTests {
    @Test("should report used space and the part no folder accounts for")
    func unattributedSpace() {
        let usage = VolumeUsage(totalCapacity: 460, availableCapacity: 40, availableForImportantUsage: 55)

        #expect(usage.usedCapacity == 420)
        #expect(usage.unattributed(scannedSize: 340) == 80)
        #expect(usage.unattributed(scannedSize: 500) == 0)
    }

    @Test("should read real capacity figures for the startup volume")
    func startupVolumeUsage() throws {
        let usage = try SystemVolumeInfo().usage(ofVolumeContaining: URL(filePath: "/"))

        #expect(usage.totalCapacity > 0)
        #expect(usage.availableCapacity > 0)
        #expect(usage.usedCapacity > 0)
    }
}

private struct StubAccess: FullDiskAccessChecking {
    let granted: Bool
    func hasFullDiskAccess() -> Bool { granted }
}

struct ScanAccessTests {
    private let home = URL(filePath: "/Users/someone", directoryHint: .isDirectory)

    @Test("should leave consent-prompting folders unread without Full Disk Access")
    func withoutAccess() {
        let configuration = ScanConfiguration.forScan(access: StubAccess(granted: false), home: home)

        #expect(configuration.unreadFolders.contains("/Users/someone/Music"))
        #expect(configuration.unreadFolders.contains("/Users/someone/Documents"))
        #expect(configuration.unreadFolders.contains("/Users/someone/Library/Containers"))
        #expect(configuration.unreadFolders.count == ProtectedLocations.homeRelativePaths.count)
    }

    @Test("should read everything with Full Disk Access")
    func withAccess() {
        let configuration = ScanConfiguration.forScan(access: StubAccess(granted: true), home: home)

        #expect(configuration.unreadFolders.isEmpty)
    }

    @Test("should compare folder paths regardless of a trailing slash")
    func comparablePaths() {
        let withSlash = URL(filePath: "/Users/someone/Music/", directoryHint: .isDirectory)
        let withoutSlash = URL(filePath: "/Users/someone/Music", directoryHint: .notDirectory)

        #expect(ScanConfiguration.comparablePath(of: withSlash) == ScanConfiguration.comparablePath(of: withoutSlash))
    }
}
