import AppKit
import Foundation
import UniformTypeIdentifiers

/// Looks up installed apps, so a folder named after one can be explained without any guessing.
nonisolated protocol InstalledAppNaming: Sendable {
    /// The app's display name for a bundle identifier, or `nil` when nothing with that identifier
    /// is installed.
    func name(forBundleIdentifier identifier: String) -> String?
    /// True when an app with this display name is installed.
    func isInstalled(named name: String) -> Bool
}

nonisolated struct InstalledApps: InstalledAppNaming {
    func name(forBundleIdentifier identifier: String) -> String? {
        // Bundle identifiers have at least two parts; anything else isn't worth a lookup.
        guard identifier.contains("."), !identifier.hasPrefix(".") else { return nil }
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: identifier) else { return nil }
        return displayName(of: url)
    }

    func isInstalled(named name: String) -> Bool {
        let candidates = [
            URL(filePath: "/Applications", directoryHint: .isDirectory),
            URL.homeDirectory.appending(path: "Applications", directoryHint: .isDirectory),
            URL(filePath: "/System/Applications", directoryHint: .isDirectory),
        ]
        return candidates.contains { folder in
            FileManager.default.fileExists(atPath: folder.appending(path: name + ".app").path(percentEncoded: false))
        }
    }

    private func displayName(of url: URL) -> String {
        let values = try? url.resourceValues(forKeys: [.localizedNameKey])
        let name = values?.localizedName ?? url.lastPathComponent
        return name.hasSuffix(".app") ? String(name.dropLast(4)) : name
    }
}
