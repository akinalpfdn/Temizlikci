import CryptoKit
import Foundation

/// Keeps scan snapshots per location.
nonisolated protocol SnapshotStoring: Sendable {
    /// The newest snapshots of a location, newest first.
    func recent(forLocation path: String, limit: Int) throws -> [ScanSnapshot]
    func save(_ snapshot: ScanSnapshot) throws
    /// Deletes all but the newest `count` snapshots of a location.
    func prune(location path: String, keeping count: Int) throws
}

nonisolated extension SnapshotStoring {
    func latest(forLocation path: String) throws -> ScanSnapshot? {
        try recent(forLocation: path, limit: 1).first
    }
}

/// Stores snapshots as compressed JSON in Application Support, one folder per location.
nonisolated struct FileSnapshotStore: SnapshotStoring {
    static let keptPerLocation = 10
    let directory: URL

    init(directory: URL = URL.applicationSupportDirectory.appending(path: "Temizlikci/Snapshots", directoryHint: .isDirectory)) {
        self.directory = directory
    }

    func recent(forLocation path: String, limit: Int) throws -> [ScanSnapshot] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try files(forLocation: path).suffix(limit).reversed().map { url in
            let compressed = try Data(contentsOf: url)
            let data = try (compressed as NSData).decompressed(using: .lzfse) as Data
            return try decoder.decode(ScanSnapshot.self, from: data)
        }
    }

    func save(_ snapshot: ScanSnapshot) throws {
        let folder = folder(forLocation: snapshot.locationPath)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try (encoder.encode(snapshot) as NSData).compressed(using: .lzfse) as Data
        let name = String(format: "%.0f.snapshot", snapshot.date.timeIntervalSince1970 * 1000)
        try data.write(to: folder.appending(path: name), options: .atomic)
    }

    func prune(location path: String, keeping count: Int) throws {
        // Snapshots are the app's own cache, not user content, so removing old ones directly is intended.
        for old in try files(forLocation: path).dropLast(count) {
            try FileManager.default.removeItem(at: old)
        }
    }

    /// Snapshot files of a location, oldest first (names are millisecond timestamps).
    private func files(forLocation path: String) throws -> [URL] {
        let folder = folder(forLocation: path)
        guard FileManager.default.fileExists(atPath: folder.path(percentEncoded: false)) else { return [] }
        return try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "snapshot" }
            .sorted { (Double($0.deletingPathExtension().lastPathComponent) ?? 0) < (Double($1.deletingPathExtension().lastPathComponent) ?? 0) }
    }

    private func folder(forLocation path: String) -> URL {
        let digest = SHA256.hash(data: Data(path.utf8)).prefix(8).map { String(format: "%02x", $0) }.joined()
        return directory.appending(path: digest, directoryHint: .isDirectory)
    }
}
