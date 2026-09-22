import Foundation

/// Reads when a project was last worked on, without walking the whole project.
///
/// Folder modification dates only change when entries are added or removed, so editing a file
/// leaves its folder's date untouched. Git's index is written on every stage, commit, checkout
/// and status refresh, which makes it the most reliable signal when it exists; otherwise the
/// newest file in the project's own top two levels is used, skipping build artifacts.
nonisolated struct FileSystemProjectActivity: ProjectActivityReading {
    /// How deep to look for recently changed files when there is no Git index.
    static let depth = 2
    /// Never descend into these, whatever the rules matched: they change when tools run, not when
    /// the developer works.
    static let alwaysIgnored: Set<String> = [
        ".git", "node_modules", "build", ".build", "target", ".dart_tool", ".next", "DerivedData",
        "Pods", ".gradle", "vendor", "dist", "out", "__pycache__", ".venv", "venv",
    ]

    func lastTouched(project url: URL, ignoring artifactNames: Set<String>) -> Date? {
        if let git = gitActivity(in: url) { return git }
        let ignored = artifactNames.union(Self.alwaysIgnored)
        return newestFile(in: url, ignoring: ignored, depth: Self.depth)
    }

    /// The newest of `.git/index` and `.git/HEAD`: staging, committing and switching branches all
    /// rewrite one of them.
    private func gitActivity(in url: URL) -> Date? {
        let git = url.appending(path: ".git", directoryHint: .isDirectory)
        let dates = ["index", "HEAD"].compactMap { modificationDate(of: git.appending(path: $0)) }
        return dates.max()
    }

    private func newestFile(in folder: URL, ignoring ignored: Set<String>, depth: Int) -> Date? {
        guard depth > 0 else { return nil }
        let keys: [URLResourceKey] = [.contentModificationDateKey, .isDirectoryKey]
        guard let entries = try? FileManager.default.contentsOfDirectory(
            at: folder, includingPropertiesForKeys: keys, options: [.skipsPackageDescendants]
        ) else { return nil }
        var newest: Date?
        for entry in entries {
            let values = try? entry.resourceValues(forKeys: Set(keys))
            if values?.isDirectory == true {
                guard !ignored.contains(entry.lastPathComponent), !entry.lastPathComponent.hasPrefix(".") else { continue }
                if let inside = newestFile(in: entry, ignoring: ignored, depth: depth - 1) {
                    newest = max(newest ?? inside, inside)
                }
            } else if let date = values?.contentModificationDate {
                newest = max(newest ?? date, date)
            }
        }
        return newest
    }

    private func modificationDate(of url: URL) -> Date? {
        try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
    }
}
