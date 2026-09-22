import Foundation
import Testing
@testable import Temizlikci

/// Marker files that exist only for the test, by folder path.
nonisolated private struct FixedMarkers: MarkerChecking {
    let markers: [String: Set<String>]

    func folder(_ folder: URL, contains marker: String) -> Bool {
        var path = folder.path(percentEncoded: false)
        if path.count > 1, path.hasSuffix("/") { path.removeLast() }
        return markers[path]?.contains(marker) ?? false
    }
}

nonisolated private struct FixedActivity: ProjectActivityReading {
    let dates: [String: Date]

    func lastTouched(project url: URL, ignoring artifactNames: Set<String>) -> Date? {
        var path = url.path(percentEncoded: false)
        if path.count > 1, path.hasSuffix("/") { path.removeLast() }
        return dates[path]
    }
}

@Suite("Stale projects")
struct ProjectFinderTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let mb = Int64(1_000_000)

    private func folder(_ path: String, _ children: [FileNode] = []) -> FileNode {
        .directory(url: URL(filePath: path, directoryHint: .isDirectory), modificationDate: nil, children: children)
    }

    private func file(_ path: String, _ size: Int64) -> FileNode {
        .file(url: URL(filePath: path), allocatedSize: size, modificationDate: nil)
    }

    /// /Code
    /// ├── App (has .git, an Xcode project and DerivedData-style build output)
    /// ├── Site (no .git; package.json marker next to node_modules)
    /// └── Notes (no project at all)
    private func tree() -> FileNode {
        folder("/Code", [
            folder("/Code/App", [
                folder("/Code/App/.git", [file("/Code/App/.git/pack", 20 * mb)]),
                folder("/Code/App/App.xcodeproj"),
                folder("/Code/App/build", [file("/Code/App/build/out", 800 * mb)]),
            ]),
            folder("/Code/Site", [
                folder("/Code/Site/node_modules", [
                    file("/Code/Site/node_modules/lib", 400 * mb),
                    folder("/Code/Site/node_modules/inner", [folder("/Code/Site/node_modules/inner/.git")]),
                ]),
            ]),
            folder("/Code/Notes", [file("/Code/Notes/draft", 30 * mb)]),
        ])
    }

    private func engineMatches(_ root: FileNode) -> [CleanupMatch] {
        let rules = [
            CleanupRule(id: "node.modules", ecosystem: .node, safety: .safe, matcher: .projectFolder(name: "node_modules", marker: "package.json"), reason: L10n.Cleanup.reasonNodeModules, action: .moveToTrash),
            CleanupRule(id: "flutter.build", ecosystem: .flutter, safety: .safe, matcher: .projectFolder(name: "build", marker: "pubspec.yaml"), reason: L10n.Cleanup.reasonFlutterBuild, action: .moveToTrash),
        ]
        let markers = FixedMarkers(markers: [
            "/Code/Site": ["package.json"],
            "/Code/App": ["pubspec.yaml"],
        ])
        return RuleEngine(rules: rules, home: URL(filePath: "/Users/dev", directoryHint: .isDirectory), markers: markers).matches(in: root)
    }

    private func finder(dates: [String: Date]) -> ProjectFinder {
        ProjectFinder(
            markers: FixedMarkers(markers: ["/Code/Site": ["package.json"], "/Code/App": ["pubspec.yaml"]]),
            activity: FixedActivity(dates: dates),
            home: URL(filePath: "/Users/dev", directoryHint: .isDirectory)
        )
    }

    @Test("should find a project by its Git folder and by a marker next to build output, and keep the outermost one")
    func detection() throws {
        let root = tree()
        let matches = engineMatches(root)

        let projects = finder(dates: [:]).projects(in: root, matches: matches)

        #expect(projects.map(\.name) == ["App", "Site"])
        #expect(projects.map(\.evidence) == [.git, .node])
        // The repository inside node_modules belongs to Site, not to a project of its own.
        #expect(!projects.contains { $0.url.path(percentEncoded: false).contains("node_modules") })
    }

    @Test("should give each project the artifacts inside it")
    func artifactOwnership() throws {
        let root = tree()
        let projects = finder(dates: [:]).projects(in: root, matches: engineMatches(root))
        let app = try #require(projects.first { $0.name == "App" })
        let site = try #require(projects.first { $0.name == "Site" })

        #expect(app.artifacts.map(\.node.name) == ["build"])
        #expect(app.reclaimableSize == 800 * mb)
        #expect(site.artifacts.map(\.node.name) == ["node_modules"])
    }

    @Test("should count a project as stale only once the period has passed, and never without a date")
    func staleness() throws {
        let day = TimeInterval(24 * 60 * 60)
        let root = tree()
        let projects = finder(dates: ["/Code/App": now.addingTimeInterval(-100 * day)]).projects(in: root, matches: engineMatches(root))
        let app = try #require(projects.first { $0.name == "App" })
        let site = try #require(projects.first { $0.name == "Site" })

        #expect(app.isStale(on: now, after: .quarter))
        #expect(!app.isStale(on: now, after: .halfYear))
        #expect(!site.isStale(on: now, after: .month))
    }

    @Test("should read activity from the Git index, and otherwise from the newest file it can see")
    func activityFromDisk() throws {
        let tree = try FixtureTree()
        let project = tree.root.appending(path: "Proj", directoryHint: .isDirectory)
        let sources = project.appending(path: "Sources", directoryHint: .isDirectory)
        let artifacts = project.appending(path: "build", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: sources, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: artifacts, withIntermediateDirectories: true)
        let old = Date(timeIntervalSince1970: 1_700_000_000)
        let recent = Date(timeIntervalSince1970: 1_790_000_000)
        try write(sources.appending(path: "main.swift"), date: old)
        try write(artifacts.appending(path: "out.o"), date: recent)

        let reader = FileSystemProjectActivity()
        #expect(reader.lastTouched(project: project, ignoring: ["build"]) == old)

        let git = project.appending(path: ".git", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: git, withIntermediateDirectories: true)
        try write(git.appending(path: "index"), date: recent)
        #expect(reader.lastTouched(project: project, ignoring: ["build"]) == recent)
    }

    private func write(_ url: URL, date: Date) throws {
        try Data("x".utf8).write(to: url)
        try FileManager.default.setAttributes([.modificationDate: date], ofItemAtPath: url.path(percentEncoded: false))
    }

    @Test("should not list repositories that belong to tools rather than to the developer")
    func ignoresToolRepositories() {
        let root = folder("/", [
            folder("/opt", [folder("/opt/homebrew", [folder("/opt/homebrew/tap", [folder("/opt/homebrew/tap/.git")])])]),
            folder("/Users", [folder("/Users/dev", [
                folder("/Users/dev/Library", [folder("/Users/dev/Library/Caches", [folder("/Users/dev/Library/Caches/repo", [folder("/Users/dev/Library/Caches/repo/.git")])])]),
                folder("/Users/dev/Work", [folder("/Users/dev/Work/.git")]),
            ])]),
        ])

        let projects = finder(dates: [:]).projects(in: root, matches: [])

        #expect(projects.map(\.name) == ["Work"])
    }
}
