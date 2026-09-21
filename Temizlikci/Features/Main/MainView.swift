import SwiftUI

struct MainView: View {
    @Bindable var model: MainViewModel

    var body: some View {
        NavigationSplitView {
            SidebarView(model: model)
                .navigationSplitViewColumnWidth(
                    min: WindowMetrics.sidebarWidth.minimum,
                    ideal: WindowMetrics.sidebarWidth.ideal,
                    max: WindowMetrics.sidebarWidth.maximum
                )
        } detail: {
            DetailView(model: model)
                .navigationTitle(model.windowTitle)
                .navigationSubtitle(Text(L10n.Toolbar.noScanSubtitle))
                .toolbar { MainToolbar(model: model) }
        }
        .inspector(isPresented: $model.isInspectorPresented) {
            InspectorView()
                .inspectorColumnWidth(
                    min: WindowMetrics.inspectorWidth.minimum,
                    ideal: WindowMetrics.inspectorWidth.ideal,
                    max: WindowMetrics.inspectorWidth.maximum
                )
        }
        .frame(minWidth: WindowMetrics.minimumSize.width, minHeight: WindowMetrics.minimumSize.height)
    }
}

private struct MainToolbar: ToolbarContent {
    @Bindable var model: MainViewModel

    var body: some ToolbarContent {
        ToolbarItem {
            Toggle(isOn: $model.isHighlightingReclaimable) {
                Label { Text(L10n.Toolbar.highlightReclaimable) } icon: { Image(systemName: "sparkles") }
            }
            .toggleStyle(.button)
            .disabled(!model.canHighlightReclaimable)
            .help(Text(L10n.Toolbar.highlightReclaimable))
        }
        ToolbarItem {
            Button {
                model.isInspectorPresented.toggle()
            } label: {
                Label { Text(L10n.Toolbar.inspector) } icon: { Image(systemName: "sidebar.trailing") }
            }
            .help(Text(L10n.Toolbar.inspector))
        }
    }
}
