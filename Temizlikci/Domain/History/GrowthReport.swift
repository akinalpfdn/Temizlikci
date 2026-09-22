import Foundation

nonisolated struct GrowthChange: Sendable, Identifiable, Equatable {
    enum Kind: Sendable, Equatable {
        case grew, shrank
        /// Recorded now but not before: new, or under the recording threshold last time.
        case appeared
        /// Recorded before but gone from the tree now.
        case removed
    }

    let path: String
    let previous: Int64?
    let current: Int64?
    var id: String { path }
    var delta: Int64 { (current ?? 0) - (previous ?? 0) }

    var kind: Kind {
        switch (previous, current) {
        case (nil, _): .appeared
        case (_, nil): .removed
        default: delta >= 0 ? .grew : .shrank
        }
    }
}

/// What changed between two scans of the same location.
nonisolated struct GrowthReport: Sendable {
    /// Changes smaller than this are noise (caches ticking, logs rotating).
    static let minimumChange: Int64 = 10_000_000

    let previousDate: Date
    let currentDate: Date
    let changes: [String: GrowthChange]

    func change(forPath path: String) -> GrowthChange? {
        changes[path]
    }

    /// The largest changes, leaving out folders whose change is mostly explained by one item inside
    /// them, so the list points at where growth actually happened.
    func biggestChanges(limit: Int = 50) -> [GrowthChange] {
        var largestChildDelta: [String: Int64] = [:]
        for change in changes.values {
            let parent = (change.path as NSString).deletingLastPathComponent
            let existing = largestChildDelta[parent] ?? 0
            if abs(change.delta) > abs(existing) { largestChildDelta[parent] = change.delta }
        }
        return changes.values
            .filter { change in
                guard let child = largestChildDelta[change.path] else { return true }
                let explained = child.signum() == change.delta.signum() && abs(child) * 10 >= abs(change.delta) * 8
                return !explained
            }
            .sorted { abs($0.delta) > abs($1.delta) }
            .prefix(limit)
            .map { $0 }
    }

    static func compare(previous: ScanSnapshot, current: ScanSnapshot, minimumChange: Int64 = minimumChange) -> GrowthReport {
        let unread = previous.unreadPaths.union(current.unreadPaths)
        func isComparable(_ path: String) -> Bool {
            !unread.contains(path) && !unread.contains { path.hasPrefix($0 + "/") }
        }
        var changes: [String: GrowthChange] = [:]
        for path in Set(previous.sizes.keys).union(current.sizes.keys) where isComparable(path) {
            let change = GrowthChange(path: path, previous: previous.sizes[path], current: current.sizes[path])
            if abs(change.delta) >= minimumChange { changes[path] = change }
        }
        return GrowthReport(previousDate: previous.date, currentDate: current.date, changes: changes)
    }
}
