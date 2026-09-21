import Foundation
import Observation

@MainActor
@Observable
final class MainViewModel {
    var selection: SidebarDestination? = .startupDisk
    var isInspectorPresented = true

    private(set) var chosenFolder: URL?
    let startupVolumeName: String

    /// One scan model per location, created when the location becomes available.
    private var scanModels: [SidebarDestination: LocationScanModel] = [:]

    private let volumeInfo: VolumeInfoProviding
    private let folderPicker: FolderPicking
    private let access: FullDiskAccessChecking
    private let revealer: FileRevealing
    private let makeScanner: (ScanConfiguration) -> DiskScanning

    init(
        volumeInfo: VolumeInfoProviding,
        folderPicker: FolderPicking,
        access: FullDiskAccessChecking = SystemFullDiskAccessChecker(),
        revealer: FileRevealing = FinderRevealer(),
        homeFolder: URL = URL.homeDirectory,
        makeScanner: @escaping (ScanConfiguration) -> DiskScanning = { FileSystemScanner(configuration: $0) }
    ) {
        startupVolumeName = volumeInfo.startupVolumeName() ?? String(localized: L10n.Sidebar.startupDiskFallback)
        self.volumeInfo = volumeInfo
        self.folderPicker = folderPicker
        self.access = access
        self.revealer = revealer
        self.makeScanner = makeScanner
        scanModels[.startupDisk] = makeScanModel(ScanLocation(url: URL(filePath: "/", directoryHint: .isDirectory), displayName: startupVolumeName, isWholeVolume: true))
        scanModels[.home] = makeScanModel(ScanLocation(url: homeFolder, displayName: String(localized: L10n.Sidebar.home), isWholeVolume: false))
    }

    var locationDestinations: [SidebarDestination] {
        chosenFolder == nil ? [.startupDisk, .home] : [.startupDisk, .home, .chosenFolder]
    }

    let insightDestinations: [SidebarDestination] = [.developer, .largeFiles, .trash]

    /// The scan model behind the selected sidebar location, if a location is selected.
    var currentScan: LocationScanModel? {
        selection.flatMap { scanModels[$0] }
    }

    func scanModel(for destination: SidebarDestination) -> LocationScanModel? {
        scanModels[destination]
    }

    var windowTitle: String {
        if let scan = currentScan, let folder = scan.currentFolder, folder.id != scan.tree?.id {
            return scan.title(for: folder)
        }
        return selection.map(title(for:)) ?? String(localized: L10n.App.name)
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
        scanModels[.chosenFolder]?.stopScan()
        chosenFolder = folder
        scanModels[.chosenFolder] = makeScanModel(ScanLocation(url: folder, displayName: Self.displayName(of: folder), isWholeVolume: false))
        selection = .chosenFolder
    }

    private func makeScanModel(_ location: ScanLocation) -> LocationScanModel {
        LocationScanModel(location: location, volumeInfo: volumeInfo, access: access, revealer: revealer, makeScanner: makeScanner)
    }

    private static func displayName(of folder: URL) -> String {
        FileManager.default.displayName(atPath: folder.path(percentEncoded: false))
    }
}
