import SwiftUI

/// A size change: an arrow symbol plus the amount, never color alone, with a spoken description.
struct GrowthLabel: View {
    let change: GrowthChange

    var body: some View {
        Label { Text(amount) } icon: { Image(systemName: symbol) }
            .labelStyle(.titleAndIcon)
            .font(Typography.listSize)
            .foregroundStyle(.secondary)
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
