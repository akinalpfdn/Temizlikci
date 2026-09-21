import SwiftUI

struct SidebarView: View {
    @Bindable var model: MainViewModel

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

    private func row(for destination: SidebarDestination) -> some View {
        Label { Text(model.title(for: destination)) } icon: { Image(systemName: destination.systemImage) }
            .badge(badge(for: destination))
            .tag(destination)
    }

    private func badge(for destination: SidebarDestination) -> Text? {
        guard destination == .trash, model.trashLedger.totalSize > 0 else { return nil }
        return Text(Formatting.bytes(model.trashLedger.totalSize))
    }
}
