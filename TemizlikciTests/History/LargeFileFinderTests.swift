import Foundation
import Testing
@testable import Temizlikci

@Suite("Large files")
struct LargeFileFinderTests {
    @Test("should list every individual file in the tree, largest first, with its path of IDs")
    func largestFirst() throws {
        let root = TreeBuilder.sample()

        let files = LargeFileFinder.largest(in: root)

        #expect(files.map(\.node.allocatedSize) == [500, 200, 100, 100, 100])
        #expect(Set(files.map(\.node.name)) == ["Big.app", "Small.app", "q1.pdf", "notes.txt", "movie.mov"])
        let q1 = try #require(files.first { $0.node.name == "q1.pdf" })
        #expect(root.nodes(along: q1.idPath).dropFirst().map(\.name) == ["Docs", "Reports", "q1.pdf"])
    }

    @Test("should skip grouped smaller files and stop at the limit")
    func limitAndGroups() {
        let root = FileNode.directory(url: TreeBuilder.root, modificationDate: nil, children: [
            TreeBuilder.file("a", 300), TreeBuilder.file("b", 200), TreeBuilder.file("c", 100),
            .smallerFiles(in: TreeBuilder.root, count: 40, allocatedSize: 900),
        ])

        let files = LargeFileFinder.largest(in: root, limit: 2)

        #expect(files.map(\.node.name) == ["a", "b"])
    }
}
