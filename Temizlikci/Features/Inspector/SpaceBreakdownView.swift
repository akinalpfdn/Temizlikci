import SwiftUI

extension SpacePart {
    var title: LocalizedStringResource {
        switch kind {
        case .systemVolume(let name): L10n.Space.systemVolume(name)
        case .mountedImage(let name): L10n.Space.mountedImage(name)
        case .purgeable: L10n.Space.purgeable
        case .remainder: L10n.Space.remainder
        }
    }

    var detail: LocalizedStringResource {
        switch kind {
        case .systemVolume: L10n.Space.systemVolumeDetail
        case .mountedImage: L10n.Space.mountedImageDetail
        case .purgeable: L10n.Space.purgeableDetail
        case .remainder: L10n.Space.remainderDetail
        }
    }

    var symbol: String {
        switch kind {
        case .systemVolume: "internaldrive"
        case .mountedImage: "externaldrive"
        case .purgeable: "arrow.3.trianglepath"
        case .remainder: "questionmark.circle"
        }
    }
}

/// Splits "Other Used Space" into named parts, each with what it is and what to do about it.
struct SpaceBreakdownView: View {
    let breakdown: SpaceBreakdown?
    @State private var expanded: SpacePart.ID?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text(L10n.Space.breakdownTitle).font(.headline)
            if let breakdown {
                ForEach(breakdown.parts) { part in
                    row(part, total: breakdown.total, isLast: part.id == breakdown.parts.last?.id, breakdown: breakdown)
                }
                Text(L10n.Space.source)
                    .font(Typography.chartCaption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                HStack(spacing: Spacing.xSmall) {
                    ProgressView().controlSize(.small)
                    Text(L10n.Space.reading).foregroundStyle(.secondary)
                }
            }
        }
    }

    private func row(_ part: SpacePart, total: Int64, isLast: Bool, breakdown: SpaceBreakdown) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxSmall) {
            Button {
                expanded = expanded == part.id ? nil : part.id
            } label: {
                HStack(spacing: Spacing.xSmall) {
                    Image(systemName: part.symbol).foregroundStyle(.secondary).frame(width: 18)
                    Text(part.title).lineLimit(1).truncationMode(.middle)
                    Spacer(minLength: Spacing.xSmall)
                    Text(Formatting.bytes(part.size)).font(Typography.listSize).monospacedDigit()
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            share(of: part, total: total)
            if expanded == part.id {
                Text(detail(for: part, breakdown: breakdown))
                    .font(Typography.chartCaption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Spacing.xxSmall)
            }
            if !isLast { Divider().padding(.vertical, Spacing.xxSmall) }
        }
    }

    /// A bar as well as the size, so the split reads at a glance without relying on color.
    private func share(of part: SpacePart, total: Int64) -> some View {
        GeometryReader { proxy in
            let fraction = total > 0 ? min(1, Double(part.size) / Double(total)) : 0
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary)
                Capsule()
                    .fill(part.kind == .remainder ? AnyShapeStyle(.tertiary) : AnyShapeStyle(ChartPalette.neutral))
                    .frame(width: max(2, proxy.size.width * fraction))
            }
        }
        .frame(height: 4)
        .accessibilityHidden(true)
    }

    private func detail(for part: SpacePart, breakdown: SpaceBreakdown) -> String {
        var text = String(localized: part.detail)
        if part.kind == .remainder, breakdown.hasUnreadableFolders {
            text += " " + String(localized: L10n.Space.remainderNoAccess)
        }
        return text
    }
}
