import Foundation

/// Every user-facing string in the app. Keys and English values live in `Localizable.xcstrings`;
/// views consume these resources and never render string literals.
/// Nonisolated because resources are Sendable values that background services also need.
nonisolated enum L10n {
    enum App {
        static let name = LocalizedStringResource("app.name", defaultValue: "Temizlikci", comment: "The app's name. Keep it untranslated.")
    }

    enum Sidebar {
        static let locations = LocalizedStringResource("sidebar.section.locations", defaultValue: "Locations", comment: "Sidebar section listing places that can be scanned.")
        static let insights = LocalizedStringResource("sidebar.section.insights", defaultValue: "Insights", comment: "Sidebar section listing analysis views.")
        static let startupDiskFallback = LocalizedStringResource("sidebar.item.startupDisk", defaultValue: "Startup Disk", comment: "Sidebar item for the startup volume, used when the volume name can't be read.")
        static let home = LocalizedStringResource("sidebar.item.home", defaultValue: "Home", comment: "Sidebar item for the user's home folder.")
        static let chooseFolder = LocalizedStringResource("sidebar.action.chooseFolder", defaultValue: "Choose Folder…", comment: "Sidebar row that opens a panel to pick a folder to scan.")
        static let developer = LocalizedStringResource("sidebar.item.developer", defaultValue: "Developer", comment: "Sidebar item for reclaimable developer files.")
        static let largeFiles = LocalizedStringResource("sidebar.item.largeFiles", defaultValue: "Large Files", comment: "Sidebar item listing the largest files.")
        static let trash = LocalizedStringResource("sidebar.item.trash", defaultValue: "Trash", comment: "Sidebar item for items moved to the Trash.")
    }

    enum Toolbar {
        static let noScanSubtitle = LocalizedStringResource("toolbar.subtitle.noScan", defaultValue: "No scan yet", comment: "Window subtitle before any scan has run.")
        static let inspector = LocalizedStringResource("toolbar.inspector", defaultValue: "Inspector", comment: "Toolbar button that shows or hides the inspector.")
    }

    enum Menu {
        static let chooseFolder = LocalizedStringResource("menu.file.chooseFolder", defaultValue: "Choose Folder…", comment: "File menu command that opens a panel to pick a folder to scan.")
    }

    enum FolderPicker {
        static let prompt = LocalizedStringResource("folderPicker.prompt", defaultValue: "Choose", comment: "Default button of the folder selection panel.")
        static let message = LocalizedStringResource("folderPicker.message", defaultValue: "Choose a folder to measure.", comment: "Explanation shown in the folder selection panel.")
    }

    enum Overview {
        static let emptyTitle = LocalizedStringResource("overview.empty.title", defaultValue: "See What’s Using Your Disk", comment: "Title of the empty state before the first scan.")
        static let emptyMessage = LocalizedStringResource("overview.empty.message", defaultValue: "Temizlikci measures every folder and shows the result as rings you can open. Nothing is changed or deleted while it scans.", comment: "Explanation in the empty state before the first scan.")
    }

    enum Insights {
        static let notScannedTitle = LocalizedStringResource("insights.empty.title", defaultValue: "Nothing Scanned Yet", comment: "Title shown in insight views before any scan has run.")
        static let developerMessage = LocalizedStringResource("insights.empty.developer", defaultValue: "Scan a location to find build caches, simulators, and other developer files you can remove.", comment: "Empty state message of the Developer view.")
        static let largeFilesMessage = LocalizedStringResource("insights.empty.largeFiles", defaultValue: "Scan a location to list its largest files.", comment: "Empty state message of the Large Files view.")
        static let trashMessage = LocalizedStringResource("insights.empty.trash", defaultValue: "Items you move to the Trash from Temizlikci appear here until you empty it.", comment: "Empty state message of the Trash view.")
    }

    enum Inspector {
        static let noSelectionTitle = LocalizedStringResource("inspector.empty.title", defaultValue: "No Selection", comment: "Inspector title when nothing is selected.")
        static let noSelectionMessage = LocalizedStringResource("inspector.empty.message", defaultValue: "Select a folder in the chart or the list to see its details.", comment: "Inspector message when nothing is selected.")
    }

    enum ScanErrors {
        static func rootNotFound(_ name: String) -> LocalizedStringResource {
            LocalizedStringResource("scanError.rootNotFound", defaultValue: "“\(name)” can’t be found.", comment: "Scan error. The argument is the folder name.")
        }
        static func rootNotFolder(_ name: String) -> LocalizedStringResource {
            LocalizedStringResource("scanError.rootNotFolder", defaultValue: "“\(name)” isn’t a folder.", comment: "Scan error. The argument is the item name.")
        }
        static func rootUnreadable(_ name: String) -> LocalizedStringResource {
            LocalizedStringResource("scanError.rootUnreadable", defaultValue: "Temizlikci can’t read “\(name)”.", comment: "Scan error. The argument is the folder name.")
        }
        static let chooseAnotherFolder = LocalizedStringResource("scanError.suggestion.chooseAnother", defaultValue: "Choose another folder to scan.", comment: "Recovery suggestion for a missing scan location.")
        static let grantAccess = LocalizedStringResource("scanError.suggestion.grantAccess", defaultValue: "Give Temizlikci Full Disk Access in System Settings › Privacy & Security, then scan again.", comment: "Recovery suggestion when a folder can't be read.")
    }

    enum Scan {
        static func scanLocation(_ name: String) -> LocalizedStringResource {
            LocalizedStringResource("scan.action.scanLocation", defaultValue: "Scan \(name)", comment: "Button that starts scanning a location. The argument is its name.")
        }
        static let failedTitle = LocalizedStringResource("scan.failed.title", defaultValue: "The Scan Didn’t Finish", comment: "Title shown when a scan fails.")
        static let tryAgain = LocalizedStringResource("scan.failed.tryAgain", defaultValue: "Try Again", comment: "Button that restarts a failed scan.")
        static let chartHint = LocalizedStringResource("scan.chart.hint", defaultValue: "Click to select · Double-click to open · Click the center to go up", comment: "Hint under the chart explaining how to use it.")
        static func scannedFooter(date: String, duration: String) -> LocalizedStringResource {
            LocalizedStringResource("scan.footer.scanned", defaultValue: "Scanned \(date) in \(duration)", comment: "Footer after a scan. Arguments: when it finished, how long it took.")
        }
        static let sizesFooter = LocalizedStringResource("scan.footer.sizes", defaultValue: "Sizes are space on disk. APFS clones may be counted more than once.", comment: "Footer note explaining how sizes are measured.")
        static let noMatches = LocalizedStringResource("scan.search.noMatches", defaultValue: "No Results", comment: "Shown in the list when a search finds nothing.")
    }

    enum Chart {
        static func accessibilityLabel(_ name: String) -> LocalizedStringResource {
            LocalizedStringResource("chart.accessibility.label", defaultValue: "Disk usage of \(name)", comment: "Accessibility label of the sunburst chart. The argument is the folder name.")
        }
        static func summary(name: String, size: String, largest: String) -> LocalizedStringResource {
            LocalizedStringResource("chart.accessibility.summary", defaultValue: "\(name) uses \(size). The largest item is \(largest).", comment: "Audio Graphs summary. Arguments: folder, its size, largest item.")
        }
        static let itemsAxis = LocalizedStringResource("chart.axis.items", defaultValue: "Items", comment: "Audio Graphs axis listing the items in the folder.")
        static let sizeAxis = LocalizedStringResource("chart.axis.size", defaultValue: "Size", comment: "Audio Graphs axis for space on disk.")
        static let open = LocalizedStringResource("chart.action.open", defaultValue: "Open", comment: "Action that shows a folder's contents in the chart.")
        static func opened(_ name: String) -> LocalizedStringResource {
            LocalizedStringResource("chart.announcement.opened", defaultValue: "Opened \(name)", comment: "VoiceOver announcement after opening a folder.")
        }
        static func goUp(_ name: String) -> LocalizedStringResource {
            LocalizedStringResource("chart.center.goUp", defaultValue: "Go up to \(name)", comment: "Accessibility label of the chart center, which opens the enclosing folder.")
        }
        static func usedOfVolume(_ capacity: String) -> LocalizedStringResource {
            LocalizedStringResource("chart.center.usedOfVolume", defaultValue: "used of \(capacity)", comment: "Chart center caption under the used size of a disk. The argument is the disk capacity.")
        }
        static func shareOf(_ percent: String, _ name: String) -> LocalizedStringResource {
            LocalizedStringResource("chart.center.shareOf", defaultValue: "\(percent) of \(name)", comment: "Chart center caption. Arguments: a percentage, the containing folder.")
        }
        static let measuredSoFar = LocalizedStringResource("chart.center.measuredSoFar", defaultValue: "measured so far", comment: "Chart center caption while a scan is running.")
    }

    enum Nodes {
        static func smallerFiles(_ count: String) -> LocalizedStringResource {
            LocalizedStringResource("node.smallerFiles", defaultValue: "Smaller Files (\(count))", comment: "Several files under 10 MB, shown as one item. The argument is how many.")
        }
        static let mergedItems = LocalizedStringResource("node.merged", defaultValue: "Smaller Items", comment: "Items too small to draw in the chart, shown together.")
        static let unattributed = LocalizedStringResource("node.unattributed", defaultValue: "Other Used Space", comment: "Used disk space that no scanned folder accounts for.")
        static let pending = LocalizedStringResource("node.pending", defaultValue: "Not Scanned Yet", comment: "Space not measured yet while a scan runs.")
        static let needsAccess = LocalizedStringResource("node.needsAccess", defaultValue: "Needs Access", comment: "Badge on a folder that can't be read without Full Disk Access.")
        static let folderKind = LocalizedStringResource("node.kind.folder", defaultValue: "Folder", comment: "Inspector subtitle for a folder.")
        static let fileKind = LocalizedStringResource("node.kind.file", defaultValue: "File", comment: "Inspector subtitle for a file.")
        static let smallerFilesKind = LocalizedStringResource("node.kind.smallerFiles", defaultValue: "Files Under 10 MB", comment: "Inspector subtitle for grouped small files.")
        static let protectedKind = LocalizedStringResource("node.kind.protected", defaultValue: "Protected Folder", comment: "Inspector subtitle for a folder that needs Full Disk Access.")
        static let unattributedKind = LocalizedStringResource("node.kind.unattributed", defaultValue: "Unattributed Space", comment: "Inspector subtitle for space no folder accounts for.")
        static let pendingKind = LocalizedStringResource("node.kind.pending", defaultValue: "Still Scanning", comment: "Inspector subtitle for space not measured yet.")
    }

    enum Details {
        static let size = LocalizedStringResource("details.size", defaultValue: "Size", comment: "Inspector label for space on disk.")
        static let shareOfScan = LocalizedStringResource("details.shareOfScan", defaultValue: "Share of Scan", comment: "Inspector label for the share of everything scanned.")
        static let shareOfFolder = LocalizedStringResource("details.shareOfFolder", defaultValue: "Share of Folder", comment: "Inspector label for the share of the containing folder.")
        static let files = LocalizedStringResource("details.files", defaultValue: "Files", comment: "Inspector label for the number of files.")
        static let modified = LocalizedStringResource("details.modified", defaultValue: "Modified", comment: "Inspector label for the last modification date.")
        static let path = LocalizedStringResource("details.path", defaultValue: "Path", comment: "Inspector label for the item's location.")
        static let revealInFinder = LocalizedStringResource("details.revealInFinder", defaultValue: "Reveal in Finder", comment: "Button that shows the item in Finder.")
        static let quickLook = LocalizedStringResource("details.quickLook", defaultValue: "Quick Look", comment: "Button that previews the item.")
        static let unattributedExplanation = LocalizedStringResource("details.explain.unattributed", defaultValue: "Space macOS reports as used that no scanned folder accounts for: folders Temizlikci can’t read without Full Disk Access, items in the Trash, the system volume’s hidden parts, APFS snapshots, and purgeable files.", comment: "Inspector explanation for unattributed space.")
        static let inaccessibleExplanation = LocalizedStringResource("details.explain.inaccessible", defaultValue: "Temizlikci can’t read this folder without Full Disk Access, so its size isn’t included.", comment: "Inspector explanation for a protected folder.")
        static let smallerFilesExplanation = LocalizedStringResource("details.explain.smallerFiles", defaultValue: "Files under 10 MB in this folder, added together.", comment: "Inspector explanation for grouped small files.")
        static let pendingExplanation = LocalizedStringResource("details.explain.pending", defaultValue: "This part of the disk hasn’t been measured yet.", comment: "Inspector explanation for space not scanned yet.")
    }

    enum Table {
        static let name = LocalizedStringResource("table.column.name", defaultValue: "Name", comment: "List column with item names.")
        static let size = LocalizedStringResource("table.column.size", defaultValue: "Size", comment: "List column with space on disk.")
        static let share = LocalizedStringResource("table.column.share", defaultValue: "Share", comment: "List column with each item's share of the folder.")
    }

    enum Navigation {
        static let back = LocalizedStringResource("navigation.back", defaultValue: "Back", comment: "Toolbar and menu command that returns to the previous folder.")
        static let forward = LocalizedStringResource("navigation.forward", defaultValue: "Forward", comment: "Toolbar and menu command that goes forward in folder history.")
        static let enclosingFolder = LocalizedStringResource("navigation.enclosingFolder", defaultValue: "Enclosing Folder", comment: "Menu command that opens the folder containing the current one.")
        static let goMenu = LocalizedStringResource("navigation.menu.go", defaultValue: "Go", comment: "Title of the menu with navigation commands.")
        static let rescan = LocalizedStringResource("navigation.rescan", defaultValue: "Rescan", comment: "Command that scans the current location again.")
        static let stop = LocalizedStringResource("navigation.stop", defaultValue: "Stop Scanning", comment: "Command that cancels the running scan.")
        static let searchPrompt = LocalizedStringResource("navigation.searchPrompt", defaultValue: "Search This Folder", comment: "Placeholder of the search field.")
        static func scanningSubtitle(_ size: String) -> LocalizedStringResource {
            LocalizedStringResource("navigation.subtitle.scanning", defaultValue: "Scanning… \(size) so far", comment: "Window subtitle during a scan. The argument is the size measured so far.")
        }
        static func volumeSubtitle(used: String, available: String) -> LocalizedStringResource {
            LocalizedStringResource("navigation.subtitle.volume", defaultValue: "\(used) used · \(available) available", comment: "Window subtitle for a scanned disk.")
        }
    }

    enum Trash {
        static let moveToTrash = LocalizedStringResource("trash.action.move", defaultValue: "Move to Trash", comment: "Command and button that moves the selected item to the Trash.")
        static let putBack = LocalizedStringResource("trash.action.putBack", defaultValue: "Put Back", comment: "Button that returns an item from the Trash to where it was.")
        static let undo = LocalizedStringResource("trash.action.undo", defaultValue: "Undo", comment: "Button in the confirmation that returns the item from the Trash.")
        static let showInFinder = LocalizedStringResource("trash.action.showInFinder", defaultValue: "Show Trash in Finder", comment: "Button that opens the Trash in Finder.")
        static func moved(name: String, size: String) -> LocalizedStringResource {
            LocalizedStringResource("trash.toast.moved", defaultValue: "Moved “\(name)” to the Trash. Its \(size) is freed when you empty the Trash.", comment: "Confirmation after moving an item to the Trash. Arguments: item name, its size.")
        }
        static func total(_ size: String) -> LocalizedStringResource {
            LocalizedStringResource("trash.summary.total", defaultValue: "\(size) moved to the Trash from Temizlikci", comment: "Header of the Trash view. The argument is a size.")
        }
        static let emptyNote = LocalizedStringResource("trash.summary.note", defaultValue: "This space is freed when you empty the Trash in Finder.", comment: "Explanation in the Trash view.")
        static func movedFrom(_ folder: String) -> LocalizedStringResource {
            LocalizedStringResource("trash.row.from", defaultValue: "From \(folder)", comment: "Where a trashed item came from. The argument is a folder path.")
        }
        static func noPermission(_ name: String) -> LocalizedStringResource {
            LocalizedStringResource("trash.error.noPermission", defaultValue: "You don’t have permission to move “\(name)” to the Trash.", comment: "Error when the item can't be moved to the Trash.")
        }
        static func missing(_ name: String) -> LocalizedStringResource {
            LocalizedStringResource("trash.error.missing", defaultValue: "“\(name)” no longer exists.", comment: "Error when the item was removed since the scan.")
        }
        static func failed(_ name: String) -> LocalizedStringResource {
            LocalizedStringResource("trash.error.failed", defaultValue: "“\(name)” couldn’t be moved to the Trash.", comment: "Generic error when moving an item to the Trash fails.")
        }
        static func putBackFailed(_ name: String) -> LocalizedStringResource {
            LocalizedStringResource("trash.error.putBackFailed", defaultValue: "“\(name)” couldn’t be put back.", comment: "Error when returning an item from the Trash fails.")
        }
        static let rescanSuggestion = LocalizedStringResource("trash.error.suggestion.rescan", defaultValue: "Rescan to see the folder as it is now.", comment: "Recovery suggestion after a Trash error.")
        static let putBackSuggestion = LocalizedStringResource("trash.error.suggestion.putBack", defaultValue: "Open the Trash in Finder and drag the item back.", comment: "Recovery suggestion when putting back fails.")
        static let permissionSuggestion = LocalizedStringResource("trash.error.suggestion.permission", defaultValue: "Use Finder to move it; it can ask for an administrator password.", comment: "Recovery suggestion when permission is missing.")
    }

    enum Access {
        static let bannerTitle = LocalizedStringResource("access.banner.title", defaultValue: "Some Folders Need Full Disk Access", comment: "Title of the banner shown when protected folders were skipped.")
        static func bannerMessage(_ count: String) -> LocalizedStringResource {
            LocalizedStringResource("access.banner.message", defaultValue: "Temizlikci didn’t open \(count) protected folders, such as Documents and Mail, so their space is counted in Other Used Space.", comment: "Banner message. The argument is how many folders were skipped.")
        }
        static let relaunchHint = LocalizedStringResource("access.banner.relaunch", defaultValue: "After turning on access for Temizlikci, quit and reopen it, then scan again.", comment: "Hint in the access banner.")
        static let openSettings = LocalizedStringResource("access.banner.openSettings", defaultValue: "Open Privacy Settings…", comment: "Button that opens Full Disk Access in System Settings.")
        static let notNow = LocalizedStringResource("access.banner.notNow", defaultValue: "Not Now", comment: "Button that hides the access banner.")
    }

    enum Alerts {
        static let ok = LocalizedStringResource("alert.ok", defaultValue: "OK", comment: "Button that dismisses an informational alert.")
        static let cancel = LocalizedStringResource("alert.cancel", defaultValue: "Cancel", comment: "Button that cancels an alert's action.")
    }

    enum Cleanup {
        static let safe = LocalizedStringResource("cleanup.safety.safe", defaultValue: "Safe to Remove", comment: "Label for items that regenerate on their own.")
        static let tool = LocalizedStringResource("cleanup.safety.tool", defaultValue: "Remove with Tool", comment: "Label for items that must be removed with their own tool.")
        static let keep = LocalizedStringResource("cleanup.safety.keep", defaultValue: "Keep", comment: "Label for items that hold personal data and shouldn't be deleted here.")
        static let highlight = LocalizedStringResource("cleanup.highlight", defaultValue: "Highlight Reclaimable", comment: "Toolbar toggle and menu item that colors the chart by cleanup safety.")
        static let reasonDerivedData = LocalizedStringResource("cleanup.reason.derivedData", defaultValue: "Build products and indexes. Xcode rebuilds them on the next build.", comment: "Why an item has its cleanup label.")
        static let reasonDeviceSupport = LocalizedStringResource("cleanup.reason.deviceSupport", defaultValue: "Debug symbols copied from your devices. Xcode copies them again the next time a device connects.", comment: "Why an item has its cleanup label.")
        static let reasonPreviews = LocalizedStringResource("cleanup.reason.previews", defaultValue: "SwiftUI preview builds. Xcode recreates them when you open a preview.", comment: "Why an item has its cleanup label.")
        static let reasonDocumentationCache = LocalizedStringResource("cleanup.reason.documentationCache", defaultValue: "Downloaded documentation. Xcode downloads it again when needed.", comment: "Why an item has its cleanup label.")
        static let reasonArchives = LocalizedStringResource("cleanup.reason.archives", defaultValue: "Builds you archived for distribution. Their debug symbols are needed to read crash reports, so keep the ones you still support.", comment: "Why an item has its cleanup label.")
        static let reasonSimulatorDevices = LocalizedStringResource("cleanup.reason.simulatorDevices", defaultValue: "Simulator devices and their data. Remove them with Xcode’s simulator tool so Xcode’s device list stays consistent.", comment: "Why an item has its cleanup label.")
        static let reasonSimulatorRuntimes = LocalizedStringResource("cleanup.reason.simulatorRuntimes", defaultValue: "Simulator runtimes. Remove them with Xcode’s simulator tool or in Xcode › Settings › Components.", comment: "Why an item has its cleanup label.")
        static let reasonGradleCaches = LocalizedStringResource("cleanup.reason.gradleCaches", defaultValue: "Gradle’s download and build caches. Gradle fetches them again on the next build.", comment: "Why an item has its cleanup label.")
        static let reasonAndroidEmulators = LocalizedStringResource("cleanup.reason.androidEmulators", defaultValue: "Android emulators. Remove them in Android Studio’s Device Manager.", comment: "Why an item has its cleanup label.")
        static let reasonAndroidSystemImages = LocalizedStringResource("cleanup.reason.androidSystemImages", defaultValue: "Android system images. Remove them in Android Studio’s SDK Manager.", comment: "Why an item has its cleanup label.")
        static let reasonFlutterBuild = LocalizedStringResource("cleanup.reason.flutterBuild", defaultValue: "Flutter build output. Building the project recreates it.", comment: "Why an item has its cleanup label.")
        static let reasonDartTool = LocalizedStringResource("cleanup.reason.dartTool", defaultValue: "Dart tooling state. Running flutter pub get recreates it.", comment: "Why an item has its cleanup label.")
        static let reasonPubCache = LocalizedStringResource("cleanup.reason.pubCache", defaultValue: "Downloaded Dart and Flutter packages. Running flutter pub get downloads them again.", comment: "Why an item has its cleanup label.")
        static let reasonNodeModules = LocalizedStringResource("cleanup.reason.nodeModules", defaultValue: "Installed npm packages. Running npm install restores them.", comment: "Why an item has its cleanup label.")
        static let reasonNextBuild = LocalizedStringResource("cleanup.reason.nextBuild", defaultValue: "Next.js build cache. The next build recreates it.", comment: "Why an item has its cleanup label.")
        static let reasonNpmCache = LocalizedStringResource("cleanup.reason.npmCache", defaultValue: "npm’s download cache. npm refills it as you install packages.", comment: "Why an item has its cleanup label.")
        static let reasonGoBuild = LocalizedStringResource("cleanup.reason.goBuild", defaultValue: "Go’s build cache. Go rebuilds it as needed.", comment: "Why an item has its cleanup label.")
        static let reasonHomebrewCache = LocalizedStringResource("cleanup.reason.homebrewCache", defaultValue: "Homebrew downloads. Homebrew fetches them again when needed.", comment: "Why an item has its cleanup label.")
        static let reasonAppData = LocalizedStringResource("cleanup.reason.appData", defaultValue: "Data that belongs to other apps, such as messages and documents. Clear it inside each app.", comment: "Why an item has its cleanup label.")
        static let ecosystemXcode = LocalizedStringResource("cleanup.ecosystem.xcode", defaultValue: "Xcode", comment: "Group title in the Developer view.")
        static let ecosystemSimulators = LocalizedStringResource("cleanup.ecosystem.simulators", defaultValue: "Simulators", comment: "Group title in the Developer view.")
        static let ecosystemAndroid = LocalizedStringResource("cleanup.ecosystem.android", defaultValue: "Android", comment: "Group title in the Developer view.")
        static let ecosystemFlutter = LocalizedStringResource("cleanup.ecosystem.flutter", defaultValue: "Flutter & Dart", comment: "Group title in the Developer view.")
        static let ecosystemNode = LocalizedStringResource("cleanup.ecosystem.node", defaultValue: "Node.js", comment: "Group title in the Developer view.")
        static let ecosystemGo = LocalizedStringResource("cleanup.ecosystem.go", defaultValue: "Go", comment: "Group title in the Developer view.")
        static let ecosystemHomebrew = LocalizedStringResource("cleanup.ecosystem.homebrew", defaultValue: "Homebrew", comment: "Group title in the Developer view.")
        static let ecosystemAppData = LocalizedStringResource("cleanup.ecosystem.appData", defaultValue: "App Data", comment: "Group title in the Developer view.")
        static func reclaimable(_ size: String) -> LocalizedStringResource {
            LocalizedStringResource("cleanup.group.reclaimable", defaultValue: "\(size) reclaimable", comment: "Size that can be removed in a group.")
        }
        static func sourceScan(_ name: String) -> LocalizedStringResource {
            LocalizedStringResource("cleanup.developer.source", defaultValue: "From the scan of \(name)", comment: "Which scan the Developer view uses.")
        }
        static let scanFirst = LocalizedStringResource("cleanup.developer.scanFirst", defaultValue: "Scan Home or your startup disk to find developer files.", comment: "Developer view empty state.")
        static let scanHome = LocalizedStringResource("cleanup.developer.scanHome", defaultValue: "Scan Home", comment: "Button in the Developer view empty state.")
        static let summaryTitle = LocalizedStringResource("cleanup.developer.summary", defaultValue: "Developer Files", comment: "Title of the Developer view summary chart.")
        static let openAndroidStudio = LocalizedStringResource("cleanup.action.openAndroidStudio", defaultValue: "Open Android Studio", comment: "Button that opens Android Studio to manage emulators or SDK packages.")
        static let manageSimulators = LocalizedStringResource("cleanup.action.manageSimulators", defaultValue: "Manage Simulators", comment: "Button that jumps to the simulator section of the Developer view.")
        static let noActions = LocalizedStringResource("cleanup.action.none", defaultValue: "Keep", comment: "Shown instead of an action for items to keep.")
    }

    enum Simulators {
        static let unavailableTitle = LocalizedStringResource("simulators.unavailable.title", defaultValue: "Unavailable Simulators", comment: "Row title for simulator devices whose runtime is gone.")
        static func unavailableDetail(_ count: String, size: String) -> LocalizedStringResource {
            LocalizedStringResource("simulators.unavailable.detail", defaultValue: "\(count) devices · \(size)", comment: "Count and size of unavailable simulators.")
        }
        static let deleteUnavailable = LocalizedStringResource("simulators.action.deleteUnavailable", defaultValue: "Delete Unavailable Simulators…", comment: "Button that removes simulators whose runtime is gone.")
        static let deleteUnavailableTitle = LocalizedStringResource("simulators.alert.deleteUnavailable.title", defaultValue: "Delete unavailable simulators?", comment: "Alert title before deleting unavailable simulators.")
        static func deleteUnavailableMessage(_ count: String, size: String) -> LocalizedStringResource {
            LocalizedStringResource("simulators.alert.deleteUnavailable.message", defaultValue: "This removes \(count) simulators whose runtime is no longer installed, and their data (\(size)). This can’t be undone.", comment: "Alert message.")
        }
        static let deleteUnavailableConfirm = LocalizedStringResource("simulators.alert.deleteUnavailable.confirm", defaultValue: "Delete Simulators", comment: "Alert button that deletes unavailable simulators.")
        static let runtimesTitle = LocalizedStringResource("simulators.runtimes.title", defaultValue: "Simulator Runtimes", comment: "Section title listing installed simulator runtimes.")
        static func runtimeName(_ platform: String, version: String) -> LocalizedStringResource {
            LocalizedStringResource("simulators.runtime.name", defaultValue: "\(platform) \(version)", comment: "Runtime name. Arguments: platform (iOS, watchOS…), version.")
        }
        static func lastUsed(_ date: String) -> LocalizedStringResource {
            LocalizedStringResource("simulators.runtime.lastUsed", defaultValue: "Last used \(date)", comment: "When a runtime was last used.")
        }
        static let deleteRuntime = LocalizedStringResource("simulators.action.deleteRuntime", defaultValue: "Delete Runtime…", comment: "Button that deletes a simulator runtime.")
        static func deleteRuntimeTitle(_ name: String) -> LocalizedStringResource {
            LocalizedStringResource("simulators.alert.deleteRuntime.title", defaultValue: "Delete the \(name) simulator runtime?", comment: "Alert title before deleting a runtime.")
        }
        static func deleteRuntimeMessage(_ size: String) -> LocalizedStringResource {
            LocalizedStringResource("simulators.alert.deleteRuntime.message", defaultValue: "This frees \(size). Simulators that use it stop working until you download it again in Xcode › Settings › Components. This can’t be undone.", comment: "Alert message.")
        }
        static let deleteRuntimeConfirm = LocalizedStringResource("simulators.alert.deleteRuntime.confirm", defaultValue: "Delete Runtime", comment: "Alert button that deletes a runtime.")
        static let working = LocalizedStringResource("simulators.working", defaultValue: "Working…", comment: "Shown while the simulator tool runs.")
        static let rescanHint = LocalizedStringResource("simulators.rescanHint", defaultValue: "Rescan to update sizes in the chart.", comment: "Shown after a simulator tool action.")
        static let toolUnavailable = LocalizedStringResource("simulators.error.toolUnavailable", defaultValue: "Xcode’s simulator tool isn’t available.", comment: "Error when simctl can't run.")
        static let toolUnavailableSuggestion = LocalizedStringResource("simulators.error.toolUnavailable.suggestion", defaultValue: "Install Xcode and open it once to finish setup, then try again.", comment: "Recovery suggestion.")
        static let toolFailed = LocalizedStringResource("simulators.error.failed", defaultValue: "The simulator tool reported an error.", comment: "Error when simctl fails.")
    }
}
