import SwiftUI

/// Items moved to the Trash from Temizlikci in this session, each with Put Back.
struct TrashListView: View {
    let main: MainViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text(L10n.Trash.total(Formatting.bytes(main.trashLedger.totalSize)))
                    .font(.title3.weight(.semibold))
                Text(L10n.Trash.emptyNote)
                    .foregroundStyle(.secondary)
            }
            List(main.trashLedger.records) { record in
                HStack(spacing: Spacing.medium) {
                    Image(systemName: record.node.kind == .directory ? "folder" : "doc")
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                        Text(record.node.name)
                        Text(L10n.Trash.movedFrom(record.originalURL.deletingLastPathComponent().path(percentEncoded: false)))
                            .font(Typography.chartCaption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    Spacer()
                    Text(Formatting.bytes(record.node.allocatedSize))
                        .font(Typography.listSize)
                    Button { main.putBack(record) } label: { Text(L10n.Trash.putBack) }
                }
                .padding(.vertical, Spacing.xxSmall)
            }
            HStack {
                Spacer()
                Button { main.trashLedger.showTrashInFinder() } label: { Text(L10n.Trash.showInFinder) }
            }
        }
        .padding(Spacing.large)
        // Items emptied from the Trash since the list was last shown drop out when it appears.
        .task { await main.trashLedger.reconcile() }
    }
}
