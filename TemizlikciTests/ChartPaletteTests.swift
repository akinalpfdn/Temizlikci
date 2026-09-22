import AppKit
import Testing
@testable import Temizlikci

/// Guards the validated palette (DECISIONS.md, 2026-09-22).
/// Light and dark are checked at runtime through AppKit. Increased-contrast variants are checked in
/// the asset sources: AppKit selects them from the system setting and does not resolve them through
/// the public `accessibilityHighContrast*` appearance names (the compiled catalog stores them under
/// internal accessibility appearances), so a runtime check would need private API.
@MainActor
struct ChartPaletteTests {
    /// name: (light, dark, increased-contrast light, increased-contrast dark)
    // Test arguments are evaluated outside the main actor, so the fixture table must be nonisolated.
    nonisolated private static let expected: [String: (String, String, String, String)] = [
        "ChartSlot1": ("#2a78d6", "#3987e5", "#2a78d6", "#3987e5"),
        "ChartSlot2": ("#eb6834", "#d95926", "#d86030", "#db602f"),
        "ChartSlot3": ("#1baf7a", "#199e70", "#179769", "#199e70"),
        "ChartSlot4": ("#eda100", "#c98500", "#b47a00", "#c98500"),
        "ChartSlot5": ("#e87ba4", "#d55181", "#c3678a", "#d85b89"),
        "ChartSlot6": ("#008300", "#008300", "#008300", "#2e992e"),
        "ChartSlot7": ("#4a3aa7", "#9085e9", "#4a3aa7", "#9085e9"),
        "ChartSlot8": ("#e34948", "#e66767", "#e34948", "#e66767"),
        "ChartNeutral": ("#c9c8c3", "#4b4b48", "#9d9c96", "#6b6a66"),
        "ChartDimmed": ("#e6e5e1", "#2f2f2d", "#d4d3ce", "#3d3d3a"),
        "ChartHatch": ("#b9b8b2", "#5a5a56", "#8f8e88", "#7a7a75"),
        "StatusSafe": ("#0ca30c", "#0ca30c", "#0ca30c", "#0ca30c"),
        "StatusSafeInk": ("#006300", "#35c35a", "#004d00", "#5ee07c"),
        "GrowthUpInk": ("#b8431a", "#ff9459", "#8f3210", "#ffb08a"),
        "GrowthDownInk": ("#0a6c77", "#4ccbd8", "#05525b", "#86e3ec"),
        "StatusTool": ("#fab219", "#fab219", "#fab219", "#fab219"),
        "StatusToolInk": ("#8a5a00", "#fab219", "#6b4500", "#ffc94d"),
    ]

    private func hex(of name: String, in appearance: NSAppearance.Name) throws -> String {
        let color = try #require(NSColor(named: name), "Missing color asset \(name)")
        let drawing = try #require(NSAppearance(named: appearance))
        var result = ""
        drawing.performAsCurrentDrawingAppearance {
            guard let rgb = color.usingColorSpace(.sRGB) else { return }
            result = String(
                format: "#%02x%02x%02x",
                Int((rgb.redComponent * 255).rounded()),
                Int((rgb.greenComponent * 255).rounded()),
                Int((rgb.blueComponent * 255).rounded())
            )
        }
        return result
    }

    @Test("should expose eight chart slots in the validated order")
    func slotCount() {
        #expect(ChartPalette.slots.count == 8)
    }

    @Test("should resolve every palette color to its documented light and dark value at runtime", arguments: Array(expected.keys).sorted())
    func resolvesLightAndDark(name: String) throws {
        let values = try #require(Self.expected[name])
        #expect(try hex(of: name, in: .aqua) == values.0)
        #expect(try hex(of: name, in: .darkAqua) == values.1)
    }

    @Test("should declare the documented value for every appearance, including increased contrast", arguments: Array(expected.keys).sorted())
    func declaresAllAppearances(name: String) throws {
        let values = try #require(Self.expected[name])
        let declared = try declaredVariants(of: name)
        #expect(declared[.light] == values.0)
        #expect(declared[.dark] == values.1)
        #expect(declared[.increasedContrastLight] == values.2)
        #expect(declared[.increasedContrastDark] == values.3)
    }

    private enum Variant { case light, dark, increasedContrastLight, increasedContrastDark }

    private struct ColorSet: Decodable {
        struct Entry: Decodable {
            struct Appearance: Decodable { let appearance: String; let value: String }
            struct ColorValue: Decodable { let components: [String: String] }
            let appearances: [Appearance]?
            let color: ColorValue
        }
        let colors: [Entry]
    }

    private func declaredVariants(of name: String) throws -> [Variant: String] {
        let url = SourceTree.appSources.appending(path: "Resources/Assets.xcassets/\(name).colorset/Contents.json")
        let colorSet = try JSONDecoder().decode(ColorSet.self, from: Data(contentsOf: url))
        var variants: [Variant: String] = [:]
        for entry in colorSet.colors {
            let traits = Set((entry.appearances ?? []).map(\.value))
            let variant: Variant = switch (traits.contains("dark"), traits.contains("high")) {
            case (false, false): .light
            case (true, false): .dark
            case (false, true): .increasedContrastLight
            case (true, true): .increasedContrastDark
            }
            let channels = ["red", "green", "blue"].compactMap { entry.color.components[$0] }
            variants[variant] = "#" + channels.map { $0.dropFirst(2).lowercased() }.joined()
        }
        return variants
    }
}
