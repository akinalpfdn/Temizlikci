import Foundation
import Testing
@testable import Temizlikci

private struct StubVolumeInfo: VolumeInfoProviding {
    let name: String?
    func startupVolumeName() -> String? { name }
    func usage(ofVolumeContaining url: URL) throws -> VolumeUsage {
        VolumeUsage(totalCapacity: 0, availableCapacity: 0, availableForImportantUsage: nil)
    }
}

private struct StubFolderPicker: FolderPicking {
    let result: URL?
    func pickFolder() async -> URL? { result }
}

@MainActor
struct MainViewModelTests {
    private func makeModel(volumeName: String? = "Macintosh HD", pickedFolder: URL? = nil) -> MainViewModel {
        MainViewModel(volumeInfo: StubVolumeInfo(name: volumeName), folderPicker: StubFolderPicker(result: pickedFolder))
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

    @Test("should keep Highlight Reclaimable unavailable before any scan")
    func highlightNeedsResults() {
        let model = makeModel()

        #expect(model.canHighlightReclaimable == false)
    }
}
