import SwiftUI

struct TemizlikciApp: App {
    @State private var model = MainViewModel(
        volumeInfo: SystemVolumeInfo(),
        folderPicker: OpenPanelFolderPicker()
    )

    var body: some Scene {
        Window(Text(L10n.App.name), id: "main") {
            MainView(model: model)
        }
        .defaultSize(WindowMetrics.defaultSize)
        .windowResizability(.contentMinSize)
        .commands {
            SidebarCommands()
            InspectorCommands()
            AppCommands(model: model)
        }

        Settings {
            SettingsView()
        }
    }
}
