import AppKit

/// Opens another app by bundle identifier, for items that app must remove (e.g. Android Studio).
protocol AppOpening {
    func isInstalled(_ bundleIdentifier: String) -> Bool
    func open(_ bundleIdentifier: String)
}

struct WorkspaceAppOpener: AppOpening {
    static let androidStudio = "com.google.android.studio"

    func isInstalled(_ bundleIdentifier: String) -> Bool {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) != nil
    }

    func open(_ bundleIdentifier: String) {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else { return }
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }
}
