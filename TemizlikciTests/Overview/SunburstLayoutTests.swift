import Foundation
import Testing
@testable import Temizlikci

struct SunburstLayoutTests {
    @Test("should fill the whole first ring in proportion to size")
    func firstRingCoversCircle() {
        let segments = SunburstLayout.segments(for: TreeBuilder.sample())
        let ring = segments.filter { $0.depth == 1 }

        // Typed in steps: as one expression it exceeds the type checker's time limit.
        let total: Double = ring.map(\.sweep).reduce(0, +)
        let error: Double = abs(total - 2 * Double.pi)
        #expect(error < 1e-9)
        #expect(ring.map(\.name) == ["Apps", "Docs", "movie.mov"])
        #expect(abs(ring[0].sweep - 2 * .pi * 0.6) < 1e-9)
    }

    @Test("should place children inside their parent's angle, at most three rings deep")
    func childrenNestInsideParents() {
        let deep = TreeBuilder.folder("a", [TreeBuilder.folder("a/b", [TreeBuilder.folder("a/b/c", [TreeBuilder.folder("a/b/c/d", [TreeBuilder.file("a/b/c/d/x", 10)])])])])
        let root = FileNode.directory(url: TreeBuilder.root, modificationDate: nil, children: [deep])
        let segments = SunburstLayout.segments(for: root)

        #expect(segments.map(\.depth).max() == SunburstLayout.ringCount)
        let sample = SunburstLayout.segments(for: TreeBuilder.sample())
        let apps = sample.first { $0.name == "Apps" && $0.depth == 1 }!
        for child in sample where child.depth == 2 && child.nodeID?.contains("/Apps/") == true {
            #expect(child.startAngle >= apps.startAngle - 1e-9 && child.endAngle <= apps.endAngle + 1e-9)
        }
    }

    @Test("should merge slivers too thin to click into one neutral segment per parent")
    func slivers() {
        let tiny = (0..<10).map { TreeBuilder.file("t\($0)", 1) }
        let root = FileNode.directory(url: TreeBuilder.root, modificationDate: nil, children: [TreeBuilder.file("big", 10_000)] + tiny)
        let segments = SunburstLayout.segments(for: root)

        let merged = segments.filter(\.isMerged)
        #expect(merged.count == 1)
        #expect(merged.first?.allocatedSize == 10)
        #expect(merged.first?.fill == .neutral)
        #expect(segments.filter { !$0.isMerged }.allSatisfy { $0.sweep >= SunburstLayout.minimumSweep })
    }

    @Test("should give palette slots to the eight largest folders and files, keeping special space neutral or hatched")
    func slots() {
        var children = (0..<9).map { TreeBuilder.file("f\($0)", Int64(100 - $0)) }
        children.append(.unattributed(on: TreeBuilder.root, allocatedSize: 500))
        children.append(.inaccessible(url: TreeBuilder.root.appending(path: "Locked")))
        let root = FileNode.directory(url: TreeBuilder.root, modificationDate: nil, children: children)
        let segments = SunburstLayout.segments(for: root)

        #expect(segments.first { $0.name == "f0" }?.fill == .slot(index: 0, depth: 1))
        #expect(segments.first { $0.name == "f7" }?.fill == .slot(index: 7, depth: 1))
        #expect(segments.first { $0.name == "f8" }?.fill == .neutral)
        #expect(segments.first { $0.nodeID?.hasSuffix("unattributed") == true }?.fill == .unattributedHatch)
    }

    @Test("should pass a folder's slot to its descendants with the ring depth")
    func inheritedSlots() {
        let segments = SunburstLayout.segments(for: TreeBuilder.sample())

        #expect(segments.first { $0.name == "Reports" }?.fill == .slot(index: 1, depth: 2))
        #expect(segments.first { $0.name == "q1.pdf" }?.fill == .slot(index: 1, depth: 3))
    }

    @Test("should find the segment under a point and treat the center as the hole")
    func hitTesting() {
        let segments = SunburstLayout.segments(for: TreeBuilder.sample())
        let side: CGFloat = 400
        let ringOneMiddle = (SunburstLayout.ringBounds(depth: 1).inner + SunburstLayout.ringBounds(depth: 1).outer) / 2 * 200
        let justRightOfTop = CGPoint(x: 200 + 1, y: 200 - ringOneMiddle)

        #expect(SunburstLayout.segment(at: justRightOfTop, side: side, in: segments)?.name == "Apps")
        #expect(SunburstLayout.segment(at: CGPoint(x: 200, y: 200), side: side, in: segments) == nil)
        #expect(SunburstLayout.isInHole(CGPoint(x: 200, y: 200), side: side))
        #expect(SunburstLayout.segment(at: CGPoint(x: 0, y: 0), side: side, in: segments) == nil)
    }
}
