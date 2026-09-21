import Foundation
import Synchronization

nonisolated protocol DiskScanning: Sendable {
    /// Measures `root` and everything below it. The stream publishes progress snapshots and ends
    /// with `.finished`, or throws `ScanError` for an unusable root. Cancelling the consuming task
    /// (or dropping the stream) stops the scan.
    func scan(_ root: URL) -> AsyncThrowingStream<ScanEvent, Error>
}

/// Walks a folder tree off the main actor and measures space on disk.
///
/// Correctness rules (see DEVPLAN "Constraints"):
/// - Sizes are allocated sizes; a hard-linked file is counted once.
/// - Symbolic links are never followed.
/// - Directories that are volume roots or mount triggers below the scan root are skipped. That keeps
///   mounted disk images, other volumes, and the Data volume's own mount point
///   (`/System/Volumes/Data`) out of the totals, so scanning `/` reads the Data volume only once,
///   through its firmlinks (`/Users`, `/Applications`, …).
/// - Unreadable folders become `.inaccessible` nodes instead of failing the scan.
/// - The file system's virtual root folders (`configuration.skippedPaths`) are never visited.
/// - Folders in `configuration.unreadFolders` are never opened, so scanning without Full Disk Access
///   doesn't trigger one consent prompt per protected folder.
nonisolated struct FileSystemScanner: DiskScanning {
    let configuration: ScanConfiguration

    init(configuration: ScanConfiguration = .standard) {
        self.configuration = configuration
    }

    func scan(_ root: URL) -> AsyncThrowingStream<ScanEvent, Error> {
        AsyncThrowingStream { continuation in
            let work = Task {
                do {
                    let result = try await run(root: root, continuation: continuation)
                    continuation.yield(.finished(result))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in work.cancel() }
        }
    }

    private func run(root: URL, continuation: AsyncThrowingStream<ScanEvent, Error>.Continuation) async throws -> ScanResult {
        let start = ContinuousClock.now
        let rootValues = try validateRoot(root)
        let context = ScanContext()

        let ticker = Task {
            while !Task.isCancelled {
                // Sleep only fails on cancellation, which also ends the loop.
                try? await Task.sleep(for: configuration.progressInterval)
                continuation.yield(.progress(context.snapshot()))
            }
        }
        defer { ticker.cancel() }

        let node = try await scanDirectory(root, modificationDate: rootValues.contentModificationDate, depth: 0, context: context)
        let tally = context.snapshot()
        return ScanResult(
            root: node,
            duration: start.duration(to: .now),
            fileCount: tally.fileCount,
            directoryCount: tally.directoryCount,
            inaccessibleCount: tally.inaccessibleCount
        )
    }

    private func validateRoot(_ root: URL) throws -> URLResourceValues {
        let values: URLResourceValues
        do {
            values = try root.resourceValues(forKeys: [.isDirectoryKey, .contentModificationDateKey])
        } catch {
            throw ScanError.rootNotFound(root)
        }
        guard values.isDirectory == true else { throw ScanError.rootNotFolder(root) }
        guard FileManager.default.isReadableFile(atPath: root.path(percentEncoded: false)) else {
            throw ScanError.rootUnreadable(root)
        }
        return values
    }

    // MARK: - Walking

    private func scanDirectory(_ url: URL, modificationDate: Date?, depth: Int, context: ScanContext) async throws -> FileNode {
        guard depth < configuration.parallelDepth else {
            return try scanDirectorySynchronously(url, modificationDate: modificationDate, context: context)
        }
        try Task.checkCancellation()
        guard let listing = read(url, context: context) else { return .inaccessible(url: url) }

        let subdirectories = try await withThrowingTaskGroup(of: FileNode.self) { group in
            for directory in listing.directories {
                group.addTask {
                    try await scanDirectory(directory.url, modificationDate: directory.modificationDate, depth: depth + 1, context: context)
                }
            }
            var nodes: [FileNode] = []
            for try await node in group {
                nodes.append(node)
                if depth == 0 { context.recordCompletedTopLevel(node) }
            }
            return nodes
        }
        return .directory(url: url, modificationDate: modificationDate, children: listing.fileNodes + subdirectories)
    }

    private func scanDirectorySynchronously(_ url: URL, modificationDate: Date?, context: ScanContext) throws -> FileNode {
        try Task.checkCancellation()
        guard let listing = read(url, context: context) else { return .inaccessible(url: url) }
        let subdirectories = try listing.directories.map {
            try scanDirectorySynchronously($0.url, modificationDate: $0.modificationDate, context: context)
        }
        return .directory(url: url, modificationDate: modificationDate, children: listing.fileNodes + subdirectories)
    }

    // MARK: - Reading one directory

    private struct Listing {
        var fileNodes: [FileNode] = []
        var directories: [(url: URL, modificationDate: Date?)] = []
    }

    private static let keys: [URLResourceKey] = [
        .isDirectoryKey, .isSymbolicLinkKey, .isVolumeKey, .isMountTriggerKey,
        .totalFileAllocatedSizeKey, .fileAllocatedSizeKey, .linkCountKey, .fileIdentifierKey,
        .contentModificationDateKey,
    ]
    private static let keySet = Set(keys)

    /// Returns `nil` when the directory can't be listed, after recording it as inaccessible.
    private func read(_ url: URL, context: ScanContext) -> Listing? {
        // Listing creates many autoreleased Foundation objects; without a pool per directory they
        // pile up until the whole subtree task ends.
        autoreleasepool { readEntries(of: url, context: context) }
    }

    private func readEntries(of url: URL, context: ScanContext) -> Listing? {
        let entries: [URL]
        do {
            entries = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: Self.keys)
        } catch {
            context.recordInaccessible()
            return nil
        }

        var listing = Listing()
        var smallCount = 0
        var smallSize: Int64 = 0
        var listedBytes: Int64 = 0
        var fileCount = 0

        for entry in entries {
            guard let values = try? entry.resourceValues(forKeys: Self.keySet) else {
                // The entry vanished between listing and reading; there is nothing left to measure.
                continue
            }
            if values.isDirectory == true && values.isSymbolicLink != true {
                if values.isVolume == true || values.isMountTrigger == true { continue }
                let comparable = ScanConfiguration.comparablePath(of: entry)
                if configuration.skippedPaths.contains(comparable) { continue }
                if configuration.unreadFolders.contains(comparable) {
                    context.recordInaccessible()
                    listing.fileNodes.append(.inaccessible(url: entry))
                    continue
                }
                listing.directories.append((entry, values.contentModificationDate))
                continue
            }
            let size = allocatedSize(of: values, context: context)
            listedBytes += size
            fileCount += 1
            if size >= configuration.individualFileThreshold {
                listing.fileNodes.append(.file(url: entry, allocatedSize: size, modificationDate: values.contentModificationDate))
            } else {
                smallCount += 1
                smallSize += size
            }
        }
        if smallCount > 0 {
            listing.fileNodes.append(.smallerFiles(in: url, count: smallCount, allocatedSize: smallSize))
        }
        context.recordDirectory(url, fileCount: fileCount, allocatedSize: listedBytes)
        return listing
    }

    private func allocatedSize(of values: URLResourceValues, context: ScanContext) -> Int64 {
        let size = Int64(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? 0)
        guard (values.linkCount ?? 1) > 1, let identifier = values.fileIdentifier else { return size }
        return context.claimHardLink(identifier) ? size : 0
    }
}

/// Shared, lock-protected state for one scan.
nonisolated private final class ScanContext: Sendable {
    private let progress = Mutex(ScanProgress())
    private let seenHardLinks = Mutex(Set<UInt64>())

    func snapshot() -> ScanProgress {
        progress.withLock { $0 }
    }

    func recordDirectory(_ url: URL, fileCount: Int, allocatedSize: Int64) {
        progress.withLock {
            $0.directoryCount += 1
            $0.fileCount += fileCount
            $0.allocatedSize += allocatedSize
            $0.currentDirectory = url
        }
    }

    func recordInaccessible() {
        progress.withLock { $0.inaccessibleCount += 1 }
    }

    func recordCompletedTopLevel(_ node: FileNode) {
        progress.withLock { $0.completedTopLevel.append(node) }
    }

    /// Returns true the first time a hard-linked file is seen, so its space is counted once.
    func claimHardLink(_ identifier: UInt64) -> Bool {
        seenHardLinks.withLock { $0.insert(identifier).inserted }
    }
}
