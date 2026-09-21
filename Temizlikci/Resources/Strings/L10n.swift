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
        static let highlightReclaimable = LocalizedStringResource("toolbar.highlightReclaimable", defaultValue: "Highlight Reclaimable", comment: "Toolbar toggle that colors the chart by cleanup safety.")
        static let inspector = LocalizedStringResource("toolbar.inspector", defaultValue: "Inspector", comment: "Toolbar button that shows or hides the inspector.")
    }

    enum Menu {
        static let chooseFolder = LocalizedStringResource("menu.file.chooseFolder", defaultValue: "Choose Folder…", comment: "File menu command that opens a panel to pick a folder to scan.")
        static let highlightReclaimable = LocalizedStringResource("menu.view.highlightReclaimable", defaultValue: "Highlight Reclaimable", comment: "View menu toggle that colors the chart by cleanup safety.")
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
}
