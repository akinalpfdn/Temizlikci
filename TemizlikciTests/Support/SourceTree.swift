import Foundation

/// Locates the app's source folder from this file's compile-time path, so hygiene tests
/// can read the real sources instead of relying on hand-maintained lists.
enum SourceTree {
    static let appSources: URL = URL(filePath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appending(path: "Temizlikci", directoryHint: .isDirectory)

    static func swiftFiles(under relativePath: String) throws -> [URL] {
        let folder = appSources.appending(path: relativePath, directoryHint: .isDirectory)
        guard let enumerator = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: nil) else {
            return []
        }
        return enumerator.compactMap { $0 as? URL }.filter { $0.pathExtension == "swift" }
    }
}
