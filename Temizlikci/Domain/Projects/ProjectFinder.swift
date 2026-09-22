import Foundation

/// A project folder found in a scan, with the build artifacts inside it.
nonisolated struct DeveloperProject: Sendable, Identifiable {
    let node: FileNode
    /// IDs from the scan's root down to the project folder.
    let idPath: [String]
    /// What made this folder a project ("Git repository", "Swift package", …).
    let evidence: ProjectEvidence
    /// Cleanup matches inside this project.
    let artifacts: [CleanupMatch]
    /// Newest change to the project's own files; `nil` when nothing could be read.
    let lastTouched: Date?

    var id: String { node.id }
    var url: URL { node.url }
    var name: String { node.name }

    /// Bytes held by artifacts that can be moved to the Trash.
    var reclaimableSize: Int64 {
        artifacts.filter { $0.rule.safety == .safe }.reduce(0) { $0 + $1.node.allocatedSize }
    }

    func isStale(on date: Date, after period: StalePeriod) -> Bool {
        guard let lastTouched else { return false }
        return date.timeIntervalSince(lastTouched) >= period.duration
    }
}

/// What identified a folder as a project. Shown to explain why it is listed.
nonisolated enum ProjectEvidence: String, Sendable, CaseIterable {
    case git, xcode, swiftPackage, node, flutter, rust, gradle, go, unity
}

/// How long a project must sit untouched before it is listed.
nonisolated enum StalePeriod: Int, Sendable, CaseIterable, Identifiable {
    case month = 30, quarter = 90, halfYear = 180, year = 365

    var id: Int { rawValue }
    var duration: TimeInterval { TimeInterval(rawValue) * 24 * 60 * 60 }
}

/// Reads when a project was last worked on. A protocol so tests don't touch the file system.
nonisolated protocol ProjectActivityReading: Sendable {
    func lastTouched(project url: URL, ignoring artifactNames: Set<String>) -> Date?
}

/// Finds project folders in a scan tree.
///
/// Markers are small files, which the scanner doesn't keep as nodes, so `.git` and `*.xcodeproj`
/// (both folders) are recognized from the tree and everything else is confirmed on disk. The
/// outermost project wins: a package inside `node_modules` belongs to the project that owns it.
nonisolated struct ProjectFinder: Sendable {
    /// Marker file → what it identifies. Checked next to a candidate folder.
    static let markers: [(file: String, evidence: ProjectEvidence)] = [
        ("Package.swift", .swiftPackage),
        ("package.json", .node),
        ("pubspec.yaml", .flutter),
        ("Cargo.toml", .rust),
        ("build.gradle", .gradle),
        ("build.gradle.kts", .gradle),
        ("go.mod", .go),
    ]

    let markerChecker: MarkerChecking
    let activity: ProjectActivityReading
    /// Folders that hold repositories belonging to tools, not to the developer.
    let ignoredPrefixes: [String]

    init(
        markers: MarkerChecking = FileSystemMarkerChecker(),
        activity: ProjectActivityReading = FileSystemProjectActivity(),
        home: URL = URL.homeDirectory
    ) {
        self.markerChecker = markers
        self.activity = activity
        let homePath = Self.trimmedPath(of: home)
        ignoredPrefixes = [
            homePath + "/Library", "/Library", "/System", "/Applications", "/usr", "/bin", "/sbin",
            "/private", "/opt", "/nix", "/Volumes/Preboot",
        ]
    }

    /// Projects in the tree, largest reclaimable artifacts first. `matches` comes from the rule engine.
    ///
    /// A folder holding `.git` or an Xcode project is recognized from the tree alone. Marker files
    /// are only looked for next to a folder that already contains a build artifact: asking the disk
    /// about every folder of a startup disk would mean hundreds of thousands of extra lookups.
    func projects(in root: FileNode, matches: [CleanupMatch]) -> [DeveloperProject] {
        let artifactNames = Set(matches.map(\.node.name))
        let markerCandidates = Set(matches.map { Self.trimmedPath(of: $0.node.url.deletingLastPathComponent()) })
        let artifactIDs = Set(matches.map(\.node.id))
        var found: [DeveloperProject] = []
        func visit(_ node: FileNode, idPath: [String]) {
            guard node.kind == .directory, !artifactIDs.contains(node.id) else { return }
            guard !isIgnored(node) else { return }
            if let evidence = evidence(for: node, markerCandidates: markerCandidates) {
                let path = Self.trimmedPath(of: node.url)
                let artifacts = matches.filter { $0.node.path.hasPrefix(path + "/") }
                found.append(DeveloperProject(
                    node: node, idPath: idPath, evidence: evidence, artifacts: artifacts,
                    lastTouched: activity.lastTouched(project: node.url, ignoring: artifactNames)
                ))
                return
            }
            for child in node.children where child.kind == .directory {
                let childID = autoreleasepool { child.id }
                visit(child, idPath: idPath + [childID])
            }
        }
        visit(root, idPath: [root.id])
        return found.sorted { $0.reclaimableSize > $1.reclaimableSize }
    }

    /// Homebrew taps, Xcode's caches and macOS itself are full of repositories nobody works on;
    /// listing them as stale projects would bury the developer's own work.
    private func isIgnored(_ node: FileNode) -> Bool {
        let path = autoreleasepool { Self.trimmedPath(of: node.url) }
        return ignoredPrefixes.contains { path == $0 || path.hasPrefix($0 + "/") }
    }

    /// Scanner URLs are standardized, so dropping a trailing slash is enough to compare folder paths.
    private static func trimmedPath(of url: URL) -> String {
        var path = url.path(percentEncoded: false)
        if path.count > 1, path.hasSuffix("/") { path.removeLast() }
        return path
    }

    /// What makes this folder a project, if anything.
    private func evidence(for node: FileNode, markerCandidates: Set<String>) -> ProjectEvidence? {
        var hasUnitySettings = false
        for child in node.children where child.kind == .directory {
            let name = autoreleasepool { child.name }
            if name == ".git" { return .git }
            if name.hasSuffix(".xcodeproj") || name.hasSuffix(".xcworkspace") { return .xcode }
            if name == "ProjectSettings" { hasUnitySettings = true }
        }
        guard markerCandidates.contains(autoreleasepool { Self.trimmedPath(of: node.url) }) else { return nil }
        if hasUnitySettings { return .unity }
        for marker in Self.markers where markerChecker.folder(node.url, contains: marker.file) {
            return marker.evidence
        }
        return nil
    }
}
