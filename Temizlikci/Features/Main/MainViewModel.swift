import Foundation
import Observation

@MainActor
@Observable
final class MainViewModel {
    var selection: SidebarDestination? = .startupDisk
    var isInspectorPresented = true
    var isHighlightingReclaimable = false

    private(set) var chosenFolder: URL?
    /// Becomes true once a scan has produced results; until then result-dependent commands stay disabled.
    private(set) var hasScanResults = false

    let startupVolumeName: String
    private let folderPicker: FolderPicking

    init(volumeInfo: VolumeInfoProviding, folderPicker: FolderPicking) {
        startupVolumeName = volumeInfo.startupVolumeName() ?? String(localized: L10n.Sidebar.startupDiskFallback)
        self.folderPicker = folderPicker
    }

    var locationDestinations: [SidebarDestination] {
        chosenFolder == nil ? [.startupDisk, .home] : [.startupDisk, .home, .chosenFolder]
    }

    let insightDestinations: [SidebarDestination] = [.developer, .largeFiles, .trash]

    var canHighlightReclaimable: Bool { hasScanResults }

    var windowTitle: String {
        selection.map(title(for:)) ?? String(localized: L10n.App.name)
    }

    func title(for destination: SidebarDestination) -> String {
        switch destination {
        case .startupDisk: startupVolumeName
        case .home: String(localized: L10n.Sidebar.home)
        case .chosenFolder: chosenFolder.map(Self.displayName(of:)) ?? String(localized: L10n.Sidebar.chooseFolder)
        case .developer: String(localized: L10n.Sidebar.developer)
        case .largeFiles: String(localized: L10n.Sidebar.largeFiles)
        case .trash: String(localized: L10n.Sidebar.trash)
        }
    }

    func chooseFolder() async {
        guard let folder = await folderPicker.pickFolder() else { return }
        chosenFolder = folder
        selection = .chosenFolder
    }

    private static func displayName(of folder: URL) -> String {
        FileManager.default.displayName(atPath: folder.path(percentEncoded: false))
    }
}
