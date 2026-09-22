import QuickLook
import SwiftUI

/// The largest individual files in a scan, with the same actions as the chart.
struct LargeFilesView: View {
    let main: MainViewModel
    @Bindable var scan: LocationScanModel
    @Environment(\.undoManager) private var undoManager
    @State private var selection: LargeFile.ID?
    @State private var sortOrder = [KeyPathComparator(\LargeFile.node.allocatedSize, order: .reverse)]

    var body: some View {
        if scan.largeFiles.isEmpty {
            ContentUnavailableView {
                Label { Text(L10n.LargeFiles.noneTitle) } icon: { Image(systemName: "doc") }
            } description: {
                Text(L10n.LargeFiles.noneMessage)
            }
        } else {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text(L10n.LargeFiles.title(scan.location.displayName)).font(.title2.weight(.semibold))
                Text(L10n.LargeFiles.hint).foregroundStyle(.secondary)
                table
            }
            .padding(Spacing.large)
            .overlay(alignment: .bottom) { TrashConfirmation(model: scan) }
            .modifier(ActionErrorAlert(model: scan))
            .quickLookPreview($scan.previewURL)
        }
    }

    private var table: some View {
        Table(scan.largeFiles.sorted(using: sortOrder), selection: $selection, sortOrder: $sortOrder) {
            TableColumn(String(localized: L10n.Table.name), value: \.node.name) { file in
                VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                    Text(file.node.name).lineLimit(1).truncationMode(.middle)
                    Text(file.node.url.deletingLastPathComponent().path(percentEncoded: false))
                        .font(Typography.chartCaption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .width(min: 200)
            TableColumn(String(localized: L10n.LargeFiles.modified)) { file in
                Text(file.node.modificationDate.map { $0.formatted(date: .abbreviated, time: .omitted) } ?? "")
                    .foregroundStyle(.secondary)
            }
            .width(min: 90, ideal: 110, max: 140)
            TableColumn(String(localized: L10n.Growth.column)) { file in
                if let change = scan.growth(for: file.node) { GrowthLabel(change: change) }
            }
            .width(min: 84, ideal: 92, max: 120)
            TableColumn(String(localized: L10n.Table.size), value: \.node.allocatedSize) { file in
                Text(Formatting.bytes(file.node.allocatedSize))
                    .font(Typography.listSize)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(min: 80, ideal: 96, max: 120)
        }
        .onChange(of: selection) { _, id in main.inspect(id.map { .node($0) }) }
        .contextMenu(forSelectionType: LargeFile.ID.self) { ids in
            if let file = file(for: ids) {
                Button { main.show(path: file.node.path, in: scan) } label: { Text(L10n.Growth.showInChart) }
                Button { scan.revealInFinder(file) } label: { Text(L10n.Details.revealInFinder) }
                Button { scan.quickLook(file) } label: { Text(L10n.Details.quickLook) }
                if scan.canMoveToTrash(file) {
                    Divider()
                    Button { scan.moveToTrash(file, undoManager: undoManager) } label: { Text(L10n.Trash.moveToTrash) }
                }
            }
        } primaryAction: { ids in
            if let file = file(for: ids) { main.show(path: file.node.path, in: scan) }
        }
    }

    private func file(for ids: Set<LargeFile.ID>) -> LargeFile? {
        guard let id = ids.first else { return nil }
        return scan.largeFiles.first { $0.id == id }
    }
}
