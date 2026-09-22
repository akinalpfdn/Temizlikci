import Foundation

/// A scanned folder recognized by a cleanup rule.
nonisolated struct CleanupMatch: Sendable, Identifiable {
    let rule: CleanupRule
    let node: FileNode
    /// IDs from the scan's root down to the matched node.
    let idPath: [String]

    var id: String { node.id }
}

/// Answers "does this project folder have its marker file next to it?". A protocol so tests don't
/// depend on the file system; small files like `pubspec.yaml` aren't individual nodes in the tree.
nonisolated protocol MarkerChecking: Sendable {
    func folder(_ folder: URL, contains marker: String) -> Bool
}

nonisolated struct FileSystemMarkerChecker: MarkerChecking {
    func folder(_ folder: URL, contains marker: String) -> Bool {
        FileManager.default.fileExists(atPath: folder.appending(path: marker).path(percentEncoded: false))
    }
}

/// Finds developer artifacts in a scan result. Stops descending into a folder once it matches, so
/// nested `node_modules` and everything inside a matched cache belong to the outermost match. The
/// exception is a folder labelled "keep": the search continues inside it, because app containers
/// hold things with their own rules.
nonisolated struct RuleEngine: Sendable {
    let rules: [CleanupRule]
    let home: URL
    let markers: MarkerChecking

    init(rules: [CleanupRule] = CleanupRule.catalog, home: URL = URL.homeDirectory, markers: MarkerChecking = FileSystemMarkerChecker()) {
        self.rules = rules
        self.home = home
        self.markers = markers
    }

    func matches(in root: FileNode) -> [CleanupMatch] {
        let byPath = Dictionary(rules.compactMap { rule -> (String, CleanupRule)? in
            guard case .path(let pattern) = rule.matcher else { return nil }
            return (expand(pattern), rule)
        }, uniquingKeysWith: { first, _ in first })
        let childRules = rules.compactMap { rule -> (parent: String, prefix: String, containing: String, rule: CleanupRule)? in
            guard case .childOf(let parent, let prefix, let containing) = rule.matcher else { return nil }
            return (expand(parent), prefix, containing, rule)
        }
        let projectRules = rules.compactMap { rule -> (name: String, marker: String, rule: CleanupRule)? in
            guard case .projectFolder(let name, let marker) = rule.matcher else { return nil }
            return (name, marker, rule)
        }

        var found: [CleanupMatch] = []
        func visit(_ node: FileNode, idPath: [String], parentPath: String?) {
            guard node.kind == .directory || node.kind == .inaccessible else { return }
            // Path and name lookups create autoreleased Foundation objects; without a pool per folder they
            // pile up until the whole pass ends (~220 bytes per folder, measured; Lore knownIssue 101).
            let (path, rule) = autoreleasepool { () -> (String, CleanupRule?) in
                let path = Self.trimmedPath(of: node.url)
                let name = node.name
                let rule = byPath[path]
                    ?? parentPath.flatMap { parent in
                        childRules.first { $0.parent == parent && name.hasPrefix($0.prefix) && name.contains($0.containing) }?.rule
                    }
                    ?? projectRules.first { $0.name == name && markers.folder(node.url.deletingLastPathComponent(), contains: $0.marker) }?.rule
                return (path, rule)
            }
            if let rule {
                found.append(CleanupMatch(rule: rule, node: node, idPath: idPath))
                // Stop inside caches: everything below belongs to the same match. Folders to keep are
                // different — app containers hold Docker's disk image, and that needs its own label.
                if rule.safety != .keep { return }
            }
            for child in node.children where child.kind == .directory || child.kind == .inaccessible {
                let childID = autoreleasepool { child.id }
                visit(child, idPath: idPath + [childID], parentPath: path)
            }
        }
        visit(root, idPath: [root.id], parentPath: nil)
        return found
    }

    /// Scanner URLs are already standardized, so trimming the trailing slash is enough (and much cheaper
    /// than standardizing every one of the tree's folders again).
    private static func trimmedPath(of url: URL) -> String {
        var path = url.path(percentEncoded: false)
        if path.count > 1, path.hasSuffix("/") { path.removeLast() }
        return path
    }

    private func expand(_ pattern: String) -> String {
        guard pattern.hasPrefix("~") else { return pattern }
        let home = ScanConfiguration.comparablePath(of: self.home)
        return home + pattern.dropFirst()
    }
}
