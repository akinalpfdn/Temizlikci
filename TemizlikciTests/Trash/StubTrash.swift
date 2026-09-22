import Foundation
@testable import Temizlikci

/// Records Trash operations instead of performing them, so tests never touch the real Trash.
final class StubTrash: Trashing {
    private(set) var trashed: [URL] = []
    private(set) var putBack: [URL] = []
    var failure: Error?

    func moveToTrash(_ url: URL) throws -> URL {
        if let failure { throw failure }
        trashed.append(url)
        return URL(filePath: "/Trash-Stub").appending(path: url.lastPathComponent)
    }

    func putBack(_ trashedURL: URL, to originalURL: URL) throws {
        if let failure { throw failure }
        putBack.append(originalURL)
    }

    /// Trashed URLs that tests pretend were emptied from the Trash, or can't be checked.
    var gone: Set<URL> = []
    var unknown: Set<URL> = []

    func showTrashInFinder() {}

    func presence(of trashedURLs: [URL]) async -> [TrashPresence] {
        trashedURLs.map { gone.contains($0) ? .gone : unknown.contains($0) ? .unknown : .present }
    }
}
