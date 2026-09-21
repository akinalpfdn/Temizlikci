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
}

/// Cleanup-safety colors. Always paired with a symbol and a label, never used alone.
enum StatusPalette {
    static let safeFill = Color.statusSafe
    static let safeInk = Color.statusSafeInk
    static let toolFill = Color.statusTool
    static let toolInk = Color.statusToolInk
}
