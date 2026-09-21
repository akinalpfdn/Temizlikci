import CoreGraphics
import Foundation

/// How one segment of the sunburst is colored. Resolved to real colors by the view.
nonisolated enum SegmentFill: Equatable, Sendable {
    /// A palette slot (0-based) and the ring depth, which lightens the slot's tint.
    case slot(index: Int, depth: Int)
    /// Smaller items, merged slivers, and top-level entries beyond the last slot.
    case neutral
    /// Space no folder accounts for.
    case unattributedHatch
    /// Folders that need access.
    case inaccessibleHatch
    /// Not measured yet.
    case pending
}

nonisolated struct SunburstSegment: Identifiable, Equatable, Sendable {
    let id: String
    /// `nil` for merged slivers, which have no single node behind them.
    let nodeID: String?
    let name: String
    let allocatedSize: Int64
    /// 1 = innermost ring.
    let depth: Int
    /// Radians, clockwise from 12 o'clock.
    let startAngle: Double
    let endAngle: Double
    let fill: SegmentFill
    /// True when this segment stands for several slivers too thin to draw.
    let isMerged: Bool

    var midAngle: Double { (startAngle + endAngle) / 2 }
    var sweep: Double { endAngle - startAngle }
}

/// Pure geometry for the sunburst: which segments to draw and where. No UI types, so it's unit-tested.
nonisolated enum SunburstLayout {
    static let ringCount = 3
    /// Segments thinner than this are merged per parent so every drawn segment stays clickable.
    static let minimumSweep = 1.2 * Double.pi / 180

    static func segments(for root: FileNode) -> [SunburstSegment] {
        guard root.allocatedSize > 0 else { return [] }
        var output: [SunburstSegment] = []
        let slots = slotAssignments(for: root)
        layOut(
            parent: root, start: 0, end: 2 * .pi, depth: 1,
            inheritedSlot: nil, slots: slots, into: &output
        )
        return output
    }

    /// Palette slots go to the root's top-level folders and files in size order; special kinds and
    /// anything past the eighth slot stay neutral (DECISIONS: color by top-level folder).
    static func slotAssignments(for root: FileNode) -> [String: Int] {
        var assignments: [String: Int] = [:]
        for child in root.children where takesSlot(child) {
            guard assignments.count < 8 else { break }
            assignments[child.id] = assignments.count
        }
        return assignments
    }

    private static func takesSlot(_ node: FileNode) -> Bool {
        switch node.kind {
        case .directory, .file: node.allocatedSize > 0
        case .smallerFiles, .inaccessible, .unattributed, .pending: false
        }
    }

    private static func layOut(
        parent: FileNode, start: Double, end: Double, depth: Int,
        inheritedSlot: Int?, slots: [String: Int], into output: inout [SunburstSegment]
    ) {
        guard depth <= ringCount, parent.allocatedSize > 0 else { return }
        let span = end - start
        var cursor = start
        var mergedSize: Int64 = 0
        var mergedSweep = 0.0

        // Children are kept sorted largest-first by `FileNode.directory`.
        for child in parent.children where child.allocatedSize > 0 {
            let sweep = span * Double(child.allocatedSize) / Double(parent.allocatedSize)
            guard sweep >= minimumSweep else {
                mergedSize += child.allocatedSize
                mergedSweep += sweep
                continue
            }
            let slot = depth == 1 ? slots[child.id] : inheritedSlot
            output.append(SunburstSegment(
                id: child.id, nodeID: child.id, name: child.name, allocatedSize: child.allocatedSize,
                depth: depth, startAngle: cursor, endAngle: cursor + sweep,
                fill: fill(for: child, slot: slot, depth: depth), isMerged: false
            ))
            if child.kind == .directory {
                layOut(parent: child, start: cursor, end: cursor + sweep, depth: depth + 1,
                       inheritedSlot: slot, slots: slots, into: &output)
            }
            cursor += sweep
        }

        if mergedSweep > 0 {
            output.append(SunburstSegment(
                id: parent.id + "\u{0}merged", nodeID: nil, name: "", allocatedSize: mergedSize,
                depth: depth, startAngle: cursor, endAngle: cursor + mergedSweep,
                fill: .neutral, isMerged: true
            ))
        }
    }

    private static func fill(for node: FileNode, slot: Int?, depth: Int) -> SegmentFill {
        switch node.kind {
        case .unattributed: return .unattributedHatch
        case .inaccessible: return .inaccessibleHatch
        case .pending: return .pending
        case .smallerFiles: return .neutral
        case .directory, .file:
            guard let slot else { return .neutral }
            return .slot(index: slot, depth: depth)
        }
    }

    // MARK: - Geometry

    /// Ring bounds as fractions of the chart radius, matching the approved design.
    static func ringBounds(depth: Int) -> (inner: Double, outer: Double) {
        switch depth {
        case 1: (0.43, 0.68)
        case 2: (0.695, 0.865)
        default: (0.88, 0.99)
        }
    }

    static let holeFraction = 0.41

    /// The segment under `point` in a square chart of side `side`, or `nil` for the hole or outside.
    static func segment(at point: CGPoint, side: CGFloat, in segments: [SunburstSegment]) -> SunburstSegment? {
        let radius = side / 2
        let dx = point.x - radius
        let dy = point.y - radius
        let distance = (dx * dx + dy * dy).squareRoot() / radius
        guard let depth = (1...ringCount).first(where: {
            let bounds = ringBounds(depth: $0)
            return distance >= bounds.inner && distance <= bounds.outer
        }) else { return nil }
        var angle = atan2(Double(dx), Double(-dy))
        if angle < 0 { angle += 2 * .pi }
        return segments.first { $0.depth == depth && angle >= $0.startAngle && angle < $0.endAngle }
    }

    /// True when `point` falls inside the center hole.
    static func isInHole(_ point: CGPoint, side: CGFloat) -> Bool {
        let radius = side / 2
        let dx = point.x - radius
        let dy = point.y - radius
        return (dx * dx + dy * dy).squareRoot() / radius < holeFraction
    }
}
