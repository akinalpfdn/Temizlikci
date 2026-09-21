import AppKit

/// Reveals items in Finder. A protocol so view models stay testable without AppKit side effects.
protocol FileRevealing {
    func reveal(_ url: URL)
}

struct FinderRevealer: FileRevealing {
    func reveal(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}
