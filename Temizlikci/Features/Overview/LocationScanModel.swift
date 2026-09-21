import Foundation
import Observation

/// Scan, navigation, selection, and search for one location (startup disk, Home, or a chosen folder).
@MainActor
@Observable
final class LocationScanModel {
    enum Phase: Equatable {
        case idle
        case scanning
        case finished
        case failed(message: String, suggestion: String?)
    }

    /// An action that failed, shown as an alert with what happened and what to do.
    struct ActionError: Identifiable {
        let id = UUID()
        let message: String
        let suggestion: String?
    }

    let location: ScanLocation

    private(set) var phase: Phase = .idle
    private(set) var progress = ScanProgress()
    private(set) var result: ScanResult?
    private(set) var usage: VolumeUsage?
    private(set) var finishedAt: Date?

    /// What the chart and list show: the scan result plus unattributed space, or a partial tree while scanning.
    private(set) var tree: FileNode?
    /// Folders from `tree` down to the folder shown in the chart.
    private(set) var path: [FileNode] = []
    private var backStack: [[FileNode]] = []
    private var forwardStack: [[FileNode]] = []

    private(set) var segments: [SunburstSegment] = []
    /// For every node reachable from the current folder through the chart or search: its chain of
    /// folders, starting with the current folder.
    private var chains: [String: [FileNode]] = [:]
    private var slots: [String: Int] = [:]

    private(set) var selection: FileNode?
    var hoveredID: String?
    var previewURL: URL?
    var searchText = "" {
        didSet { refreshRows() }
    }
    var sortOrder = [KeyPathComparator(\FileNode.allocatedSize, order: .reverse)] {
        didSet { refreshRows() }
    }
    private(set) var rows: [FileNode] = []

    /// The most recent Move to Trash, shown as a confirmation with Undo until dismissed.
    private(set) var lastTrashed: TrashRecord?
    var actionError: ActionError?
    /// True when the tree could not be updated in place and a rescan would show sizes more accurately.
    private(set) var isOutdated = false

    private let makeScanner: (ScanConfiguration) -> DiskScanning
    private let volumeInfo: VolumeInfoProviding
    private let access: FullDiskAccessChecking
    private let revealer: FileRevealing
    private let trash: Trashing
    private let ledger: TrashLedger
    private(set) var scanTask: Task<Void, Never>?

    /// Search stops after this many matches so typing stays responsive on large trees.
    static let searchResultLimit = 500

    init(
        location: ScanLocation,
        volumeInfo: VolumeInfoProviding,
        access: FullDiskAccessChecking,
        revealer: FileRevealing,
        trash: Trashing,
        ledger: TrashLedger,
        makeScanner: @escaping (ScanConfiguration) -> DiskScanning
    ) {
        self.location = location
        self.volumeInfo = volumeInfo
        self.access = access
        self.revealer = revealer
        self.trash = trash
        self.ledger = ledger
        self.makeScanner = makeScanner
    }

    // MARK: - Derived state

    var currentFolder: FileNode? { path.last }
    var isScanning: Bool { phase == .scanning }
    var hasResult: Bool { phase == .finished }
    var canGoBack: Bool { hasResult && !backStack.isEmpty }
    var canGoForward: Bool { hasResult && !forwardStack.isEmpty }
    var canGoUp: Bool { hasResult && path.count > 1 }

    /// What the chart center describes: the hovered item, else the selection, else the current folder.
    var focusNode: FileNode? {
        hoveredID.flatMap(node(withID:)) ?? selection ?? currentFolder
    }

    func node(withID id: String) -> FileNode? {
        if id == currentFolder?.id { return currentFolder }
        return chains[id]?.last
    }

    // MARK: - Scanning

    func startScan() {
        scanTask?.cancel()
        let scanner = makeScanner(ScanConfiguration.forScan(access: access))
        // Capacity only adds the unmeasured and unattributed segments; without it the scan is still correct.
        usage = location.isWholeVolume ? try? volumeInfo.usage(ofVolumeContaining: location.url) : nil
        phase = .scanning
        progress = ScanProgress()
        result = nil
        finishedAt = nil
        show(nil)

        let events = scanner.scan(location.url)
        scanTask = Task { [weak self] in
            do {
                for try await event in events {
                    guard let self else { return }
                    switch event {
                    case .progress(let snapshot): self.apply(snapshot)
                    case .finished(let finished): self.finish(finished)
                    }
                }
            } catch is CancellationError {
                // Stopping is intentional; `stopScan()` already reset the state.
            } catch {
                self?.fail(error)
            }
        }
    }

    func stopScan() {
        scanTask?.cancel()
        scanTask = nil
        phase = .idle
        show(nil)
    }

    private func apply(_ snapshot: ScanProgress) {
        progress = snapshot
        var children = snapshot.completedTopLevel
        let measured = children.reduce(0) { $0 + $1.allocatedSize }
        if let usage, usage.usedCapacity > measured {
            children.append(.pending(in: location.url, allocatedSize: usage.usedCapacity - measured))
        }
        let partial = FileNode.directory(url: location.url, modificationDate: nil, children: children)
        tree = partial
        path = [partial]
        refreshLayout()
        refreshRows()
    }

    private func finish(_ finished: ScanResult) {
        result = finished
        finishedAt = Date()
        var root = finished.root
        if let usage {
            let unattributed = usage.unattributed(scannedSize: root.allocatedSize)
            if unattributed > 0 {
                root = root.adding(.unattributed(on: location.url, allocatedSize: unattributed))
            }
        }
        phase = .finished
        scanTask = nil
        show(root)
    }

    private func fail(_ error: Error) {
        let described = error as? LocalizedError
        phase = .failed(
            message: described?.errorDescription ?? error.localizedDescription,
            suggestion: described?.recoverySuggestion
        )
        scanTask = nil
        show(nil)
    }

    private func show(_ root: FileNode?) {
        tree = root
        path = root.map { [$0] } ?? []
        backStack = []
        forwardStack = []
        selection = nil
        hoveredID = nil
        searchText = ""
        lastTrashed = nil
        isOutdated = false
        refreshLayout()
        refreshRows()
    }

    // MARK: - Trash

    func canMoveToTrash(_ node: FileNode?) -> Bool {
        guard hasResult, let node, node.id != tree?.id else { return false }
        return node.kind == .directory || node.kind == .file
    }

    /// Moves `node` to the Trash, updates the tree without rescanning, and registers Undo.
    /// No confirmation: the action is undoable (HIG Alerts).
    func moveToTrash(_ node: FileNode?, undoManager: UndoManager?) {
        guard let node, canMoveToTrash(node), let tree, let ids = absolutePath(to: node) else { return }
        let trashedURL: URL
        do {
            trashedURL = try trash.moveToTrash(node.url)
        } catch {
            report(error)
            return
        }
        let record = TrashRecord(
            node: node, originalURL: node.url, trashedURL: trashedURL, date: Date(),
            locationURL: location.url, ancestorIDs: Array(ids.dropLast())
        )
        if let updated = tree.removingDescendant(at: ids.dropFirst()) {
            replaceTree(with: updated)
        } else {
            isOutdated = true
        }
        ledger.add(record)
        lastTrashed = record
        undoManager?.registerUndo(withTarget: self) { model in model.putBack(record) }
        undoManager?.setActionName(String(localized: L10n.Trash.moveToTrash))
    }

    /// Returns a trashed item to its folder and to the tree.
    func putBack(_ record: TrashRecord) {
        do {
            try trash.putBack(record.trashedURL, to: record.originalURL)
        } catch {
            report(error)
            return
        }
        ledger.remove(record)
        if lastTrashed?.id == record.id { lastTrashed = nil }
        guard let tree, record.locationURL == location.url, record.ancestorIDs.first == tree.id,
              let updated = tree.insertingDescendant(record.node, under: record.ancestorIDs.dropFirst()) else {
            isOutdated = hasResult
            return
        }
        replaceTree(with: updated)
    }

    func dismissTrashConfirmation() {
        lastTrashed = nil
    }

    private func report(_ error: Error) {
        let described = error as? LocalizedError
        actionError = ActionError(
            message: described?.errorDescription ?? error.localizedDescription,
            suggestion: described?.recoverySuggestion
        )
    }

    /// IDs from the tree root down to `node`.
    private func absolutePath(to node: FileNode) -> [String]? {
        let pathIDs = path.map(\.id)
        if node.id == currentFolder?.id { return pathIDs }
        guard let chain = chains[node.id] else { return nil }
        return pathIDs + chain.dropFirst().map(\.id)
    }

    private func replaceTree(with updated: FileNode) {
        let root = rebalancingUnattributed(updated)
        let oldPath = path.map(\.id)
        tree = root
        path = root.nodes(along: oldPath)
        backStack = []
        forwardStack = []
        selection = nil
        hoveredID = nil
        refreshLayout()
        refreshRows()
    }

    /// Trashed items still use space until the Trash is emptied, so used capacity doesn't change:
    /// whatever leaves the scanned folders moves into Other Used Space.
    private func rebalancingUnattributed(_ root: FileNode) -> FileNode {
        guard let usage else { return root }
        let scanned = FileNode.directory(url: root.url, modificationDate: root.modificationDate,
                                         children: root.children.filter { $0.kind != .unattributed })
        let other = usage.unattributed(scannedSize: scanned.allocatedSize)
        return other > 0 ? scanned.adding(.unattributed(on: location.url, allocatedSize: other)) : scanned
    }

    // MARK: - Navigation

    func open(_ node: FileNode) {
        guard hasResult, node.kind == .directory, !node.children.isEmpty, node.id != currentFolder?.id,
              let chain = chains[node.id] else { return }
        navigate(to: path + chain.dropFirst())
        selection = nil
    }

    func openSelection() {
        if let selection { open(selection) }
    }

    func goUp() {
        guard canGoUp, let leaving = currentFolder else { return }
        navigate(to: Array(path.dropLast()))
        select(leaving)
    }

    func goBack() {
        guard canGoBack, let previous = backStack.popLast() else { return }
        forwardStack.append(path)
        path = previous
        didNavigate()
    }

    func goForward() {
        guard canGoForward, let next = forwardStack.popLast() else { return }
        backStack.append(path)
        path = next
        didNavigate()
    }

    func goToAncestor(at index: Int) {
        guard hasResult, index < path.count - 1 else { return }
        navigate(to: Array(path.prefix(index + 1)))
    }

    private func navigate(to newPath: [FileNode]) {
        guard newPath.map(\.id) != path.map(\.id) else { return }
        backStack.append(path)
        forwardStack.removeAll()
        path = newPath
        didNavigate()
    }

    private func didNavigate() {
        selection = nil
        hoveredID = nil
        searchText = ""
        refreshLayout()
        refreshRows()
    }

    // MARK: - Selection

    /// Selects a node from the chart, the list, or the current folder (all of which have known chains).
    func select(_ node: FileNode?) {
        selection = node
    }

    func selectNode(withID id: String?) {
        select(id.flatMap(node(withID:)))
    }

    /// Moves the selection among its siblings, wrapping around. Selects the first item when nothing is selected.
    func selectSibling(offset: Int) {
        guard let current = selection, let chain = chains[current.id], chain.count >= 2 else {
            selectFirstChild(of: currentFolder)
            return
        }
        let parentChain = Array(chain.dropLast())
        let siblings = visibleChildren(of: chain[chain.count - 2])
        guard let index = siblings.firstIndex(where: { $0.id == current.id }), !siblings.isEmpty else { return }
        let next = siblings[(index + offset + siblings.count) % siblings.count]
        chains[next.id] = parentChain + [next]
        selection = next
    }

    /// Moves the selection one ring outward (to its parent), staying inside the current folder.
    func selectParentRing() {
        guard let current = selection, let chain = chains[current.id], chain.count > 2 else { return }
        selection = chain[chain.count - 2]
    }

    /// Moves the selection one ring inward (to its largest child), within the drawn rings.
    func selectChildRing() {
        guard let current = selection, let chain = chains[current.id], chain.count <= SunburstLayout.ringCount else {
            if selection == nil { selectFirstChild(of: currentFolder) }
            return
        }
        guard let child = visibleChildren(of: current).first else { return }
        chains[child.id] = chain + [child]
        selection = child
    }

    private func selectFirstChild(of folder: FileNode?) {
        guard let folder, let first = visibleChildren(of: folder).first else { return }
        chains[first.id] = [folder, first]
        selection = first
    }

    private func visibleChildren(of node: FileNode) -> [FileNode] {
        node.children.filter { $0.allocatedSize > 0 }
    }

    // MARK: - Presentation

    func title(for node: FileNode) -> String {
        if node.id == tree?.id { return location.displayName }
        switch node.kind {
        case .smallerFiles(let count): return String(localized: L10n.Nodes.smallerFiles(count.formatted()))
        case .unattributed: return String(localized: L10n.Nodes.unattributed)
        case .pending: return String(localized: L10n.Nodes.pending)
        case .directory, .file, .inaccessible: return node.name
        }
    }

    func title(for segment: SunburstSegment) -> String {
        if segment.isMerged { return String(localized: L10n.Nodes.mergedItems) }
        return segment.nodeID.flatMap(node(withID:)).map(title(for:)) ?? segment.name
    }

    /// The chart color role for a list row, so rows and segments always match.
    func fill(for node: FileNode) -> SegmentFill {
        switch node.kind {
        case .unattributed: return .unattributedHatch
        case .inaccessible: return .inaccessibleHatch
        case .pending: return .pending
        case .smallerFiles: return .neutral
        case .directory, .file:
            guard let chain = chains[node.id], chain.count >= 2, let slot = slots[chain[1].id] else { return .neutral }
            return .slot(index: slot, depth: chain.count - 1)
        }
    }

    func share(of node: FileNode, in container: FileNode?) -> Double? {
        guard let container, container.allocatedSize > 0 else { return nil }
        return Double(node.allocatedSize) / Double(container.allocatedSize)
    }

    /// The folder that contains `node`, if it is visible from the current folder.
    func parent(of node: FileNode) -> FileNode? {
        if node.id == currentFolder?.id { return path.dropLast().last }
        guard let chain = chains[node.id], chain.count >= 2 else { return nil }
        return chain[chain.count - 2]
    }

    // MARK: - Finder

    func actionableURL(for node: FileNode?) -> URL? {
        guard let node else { return nil }
        switch node.kind {
        case .directory, .file, .inaccessible, .smallerFiles: return node.url
        case .unattributed, .pending: return nil
        }
    }

    func revealInFinder() {
        if let url = actionableURL(for: selection ?? currentFolder) { revealer.reveal(url) }
    }

    func quickLook() {
        previewURL = actionableURL(for: selection ?? currentFolder)
    }

    // MARK: - Derived collections

    private func refreshLayout() {
        guard let folder = currentFolder else {
            segments = []
            chains = [:]
            slots = [:]
            return
        }
        segments = SunburstLayout.segments(for: folder)
        slots = SunburstLayout.slotAssignments(for: folder)
        var map: [String: [FileNode]] = [:]
        func walk(_ node: FileNode, chain: [FileNode]) {
            guard chain.count <= SunburstLayout.ringCount else { return }
            for child in node.children {
                let childChain = chain + [child]
                map[child.id] = childChain
                if child.kind == .directory { walk(child, chain: childChain) }
            }
        }
        walk(folder, chain: [folder])
        chains = map
    }

    private func refreshRows() {
        guard let folder = currentFolder else {
            rows = []
            return
        }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            rows = folder.children.filter { $0.allocatedSize > 0 || $0.kind == .inaccessible }.sorted(using: sortOrder)
            return
        }
        var matches: [FileNode] = []
        func search(_ node: FileNode, chain: [FileNode]) {
            for child in node.children where matches.count < Self.searchResultLimit {
                let childChain = chain + [child]
                if !child.name.isEmpty, child.name.localizedCaseInsensitiveContains(query) {
                    chains[child.id] = chains[child.id] ?? childChain
                    matches.append(child)
                }
                if child.kind == .directory { search(child, chain: childChain) }
            }
        }
        search(folder, chain: [folder])
        rows = matches.sorted(using: sortOrder)
    }
}
