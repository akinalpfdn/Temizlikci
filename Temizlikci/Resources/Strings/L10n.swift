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
        static let whatGrew = LocalizedStringResource("sidebar.item.whatGrew", defaultValue: "What Grew", comment: "Sidebar item that compares the latest scan with the previous one.")
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
        static func savedFooter(_ age: String) -> LocalizedStringResource {
            LocalizedStringResource("scan.footer.saved", defaultValue: "From the scan \(age)", comment: "Footer when the tree comes from a saved scan. The argument is a relative time such as \"3 days ago\".")
        }
        static let measuring = LocalizedStringResource("scan.measuring", defaultValue: "Still measuring", comment: "Spoken for a folder whose size is still growing during a scan.")
        static let refreshing = LocalizedStringResource("scan.refreshing", defaultValue: "Refreshing in the background…", comment: "Shown while a new scan replaces a saved one.")
        static let refreshNow = LocalizedStringResource("scan.refreshNow", defaultValue: "Rescan", comment: "Button that starts a fresh scan of a saved result.")
        static let sizesFooter = LocalizedStringResource("scan.footer.sizes", defaultValue: "Sizes are space on disk. APFS clones may be counted more than once.", comment: "Footer note explaining how sizes are measured.")
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
        static let pendingExplanation = LocalizedStringResource("details.explain.pending", defaultValue: "Used space the scan hasn’t reached yet. It shrinks as folders are measured and is gone when the scan finishes; anything still unexplained then becomes Other Used Space.", comment: "Inspector explanation for space not scanned yet.")
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
        static let highlightUnavailable = LocalizedStringResource("cleanup.highlight.unavailable", defaultValue: "Nothing here is a developer cache or build folder, so there's nothing to highlight.", comment: "Help for the highlight button when the location has no developer artifacts.")
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
        static let reasonSwiftPMCache = LocalizedStringResource("cleanup.reason.swiftpmCache", defaultValue: "Swift Package Manager’s download cache. Building a package fetches what it needs again.", comment: "Why an item has its cleanup label.")
        static let reasonSwiftPMBuild = LocalizedStringResource("cleanup.reason.swiftpmBuild", defaultValue: "Swift package build output. The next build recreates it.", comment: "Why an item has its cleanup label.")
        static let reasonXcodeCache = LocalizedStringResource("cleanup.reason.xcodeCache", defaultValue: "Xcode’s own cache. Xcode refills it as you work.", comment: "Why an item has its cleanup label.")
        static let reasonCocoaPodsCache = LocalizedStringResource("cleanup.reason.cocoapodsCache", defaultValue: "Downloaded pods. Running pod install downloads them again.", comment: "Why an item has its cleanup label.")
        static let reasonPods = LocalizedStringResource("cleanup.reason.pods", defaultValue: "Dependencies installed for this project. Running pod install restores them.", comment: "Why an item has its cleanup label.")
        static let reasonCargoRegistry = LocalizedStringResource("cleanup.reason.cargoRegistry", defaultValue: "Downloaded crates. Cargo restores anything a build needs, by re-extracting or downloading it again.", comment: "Why an item has its cleanup label.")
        static let reasonCargoTarget = LocalizedStringResource("cleanup.reason.cargoTarget", defaultValue: "Rust build output. Running cargo build recreates it.", comment: "Why an item has its cleanup label.")
        static let reasonRustup = LocalizedStringResource("cleanup.reason.rustup", defaultValue: "Installed Rust toolchains, not a cache. Remove ones you don’t need with rustup toolchain uninstall.", comment: "Why an item has its cleanup label.")
        static let reasonPipCache = LocalizedStringResource("cleanup.reason.pipCache", defaultValue: "pip’s download cache. Clear it with pip cache purge, or remove it here — pip downloads packages again as needed.", comment: "Why an item has its cleanup label.")
        static let reasonUvCache = LocalizedStringResource("cleanup.reason.uvCache", defaultValue: "uv’s cache. uv states it is never safe to delete by hand; run uv cache clean instead.", comment: "Why an item has its cleanup label.")
        static let reasonNuGet = LocalizedStringResource("cleanup.reason.nuget", defaultValue: "Extracted NuGet packages that projects reference directly. Clear them with dotnet nuget locals global-packages --clear, then restore your projects.", comment: "Why an item has its cleanup label.")
        static let reasonMaven = LocalizedStringResource("cleanup.reason.maven", defaultValue: "Downloaded Java dependencies. Maven downloads them again on the next build.", comment: "Why an item has its cleanup label.")
        static let reasonGradleBuild = LocalizedStringResource("cleanup.reason.gradleBuild", defaultValue: "Gradle build output for this project. The next build recreates it.", comment: "Why an item has its cleanup label.")
        static let reasonGoModCache = LocalizedStringResource("cleanup.reason.goModCache", defaultValue: "Downloaded Go modules, stored read-only. Remove them with go clean -modcache.", comment: "Why an item has its cleanup label.")
        static let reasonDocker = LocalizedStringResource("cleanup.reason.docker", defaultValue: "Docker’s disk image, holding every image, container and volume. Reclaim space with docker system prune; deleting the file loses all of it.", comment: "Why an item has its cleanup label.")
        static let reasonJetBrains = LocalizedStringResource("cleanup.reason.jetbrains", defaultValue: "Caches and indexes of JetBrains IDEs. They are rebuilt when you open a project.", comment: "Why an item has its cleanup label.")
        static let reasonYarnCache = LocalizedStringResource("cleanup.reason.yarnCache", defaultValue: "Yarn’s package cache. Yarn downloads packages again as needed.", comment: "Why an item has its cleanup label.")
        static let reasonPnpmStore = LocalizedStringResource("cleanup.reason.pnpmStore", defaultValue: "pnpm’s package store, which every node_modules folder links into. Use pnpm store prune, which only removes what nothing references.", comment: "Why an item has its cleanup label.")
        static let reasonBunCache = LocalizedStringResource("cleanup.reason.bunCache", defaultValue: "Bun’s install cache. Bun downloads packages again as needed.", comment: "Why an item has its cleanup label.")
        static let reasonElectronCache = LocalizedStringResource("cleanup.reason.electronCache", defaultValue: "Downloaded Electron binaries. They are fetched again on the next install.", comment: "Why an item has its cleanup label.")
        static let reasonNodeGyp = LocalizedStringResource("cleanup.reason.nodeGyp", defaultValue: "Node headers kept for building native modules. They are downloaded again when needed.", comment: "Why an item has its cleanup label.")
        static let reasonPlaywright = LocalizedStringResource("cleanup.reason.playwright", defaultValue: "Browsers downloaded for Playwright tests. Running playwright install downloads them again.", comment: "Why an item has its cleanup label.")
        static let reasonUnityLibrary = LocalizedStringResource("cleanup.reason.unityLibrary", defaultValue: "Unity’s imported asset cache for this project. Unity rebuilds it when you open the project, which can take a while.", comment: "Why an item has its cleanup label.")
        static let ecosystemSwift = LocalizedStringResource("cleanup.ecosystem.swift", defaultValue: "Swift & CocoaPods", comment: "Group title in the Developer view.")
        static let ecosystemRust = LocalizedStringResource("cleanup.ecosystem.rust", defaultValue: "Rust", comment: "Group title in the Developer view.")
        static let ecosystemPython = LocalizedStringResource("cleanup.ecosystem.python", defaultValue: "Python", comment: "Group title in the Developer view.")
        static let ecosystemDotNet = LocalizedStringResource("cleanup.ecosystem.dotnet", defaultValue: ".NET", comment: "Group title in the Developer view.")
        static let ecosystemJava = LocalizedStringResource("cleanup.ecosystem.java", defaultValue: "Java & Gradle", comment: "Group title in the Developer view.")
        static let ecosystemDocker = LocalizedStringResource("cleanup.ecosystem.docker", defaultValue: "Docker", comment: "Group title in the Developer view.")
        static let ecosystemEditors = LocalizedStringResource("cleanup.ecosystem.editors", defaultValue: "Editors", comment: "Group title in the Developer view.")
        static let ecosystemUnity = LocalizedStringResource("cleanup.ecosystem.unity", defaultValue: "Unity", comment: "Group title in the Developer view.")
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

    enum Intro {
        static let title = LocalizedStringResource("intro.title", defaultValue: "How to Read the Chart", comment: "Title of the chart introduction.")
        static let rings = LocalizedStringResource("intro.tip.rings", defaultValue: "Each ring shows what’s inside the ring before it. The innermost ring is the folder you’re looking at.", comment: "Intro tip about rings.")
        static let size = LocalizedStringResource("intro.tip.size", defaultValue: "The wider a segment, the more space it uses. The list beside the chart shows the same items with exact sizes.", comment: "Intro tip about segment size.")
        static let interaction = LocalizedStringResource("intro.tip.interaction", defaultValue: "Click a segment to see its details. Double-click a folder to open it, and click the center to go back up.", comment: "Intro tip about interaction.")
        static let highlight = LocalizedStringResource("intro.tip.highlight", defaultValue: "Turn on Highlight Reclaimable to see which developer files are safe to remove.", comment: "Intro tip about highlighting.")
        static let tryIt = LocalizedStringResource("intro.tryIt", defaultValue: "Try it on this example.", comment: "Invitation to interact with the sample chart.")
        static let done = LocalizedStringResource("intro.done", defaultValue: "Get Started", comment: "Button that closes the introduction.")
        static let menuItem = LocalizedStringResource("intro.menuItem", defaultValue: "How to Read the Chart", comment: "Help menu item that shows the introduction again.")
        static let sampleName = LocalizedStringResource("intro.sample.name", defaultValue: "Example Folder", comment: "Name of the sample folder in the introduction.")
        static let samplePhotos = LocalizedStringResource("intro.sample.photos", defaultValue: "Photos", comment: "Folder name in the introduction's example chart.")
        static let sampleProjects = LocalizedStringResource("intro.sample.projects", defaultValue: "Projects", comment: "Folder name in the introduction's example chart.")
        static let sampleMusic = LocalizedStringResource("intro.sample.music", defaultValue: "Music", comment: "Folder name in the introduction's example chart.")
        static let sampleApps = LocalizedStringResource("intro.sample.apps", defaultValue: "Apps", comment: "Folder name in the introduction's example chart.")
        static let sampleCaches = LocalizedStringResource("intro.sample.caches", defaultValue: "Caches", comment: "Folder name in the introduction's example chart.")
        static let sampleVacation = LocalizedStringResource("intro.sample.vacation", defaultValue: "Vacation", comment: "Folder name in the introduction's example chart.")
        static let sampleFamily = LocalizedStringResource("intro.sample.family", defaultValue: "Family", comment: "Folder name in the introduction's example chart.")
        static let sampleWebsite = LocalizedStringResource("intro.sample.website", defaultValue: "Website", comment: "Folder name in the introduction's example chart.")
        static let sampleGame = LocalizedStringResource("intro.sample.game", defaultValue: "Game", comment: "Folder name in the introduction's example chart.")
    }

    enum Search {
        static let find = LocalizedStringResource("search.find", defaultValue: "Find", comment: "Edit menu command that moves focus to the search field.")
    }

    enum Volume {
        static func free(_ size: String) -> LocalizedStringResource {
            LocalizedStringResource("volume.free", defaultValue: "\(size) free", comment: "Sidebar badge with a disk's free space.")
        }
    }

    enum Growth {
        static let column = LocalizedStringResource("growth.column", defaultValue: "Change", comment: "List column with the change in size since the previous scan.")
        static func grew(_ size: String) -> LocalizedStringResource {
            LocalizedStringResource("growth.accessibility.grew", defaultValue: "Grew by \(size)", comment: "Accessibility description of growth.")
        }
        static func shrank(_ size: String) -> LocalizedStringResource {
            LocalizedStringResource("growth.accessibility.shrank", defaultValue: "Shrank by \(size)", comment: "Accessibility description of shrinking.")
        }
        static let appearedHelp = LocalizedStringResource("growth.appeared.help", defaultValue: "New, or under 100 MB in the previous scan.", comment: "Explains an item that wasn't recorded in the previous scan.")
        static let removed = LocalizedStringResource("growth.removed", defaultValue: "Removed", comment: "Label for an item that no longer exists.")
        static let emptyTitle = LocalizedStringResource("growth.empty.title", defaultValue: "Nothing to Compare Yet", comment: "Title when there's only one scan.")
        static let emptyMessage = LocalizedStringResource("growth.empty.message", defaultValue: "Temizlikci keeps a small summary of every scan on this Mac. Scan the same location again later to see what grew.", comment: "Explanation when there's only one scan.")
        static let noChangesTitle = LocalizedStringResource("growth.noChanges.title", defaultValue: "No Big Changes", comment: "Title when nothing changed by more than 10 MB.")
        static func noChangesMessage(_ date: String) -> LocalizedStringResource {
            LocalizedStringResource("growth.noChanges.message", defaultValue: "Nothing changed by more than 10 MB since \(date).", comment: "Message when nothing changed much.")
        }
        static func header(_ name: String, date: String) -> LocalizedStringResource {
            LocalizedStringResource("growth.header", defaultValue: "\(name) since \(date)", comment: "Title of the What Grew view. Arguments: location, date of the previous scan.")
        }
        static let grewSection = LocalizedStringResource("growth.section.grew", defaultValue: "Grew", comment: "Heading over the items that got bigger.")
        static let shrankSection = LocalizedStringResource("growth.section.shrank", defaultValue: "Shrank", comment: "Heading over the items that got smaller.")
        static func net(_ size: String) -> LocalizedStringResource {
            LocalizedStringResource("growth.net", defaultValue: "Net change \(size)", comment: "Sum of all changes since the previous scan.")
        }
        static func fromSavedScans(_ date: String) -> LocalizedStringResource {
            LocalizedStringResource("growth.fromSavedScans", defaultValue: "From the two saved scans, the most recent on \(date). Scan again to compare with what is on disk now.", comment: "Note shown when the comparison comes from saved scans instead of a scan in this session.")
        }
        static let showInChart = LocalizedStringResource("growth.showInChart", defaultValue: "Show in Chart", comment: "Button that opens a changed folder in the chart.")
        static func previous(_ size: String) -> LocalizedStringResource {
            LocalizedStringResource("growth.previous", defaultValue: "was \(size)", comment: "Previous size of a changed item.")
        }
        static func inspectorChange(_ date: String) -> LocalizedStringResource {
            LocalizedStringResource("growth.inspector.label", defaultValue: "Change since \(date)", comment: "Inspector label for the size change.")
        }
    }

    enum LargeFiles {
        static func title(_ name: String) -> LocalizedStringResource {
            LocalizedStringResource("largeFiles.title", defaultValue: "Largest Files in \(name)", comment: "Title of the Large Files view. The argument is the scanned location.")
        }
        static let modified = LocalizedStringResource("largeFiles.column.modified", defaultValue: "Modified", comment: "Large Files column with the modification date.")
        static let hint = LocalizedStringResource("largeFiles.hint", defaultValue: "Double-click a file to show it in the chart. Control-click for more actions.", comment: "Hint under the Large Files title.")
        static let noneTitle = LocalizedStringResource("largeFiles.none.title", defaultValue: "No Files Over 10 MB", comment: "Title when a scan found no large files.")
        static let noneMessage = LocalizedStringResource("largeFiles.none.message", defaultValue: "Temizlikci lists files of 10 MB or more here after a scan.", comment: "Message when a scan found no large files.")
    }

    enum Projects {
        static let title = LocalizedStringResource("projects.title", defaultValue: "Stale Projects", comment: "Section listing projects nobody has worked on for a while.")
        static let periodLabel = LocalizedStringResource("projects.period.label", defaultValue: "Untouched for", comment: "Label of the control that picks how old a project must be.")
        static let periodMonth = LocalizedStringResource("projects.period.month", defaultValue: "30 days", comment: "Staleness period.")
        static let periodQuarter = LocalizedStringResource("projects.period.quarter", defaultValue: "90 days", comment: "Staleness period.")
        static let periodHalfYear = LocalizedStringResource("projects.period.halfYear", defaultValue: "6 months", comment: "Staleness period.")
        static let periodYear = LocalizedStringResource("projects.period.year", defaultValue: "1 year", comment: "Staleness period.")
        static let empty = LocalizedStringResource("projects.empty", defaultValue: "No project has been left alone that long.", comment: "Shown when no project is stale.")
        static func lastTouched(_ date: String) -> LocalizedStringResource {
            LocalizedStringResource("projects.lastTouched", defaultValue: "Last worked on \(date)", comment: "When someone last changed a project's own files.")
        }
        static func total(_ size: String) -> LocalizedStringResource {
            LocalizedStringResource("projects.total", defaultValue: "\(size) in total", comment: "Size of the whole project folder.")
        }
        static let onlyBuildOutput = LocalizedStringResource("projects.onlyBuildOutput", defaultValue: "Temizlikci only ever moves this project’s build output to the Trash, never the project itself.", comment: "Reassurance in the project inspector.")
        static let lastWorkedOn = LocalizedStringResource("projects.lastWorkedOn", defaultValue: "Last Worked On", comment: "Inspector label for when a project was last changed.")
        static let buildOutput = LocalizedStringResource("projects.buildOutput", defaultValue: "Build output", comment: "Header over a project's build artifacts.")
        static let noArtifacts = LocalizedStringResource("projects.noArtifacts", defaultValue: "No build output to remove.", comment: "Shown for a stale project that holds no artifacts.")
        static let evidenceGit = LocalizedStringResource("projects.evidence.git", defaultValue: "Git repository", comment: "How a folder was identified as a project.")
        static let evidenceXcode = LocalizedStringResource("projects.evidence.xcode", defaultValue: "Xcode project", comment: "How a folder was identified as a project.")
        static let evidenceSwiftPackage = LocalizedStringResource("projects.evidence.swiftPackage", defaultValue: "Swift package", comment: "How a folder was identified as a project.")
        static let evidenceNode = LocalizedStringResource("projects.evidence.node", defaultValue: "Node.js project", comment: "How a folder was identified as a project.")
        static let evidenceFlutter = LocalizedStringResource("projects.evidence.flutter", defaultValue: "Flutter or Dart package", comment: "How a folder was identified as a project.")
        static let evidenceRust = LocalizedStringResource("projects.evidence.rust", defaultValue: "Rust crate", comment: "How a folder was identified as a project.")
        static let evidenceGradle = LocalizedStringResource("projects.evidence.gradle", defaultValue: "Gradle project", comment: "How a folder was identified as a project.")
        static let evidenceGo = LocalizedStringResource("projects.evidence.go", defaultValue: "Go module", comment: "How a folder was identified as a project.")
        static let evidenceUnity = LocalizedStringResource("projects.evidence.unity", defaultValue: "Unity project", comment: "How a folder was identified as a project.")
        static let unknownActivity = LocalizedStringResource("projects.unknownActivity", defaultValue: "Last change unknown", comment: "Shown when the project's activity date can't be read.")
    }

    enum Space {
        static let breakdownTitle = LocalizedStringResource("space.breakdown.title", defaultValue: "What Fills This Space", comment: "Header over the breakdown of unattributed disk space.")
        static let purgeable = LocalizedStringResource("space.part.purgeable", defaultValue: "Purgeable", comment: "Space macOS frees when it needs room.")
        static let purgeableDetail = LocalizedStringResource("space.part.purgeable.detail", defaultValue: "Snapshots, caches and redownloadable files. macOS frees these when the disk fills up, so you don't have to.", comment: "Explains purgeable space.")
        static let remainder = LocalizedStringResource("space.part.remainder", defaultValue: "Not Attributed", comment: "Used space that the named parts don't explain.")
        static let remainderDetail = LocalizedStringResource("space.part.remainder.detail", defaultValue: "Used space that nothing above explains. Some of it belongs to macOS itself.", comment: "Explains the leftover part.")
        static let remainderNoAccess = LocalizedStringResource("space.part.remainder.noAccess", defaultValue: "Folders that need Full Disk Access are counted here too.", comment: "Added to the leftover explanation when access is missing.")
        static func systemVolume(_ name: String) -> LocalizedStringResource {
            LocalizedStringResource("space.part.volume", defaultValue: "\(name) volume", comment: "Another volume on the same disk, such as VM or Preboot.")
        }
        static let systemVolumeDetail = LocalizedStringResource("space.part.volume.detail", defaultValue: "A separate volume on this disk that macOS manages: swap files, startup data and recovery. Temizlikci doesn't scan it and you shouldn't remove it.", comment: "Explains a system volume.")
        static func mountedImage(_ name: String) -> LocalizedStringResource {
            LocalizedStringResource("space.part.image", defaultValue: "\(name)", comment: "A mounted disk image, such as a simulator runtime.")
        }
        static let mountedImageDetail = LocalizedStringResource("space.part.image.detail", defaultValue: "A disk image stored on this disk and mounted inside it. Simulator runtimes are kept this way; remove them in the Developer view.", comment: "Explains a mounted disk image.")
        static let source = LocalizedStringResource("space.source", defaultValue: "Figures come from macOS and from the disk's own layout, read at the end of the scan.", comment: "Says where the breakdown numbers come from.")
        static let reading = LocalizedStringResource("space.reading", defaultValue: "Reading the disk's layout…", comment: "Shown while the breakdown is being read.")
    }

    enum Settings {
        static let title = LocalizedStringResource("settings.title", defaultValue: "General", comment: "Title of the settings pane.")
        static let refreshLabel = LocalizedStringResource("settings.refresh.label", defaultValue: "Refresh a saved scan when it is older than", comment: "Label of the automatic refresh control.")
        static let refreshDay = LocalizedStringResource("settings.refresh.day", defaultValue: "1 day", comment: "Refresh period.")
        static let refreshThreeDays = LocalizedStringResource("settings.refresh.threeDays", defaultValue: "3 days", comment: "Refresh period.")
        static let refreshWeek = LocalizedStringResource("settings.refresh.week", defaultValue: "1 week", comment: "Refresh period.")
        static let refreshNever = LocalizedStringResource("settings.refresh.never", defaultValue: "Never", comment: "Refresh period meaning the app never scans by itself.")
        static let refreshExplanation = LocalizedStringResource("settings.refresh.explanation", defaultValue: "Temizlikci shows the last scan of a location as soon as you open it. When that scan is older than this, it reads the disk again in the background and replaces it when it's done.", comment: "Explains the automatic refresh setting.")
    }

    enum Identity {
        static let startupDisk = LocalizedStringResource("identity.startupDisk", defaultValue: "The disk macOS starts from. Everything on this Mac lives here.", comment: "What a well-known folder is.")
        static let applications = LocalizedStringResource("identity.applications", defaultValue: "Apps installed for everyone on this Mac.", comment: "What a well-known folder is.")
        static let libraryShared = LocalizedStringResource("identity.library.shared", defaultValue: "Support files shared by every account: fonts, printer drivers, and developer tools.", comment: "What a well-known folder is.")
        static let system = LocalizedStringResource("identity.system", defaultValue: "macOS itself, on a read-only volume. It can't be changed or removed.", comment: "What a well-known folder is.")
        static let dataVolume = LocalizedStringResource("identity.dataVolume", defaultValue: "Where everything that isn't macOS is stored, shown by the system as part of the startup disk.", comment: "What a well-known folder is.")
        static let users = LocalizedStringResource("identity.users", defaultValue: "The home folder of every account on this Mac.", comment: "What a well-known folder is.")
        static let volumes = LocalizedStringResource("identity.volumes", defaultValue: "Where other disks and disk images appear while they're connected.", comment: "What a well-known folder is.")
        static let privateFolder = LocalizedStringResource("identity.private", defaultValue: "Working files macOS needs while it runs: logs, databases and temporary data.", comment: "What a well-known folder is.")
        static let temporary = LocalizedStringResource("identity.temporary", defaultValue: "Temporary files. macOS clears them on its own.", comment: "What a well-known folder is.")
        static let unixTools = LocalizedStringResource("identity.unixTools", defaultValue: "Command-line tools that come with macOS.", comment: "What a well-known folder is.")
        static let optional = LocalizedStringResource("identity.optional", defaultValue: "Software installed outside of macOS, usually by Homebrew or a similar tool.", comment: "What a well-known folder is.")
        static let cores = LocalizedStringResource("identity.cores", defaultValue: "Crash dumps written when a program stops unexpectedly.", comment: "What a well-known folder is.")
        static let home = LocalizedStringResource("identity.home", defaultValue: "Your home folder: your documents, downloads and settings.", comment: "What a well-known folder is.")
        static let library = LocalizedStringResource("identity.library", defaultValue: "Your account's support files: app data, caches, settings and logs.", comment: "What a well-known folder is.")
        static let caches = LocalizedStringResource("identity.caches", defaultValue: "Files apps keep to work faster. Apps rebuild them when they're gone.", comment: "What a well-known folder is.")
        static let applicationSupport = LocalizedStringResource("identity.applicationSupport", defaultValue: "Data apps store outside their own bundle, such as libraries, projects and downloaded content.", comment: "What a well-known folder is.")
        static let containers = LocalizedStringResource("identity.containers", defaultValue: "The private folder of each sandboxed app, holding that app's own documents and data.", comment: "What a well-known folder is.")
        static let groupContainers = LocalizedStringResource("identity.groupContainers", defaultValue: "Data shared between apps from the same developer.", comment: "What a well-known folder is.")
        static let preferences = LocalizedStringResource("identity.preferences", defaultValue: "Settings files for your apps.", comment: "What a well-known folder is.")
        static let logs = LocalizedStringResource("identity.logs", defaultValue: "Log files written by apps and by macOS.", comment: "What a well-known folder is.")
        static let iCloudDrive = LocalizedStringResource("identity.iCloudDrive", defaultValue: "Your iCloud Drive. Files kept in the cloud only take space here while they're downloaded.", comment: "What a well-known folder is.")
        static let developer = LocalizedStringResource("identity.developer", defaultValue: "Xcode's working files: build products, device support and simulators.", comment: "What a well-known folder is.")
        static let desktop = LocalizedStringResource("identity.desktop", defaultValue: "What you see on your desktop.", comment: "What a well-known folder is.")
        static let documents = LocalizedStringResource("identity.documents", defaultValue: "Your documents.", comment: "What a well-known folder is.")
        static let downloads = LocalizedStringResource("identity.downloads", defaultValue: "Files you downloaded.", comment: "What a well-known folder is.")
        static let movies = LocalizedStringResource("identity.movies", defaultValue: "Your videos, and libraries from apps like Final Cut Pro.", comment: "What a well-known folder is.")
        static let music = LocalizedStringResource("identity.music", defaultValue: "Your music library and audio projects.", comment: "What a well-known folder is.")
        static let pictures = LocalizedStringResource("identity.pictures", defaultValue: "Your photo libraries and images.", comment: "What a well-known folder is.")
        static let publicFolder = LocalizedStringResource("identity.public", defaultValue: "Files you share with other accounts on this Mac.", comment: "What a well-known folder is.")
        static let trash = LocalizedStringResource("identity.trash", defaultValue: "Your Trash. It keeps taking space until you empty it.", comment: "What a well-known folder is.")
        static func application(_ name: String) -> LocalizedStringResource {
            LocalizedStringResource("identity.application", defaultValue: "The \(name) app.", comment: "An application bundle. The argument is the app's name.")
        }
        static func appData(_ name: String) -> LocalizedStringResource {
            LocalizedStringResource("identity.appData", defaultValue: "Data belonging to \(name).", comment: "A folder holding an app's data. The argument is the app's name.")
        }
        static let sectionTitle = LocalizedStringResource("identity.section.title", defaultValue: "What Is This?", comment: "Header of the inspector section that explains an item.")
        static let explain = LocalizedStringResource("identity.explain", defaultValue: "Explain This Folder", comment: "Button that asks the on-device model about an unknown folder.")
        static let explaining = LocalizedStringResource("identity.explaining", defaultValue: "Reading the folder's name and what's inside it…", comment: "Shown while the on-device model writes an explanation.")
        static let generatedNote = LocalizedStringResource("identity.generated.note", defaultValue: "Written on this Mac by Apple Intelligence from the folder's name and the names inside it. It can be wrong, and it never changes what Temizlikci considers safe to remove.", comment: "Label under a generated explanation.")
        static let retry = LocalizedStringResource("identity.retry", defaultValue: "Try Again", comment: "Button that asks the model once more.")
        static func failed(_ reason: String) -> LocalizedStringResource {
            LocalizedStringResource("identity.failed", defaultValue: "Couldn't write an explanation: \(reason)", comment: "Shown when the on-device model fails. The argument is the reason.")
        }
        static let unavailableNotEnabled = LocalizedStringResource("identity.unavailable.notEnabled", defaultValue: "Turn on Apple Intelligence in System Settings to have unknown folders explained on this Mac.", comment: "Shown when Apple Intelligence is off.")
        static let unavailableDevice = LocalizedStringResource("identity.unavailable.device", defaultValue: "This Mac doesn't support Apple Intelligence, so unknown folders can't be explained.", comment: "Shown when the Mac can't run the model.")
        static let unavailableNotReady = LocalizedStringResource("identity.unavailable.notReady", defaultValue: "Apple Intelligence is still downloading. Explanations work once it's ready.", comment: "Shown when the model isn't downloaded yet.")
    }

    enum Git {
        static let title = LocalizedStringResource("git.title", defaultValue: "Git", comment: "Header of the Git section in the project inspector.")
        static let reading = LocalizedStringResource("git.reading", defaultValue: "Checking for work that exists only on this Mac…", comment: "Shown while Git is read.")
        static let unreadable = LocalizedStringResource("git.unreadable", defaultValue: "Git couldn’t read this repository. The developer tools may be missing, or the folder is no longer a repository.", comment: "Shown when Git can't read a repository.")
        static let localWork = LocalizedStringResource("git.localWork", defaultValue: "Some work exists only on this Mac. Push or back it up before deleting this project.", comment: "Warning when a repository has uncommitted or unpushed work.")
        static let allPushed = LocalizedStringResource("git.allPushed", defaultValue: "Everything is committed and pushed.", comment: "Shown when a repository has no local-only work.")
        static let localWorkBadge = LocalizedStringResource("git.badge.localWork", defaultValue: "Unpushed Work", comment: "Short badge on a project row with local-only Git work.")
        static let allPushedBadge = LocalizedStringResource("git.badge.allPushed", defaultValue: "Pushed", comment: "Short badge on a project row whose Git work is all pushed.")
        static let branch = LocalizedStringResource("git.branch", defaultValue: "Branch", comment: "Label for the checked-out branch.")
        static let detached = LocalizedStringResource("git.detached", defaultValue: "No branch (detached)", comment: "Shown when HEAD isn't on a branch.")
        static let noRemote = LocalizedStringResource("git.noRemote", defaultValue: "No remote: nothing here was ever pushed", comment: "Row for a repository without a remote.")
        static let unpushedCommits = LocalizedStringResource("git.unpushedCommits", defaultValue: "Commits not on any remote", comment: "Label for the number of commits that exist only locally.")
        static let behind = LocalizedStringResource("git.behind", defaultValue: "Commits to pull", comment: "Label for how far the branch is behind its upstream.")
        static let staged = LocalizedStringResource("git.staged", defaultValue: "Staged changes", comment: "Label for staged files.")
        static let unstaged = LocalizedStringResource("git.unstaged", defaultValue: "Unstaged changes", comment: "Label for modified files not staged.")
        static let untracked = LocalizedStringResource("git.untracked", defaultValue: "Untracked files", comment: "Label for files Git doesn't track.")
        static let conflicted = LocalizedStringResource("git.conflicted", defaultValue: "Unresolved conflicts", comment: "Label for files with merge conflicts.")
        static let stashes = LocalizedStringResource("git.stashes", defaultValue: "Stashes", comment: "Label for stashed changes.")
        static let branchesOnlyHere = LocalizedStringResource("git.branchesOnlyHere", defaultValue: "Branches with commits only here", comment: "Header over local branches with unpushed commits.")
    }

    enum Accessibility {
        static let expanded = LocalizedStringResource("accessibility.expanded", defaultValue: "Expanded", comment: "Spoken state of an open section.")
        static let collapsed = LocalizedStringResource("accessibility.collapsed", defaultValue: "Collapsed", comment: "Spoken state of a closed section.")
    }
}
