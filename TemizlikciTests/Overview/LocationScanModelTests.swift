import Foundation
import Testing
@testable import Temizlikci

nonisolated private struct StubScanner: DiskScanning {
    let events: [ScanEvent]
    var failure: ScanError?

    func scan(_ root: URL) -> AsyncThrowingStream<ScanEvent, Error> {
        AsyncThrowingStream { continuation in
            for event in events { continuation.yield(event) }
            if let failure { continuation.finish(throwing: failure) } else { continuation.finish() }
        }
    }
}

nonisolated private struct GrantedAccess: FullDiskAccessChecking {
    func hasFullDiskAccess() -> Bool { true }
}

private struct FixedVolume: VolumeInfoProviding {
    let usage: VolumeUsage
    func startupVolumeName() -> String? { "Macintosh HD" }
    func usage(ofVolumeContaining url: URL) throws -> VolumeUsage { usage }
}

/// No project markers anywhere, so only path rules can match in these trees.
nonisolated private struct NoMarkers: MarkerChecking {
    func folder(_ folder: URL, contains marker: String) -> Bool { false }
}

private final class RecordingRevealer: FileRevealing {
    private(set) var revealed: [URL] = []
    func reveal(_ url: URL) { revealed.append(url) }
}

@MainActor
struct LocationScanModelTests {
    private let revealer = RecordingRevealer()
    private let trash = StubTrash()
    private let ledger: TrashLedger
    private let snapshots = InMemorySnapshots()

    init() {
        ledger = TrashLedger(trash: trash)
    }

    private func makeModel(
        wholeVolume: Bool = false,
        events: [ScanEvent] = [.finished(ScanResult(root: TreeBuilder.sample(), duration: .seconds(1), fileCount: 5, directoryCount: 3, inaccessibleCount: 0))],
        failure: ScanError? = nil,
        usage: VolumeUsage = VolumeUsage(totalCapacity: 2_000, availableCapacity: 800, availableForImportantUsage: nil)
    ) -> LocationScanModel {
        LocationScanModel(
            location: ScanLocation(url: TreeBuilder.root, displayName: "Scan Place", isWholeVolume: wholeVolume),
            volumeInfo: FixedVolume(usage: usage),
            access: GrantedAccess(),
            revealer: revealer,
            trash: trash,
            ledger: ledger,
            ruleEngine: RuleEngine(home: URL(filePath: "/Users/dev", directoryHint: .isDirectory), markers: NoMarkers()),
            snapshots: snapshots,
            makeScanner: { _ in StubScanner(events: events, failure: failure) }
        )
    }

    private func scanned(_ model: LocationScanModel) async -> LocationScanModel {
        model.startScan()
        await model.scanTask?.value
        return model
    }

    private func child(_ name: String, of node: FileNode?) -> FileNode? {
        node?.children.first { $0.name == name }
    }

    @Test("should show the scan result with the location's name at the root")
    func finishedScan() async {
        let model = await scanned(makeModel())

        #expect(model.phase == .finished)
        #expect(model.tree?.allocatedSize == 1_000)
        #expect(model.title(for: model.tree!) == "Scan Place")
        #expect(model.rows.map(\.name) == ["Apps", "Docs", "movie.mov"])
        #expect(!model.segments.isEmpty)
    }

    @Test("should add the volume's unattributed space to a whole-volume scan")
    func unattributedSpace() async {
        let model = await scanned(makeModel(wholeVolume: true))

        #expect(model.tree?.allocatedSize == 1_200)
        #expect(model.tree?.children.contains { $0.kind == .unattributed && $0.allocatedSize == 200 } == true)
    }

    @Test("should show measured folders and the unmeasured remainder while scanning")
    func progressiveTree() async {
        var progress = ScanProgress()
        progress.allocatedSize = 600
        progress.completedTopLevel = [TreeBuilder.folder("Apps", [TreeBuilder.file("Apps/Big.app", 600)])]
        let model = await scanned(makeModel(wholeVolume: true, events: [.progress(progress)]))

        #expect(model.phase == .scanning)
        #expect(model.tree?.allocatedSize == 1_200)
        #expect(model.tree?.children.contains { $0.kind == .pending && $0.allocatedSize == 600 } == true)
        #expect(model.canGoBack == false)
    }

    @Test("should explain a failed scan with the error's message and next step")
    func failedScan() async {
        let model = await scanned(makeModel(events: [], failure: .rootNotFound(TreeBuilder.root)))

        guard case .failed(let message, let suggestion) = model.phase else {
            Issue.record("Expected a failed phase")
            return
        }
        #expect(message.contains("Scan"))
        #expect(suggestion?.isEmpty == false)
        #expect(model.tree == nil)
    }

    @Test("should clear results when the scan is stopped")
    func stopScan() async {
        let model = await scanned(makeModel())

        model.stopScan()

        #expect(model.phase == .idle)
        #expect(model.tree == nil)
        #expect(model.rows.isEmpty)
    }

    @Test("should open folders, go up, and move back and forward through history")
    func navigation() async throws {
        let model = await scanned(makeModel())
        let docs = try #require(child("Docs", of: model.currentFolder))

        model.open(docs)
        #expect(model.currentFolder?.name == "Docs")
        #expect(model.canGoBack && model.canGoUp && !model.canGoForward)

        model.goBack()
        #expect(model.currentFolder?.id == model.tree?.id)
        #expect(model.canGoForward)

        model.goForward()
        #expect(model.currentFolder?.name == "Docs")

        model.goUp()
        #expect(model.currentFolder?.id == model.tree?.id)
        #expect(model.selection?.name == "Docs")
        #expect(!model.canGoForward)
    }

    @Test("should open a folder two rings deep in one step, keeping the path")
    func openDeepFolder() async throws {
        let model = await scanned(makeModel())
        let reports = try #require(model.node(withID: TreeBuilder.root.appending(path: "Docs/Reports", directoryHint: .isDirectory).path(percentEncoded: false)))

        model.open(reports)

        #expect(model.path.map(\.name) == ["Scan", "Docs", "Reports"])
        model.goToAncestor(at: 0)
        #expect(model.path.count == 1)
    }

    @Test("should not open files or empty folders")
    func openIgnoresFiles() async throws {
        let model = await scanned(makeModel())
        let movie = try #require(child("movie.mov", of: model.currentFolder))

        model.open(movie)

        #expect(model.path.count == 1)
    }

    @Test("should move the selection between siblings with wrap-around, and between rings")
    func keyboardSelection() async {
        let model = await scanned(makeModel())

        model.selectSibling(offset: 1)
        #expect(model.selection?.name == "Apps")
        model.selectSibling(offset: -1)
        #expect(model.selection?.name == "movie.mov")
        model.selectSibling(offset: -1)
        #expect(model.selection?.name == "Docs")

        model.selectChildRing()
        #expect(model.selection?.name == "Reports")
        model.selectParentRing()
        #expect(model.selection?.name == "Docs")

        model.openSelection()
        #expect(model.currentFolder?.name == "Docs")
    }

    @Test("should search below the current folder and open a result's folder")
    func search() async throws {
        let model = await scanned(makeModel())

        model.searchText = "q1"
        #expect(model.rows.map(\.name) == ["q1.pdf"])

        model.searchText = "zzz"
        #expect(model.rows.isEmpty)

        model.searchText = "reports"
        let reports = try #require(model.rows.first)
        model.open(reports)
        #expect(model.path.map(\.name) == ["Scan", "Docs", "Reports"])
        #expect(model.searchText.isEmpty)
    }

    @Test("should sort rows by the chosen column")
    func sorting() async {
        let model = await scanned(makeModel())

        model.sortOrder = [KeyPathComparator(\FileNode.name)]

        #expect(model.rows.map(\.name) == ["Apps", "Docs", "movie.mov"].sorted())
    }

    @Test("should reveal the selection in Finder, or the current folder when nothing is selected")
    func reveal() async throws {
        let model = await scanned(makeModel())

        model.revealInFinder()
        let apps = try #require(child("Apps", of: model.currentFolder))
        model.select(apps)
        model.revealInFinder()

        #expect(revealer.revealed == [TreeBuilder.root, apps.url])
    }

    @Test("should match each row's color to its chart segment")
    func rowFills() async throws {
        let model = await scanned(makeModel())
        let apps = try #require(child("Apps", of: model.currentFolder))

        #expect(model.fill(for: apps) == .slot(index: 0, depth: 1))
        #expect(model.fill(for: apps) == model.segments.first { $0.nodeID == apps.id }?.fill)
    }

    // MARK: - Trash

    @Test("should move an item to the Trash, update the tree without rescanning, and record it")
    func moveToTrash() async throws {
        let model = await scanned(makeModel())
        let apps = try #require(child("Apps", of: model.currentFolder))

        model.moveToTrash(apps, undoManager: nil)

        #expect(trash.trashed == [apps.url])
        #expect(model.tree?.allocatedSize == 400)
        #expect(model.rows.map(\.name) == ["Docs", "movie.mov"])
        #expect(ledger.records.map(\.node.name) == ["Apps"])
        #expect(ledger.totalSize == 600)
        #expect(model.lastTrashed?.node.name == "Apps")
    }

    @Test("should undo Move to Trash through the undo manager")
    func undoMoveToTrash() async throws {
        let model = await scanned(makeModel())
        let undoManager = UndoManager()
        let reports = try #require(model.node(withID: TreeBuilder.root.appending(path: "Docs/Reports", directoryHint: .isDirectory).path(percentEncoded: false)))

        model.moveToTrash(reports, undoManager: undoManager)
        #expect(model.tree?.allocatedSize == 800)
        undoManager.undo()

        #expect(trash.putBack == [reports.url])
        #expect(model.tree?.allocatedSize == 1_000)
        #expect(ledger.records.isEmpty)
        #expect(model.lastTrashed == nil)
    }

    @Test("should keep used space unchanged on a whole volume, moving trashed space into Other Used Space")
    func trashOnWholeVolume() async throws {
        let model = await scanned(makeModel(wholeVolume: true))
        let apps = try #require(child("Apps", of: model.currentFolder))

        model.moveToTrash(apps, undoManager: nil)

        #expect(model.tree?.allocatedSize == 1_200)
        #expect(model.tree?.children.first { $0.kind == .unattributed }?.allocatedSize == 800)
    }

    @Test("should go to the enclosing folder when the open folder is moved to the Trash")
    func trashCurrentFolder() async throws {
        let model = await scanned(makeModel())
        model.open(try #require(child("Docs", of: model.currentFolder)))

        model.moveToTrash(model.currentFolder, undoManager: nil)

        #expect(model.path.count == 1)
        #expect(model.rows.map(\.name) == ["Apps", "movie.mov"])
    }

    @Test("should report a failed move and leave the tree unchanged")
    func failedMove() async throws {
        let model = await scanned(makeModel())
        let apps = try #require(child("Apps", of: model.currentFolder))
        // The real service converts Cocoa errors into TrashError before throwing.
        trash.failure = TrashError(movingToTrash: apps.url, underlying: CocoaError(.fileWriteNoPermission))

        model.moveToTrash(apps, undoManager: nil)

        #expect(model.actionError?.message.contains("Apps") == true)
        #expect(model.tree?.allocatedSize == 1_000)
        #expect(ledger.records.isEmpty)
    }

    @Test("should only offer Move to Trash for real files and folders below the scanned location")
    func trashEligibility() async throws {
        let model = await scanned(makeModel(wholeVolume: true))
        let other = try #require(model.tree?.children.first { $0.kind == .unattributed })

        #expect(!model.canMoveToTrash(model.tree))
        #expect(!model.canMoveToTrash(other))
        #expect(model.canMoveToTrash(child("movie.mov", of: model.currentFolder)))
    }

    // MARK: - Cleanup rules

    private func modelWithDerivedData() -> LocationScanModel {
        let derived = FileNode.directory(url: URL(filePath: "/Users/dev/Library/Developer/Xcode/DerivedData", directoryHint: .isDirectory), modificationDate: nil,
                                         children: [.file(url: URL(filePath: "/Users/dev/Library/Developer/Xcode/DerivedData/App"), allocatedSize: 700, modificationDate: nil)])
        let archives = FileNode.directory(url: URL(filePath: "/Users/dev/Library/Developer/Xcode/Archives", directoryHint: .isDirectory), modificationDate: nil,
                                          children: [.file(url: URL(filePath: "/Users/dev/Library/Developer/Xcode/Archives/A"), allocatedSize: 300, modificationDate: nil)])
        func folder(_ path: String, _ children: [FileNode]) -> FileNode {
            .directory(url: URL(filePath: path, directoryHint: .isDirectory), modificationDate: nil, children: children)
        }
        let root = folder("/Users/dev", [folder("/Users/dev/Library", [folder("/Users/dev/Library/Developer", [folder("/Users/dev/Library/Developer/Xcode", [derived, archives])])])])
        return LocationScanModel(
            location: ScanLocation(url: URL(filePath: "/Users/dev", directoryHint: .isDirectory), displayName: "Home", isWholeVolume: false),
            volumeInfo: FixedVolume(usage: VolumeUsage(totalCapacity: 0, availableCapacity: 0, availableForImportantUsage: nil)),
            access: GrantedAccess(), revealer: revealer, trash: trash, ledger: ledger,
            ruleEngine: RuleEngine(home: URL(filePath: "/Users/dev", directoryHint: .isDirectory), markers: NoMarkers()),
            snapshots: snapshots,
            makeScanner: { _ in StubScanner(events: [.finished(ScanResult(root: root, duration: .seconds(1), fileCount: 2, directoryCount: 6, inaccessibleCount: 0))]) }
        )
    }

    @Test("should find developer artifacts after a scan, largest first")
    func cleanupMatchesAfterScan() async throws {
        let model = await scanned(modelWithDerivedData())
        await model.cleanupTask?.value

        #expect(model.cleanupMatches.map(\.rule.id) == ["xcode.derivedData", "xcode.archives"])
        #expect(model.canHighlightReclaimable)
        let derived = try #require(model.cleanupMatches.first?.node)
        #expect(model.cleanupMatch(for: derived)?.rule.safety == .safe)
    }

    @Test("should never offer Move to Trash for items to keep, and color them by safety when highlighting")
    func keepAndHighlight() async throws {
        let model = await scanned(modelWithDerivedData())
        await model.cleanupTask?.value
        let archives = try #require(model.cleanupMatches.first { $0.rule.safety == .keep })

        model.moveToTrash(archives, undoManager: nil)
        #expect(trash.trashed.isEmpty)

        model.isHighlightingReclaimable = true
        let derivedMatch = try #require(model.cleanupMatches.first { $0.rule.safety == .safe })
        #expect(model.displayFill(for: derivedMatch.node) == .safety(.safe))
    }

    @Test("should move a matched cache to the Trash from the Developer view and drop its match")
    func trashFromDeveloperView() async throws {
        let model = await scanned(modelWithDerivedData())
        await model.cleanupTask?.value
        let derived = try #require(model.cleanupMatches.first { $0.rule.safety == .safe })

        model.moveToTrash(derived, undoManager: nil)
        #expect(!model.cleanupMatches.contains { $0.node.id == derived.node.id })
        await model.cleanupTask?.value

        #expect(trash.trashed == [derived.node.url])
        #expect(model.tree?.allocatedSize == 300)
        #expect(model.cleanupMatches.map(\.rule.id) == ["xcode.archives"])
    }

    // MARK: - History

    private func model(events: [ScanEvent]) -> LocationScanModel {
        LocationScanModel(
            location: ScanLocation(url: TreeBuilder.root, displayName: "Scan Place", isWholeVolume: false),
            volumeInfo: FixedVolume(usage: VolumeUsage(totalCapacity: 0, availableCapacity: 0, availableForImportantUsage: nil)),
            access: GrantedAccess(), revealer: revealer, trash: trash, ledger: ledger,
            ruleEngine: RuleEngine(rules: []), snapshots: snapshots,
            makeScanner: { _ in StubScanner(events: events) }
        )
    }

    private func finished(_ root: FileNode) -> [ScanEvent] {
        [.finished(ScanResult(root: root, duration: .seconds(1), fileCount: 0, directoryCount: 0, inaccessibleCount: 0))]
    }

    private func scannedWithHistory(_ model: LocationScanModel) async -> LocationScanModel {
        let model = await scanned(model)
        await model.cleanupTask?.value
        await model.historyTask?.value
        return model
    }

    @Test("should save a snapshot after the first scan and show growth after the next one")
    func growthBetweenScans() async throws {
        let first = await scannedWithHistory(model(events: finished(TreeBuilder.sample())))
        #expect(first.growth == nil)
        #expect(snapshots.all.count == 1)

        let bigger = FileNode.directory(url: TreeBuilder.root, modificationDate: nil, children: [
            TreeBuilder.folder("Apps", [TreeBuilder.file("Apps/Big.app", 50_000_000_500), TreeBuilder.file("Apps/Small.app", 100)]),
            TreeBuilder.folder("Docs", [TreeBuilder.folder("Docs/Reports", [TreeBuilder.file("Docs/Reports/q1.pdf", 200)]), TreeBuilder.file("Docs/notes.txt", 100)]),
            TreeBuilder.file("movie.mov", 100),
        ])
        let second = await scannedWithHistory(model(events: finished(bigger)))

        let apps = try #require(second.rows.first { $0.name == "Apps" })
        #expect(second.growth(for: apps)?.kind == .grew)
        #expect(second.growth?.biggestChanges().first?.path.hasSuffix("/Apps/Big.app") == true)
        #expect(snapshots.all.count == 2)
    }

    @Test("should open the folder that holds a changed item and select it")
    func showChangedItem() async throws {
        let model = await scannedWithHistory(model(events: finished(TreeBuilder.sample())))

        model.showItem(atPath: TreeBuilder.root.appending(path: "Docs/notes.txt").path(percentEncoded: false))

        #expect(model.currentFolder?.name == "Docs")
        #expect(model.selection?.name == "notes.txt")
    }

    @Test("should list the largest files after a scan and move one to the Trash from that list")
    func largeFiles() async throws {
        let model = await scanned(makeModel())
        await model.cleanupTask?.value
        #expect(model.largeFiles.first?.node.name == "Big.app")
        let q1 = try #require(model.largeFiles.first { $0.node.name == "q1.pdf" })

        model.moveToTrash(q1, undoManager: nil)

        #expect(trash.trashed == [q1.node.url])
        #expect(!model.largeFiles.contains { $0.id == q1.id })
        #expect(model.tree?.allocatedSize == 800)
    }

    @Test("should not offer Move to Trash for a large file inside a folder to keep")
    func largeFileInKeptFolder() async throws {
        let model = await scanned(modelWithDerivedData())
        await model.cleanupTask?.value
        let archived = try #require(model.largeFiles.first { $0.node.name == "A" })
        let cache = try #require(model.largeFiles.first { $0.node.name == "App" })

        #expect(!model.canMoveToTrash(archived))
        #expect(model.canMoveToTrash(cache))
        model.moveToTrash(archived, undoManager: nil)
        #expect(trash.trashed.isEmpty)
    }

    @Test("should compare the two saved scans when nothing has been scanned in this session")
    func savedGrowthWithoutScanning() async throws {
        let path = TreeBuilder.root.path(percentEncoded: false)
        let mb = Int64(1_000_000)
        try snapshots.save(ScanSnapshot(version: ScanSnapshot.currentVersion, locationPath: path, date: Date(timeIntervalSince1970: 1), sizes: ["/Scan/Apps": 100 * mb], unreadPaths: []))
        try snapshots.save(ScanSnapshot(version: ScanSnapshot.currentVersion, locationPath: path, date: Date(timeIntervalSince1970: 2), sizes: ["/Scan/Apps": 400 * mb], unreadPaths: []))
        let model = makeModel()

        model.loadSavedGrowth()
        await model.historyTask?.value

        #expect(model.growthIsFromSavedScans)
        #expect(model.growth?.change(forPath: "/Scan/Apps")?.delta == 300 * mb)
    }

    @Test("should replace the saved-scan comparison once a scan finishes")
    func scanReplacesSavedGrowth() async throws {
        let model = makeModel()
        model.loadSavedGrowth()
        await model.historyTask?.value

        _ = await scanned(model)
        await model.cleanupTask?.value
        await model.historyTask?.value

        #expect(!model.growthIsFromSavedScans)
    }

    @Test("should move an item dropped on the Trash, and ignore drops from outside the scan")
    func dropOnTrash() async throws {
        let model = await scanned(makeModel())
        let apps = try #require(child("Apps", of: model.currentFolder))

        let moved = model.moveToTrash(droppedURLs: [apps.url, URL(filePath: "/Elsewhere/thing")], undoManager: nil)

        #expect(moved)
        #expect(trash.trashed == [apps.url])
        #expect(model.rows.map(\.name) == ["Docs", "movie.mov"])
    }

    @Test("should refuse a drop of an item a rule protects")
    func dropOfProtectedItem() async throws {
        let model = await scanned(modelWithDerivedData())
        await model.cleanupTask?.value
        let archives = try #require(model.cleanupMatches.first { $0.rule.safety == .keep })

        let moved = model.moveToTrash(droppedURLs: [archives.node.url], undoManager: nil)

        #expect(!moved)
        #expect(trash.trashed.isEmpty)
    }
}
