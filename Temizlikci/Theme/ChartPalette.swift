import SwiftUI

/// Colors for chart content only; controls and text keep system colors.
/// Each asset defines light, dark, and increased-contrast variants validated for adjacent
/// segments (see DECISIONS.md, 2026-09-22). Order matters: it is the colorblind-safety mechanism.
enum ChartPalette {
    static let slots: [Color] = [
        .chartSlot1, .chartSlot2, .chartSlot3, .chartSlot4,
        .chartSlot5, .chartSlot6, .chartSlot7, .chartSlot8,
    ]

    /// Segments beyond the last slot, "Smaller items", and remainders.
    static let neutral = Color.chartNeutral
    /// Segments faded out while Highlight Reclaimable is on.
    static let dimmed = Color.chartDimmed
    /// Stripes for space no folder accounts for, and for folders that need access.
    static let hatch = Color.chartHatch
    /// The chart's background; also paints the 2 pt gaps between segments.
    static let surface = Color(nsColor: .textBackgroundColor)
    /// Label ink on light and dark segment fills.
    static let labelOnLight = Color.black.opacity(0.82)
    static let labelOnDark = Color.white

    static let segmentGap: CGFloat = 2
    static let hatchSpacing: CGFloat = 6

    /// Deeper rings mix the slot color toward the surface (approved design: ~30% / ~52% in light mode).
    static func tint(slot index: Int, depth: Int, colorScheme: ColorScheme) -> Color {
        let base = slots[index % slots.count]
        let amount: Double = switch (depth, colorScheme) {
        case (1, _): 0
        case (2, .dark): 0.22
        case (2, _): 0.30
        case (_, .dark): 0.40
        default: 0.52
        }
        return amount == 0 ? base : base.mix(with: surface, by: amount)
    }

    /// The solid color for a fill role, or `nil` for roles drawn as hatching or outlines.
    static func color(for fill: SegmentFill, colorScheme: ColorScheme) -> Color? {
        switch fill {
        case .slot(let index, let depth): tint(slot: index, depth: depth, colorScheme: colorScheme)
        case .neutral: neutral
        case .safety(.safe): StatusPalette.safeFill
        case .safety(.tool): StatusPalette.toolFill
        case .safety(.keep), .dimmed: dimmed
        case .unattributedHatch, .inaccessibleHatch, .pending: nil
        }
    }
}

/// Size-change colors: warm for growth, cool for shrinking, so the two stay apart for every kind of
/// color vision. Text ink, checked at 4.5:1 or better on the list background; never used alone
/// (always with an arrow symbol, a section heading, and a bar whose length carries the same value).
enum GrowthPalette {
    static let upInk = Color.growthUpInk
    static let downInk = Color.growthDownInk

    static func ink(for kind: GrowthChange.Kind) -> Color {
        switch kind {
        case .grew, .appeared: upInk
        case .shrank, .removed: downInk
        }
    }
}

/// Cleanup-safety colors. Always paired with a symbol and a label, never used alone.
enum StatusPalette {
    static let safeFill = Color.statusSafe
    static let safeInk = Color.statusSafeInk
    static let toolFill = Color.statusTool
    static let toolInk = Color.statusToolInk
    /// A warning that isn't a cleanup label (for example, unpushed Git work): the system orange,
    /// always paired with a warning symbol and text.
    static let attention = Color.orange
}
