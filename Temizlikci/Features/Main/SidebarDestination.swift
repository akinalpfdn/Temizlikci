import Foundation

/// Places and views reachable from the sidebar. The sidebar never holds the folder tree;
/// HIG limits sidebars to two levels, so the hierarchy lives in the content area.
enum SidebarDestination: Hashable, Identifiable {
    case startupDisk
    case home
    case chosenFolder
    case developer
    case largeFiles
    case trash

    var id: Self { self }

    var systemImage: String {
        switch self {
        case .startupDisk: "internaldrive"
        case .home: "house"
        case .chosenFolder: "folder"
        case .developer: "hammer"
        case .largeFiles: "doc"
        case .trash: "trash"
        }
    }

    var isLocation: Bool {
        switch self {
        case .startupDisk, .home, .chosenFolder: true
        case .developer, .largeFiles, .trash: false
        }
    }
}
