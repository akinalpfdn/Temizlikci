import SwiftUI

/// A disclosure group whose whole header opens and closes it, not only the triangle.
///
/// SwiftUI's macOS default reacts to the triangle alone — a target of about 13 pt, below the 20×20 pt
/// minimum in HIG "Accessibility". Finder restricts toggling to the triangle because clicking a row
/// selects it; section headers select nothing, so the full width can act as the button.
struct HeaderDisclosureStyle: DisclosureGroupStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.snappy) { configuration.isExpanded.toggle() }
            } label: {
                HStack(spacing: Spacing.small) {
                    Image(systemName: "chevron.right")
                        .font(Typography.badge)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(configuration.isExpanded ? 90 : 0))
                        .frame(width: 12)
                    configuration.label
                }
                .padding(.vertical, Spacing.xSmall)
                .frame(minHeight: 28)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityValue(Text(configuration.isExpanded ? L10n.Accessibility.expanded : L10n.Accessibility.collapsed))
            if configuration.isExpanded {
                configuration.content
            }
        }
    }
}
