import Foundation
import Testing

/// Enforces the project rules that views never hardcode user-facing text, colors, or font sizes
/// (DEVPLAN Implementation Guidelines). Strings go through `L10n`, visuals through the Theme module.
struct SourceHygieneTests {
    private static let forbidden: [(pattern: Regex<Substring>, reason: String)] = [
        (/Text\("/, "string literal in Text; use L10n"),
        (/Button\("/, "string literal in Button; use L10n"),
        (/Label\("/, "string literal in Label; use L10n"),
        (/Toggle\("/, "string literal in Toggle; use L10n"),
        (/navigationTitle\("/, "string literal title; use L10n"),
        (/Color\(red:/, "raw color; use ChartPalette or a system color"),
        (/Color\(hex/, "raw color; use ChartPalette or a system color"),
        (/Color\(\.sRGB/, "raw color; use ChartPalette or a system color"),
        (/\.font\(\.system\(size:/, "raw font size; use Typography"),
    ]

    @Test("should keep user-facing literals, raw colors, and font sizes out of views", arguments: ["Features", "App"])
    func viewsUseTokens(folder: String) throws {
        let files = try SourceTree.swiftFiles(under: folder)
        #expect(!files.isEmpty)

        for file in files {
            let source = try String(contentsOf: file, encoding: .utf8)
            for rule in Self.forbidden where source.contains(rule.pattern) {
                Issue.record("\(file.lastPathComponent): \(rule.reason)")
            }
        }
    }

    /// Models that persist anything default to the real Application Support folder. A test that
    /// builds one without in-memory stores writes into the developer's own data — and a stub scan of
    /// `/` would overwrite the real startup-disk cache.
    @Test("should give every model a test builds in-memory stores, never the real Application Support folder")
    func testsUseInMemoryStores() throws {
        let tests = SourceTree.appSources.deletingLastPathComponent().appending(path: "TemizlikciTests", directoryHint: .isDirectory)
        let enumerator = try #require(FileManager.default.enumerator(at: tests, includingPropertiesForKeys: nil))
        let files = enumerator.compactMap { $0 as? URL }.filter { $0.pathExtension == "swift" }

        for file in files where file.lastPathComponent != "SourceHygieneTests.swift" {
            let source = try String(contentsOf: file, encoding: .utf8)
            for constructor in ["LocationScanModel(", "MainViewModel("] {
                var rest = source[...]
                while let range = rest.range(of: constructor) {
                    // The arguments of this call: up to the matching closing parenthesis.
                    var depth = 1
                    var end = range.upperBound
                    while depth > 0, end < rest.endIndex {
                        if rest[end] == "(" { depth += 1 } else if rest[end] == ")" { depth -= 1 }
                        end = rest.index(after: end)
                    }
                    let arguments = rest[range.upperBound..<end]
                    for store in ["scanCache:", "snapshots:"] where !arguments.contains(store) {
                        Issue.record("\(file.lastPathComponent): \(constructor) without \(store) writes to the real Application Support folder")
                    }
                    rest = rest[end...]
                }
            }
        }
    }
}
