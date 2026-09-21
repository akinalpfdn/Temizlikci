import AppKit

nonisolated protocol FullDiskAccessChecking: Sendable {
    func hasFullDiskAccess() -> Bool
}

/// There is no public API that reports Full Disk Access. The system TCC database is readable only
/// with Full Disk Access, and a denied read fails silently — it never shows a consent prompt,
/// so probing it is safe to do at any time.
nonisolated struct SystemFullDiskAccessChecker: FullDiskAccessChecking {
    static let probe = URL(filePath: "/Library/Application Support/com.apple.TCC/TCC.db")

    func hasFullDiskAccess() -> Bool {
        guard let handle = try? FileHandle(forReadingFrom: Self.probe) else { return false }
        // Only the open matters; a close failure changes nothing about access.
        try? handle.close()
        return true
    }
}

/// Folders where macOS asks for consent the first time an app reads them. Without Full Disk Access,
/// scanning them would show one prompt per folder, so the scanner leaves them unread and reports
/// them as needing access; the app then asks once, in context (HIG Privacy).
///
/// Documented prompting locations: Desktop, Documents, Downloads, iCloud Drive, third-party cloud
/// storage (Eclectic Light, "Explainer: Permissions, privacy and TCC", 2025). Music was observed
/// prompting on macOS 26; Pictures, Movies, other apps' data, and the Contacts, Calendars, and
/// Reminders stores are included on the same grounds (their data is personal and consent-protected).
/// Removable and network volumes are mount points, which the scanner skips anyway.
nonisolated enum ProtectedLocations {
    static let homeRelativePaths = [
        "Desktop", "Documents", "Downloads", "Music", "Pictures", "Movies",
        "Library/Mobile Documents", "Library/CloudStorage",
        "Library/Containers", "Library/Group Containers",
        "Library/Application Support/AddressBook", "Library/Calendars", "Library/Reminders",
    ]

    static func folders(inHome home: URL) -> [URL] {
        homeRelativePaths.map { home.appending(path: $0, directoryHint: .isDirectory) }
    }
}

extension ScanConfiguration {
    /// The configuration to use for a scan: with Full Disk Access everything is read; without it,
    /// consent-prompting folders are left unread and reported as needing access.
    nonisolated static func forScan(access: FullDiskAccessChecking, home: URL = URL.homeDirectory) -> ScanConfiguration {
        var configuration = ScanConfiguration.standard
        if !access.hasFullDiskAccess() {
            configuration.unreadFolders = Set(ProtectedLocations.folders(inHome: home).map(ScanConfiguration.comparablePath(of:)))
        }
        return configuration
    }
}

/// Opens System Settings at Full Disk Access. The app can't grant access itself; the person turns it on.
protocol PrivacySettingsOpening {
    func openFullDiskAccessSettings()
}

struct SystemPrivacySettings: PrivacySettingsOpening {
    /// The Privacy pane keeps its legacy settings URL on macOS 26 (MacMost, "Mac System Settings Links").
    static let fullDiskAccessAddress = "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"

    func openFullDiskAccessSettings() {
        guard let url = URL(string: Self.fullDiskAccessAddress) else { return }
        NSWorkspace.shared.open(url)
    }
}
