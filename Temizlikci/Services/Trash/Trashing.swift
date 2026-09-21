import AppKit

/// Moves items to the Trash and back. The only way the app removes anything; never `removeItem`.
protocol Trashing {
    /// Moves `url` to the Trash and returns its new location there.
    func moveToTrash(_ url: URL) throws -> URL
    /// Moves an item from the Trash back to where it was.
    func putBack(_ trashedURL: URL, to originalURL: URL) throws
    func showTrashInFinder()
}

struct FileManagerTrash: Trashing {
    func moveToTrash(_ url: URL) throws -> URL {
        var resulting: NSURL?
        do {
            try FileManager.default.trashItem(at: url, resultingItemURL: &resulting)
        } catch {
            throw TrashError(movingToTrash: url, underlying: error)
        }
        guard let trashed = resulting as URL? else { throw TrashError.failed(name: url.lastPathComponent) }
        return trashed
    }

    func putBack(_ trashedURL: URL, to originalURL: URL) throws {
        do {
            try FileManager.default.moveItem(at: trashedURL, to: originalURL)
        } catch {
            throw TrashError.putBackFailed(name: originalURL.lastPathComponent)
        }
    }

    func showTrashInFinder() {
        let trash = FileManager.default.urls(for: .trashDirectory, in: .userDomainMask).first
        if let trash { NSWorkspace.shared.open(trash) }
    }
}

nonisolated enum TrashError: LocalizedError, Equatable {
    case noPermission(name: String)
    case missing(name: String)
    case failed(name: String)
    case putBackFailed(name: String)

    init(movingToTrash url: URL, underlying: Error) {
        let name = url.lastPathComponent
        switch (underlying as? CocoaError)?.code {
        case .fileWriteNoPermission?, .fileReadNoPermission?:
            self = .noPermission(name: name)
        case .fileNoSuchFile?, .fileReadNoSuchFile?:
            self = .missing(name: name)
        default:
            self = .failed(name: name)
        }
    }

    var errorDescription: String? {
        switch self {
        case .noPermission(let name): String(localized: L10n.Trash.noPermission(name))
        case .missing(let name): String(localized: L10n.Trash.missing(name))
        case .failed(let name): String(localized: L10n.Trash.failed(name))
        case .putBackFailed(let name): String(localized: L10n.Trash.putBackFailed(name))
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .noPermission: String(localized: L10n.Trash.permissionSuggestion)
        case .missing, .failed: String(localized: L10n.Trash.rescanSuggestion)
        case .putBackFailed: String(localized: L10n.Trash.putBackSuggestion)
        }
    }
}
