import Foundation
import UniformTypeIdentifiers

/// What an item is, and where that answer came from. Nothing here changes a safety label or offers
/// an action: it only explains (DECISIONS 2026-09-22).
nonisolated struct FolderIdentity: Sendable, Equatable {
    enum Source: Sendable, Equatable {
        /// A folder macOS itself defines.
        case system
        /// Data belonging to an installed app, identified by its bundle identifier or folder name.
        case app(name: String)
        /// An application bundle.
        case application
        /// A file, described by its type.
        case fileType
        /// Written by the on-device model because nothing above recognized the folder.
        case generated
    }

    let summary: String
    let source: Source

    var isGenerated: Bool { source == .generated }
}

/// Recognizes folders from what the Mac already knows: the places macOS defines, the apps that are
/// installed, and file types. Anything it doesn't recognize returns `nil`, which is what the
/// optional on-device explanation is for.
nonisolated struct FolderIdentifier: Sendable {
    /// Exact paths macOS defines, with `~` for the home folder.
    static let knownPaths: [(path: String, text: LocalizedStringResource)] = [
        ("/", L10n.Identity.startupDisk),
        ("/Applications", L10n.Identity.applications),
        ("/Library", L10n.Identity.libraryShared),
        ("/System", L10n.Identity.system),
        ("/System/Volumes/Data", L10n.Identity.dataVolume),
        ("/Users", L10n.Identity.users),
        ("/Volumes", L10n.Identity.volumes),
        ("/private", L10n.Identity.privateFolder),
        ("/private/var", L10n.Identity.privateFolder),
        ("/private/tmp", L10n.Identity.temporary),
        ("/tmp", L10n.Identity.temporary),
        ("/usr", L10n.Identity.unixTools),
        ("/bin", L10n.Identity.unixTools),
        ("/sbin", L10n.Identity.unixTools),
        ("/opt", L10n.Identity.optional),
        ("/cores", L10n.Identity.cores),
        ("~", L10n.Identity.home),
        ("~/Library", L10n.Identity.library),
        ("~/Library/Caches", L10n.Identity.caches),
        ("~/Library/Application Support", L10n.Identity.applicationSupport),
        ("~/Library/Containers", L10n.Identity.containers),
        ("~/Library/Group Containers", L10n.Identity.groupContainers),
        ("~/Library/Preferences", L10n.Identity.preferences),
        ("~/Library/Logs", L10n.Identity.logs),
        ("~/Library/Mobile Documents", L10n.Identity.iCloudDrive),
        ("~/Library/Developer", L10n.Identity.developer),
        ("~/Desktop", L10n.Identity.desktop),
        ("~/Documents", L10n.Identity.documents),
        ("~/Downloads", L10n.Identity.downloads),
        ("~/Movies", L10n.Identity.movies),
        ("~/Music", L10n.Identity.music),
        ("~/Pictures", L10n.Identity.pictures),
        ("~/Public", L10n.Identity.publicFolder),
        ("~/.Trash", L10n.Identity.trash),
    ]

    let home: URL
    let apps: InstalledAppNaming

    init(home: URL = URL.homeDirectory, apps: InstalledAppNaming = InstalledApps()) {
        self.home = home
        self.apps = apps
    }

    func identity(of node: FileNode) -> FolderIdentity? {
        let path = node.path
        if node.kind == .file {
            return fileIdentity(of: node)
        }
        if path.hasSuffix(".app") {
            let name = node.url.deletingPathExtension().lastPathComponent
            return FolderIdentity(summary: String(localized: L10n.Identity.application(name)), source: .application)
        }
        if let known = Self.knownPaths.first(where: { expand($0.path) == path }) {
            return FolderIdentity(summary: String(localized: known.text), source: .system)
        }
        if let app = appIdentity(of: node) {
            return app
        }
        return nil
    }

    /// Folders named after an app's bundle identifier or after the app itself: the containers,
    /// caches and support folders that fill up a Mac.
    private func appIdentity(of node: FileNode) -> FolderIdentity? {
        let parent = node.url.deletingLastPathComponent().path(percentEncoded: false)
        let holdsAppData = [
            "~/Library/Containers", "~/Library/Group Containers", "~/Library/Application Support",
            "~/Library/Caches", "~/Library/Preferences", "~/Library/Logs", "~/Library/Saved Application State",
        ].contains { expand($0) + "/" == parent }
        guard holdsAppData else { return nil }

        let name = node.name
        // Group containers are named group.<identifier>, and saved state folders <identifier>.savedState.
        let identifier = name.hasPrefix("group.") ? String(name.dropFirst(6)) : name
        let trimmed = identifier.hasSuffix(".savedState") ? String(identifier.dropLast(11)) : identifier
        if let appName = apps.name(forBundleIdentifier: trimmed) {
            return FolderIdentity(summary: String(localized: L10n.Identity.appData(appName)), source: .app(name: appName))
        }
        if apps.isInstalled(named: name) {
            return FolderIdentity(summary: String(localized: L10n.Identity.appData(name)), source: .app(name: name))
        }
        return nil
    }

    private func fileIdentity(of node: FileNode) -> FolderIdentity? {
        guard let type = UTType(filenameExtension: node.url.pathExtension), let description = type.localizedDescription else {
            return nil
        }
        return FolderIdentity(summary: description.localizedCapitalized, source: .fileType)
    }

    private func expand(_ pattern: String) -> String {
        guard pattern.hasPrefix("~") else { return pattern }
        var homePath = home.path(percentEncoded: false)
        if homePath.count > 1, homePath.hasSuffix("/") { homePath.removeLast() }
        return homePath + pattern.dropFirst()
    }
}
