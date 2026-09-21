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
                .navigationSubtitle(subtitle)
                .toolbar { MainToolbar(model: model, scan: model.currentScan) }
        }
        .inspector(isPresented: $model.isInspectorPresented) {
            InspectorView(scan: model.currentScan)
                .inspectorColumnWidth(
                    min: WindowMetrics.inspectorWidth.minimum,
                    ideal: WindowMetrics.inspectorWidth.ideal,
                    max: WindowMetrics.inspectorWidth.maximum
                )
        }
        .frame(minWidth: WindowMetrics.minimumSize.width, minHeight: WindowMetrics.minimumSize.height)
    }

    private var subtitle: Text {
        guard let scan = model.currentScan else { return Text(verbatim: "") }
        switch scan.phase {
        case .scanning:
            return Text(L10n.Navigation.scanningSubtitle(Formatting.bytes(scan.progress.allocatedSize)))
        case .finished:
            if let usage = scan.usage, scan.currentFolder?.id == scan.tree?.id {
                return Text(L10n.Navigation.volumeSubtitle(
                    used: Formatting.bytes(usage.usedCapacity),
                    available: Formatting.bytes(usage.availableCapacity)
                ))
            }
            return Text(Formatting.bytes(scan.currentFolder?.allocatedSize ?? 0))
        case .idle, .failed:
            return Text(L10n.Toolbar.noScanSubtitle)
        }
    }
}

private struct MainToolbar: ToolbarContent {
    let model: MainViewModel
    let scan: LocationScanModel?

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            Button { scan?.goBack() } label: {
                Label { Text(L10n.Navigation.back) } icon: { Image(systemName: "chevron.backward") }
            }
            .help(Text(L10n.Navigation.back))
            .disabled(!(scan?.canGoBack ?? false))
            Button { scan?.goForward() } label: {
                Label { Text(L10n.Navigation.forward) } icon: { Image(systemName: "chevron.forward") }
            }
            .help(Text(L10n.Navigation.forward))
            .disabled(!(scan?.canGoForward ?? false))
        }
        ToolbarItem {
            if let scan, scan.isScanning {
                Button { scan.stopScan() } label: {
                    Label { Text(L10n.Navigation.stop) } icon: { Image(systemName: "stop.circle") }
                }
                .help(Text(L10n.Navigation.stop))
            } else {
                Button { scan?.startScan() } label: {
                    Label { Text(L10n.Navigation.rescan) } icon: { Image(systemName: "arrow.clockwise") }
                }
                .help(Text(L10n.Navigation.rescan))
                .disabled(scan == nil)
            }
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
