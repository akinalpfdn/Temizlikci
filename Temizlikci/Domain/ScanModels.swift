import Foundation

nonisolated struct ScanConfiguration: Sendable {
    /// Files at least this large become their own node; smaller ones are summed per directory.
    var individualFileThreshold: Int64 = 10 * 1024 * 1024
    /// Directory levels scanned in parallel tasks; deeper levels are walked within those tasks.
    var parallelDepth = 2
    /// How often progress snapshots are published while scanning.
    var progressInterval: Duration = .milliseconds(150)
    /// Standardized paths of folders below the scan root that must not be opened (for example
    /// consent-prompting folders without Full Disk Access). They appear as `.inaccessible` nodes.
    var unreadFolders: Set<String> = []

    static let standard = ScanConfiguration()

    /// Canonical form used to compare folder paths: standardized, without a trailing slash.
    static func comparablePath(of url: URL) -> String {
        var path = url.standardizedFileURL.path(percentEncoded: false)
        while path.count > 1 && path.hasSuffix("/") { path.removeLast() }
        return path
    }
}

nonisolated struct ScanProgress: Sendable {
    var allocatedSize: Int64 = 0
    var fileCount = 0
    var directoryCount = 0
    var inaccessibleCount = 0
    var currentDirectory: URL?
    /// Top-level children of the scan root that are fully measured, for progressive rendering.
    var completedTopLevel: [FileNode] = []
}

nonisolated struct ScanResult: Sendable {
    let root: FileNode
    let duration: Duration
    let fileCount: Int
    let directoryCount: Int
    /// Folders that could not be read; their space is not in `root.allocatedSize`.
    let inaccessibleCount: Int
}

nonisolated enum ScanEvent: Sendable {
    case progress(ScanProgress)
    case finished(ScanResult)
}

nonisolated enum ScanError: LocalizedError, Equatable {
    case rootNotFound(URL)
    case rootNotFolder(URL)
    case rootUnreadable(URL)

    var errorDescription: String? {
        switch self {
        case .rootNotFound(let url):
            String(localized: L10n.ScanErrors.rootNotFound(url.lastPathComponent))
        case .rootNotFolder(let url):
            String(localized: L10n.ScanErrors.rootNotFolder(url.lastPathComponent))
        case .rootUnreadable(let url):
            String(localized: L10n.ScanErrors.rootUnreadable(url.lastPathComponent))
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .rootNotFound, .rootNotFolder:
            String(localized: L10n.ScanErrors.chooseAnotherFolder)
        case .rootUnreadable:
            String(localized: L10n.ScanErrors.grantAccess)
        }
    }
}
