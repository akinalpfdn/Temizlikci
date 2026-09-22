import SwiftUI

/// The sortable, searchable list that mirrors the chart (HIG: pair a novel chart with a conventional list).
struct ContentsTable: View {
    @Bindable var model: LocationScanModel
    @Environment(\.undoManager) private var undoManager

    var body: some View {
        Table(model.rows, selection: selection, sortOrder: $model.sortOrder) {
            TableColumn(String(localized: L10n.Table.name), value: \.name) { node in
                if node.kind == .directory || node.kind == .file {
                    NameCell(model: model, node: node).draggable(node.url)
                } else {
                    NameCell(model: model, node: node)
                }
            }
            .width(min: 120)
            TableColumn(String(localized: L10n.Table.size), value: \.allocatedSize) { node in
                SizeCell(model: model, node: node, largest: model.rows.map(\.allocatedSize).max() ?? 0)
            }
            .width(min: 110, ideal: 120, max: 160)
            TableColumn(String(localized: L10n.Growth.column)) { node in
                if let change = model.growth(for: node) {
                    GrowthLabel(change: change)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .width(min: 84, ideal: 92, max: 120)
            TableColumn(String(localized: L10n.Table.share)) { node in
                Text(model.share(of: node, in: model.currentFolder).map(Formatting.percent) ?? "")
                    .font(Typography.listSize)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(min: 52, ideal: 56, max: 72)
        }
        .contextMenu(forSelectionType: String.self) { ids in
            if let id = ids.first, let node = model.node(withID: id) {
                if node.kind == .directory {
                    Button { model.open(node) } label: { Text(L10n.Chart.open) }
                }
                if model.actionableURL(for: node) != nil {
                    Button { model.select(node); model.revealInFinder() } label: { Text(L10n.Details.revealInFinder) }
                    Button { model.select(node); model.quickLook() } label: { Text(L10n.Details.quickLook) }
                }
                if model.canMoveToTrash(node) {
                    Divider()
                    Button { model.moveToTrash(node, undoManager: undoManager) } label: { Text(L10n.Trash.moveToTrash) }
                }
            }
        } primaryAction: { ids in
            if let id = ids.first, let node = model.node(withID: id) { model.open(node) }
        }
        .overlay {
            if model.rows.isEmpty && !model.searchText.isEmpty {
                ContentUnavailableView.search(text: model.searchText)
            }
        }
    }

    private var selection: Binding<String?> {
        Binding(get: { model.selection?.id }, set: { model.selectNode(withID: $0) })
    }
}

private struct NameCell: View {
    let model: LocationScanModel
    let node: FileNode

    var body: some View {
        HStack(spacing: Spacing.small) {
            Swatch(fill: model.displayFill(for: node))
            Text(model.title(for: node))
                .lineLimit(1)
                .truncationMode(.middle)
            if node.kind == .inaccessible {
                Label { Text(L10n.Nodes.needsAccess) } icon: { Image(systemName: "lock") }
                    .font(Typography.badge)
                    .foregroundStyle(.secondary)
                    .labelStyle(.titleAndIcon)
            }
            if let match = model.cleanupMatch(for: node), match.node.id == node.id {
                SafetyBadge(level: match.rule.safety)
            }
        }
        .help(model.actionableURL(for: node)?.path(percentEncoded: false) ?? "")
    }
}

private struct SizeCell: View {
    let model: LocationScanModel
    let node: FileNode
    let largest: Int64
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: Spacing.small) {
            Capsule()
                .fill(ChartPalette.color(for: model.displayFill(for: node), colorScheme: colorScheme) ?? ChartPalette.hatch)
                .frame(width: max(2, SizeCell.barWidth * fraction), height: 6)
                .frame(width: SizeCell.barWidth, alignment: .leading)
            Text(Formatting.bytes(node.allocatedSize))
                .font(Typography.listSize)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private static let barWidth: CGFloat = 56

    private var fraction: CGFloat {
        largest > 0 ? CGFloat(node.allocatedSize) / CGFloat(largest) : 0
    }
}

/// The chart color of a row, drawn the same way as its segment.
struct Swatch: View {
    let fill: SegmentFill
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        RoundedRectangle(cornerRadius: CornerRadius.small / 2)
            .fill(ChartPalette.color(for: fill, colorScheme: colorScheme) ?? ChartPalette.dimmed)
            .overlay {
                if fill == .unattributedHatch || fill == .inaccessibleHatch {
                    RoundedRectangle(cornerRadius: CornerRadius.small / 2).strokeBorder(ChartPalette.hatch, lineWidth: 1.5)
                } else if fill == .pending {
                    RoundedRectangle(cornerRadius: CornerRadius.small / 2).strokeBorder(.secondary, style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
                }
            }
            .frame(width: 10, height: 10)
            .accessibilityHidden(true)
    }
}
