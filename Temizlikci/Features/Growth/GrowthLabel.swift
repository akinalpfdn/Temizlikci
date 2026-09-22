import SwiftUI

/// A size change: an arrow symbol plus the amount, tinted warm for growth and cool for shrinking.
/// The symbol and the sign carry the direction on their own; the color only reinforces it.
struct GrowthLabel: View {
    let change: GrowthChange

    var body: some View {
        Label { Text(amount).monospacedDigit() } icon: { Image(systemName: symbol) }
            .labelStyle(.titleAndIcon)
            .font(Typography.listSize)
            .foregroundStyle(GrowthPalette.ink(for: change.kind))
            .padding(.horizontal, Spacing.xSmall)
            .padding(.vertical, Spacing.xxSmall)
            .background(GrowthPalette.ink(for: change.kind).opacity(0.12), in: .capsule)
            .help(change.kind == .appeared ? Text(L10n.Growth.appearedHelp) : Text(verbatim: ""))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityText)
    }

    private var symbol: String {
        switch change.kind {
        case .grew: "arrow.up.right"
        case .shrank: "arrow.down.right"
        case .appeared: "plus.circle"
        case .removed: "minus.circle"
        }
    }

    private var amount: String {
        let size = Formatting.bytes(abs(change.delta))
        return change.delta >= 0 ? "+" + size : "−" + size
    }

    private var accessibilityText: Text {
        let size = Formatting.bytes(abs(change.delta))
        return change.delta >= 0 ? Text(L10n.Growth.grew(size)) : Text(L10n.Growth.shrank(size))
    }
}

/// How much of the biggest change in the list this one is, as a bar. Length repeats what the
/// amount and the arrow already say, for people who read shape before text.
struct GrowthBar: View {
    let change: GrowthChange
    let largest: Int64

    var body: some View {
        GeometryReader { proxy in
            let fraction = largest > 0 ? min(1, Double(abs(change.delta)) / Double(largest)) : 0
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary)
                Capsule()
                    .fill(GrowthPalette.ink(for: change.kind))
                    .frame(width: max(3, proxy.size.width * fraction))
            }
        }
        .frame(height: 4)
        .accessibilityHidden(true)
    }
}
