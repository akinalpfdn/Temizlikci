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
            case .tool: #expect(rule.action == .manageSimulators || rule.action == .openAndroidStudio, "\(rule.id)")
            case .keep: #expect(rule.action == .none, "\(rule.id)")
            }
        }
        #expect(Set(CleanupRule.catalog.map(\.id)).count == CleanupRule.catalog.count)
    }
}
