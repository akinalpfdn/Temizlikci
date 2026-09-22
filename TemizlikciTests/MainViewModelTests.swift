import Foundation
import Testing
@testable import Temizlikci

private struct StubVolumeInfo: VolumeInfoProviding {
    let name: String?
    func startupVolumeName() -> String? { name }
    func usage(ofVolumeContaining url: URL) throws -> VolumeUsage {
        VolumeUsage(totalCapacity: 500, availableCapacity: 35, availableForImportantUsage: nil)
    }
}

nonisolated private struct StubAccess: FullDiskAccessChecking {
    let granted: Bool
    func hasFullDiskAccess() -> Bool { granted }
}

private final class RecordingSettings: PrivacySettingsOpening {
    private(set) var opened = 0
    func openFullDiskAccessSettings() { opened += 1 }
}

private struct StubFolderPicker: FolderPicking {
    let result: URL?
    func pickFolder() async -> URL? { result }
}

@MainActor
struct MainViewModelTests {
    private let settings = RecordingSettings()
    private let apps = RecordingApps()
    private let scanCache = InMemoryScanCache()

    private func makeModel(volumeName: String? = "Macintosh HD", pickedFolder: URL? = nil, accessGranted: Bool = true) -> MainViewModel {
        MainViewModel(
            volumeInfo: StubVolumeInfo(name: volumeName),
            folderPicker: StubFolderPicker(result: pickedFolder),
            access: StubAccess(granted: accessGranted),
            revealer: FinderRevealer(),
            trash: StubTrash(),
            settings: settings,
            apps: apps,
            snapshots: InMemorySnapshots(),
            scanCache: scanCache
        )
    }

    @Test("should select the startup disk and show the inspector when launched")
    func defaultState() {
        let model = makeModel()

        #expect(model.selection == .startupDisk)
        #expect(model.isInspectorPresented)
        #expect(model.windowTitle == "Macintosh HD")
    }

    @Test("should fall back to a generic name when the volume name can't be read")
    func startupNameFallback() {
        let model = makeModel(volumeName: nil)

        #expect(model.title(for: .startupDisk) == String(localized: L10n.Sidebar.startupDiskFallback))
    }

    @Test("should add and select the chosen folder when a folder is picked")
    func chooseFolderAddsLocation() async {
        let folder = URL(filePath: "/Users/Shared", directoryHint: .isDirectory)
        let model = makeModel(pickedFolder: folder)

        await model.chooseFolder()

        #expect(model.selection == .chosenFolder)
        #expect(model.locationDestinations == [.startupDisk, .home, .chosenFolder])
        #expect(model.title(for: .chosenFolder) == FileManager.default.displayName(atPath: "/Users/Shared"))
    }

    @Test("should leave locations unchanged when the picker is cancelled")
    func cancelledPickKeepsState() async {
        let model = makeModel(pickedFolder: nil)

        await model.chooseFolder()

        #expect(model.selection == .startupDisk)
        #expect(model.locationDestinations == [.startupDisk, .home])
    }

    @Test("should give each location its own scan, with the startup disk scanned as a whole volume")
    func locationScans() async {
        let folder = URL(filePath: "/Users/Shared", directoryHint: .isDirectory)
        let model = makeModel(pickedFolder: folder)

        #expect(model.currentScan?.location.isWholeVolume == true)
        #expect(model.scanModel(for: .home)?.location.isWholeVolume == false)
        #expect(model.scanModel(for: .developer) == nil)

        await model.chooseFolder()
        #expect(model.currentScan?.location.url == folder)
    }

    @Test("should open Full Disk Access settings when asked")
    func openSettings() {
        let model = makeModel(accessGranted: false)

        model.openPrivacySettings()

        #expect(settings.opened == 1)
        #expect(model.hasFullDiskAccess == false)
    }

    @Test("should not show the access banner before any scan, with access, or after Not Now")
    func accessBannerRules() throws {
        let withoutAccess = makeModel(accessGranted: false)
        let scan = try #require(withoutAccess.currentScan)
        #expect(!withoutAccess.shouldShowAccessBanner(for: scan))

        let withAccess = makeModel(accessGranted: true)
        #expect(!withAccess.shouldShowAccessBanner(for: try #require(withAccess.currentScan)))

        withoutAccess.isAccessBannerDismissed = true
        #expect(!withoutAccess.shouldShowAccessBanner(for: scan))
    }

    @Test("should show the startup disk's free space and ask the overview to focus search")
    func freeSpaceAndFind() {
        let model = makeModel()

        #expect(model.startupFreeSpace == 35)
        let before = model.searchFocusRequest
        model.focusSearch()
        #expect(model.searchFocusRequest == before + 1)
    }

    @Test("should forget the inspected item when another sidebar destination is chosen")
    func inspectedItemBelongsToItsView() {
        let model = makeModel()
        model.selection = .developer
        model.inspect(.project("/Users/dev/Work/app"))
        #expect(model.inspected == .project("/Users/dev/Work/app"))

        model.selection = .largeFiles

        #expect(model.inspected == nil)
    }

    @Test("should offer only installed editors, and open what each one needs")
    func projectEditors() {
        let model = makeModel()
        let folder = URL(filePath: "/Users/dev/Work/app", directoryHint: .isDirectory)
        let workspace = folder.appending(path: "App.xcworkspace", directoryHint: .isDirectory)
        let project = DeveloperProject(
            node: .directory(url: folder, modificationDate: nil, children: [
                .directory(url: workspace, modificationDate: nil, children: []),
            ]),
            idPath: [], evidence: .git, artifacts: [], lastTouched: nil
        )

        #expect(model.editors(for: project).isEmpty)
        apps.installed = [WorkspaceAppOpener.xcode, WorkspaceAppOpener.visualStudioCode]
        let targets = model.editors(for: project)
        #expect(targets.map(\.editor) == [.xcode, .visualStudioCode])

        model.open(targets[0])

        #expect(apps.opened.first?.folder == workspace)
        #expect(apps.opened.first?.bundleIdentifier == WorkspaceAppOpener.xcode)
    }

    @Test("should show the saved startup-disk scan at launch without anyone pressing Scan")
    func opensSavedScanAtLaunch() async throws {
        let root = URL(filePath: "/", directoryHint: .isDirectory)
        let saved = FileNode.directory(url: root, modificationDate: nil, children: [
            .directory(url: root.appending(path: "Users", directoryHint: .isDirectory), modificationDate: nil, children: [
                .file(url: root.appending(path: "Users/big.bin"), allocatedSize: 500, modificationDate: nil),
            ]),
        ])
        try scanCache.save(root: saved, scannedAt: Date(), locationPath: "/")

        let model = makeModel()
        let startup = try #require(model.scanModel(for: .startupDisk))
        await startup.cacheTask?.value

        #expect(startup.hasResult)
        #expect(startup.rows.contains { $0.name == "Users" })
    }
}

/// Records what the app would open instead of launching anything.
private final class RecordingApps: AppOpening {
    var installed: Set<String> = []
    var opened: [(folder: URL, bundleIdentifier: String)] = []

    func isInstalled(_ bundleIdentifier: String) -> Bool { installed.contains(bundleIdentifier) }
    func open(_ bundleIdentifier: String) {}
    func open(_ folder: URL, with bundleIdentifier: String) { opened.append((folder, bundleIdentifier)) }
}
