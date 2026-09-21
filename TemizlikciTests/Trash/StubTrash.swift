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

    func showTrashInFinder() {}
}
