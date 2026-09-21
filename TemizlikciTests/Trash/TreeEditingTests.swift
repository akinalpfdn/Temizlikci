import Foundation
import Testing
@testable import Temizlikci

struct TreeEditingTests {
    private func id(_ path: String, directory: Bool = false) -> String {
        TreeBuilder.root.appending(path: path, directoryHint: directory ? .isDirectory : .notDirectory).path(percentEncoded: false)
    }

    @Test("should remove a nested item and re-total every folder above it")
    func removeNested() throws {
        let tree = TreeBuilder.sample()

        let updated = try #require(tree.removingDescendant(at: [id("Docs", directory: true), id("Docs/Reports", directory: true)][...]))

        #expect(updated.allocatedSize == 800)
        let docs = try #require(updated.children.first { $0.name == "Docs" })
        #expect(docs.allocatedSize == 100)
        #expect(docs.children.map(\.name) == ["notes.txt"])
    }

    @Test("should put a removed item back where it was")
    func insertRestores() throws {
        let tree = TreeBuilder.sample()
        let reports = try #require(tree.children.first { $0.name == "Docs" }?.children.first { $0.name == "Reports" })
        let removed = try #require(tree.removingDescendant(at: [id("Docs", directory: true), id("Docs/Reports", directory: true)][...]))

        let restored = try #require(removed.insertingDescendant(reports, under: [id("Docs", directory: true)][...]))

        #expect(restored.allocatedSize == tree.allocatedSize)
        #expect(restored.children.first { $0.name == "Docs" }?.children.map(\.name) == ["Reports", "notes.txt"])
    }

    @Test("should refuse paths that don't exist")
    func invalidPaths() {
        let tree = TreeBuilder.sample()

        #expect(tree.removingDescendant(at: ["/nope"][...]) == nil)
        #expect(tree.insertingDescendant(TreeBuilder.file("x", 1), under: ["/nope"][...]) == nil)
    }

    @Test("should follow IDs down the tree and stop at the first missing one")
    func nodesAlong() {
        let tree = TreeBuilder.sample()

        let found = tree.nodes(along: [tree.id, id("Docs", directory: true), id("Docs/Missing", directory: true)])

        #expect(found.map(\.name) == ["Scan", "Docs"])
    }
}

struct TrashErrorTests {
    private let url = URL(filePath: "/Users/someone/Big.mov")

    @Test("should explain permission, missing, and other failures with the item's name")
    func mapping() {
        #expect(TrashError(movingToTrash: url, underlying: CocoaError(.fileWriteNoPermission)) == .noPermission(name: "Big.mov"))
        #expect(TrashError(movingToTrash: url, underlying: CocoaError(.fileNoSuchFile)) == .missing(name: "Big.mov"))
        #expect(TrashError(movingToTrash: url, underlying: CocoaError(.fileWriteVolumeReadOnly)) == .failed(name: "Big.mov"))
        for error in [TrashError.noPermission(name: "Big.mov"), .missing(name: "Big.mov"), .failed(name: "Big.mov"), .putBackFailed(name: "Big.mov")] {
            #expect(error.errorDescription?.contains("Big.mov") == true)
            #expect(error.recoverySuggestion?.isEmpty == false)
        }
    }
}
