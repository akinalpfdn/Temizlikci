import SwiftUI

struct SidebarView: View {
    @Bindable var model: MainViewModel
    @Environment(\.undoManager) private var undoManager
    @State private var isDropTargeted = false

    var body: some View {
        List(selection: $model.selection) {
            Section {
                ForEach(model.locationDestinations) { row(for: $0) }
                Button {
                    Task { await model.chooseFolder() }
                } label: {
                    Label { Text(L10n.Sidebar.chooseFolder) } icon: { Image(systemName: "plus.circle") }
                }
                .buttonStyle(.plain)
            } header: {
                Text(L10n.Sidebar.locations)
            }

            Section {
                ForEach(model.insightDestinations) { row(for: $0) }
            } header: {
                Text(L10n.Sidebar.insights)
            }
        }
        .listStyle(.sidebar)
    }

    @ViewBuilder
    private func row(for destination: SidebarDestination) -> some View {
        let label = Label { Text(model.title(for: destination)) } icon: { Image(systemName: destination.systemImage) }
            .badge(badge(for: destination))
            .tag(destination)
        if destination == .trash {
            label
                // Dragging a row onto the Trash does the same as Move to Trash, Undo included.
                .dropDestination(for: URL.self) { urls, _ in
                    model.moveToTrash(droppedURLs: urls, undoManager: undoManager)
                } isTargeted: { isDropTargeted = $0 }
                .background(isDropTargeted ? AnyShapeStyle(.selection) : AnyShapeStyle(.clear), in: .rect(cornerRadius: CornerRadius.small))
        } else {
            label
        }
    }

    private func badge(for destination: SidebarDestination) -> Text? {
        switch destination {
        case .startupDisk:
            return model.startupFreeSpace.map { Text(L10n.Volume.free(Formatting.bytes($0))) }
        case .trash where model.trashLedger.totalSize > 0:
            return Text(Formatting.bytes(model.trashLedger.totalSize))
        default:
            return nil
        }
    }
}
