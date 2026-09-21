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
}
