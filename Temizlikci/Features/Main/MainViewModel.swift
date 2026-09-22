import Foundation
import Observation

@MainActor
@Observable
final class MainViewModel {
    var selection: SidebarDestination? = .startupDisk
    var isInspectorPresented = true
    /// The window's undo manager, so menu commands can register Undo for Move to Trash.
    weak var undoManager: UndoManager?

    private(set) var hasFullDiskAccess: Bool
    var isAccessBannerDismissed = false
    let trashLedger: TrashLedger
    let simulators: SimulatorsModel
    var isShowingIntro = false
    /// Incremented by Edit › Find; the visible overview moves focus to its search field.
    private(set) var searchFocusRequest = 0
    private(set) var startupFreeSpace: Int64?

    private(set) var chosenFolder: URL?
    let startupVolumeName: String

    /// One scan model per location, created when the location becomes available.
    private var scanModels: [SidebarDestination: LocationScanModel] = [:]

    private let volumeInfo: VolumeInfoProviding
    private let folderPicker: FolderPicking
    private let access: FullDiskAccessChecking
    private let revealer: FileRevealing
    private let trash: Trashing
    private let settings: PrivacySettingsOpening
    private let apps: AppOpening
    private let ruleEngine: RuleEngine
    private let projectFinder: ProjectFinder
    private let snapshots: SnapshotStoring
    private let scanCache: ScanCaching
    private let makeScanner: (ScanConfiguration) -> DiskScanning

    init(
        volumeInfo: VolumeInfoProviding,
        folderPicker: FolderPicking,
        access: FullDiskAccessChecking = SystemFullDiskAccessChecker(),
        revealer: FileRevealing = FinderRevealer(),
        trash: Trashing = FileManagerTrash(),
        settings: PrivacySettingsOpening = SystemPrivacySettings(),
        apps: AppOpening = WorkspaceAppOpener(),
        tools: ToolRunning = ProcessToolRunner(),
        snapshots: SnapshotStoring = FileSnapshotStore(),
        scanCache: ScanCaching = FileScanCache(),
        homeFolder: URL = URL.homeDirectory,
        makeScanner: @escaping (ScanConfiguration) -> DiskScanning = { FileSystemScanner(configuration: $0) }
    ) {
        startupVolumeName = volumeInfo.startupVolumeName() ?? String(localized: L10n.Sidebar.startupDiskFallback)
        self.volumeInfo = volumeInfo
        self.folderPicker = folderPicker
        self.access = access
        self.revealer = revealer
        self.trash = trash
        self.settings = settings
        self.apps = apps
        self.snapshots = snapshots
        self.scanCache = scanCache
        self.makeScanner = makeScanner
        ruleEngine = RuleEngine(home: homeFolder)
        projectFinder = ProjectFinder(home: homeFolder)
        startupFreeSpace = try? volumeInfo.usage(ofVolumeContaining: URL(filePath: "/")).availableCapacity
        simulators = SimulatorsModel(service: SimulatorService(runner: tools))
        trashLedger = TrashLedger(trash: trash)
        hasFullDiskAccess = access.hasFullDiskAccess()
        scanModels[.startupDisk] = makeScanModel(ScanLocation(url: URL(filePath: "/", directoryHint: .isDirectory), displayName: startupVolumeName, isWholeVolume: true))
        scanModels[.home] = makeScanModel(ScanLocation(url: homeFolder, displayName: String(localized: L10n.Sidebar.home), isWholeVolume: false))
    }

    var locationDestinations: [SidebarDestination] {
        chosenFolder == nil ? [.startupDisk, .home] : [.startupDisk, .home, .chosenFolder]
    }

    let insightDestinations: [SidebarDestination] = [.developer, .whatGrew, .largeFiles, .trash]

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
        case .whatGrew: String(localized: L10n.Sidebar.whatGrew)
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
        LocationScanModel(
            location: location, volumeInfo: volumeInfo, access: access, revealer: revealer,
            trash: trash, ledger: trashLedger, ruleEngine: ruleEngine, projectFinder: projectFinder,
            scanCache: scanCache, snapshots: snapshots, makeScanner: makeScanner
        )
    }

    /// Handles a drop on the sidebar's Trash: the items come from the visible scan.
    @discardableResult
    func moveToTrash(droppedURLs urls: [URL], undoManager: UndoManager?) -> Bool {
        guard let scan = currentScan else { return false }
        return scan.moveToTrash(droppedURLs: urls, undoManager: undoManager)
    }

    // MARK: - What Grew

    /// The scan the What Grew view compares: the first location, in sidebar order, with a previous scan to compare.
    var growthScan: LocationScanModel? {
        let models = locationDestinations.compactMap { scanModels[$0] }
        return models.first { $0.growth != nil && !$0.growthIsFromSavedScans } ?? models.first { $0.growth != nil }
    }

    /// Fills What Grew from saved scans when nothing has been scanned in this session.
    func loadSavedGrowth() {
        for destination in locationDestinations {
            scanModels[destination]?.loadSavedGrowth()
        }
    }

    /// Opens a changed item in its location's chart.
    func show(_ change: GrowthChange, in scan: LocationScanModel) {
        show(path: change.path, in: scan)
    }

    /// Switches to the scan's location and opens the item at `path` in the chart.
    func show(path: String, in scan: LocationScanModel) {
        guard let destination = scanModels.first(where: { $0.value === scan })?.key else { return }
        selection = destination
        scan.showItem(atPath: path)
    }

    /// The scan the Large Files view lists: the startup disk if it has results, otherwise Home or the chosen folder.
    var largeFilesScan: LocationScanModel? {
        locationDestinations.compactMap { scanModels[$0] }.first { $0.hasResult }
    }

    // MARK: - Developer insights

    /// The scan the Developer view summarizes: the startup disk if it has results, otherwise Home.
    var developerScan: LocationScanModel? {
        [scanModels[.startupDisk], scanModels[.home]].compactMap { $0 }.first { $0.hasResult }
    }

    var isAndroidStudioInstalled: Bool { apps.isInstalled(WorkspaceAppOpener.androidStudio) }

    func openAndroidStudio() {
        apps.open(WorkspaceAppOpener.androidStudio)
    }

    func scanHome() {
        selection = .home
        scanModels[.home]?.startScan()
    }

    /// After simctl changed the disk, every finished scan's sizes are outdated until rescanned.
    func simulatorsDidChangeDisk() {
        scanModels.values.forEach { $0.markOutdated() }
    }

    // MARK: - Trash

    func moveSelectionToTrash() {
        guard let scan = currentScan else { return }
        scan.moveToTrash(scan.selection ?? scan.currentFolder, undoManager: undoManager)
    }

    var canMoveSelectionToTrash: Bool {
        guard let scan = currentScan else { return false }
        return scan.canMoveToTrash(scan.selection ?? scan.currentFolder)
    }

    /// Puts an item back through the location it came from, so that location's tree updates too.
    func putBack(_ record: TrashRecord) {
        let owner = scanModels.values.first { $0.location.url == record.locationURL }
        (owner ?? scanModels[.startupDisk])?.putBack(record)
    }

    // MARK: - Full Disk Access

    /// Re-reads access, for example when the app becomes active after the person visited System Settings.
    func refreshAccess() {
        hasFullDiskAccess = access.hasFullDiskAccess()
        refreshFreeSpace()
    }

    /// Free space changes as people work; it's re-read on activation and after scans. A read failure only hides the badge.
    func refreshFreeSpace() {
        startupFreeSpace = try? volumeInfo.usage(ofVolumeContaining: URL(filePath: "/")).availableCapacity
    }

    func focusSearch() {
        searchFocusRequest += 1
    }

    func openPrivacySettings() {
        settings.openFullDiskAccessSettings()
    }

    func shouldShowAccessBanner(for scan: LocationScanModel) -> Bool {
        !hasFullDiskAccess && !isAccessBannerDismissed && (scan.result?.inaccessibleCount ?? 0) > 0
    }

    private static func displayName(of folder: URL) -> String {
        FileManager.default.displayName(atPath: folder.path(percentEncoded: false))
    }
}
