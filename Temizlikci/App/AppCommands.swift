import SwiftUI

/// Menu-bar commands. HIG requires every toolbar action to be reachable here too.
struct AppCommands: Commands {
    @Bindable var model: MainViewModel

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button {
                Task { await model.chooseFolder() }
            } label: {
                Text(L10n.Menu.chooseFolder)
            }
            .keyboardShortcut("o")
        }

        CommandGroup(after: .sidebar) {
            Toggle(isOn: $model.isHighlightingReclaimable) {
                Text(L10n.Menu.highlightReclaimable)
            }
            .disabled(!model.canHighlightReclaimable)
        }
    }
}
