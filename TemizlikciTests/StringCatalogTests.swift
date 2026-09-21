import Foundation
import Testing

/// The String Catalog is maintained by hand (extraction state "manual"), so these tests keep it
/// in lockstep with `L10n`: every key used in code exists with the same English value, and nothing is orphaned.
struct StringCatalogTests {
    private struct Catalog: Decodable {
        struct Entry: Decodable {
            struct Localization: Decodable {
                struct Unit: Decodable { let value: String }
                let stringUnit: Unit
            }
            let localizations: [String: Localization]
        }
        let sourceLanguage: String
        let strings: [String: Entry]
    }

    private func loadCatalog() throws -> Catalog {
        let url = SourceTree.appSources.appending(path: "Resources/Localizable.xcstrings")
        return try JSONDecoder().decode(Catalog.self, from: Data(contentsOf: url))
    }

    private func resourcesInCode() throws -> [String: String] {
        let pattern = /LocalizedStringResource\("([^"]+)", defaultValue: "((?:[^"\\]|\\.)*)"/
        var found: [String: String] = [:]
        for file in try SourceTree.swiftFiles(under: ".") {
            let source = try String(contentsOf: file, encoding: .utf8)
            for match in source.matches(of: pattern) {
                // Interpolated arguments are stored in the catalog as %@ placeholders.
                found[String(match.1)] = String(match.2).replacing(/\\\([^)]*\)/, with: "%@")
            }
        }
        return found
    }

    @Test("should use English as the source language")
    func sourceLanguage() throws {
        #expect(try loadCatalog().sourceLanguage == "en")
    }

    @Test("should contain every key used in code with the same English value")
    func everyKeyPresent() throws {
        let catalog = try loadCatalog()
        let resources = try resourcesInCode()
        #expect(!resources.isEmpty)

        for (key, value) in resources {
            let english = catalog.strings[key]?.localizations["en"]?.stringUnit.value
            #expect(english == value, "Catalog entry for \(key) is missing or differs from code")
        }
    }

    @Test("should not keep keys that no code uses")
    func noOrphanKeys() throws {
        let used = Set(try resourcesInCode().keys)
        let orphans = Set(try loadCatalog().strings.keys).subtracting(used)
        #expect(orphans.isEmpty, "Unused catalog keys: \(orphans.sorted())")
    }
}
