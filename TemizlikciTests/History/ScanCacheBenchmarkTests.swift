import Foundation
import Testing
@testable import Temizlikci

/// Measures the archive on a real folder tree. Opt-in: set TEST_RUNNER_TEMIZLIKCI_CACHE_PATH to a
/// folder to scan (for example the home folder). Off by default, so the normal suite stays fast.
@Suite("Scan cache benchmark")
struct ScanCacheBenchmarkTests {
    @Test("should archive a real scan in a size and time worth caching")
    func realTree() async throws {
        guard let path = ProcessInfo.processInfo.environment["TEMIZLIKCI_CACHE_PATH"] else { return }
        let root = URL(filePath: path, directoryHint: .isDirectory)
        let scanner = FileSystemScanner(configuration: ScanConfiguration())

        var scanned: FileNode?
        let scanStart = Date()
        for try await event in scanner.scan(root) {
            if case .finished(let result) = event { scanned = result.root }
        }
        let scanSeconds = Date().timeIntervalSince(scanStart)
        let tree = try #require(scanned)

        let encodeStart = Date()
        let data = ScanArchive.encode(root: tree, scannedAt: Date(), locationPath: root.path(percentEncoded: false))
        let encodeSeconds = Date().timeIntervalSince(encodeStart)

        let compressStart = Date()
        let compressed = try (data as NSData).compressed(using: .lzfse) as Data
        let compressSeconds = Date().timeIntervalSince(compressStart)

        let decodeStart = Date()
        let decompressed = try (compressed as NSData).decompressed(using: .lzfse) as Data
        let decoded = try ScanArchive.decode(decompressed)
        let decodeSeconds = Date().timeIntervalSince(decodeStart)

        #expect(decoded.root.allocatedSize == tree.allocatedSize)
        let report = """
        path: \(path)
        scan: \(String(format: "%.1f", scanSeconds))s, files: \(tree.fileCount)
        archive: \(data.count / 1_000_000) MB raw, \(compressed.count / 1_000_000) MB compressed
        encode: \(String(format: "%.2f", encodeSeconds))s, compress: \(String(format: "%.2f", compressSeconds))s
        load (decompress + decode): \(String(format: "%.2f", decodeSeconds))s
        """
        print(report)
        if let out = ProcessInfo.processInfo.environment["TEMIZLIKCI_CACHE_REPORT"] {
            try? report.write(to: URL(filePath: out), atomically: true, encoding: .utf8)
        }
    }
}
