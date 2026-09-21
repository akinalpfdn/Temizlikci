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
        static let unattributedExplanation = LocalizedStringResource("details.explain.unattributed", defaultValue: "Space macOS reports as used that no scanned folder accounts for: folders Temizlikci can’t read without Full Disk Access, the system volume’s hidden parts, APFS snapshots, and purgeable files.", comment: "Inspector explanation for unattributed space.")
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
}
