import Foundation
import Testing
@testable import Temizlikci

@Suite("Trash ledger")
struct TrashLedgerTests {
    private func record(_ name: String) -> TrashRecord {
        let original = URL(filePath: "/Work/\(name)")
        return TrashRecord(
            node: .file(url: original, allocatedSize: 100, modificationDate: nil),
            originalURL: original, trashedURL: URL(filePath: "/Trash-Stub/\(name)"), date: Date(),
            locationURL: URL(filePath: "/Work", directoryHint: .isDirectory), ancestorIDs: []
        )
    }

    @Test("should drop items emptied from the Trash and keep the rest")
    func dropsEmptiedItems() async {
        let trash = StubTrash()
        let ledger = TrashLedger(trash: trash)
        ledger.add(record("a"))
        ledger.add(record("b"))
        trash.gone = [URL(filePath: "/Trash-Stub/a")]

        await ledger.reconcile()

        #expect(ledger.records.map(\.originalURL.lastPathComponent) == ["b"])
        #expect(ledger.totalSize == 100)
    }

    @Test("should keep items it can't check, so a missing permission never empties the list")
    func keepsUnknown() async {
        let trash = StubTrash()
        let ledger = TrashLedger(trash: trash)
        ledger.add(record("a"))
        trash.unknown = [URL(filePath: "/Trash-Stub/a")]

        await ledger.reconcile()

        #expect(ledger.records.count == 1)
    }

    @Test("should tell an item that is gone from one it can't see, on the real file system")
    func presenceOnDisk() throws {
        let fixture = try FixtureTree()
        let present = try fixture.file("here.bin", bytes: 10)

        #expect(TrashPresence.check(present) == .present)
        #expect(TrashPresence.check(fixture.root.appending(path: "missing.bin")) == .gone)

        // A folder without read or search permission: the file inside can't be looked up.
        let locked = fixture.root.appending(path: "locked", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: locked, withIntermediateDirectories: true)
        let inside = try fixture.file("locked/secret.bin", bytes: 10)
        try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: locked.path(percentEncoded: false))
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: locked.path(percentEncoded: false)) }
        #expect(TrashPresence.check(inside) == .unknown)
    }
}
