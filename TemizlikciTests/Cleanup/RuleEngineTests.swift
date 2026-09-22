import Foundation
import Testing
@testable import Temizlikci

nonisolated private struct StubMarkers: MarkerChecking {
    /// Folders (standardized paths) that contain the given marker files.
    let contents: [String: Set<String>]
    func folder(_ folder: URL, contains marker: String) -> Bool {
        contents[ScanConfiguration.comparablePath(of: folder)]?.contains(marker) == true
    }
}

struct RuleEngineTests {
    private let home = URL(filePath: "/Users/dev", directoryHint: .isDirectory)

    private func dir(_ path: String, _ children: [FileNode] = []) -> FileNode {
        .directory(url: URL(filePath: path, directoryHint: .isDirectory), modificationDate: nil, children: children)
    }

    private func file(_ path: String, _ size: Int64) -> FileNode {
        .file(url: URL(filePath: path), allocatedSize: size, modificationDate: nil)
    }

    private func engine(markers: [String: Set<String>] = [:]) -> RuleEngine {
        RuleEngine(home: home, markers: StubMarkers(contents: markers))
    }

    @Test("should recognize Xcode caches by their home-relative paths")
    func xcodePaths() {
        let tree = dir("/Users/dev", [dir("/Users/dev/Library", [dir("/Users/dev/Library/Developer", [dir("/Users/dev/Library/Developer/Xcode", [
            dir("/Users/dev/Library/Developer/Xcode/DerivedData", [file("/Users/dev/Library/Developer/Xcode/DerivedData/a", 10)]),
            dir("/Users/dev/Library/Developer/Xcode/Archives", [file("/Users/dev/Library/Developer/Xcode/Archives/b", 5)]),
        ])])])])

        let matches = engine().matches(in: tree)

        #expect(Set(matches.map(\.rule.id)) == ["xcode.derivedData", "xcode.archives"])
        #expect(matches.first { $0.rule.id == "xcode.archives" }?.rule.safety == .keep)
        #expect(matches.first { $0.rule.id == "xcode.derivedData" }?.idPath.count == 5)
    }

    @Test("should match project folders only next to their marker file")
    func projectFolders() {
        let tree = dir("/Work", [
            dir("/Work/app", [dir("/Work/app/build", [file("/Work/app/build/x", 1)]), dir("/Work/app/.dart_tool")]),
            dir("/Work/website", [dir("/Work/website/build", [file("/Work/website/build/y", 1)])]),
        ])

        let matches = engine(markers: ["/Work/app": ["pubspec.yaml"]]).matches(in: tree)

        #expect(Set(matches.map { $0.node.url.path(percentEncoded: false) }) == ["/Work/app/build/", "/Work/app/.dart_tool/"])
    }

    @Test("should match only the outermost node_modules")
    func outermostNodeModules() {
        let tree = dir("/Work", [dir("/Work/site", [dir("/Work/site/node_modules", [dir("/Work/site/node_modules/pkg", [dir("/Work/site/node_modules/pkg/node_modules")])])])])

        let matches = engine(markers: ["/Work/site": ["package.json"], "/Work/site/node_modules/pkg": ["package.json"]]).matches(in: tree)

        #expect(matches.map(\.node.name) == ["node_modules"])
        #expect(matches.first?.node.url.path(percentEncoded: false) == "/Work/site/node_modules/")
    }

    @Test("should find simulator runtime assets among system asset folders")
    func simulatorRuntimeAssets() {
        let tree = dir("/", [dir("/System", [dir("/System/Library", [dir("/System/Library/AssetsV2", [
            dir("/System/Library/AssetsV2/com_apple_MobileAsset_iOSSimulatorRuntime"),
            dir("/System/Library/AssetsV2/com_apple_MobileAsset_Font8"),
        ])])])])

        let matches = engine().matches(in: tree)

        #expect(matches.map(\.node.name) == ["com_apple_MobileAsset_iOSSimulatorRuntime"])
        #expect(matches.first?.rule.safety == .tool)
    }

    @Test("should mark other apps' data as Keep even when it couldn't be read")
    func appDataKeep() {
        let tree = dir("/Users/dev", [dir("/Users/dev/Library", [.inaccessible(url: URL(filePath: "/Users/dev/Library/Containers", directoryHint: .isDirectory))])])

        let matches = engine().matches(in: tree)

        #expect(matches.map(\.rule.id) == ["appData.containers"])
    }

    @Test("should give every rule a reason and an action that fits its safety level")
    func catalogConsistency() {
        for rule in CleanupRule.catalog {
            #expect(!String(localized: rule.reason).isEmpty)
            switch rule.safety {
            case .safe: #expect(rule.action == .moveToTrash, "\(rule.id)")
            // A tool-owned item either opens its tool or explains the command in its reason;
            // it must never offer Move to Trash.
            case .tool: #expect(rule.action != .moveToTrash, "\(rule.id)")
            case .keep: #expect(rule.action == .none, "\(rule.id)")
            }
        }
        #expect(Set(CleanupRule.catalog.map(\.id)).count == CleanupRule.catalog.count)
    }

    /// Builds a tree containing every folder the catalog's exact-path rules look for, so a rule that
    /// stops matching its own target fails here.
    private func treeOfEveryPathRule() -> FileNode {
        var paths: [String] = []
        for rule in CleanupRule.catalog {
            guard case .path(let pattern) = rule.matcher else { continue }
            paths.append(pattern.hasPrefix("~") ? "/Users/dev" + pattern.dropFirst() : pattern)
        }
        return tree(containing: paths)
    }

    /// Builds a directory tree from a list of absolute paths.
    private func tree(containing paths: [String]) -> FileNode {
        func build(prefix: String, components: [[String]]) -> [FileNode] {
            var children: [FileNode] = []
            for name in Set(components.compactMap(\.first)).sorted() {
                let rest = components.filter { $0.first == name }.map { Array($0.dropFirst()) }.filter { !$0.isEmpty }
                let path = prefix + "/" + name
                children.append(dir(path, build(prefix: path, components: rest)))
            }
            return children
        }
        let components = paths.map { $0.split(separator: "/").map(String.init) }
        return dir("/", build(prefix: "", components: components))
    }

    @Test("should match every exact-path rule in the catalog against its own target")
    func everyPathRuleMatches() {
        let expected = Set(CleanupRule.catalog.compactMap { rule -> String? in
            guard case .path = rule.matcher else { return nil }
            return rule.id
        })

        let matches = engine().matches(in: treeOfEveryPathRule())

        #expect(Set(matches.map(\.rule.id)) == expected)
    }

    @Test("should not match folders that only look like a rule's target")
    func lookAlikesAreNotMatched() {
        let tree = tree(containing: [
            "/Users/dev/.cargo/registry-backup",
            "/Users/dev/Library/Caches/pip-tools",
            "/Users/dev/Library/Caches/CocoaPodsOld",
            "/Users/dev/go/pkg/sumdb",
            "/Users/dev/.nuget/plugins",
            "/Users/dev/Library/pnpm/global",
        ])

        #expect(engine().matches(in: tree).isEmpty)
    }

    @Test("should tell apart caches to remove and toolchains or stores that need their own tool")
    func safetyOfNewRules() {
        let byID = Dictionary(uniqueKeysWithValues: CleanupRule.catalog.map { ($0.id, $0) })

        for id in ["swift.swiftpmCache", "swift.cocoapodsCache", "rust.registry", "java.maven", "python.pipCache", "node.playwright"] {
            #expect(byID[id]?.safety == .safe, "\(id) should be safe to move to the Trash")
            #expect(byID[id]?.action == .moveToTrash)
        }
        // Documented as unsafe to delete by hand: uv's cache, pnpm's linked store, NuGet's expanded
        // packages, Go's read-only module cache, Rust toolchains, and Docker's disk image.
        for id in ["python.uvCache", "node.pnpmStore", "dotnet.packages", "go.modCache", "rust.toolchains", "docker.data"] {
            #expect(byID[id]?.safety == .tool, "\(id) should be removed through its own tool")
            #expect(byID[id]?.action == CleanupAction.none)
        }
    }

    @Test("should match build folders for each build system's own marker")
    func buildFoldersByMarker() {
        let tree = dir("/Work", [
            dir("/Work/android", [dir("/Work/android/build", [file("/Work/android/build/a", 1)])]),
            dir("/Work/kotlin", [dir("/Work/kotlin/build", [file("/Work/kotlin/build/b", 1)])]),
            dir("/Work/swiftpkg", [dir("/Work/swiftpkg/.build", [file("/Work/swiftpkg/.build/c", 1)])]),
            dir("/Work/ios", [dir("/Work/ios/Pods", [file("/Work/ios/Pods/d", 1)])]),
            dir("/Work/game", [dir("/Work/game/Library", [file("/Work/game/Library/e", 1)])]),
            dir("/Work/plain", [dir("/Work/plain/build", [file("/Work/plain/build/f", 1)])]),
        ])

        let matches = engine(markers: [
            "/Work/android": ["build.gradle"],
            "/Work/kotlin": ["build.gradle.kts"],
            "/Work/swiftpkg": ["Package.swift"],
            "/Work/ios": ["Podfile"],
            "/Work/game": ["ProjectSettings"],
        ]).matches(in: tree)

        #expect(Set(matches.map(\.rule.id)) == [
            "java.gradleBuild", "java.gradleBuildKts", "swift.packageBuild", "swift.pods", "unity.library",
        ])
    }
}
