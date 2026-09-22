import CryptoKit
import Foundation

/// Keeps the last full scan of each location so the app can show it again without reading the disk.
nonisolated protocol ScanCaching: Sendable {
    func save(root: FileNode, scannedAt: Date, locationPath: String) throws
    func load(locationPath: String) throws -> ScanArchive.Archived?
    func remove(locationPath: String) throws
}

/// Stores each location's scan as one compressed archive in Application Support.
nonisolated struct FileScanCache: ScanCaching {
    let directory: URL

    init(directory: URL = URL.applicationSupportDirectory.appending(path: "Temizlikci/Scans", directoryHint: .isDirectory)) {
        self.directory = directory
    }

    func save(root: FileNode, scannedAt: Date, locationPath: String) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let archive = ScanArchive.encode(root: root, scannedAt: scannedAt, locationPath: locationPath)
        let compressed = try (archive as NSData).compressed(using: .lzfse) as Data
        try compressed.write(to: file(for: locationPath), options: .atomic)
    }

    func load(locationPath: String) throws -> ScanArchive.Archived? {
        let url = file(for: locationPath)
        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else { return nil }
        let compressed = try Data(contentsOf: url)
        let data = try (compressed as NSData).decompressed(using: .lzfse) as Data
        let archived = try ScanArchive.decode(data)
        // A cache written for another folder is not usable, however it got there.
        guard archived.locationPath == locationPath else { return nil }
        return archived
    }

    func remove(locationPath: String) throws {
        let url = file(for: locationPath)
        // The cache is the app's own data, not the person's, so removing it directly is intended.
        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else { return }
        try FileManager.default.removeItem(at: url)
    }

    private func file(for path: String) -> URL {
        let digest = SHA256.hash(data: Data(path.utf8)).prefix(8).map { String(format: "%02x", $0) }.joined()
        return directory.appending(path: digest + ".scan")
    }
}
