import Foundation
import Testing
@testable import Temizlikci

nonisolated private struct StubApps: InstalledAppNaming {
    let byIdentifier: [String: String]
    let installed: Set<String>

    func name(forBundleIdentifier identifier: String) -> String? { byIdentifier[identifier] }
    func isInstalled(named name: String) -> Bool { installed.contains(name) }
}

nonisolated private struct StubExplainer: FolderExplaining {
    let unavailable: ExplanationUnavailable?
    let answer: String

    func explain(_ folder: FolderDescription) async throws -> String { answer }
}

@Suite("What is this folder")
struct FolderIdentityTests {
    private let home = URL(filePath: "/Users/dev", directoryHint: .isDirectory)

    private func folder(_ path: String, children: [FileNode] = []) -> FileNode {
        .directory(url: URL(filePath: path, directoryHint: .isDirectory), modificationDate: nil, children: children)
    }

    private func file(_ path: String, _ size: Int64 = 10) -> FileNode {
        .file(url: URL(filePath: path), allocatedSize: size, modificationDate: nil)
    }

    private func identifier(
        byIdentifier: [String: String] = [:], installed: Set<String> = []
    ) -> FolderIdentifier {
        FolderIdentifier(home: home, apps: StubApps(byIdentifier: byIdentifier, installed: installed))
    }

    @Test("should explain the folders macOS defines, including inside the home folder")
    func knownFolders() throws {
        let subject = identifier()

        #expect(subject.identity(of: folder("/System"))?.source == .system)
        #expect(subject.identity(of: folder("/Users/dev/Library/Caches"))?.source == .system)
        #expect(subject.identity(of: folder("/Users/dev/Downloads"))?.source == .system)
        let trash = try #require(subject.identity(of: folder("/Users/dev/.Trash")))
        #expect(trash.summary.contains("Trash"))
    }

    @Test("should name the app behind a container, a group container or a support folder")
    func appFolders() throws {
        let subject = identifier(byIdentifier: ["com.apple.Safari": "Safari"], installed: ["Sketch"])

        let container = try #require(subject.identity(of: folder("/Users/dev/Library/Containers/com.apple.Safari")))
        #expect(container.source == .app(name: "Safari"))
        #expect(container.summary.contains("Safari"))

        let group = try #require(subject.identity(of: folder("/Users/dev/Library/Group Containers/group.com.apple.Safari")))
        #expect(group.source == .app(name: "Safari"))

        let support = try #require(subject.identity(of: folder("/Users/dev/Library/Application Support/Sketch")))
        #expect(support.source == .app(name: "Sketch"))

        #expect(subject.identity(of: folder("/Users/dev/Library/Containers/com.unknown.tool")) == nil)
    }

    @Test("should describe an app bundle and a file by its type, and give up on anything else")
    func bundlesFilesAndUnknowns() throws {
        let subject = identifier()

        let app = try #require(subject.identity(of: folder("/Applications/Xcode.app")))
        #expect(app.source == .application)
        #expect(app.summary.contains("Xcode"))

        let pdf = try #require(subject.identity(of: file("/Users/dev/Documents/paper.pdf")))
        #expect(pdf.source == .fileType)

        #expect(subject.identity(of: folder("/Users/dev/Work/weird-cache-42")) == nil)
    }

    @Test("should describe a folder for the model without the user's name and without file contents")
    func promptStaysPrivate() {
        let node = folder("/Users/dev/Work/thing", children: [
            file("/Users/dev/Work/thing/a.bin", 500),
            file("/Users/dev/Work/thing/b.bin", 100),
        ])

        let description = FolderDescription.describing(node, home: home, limit: 1)

        #expect(description.path == "~/Work/thing")
        #expect(!description.path.contains("dev"))
        #expect(description.contents == ["a.bin"])
        #expect(description.name == "thing")
    }

    @Test("should keep working when the model isn't available")
    func withoutAppleIntelligence() async throws {
        let explainer = StubExplainer(unavailable: .appleIntelligenceOff, answer: "")
        #expect(explainer.unavailable == .appleIntelligenceOff)
        // Known folders are still explained: the model is only for what nothing recognizes.
        #expect(identifier().identity(of: folder("/Users/dev/Library"))?.source == .system)
    }

    @Test("should pass the folder to the model and return what it wrote")
    func generatedExplanation() async throws {
        let explainer = StubExplainer(unavailable: nil, answer: "A cache written by a build tool.")
        let description = FolderDescription.describing(folder("/Users/dev/Work/weird"), home: home)

        let text = try await explainer.explain(description)

        #expect(text == "A cache written by a build tool.")
    }
}
