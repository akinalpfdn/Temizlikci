import SwiftUI

/// Menu-bar commands. HIG requires every toolbar action to be reachable here too.
struct AppCommands: Commands {
    let model: MainViewModel

    private var scan: LocationScanModel? { model.currentScan }

    var body: some Commands {
        CommandGroup(after: .appInfo) {
            Button { Task { await model.updates.checkNow() } } label: { Text(L10n.Updates.checkNow) }
                .disabled(model.updates.isChecking)
        }

        CommandGroup(replacing: .newItem) {
            Button { Task { await model.chooseFolder() } } label: { Text(L10n.Menu.chooseFolder) }
                .keyboardShortcut("o")
            Divider()
            Button { scan?.startScan() } label: { Text(L10n.Navigation.rescan) }
                .keyboardShortcut("r")
                .disabled(scan == nil || scan?.isScanning == true)
            Button { scan?.stopScan() } label: { Text(L10n.Navigation.stop) }
                .keyboardShortcut(".")
                .disabled(scan?.isScanning != true)
            Divider()
            Button { scan?.revealInFinder() } label: { Text(L10n.Details.revealInFinder) }
                .keyboardShortcut("r", modifiers: [.command, .option])
                .disabled(scan?.hasResult != true)
            Button { scan?.quickLook() } label: { Text(L10n.Details.quickLook) }
                .keyboardShortcut("y")
                .disabled(scan?.hasResult != true)
        }

        CommandGroup(after: .sidebar) {
            Toggle(isOn: Binding(get: { scan?.isHighlightingReclaimable ?? false }, set: { scan?.isHighlightingReclaimable = $0 })) {
                Text(L10n.Cleanup.highlight)
            }
            .disabled(scan?.canHighlightReclaimable != true)
        }

        CommandGroup(after: .pasteboard) {
            Divider()
            Button { model.focusSearch() } label: { Text(L10n.Search.find) }
                .keyboardShortcut("f")
                .disabled(scan?.tree == nil)
            Button { model.moveSelectionToTrash() } label: { Text(L10n.Trash.moveToTrash) }
                .keyboardShortcut(.delete)
                .disabled(!model.canMoveSelectionToTrash)
        }

        CommandGroup(replacing: .help) {
            Button { model.isShowingIntro = true } label: { Text(L10n.Intro.menuItem) }
        }

        CommandMenu(String(localized: L10n.Navigation.goMenu)) {
            Button { scan?.goBack() } label: { Text(L10n.Navigation.back) }
                .keyboardShortcut("[")
                .disabled(scan?.canGoBack != true)
            Button { scan?.goForward() } label: { Text(L10n.Navigation.forward) }
                .keyboardShortcut("]")
                .disabled(scan?.canGoForward != true)
            Button { scan?.goUp() } label: { Text(L10n.Navigation.enclosingFolder) }
                .keyboardShortcut(.upArrow)
                .disabled(scan?.canGoUp != true)
        }
    }
}
