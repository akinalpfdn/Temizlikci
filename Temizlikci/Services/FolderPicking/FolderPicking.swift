import AppKit

/// Lets the person pick a folder to measure.
protocol FolderPicking {
    /// Returns the chosen folder, or `nil` when the person cancels.
    func pickFolder() async -> URL?
}

struct OpenPanelFolderPicker: FolderPicking {
    func pickFolder() async -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.prompt = String(localized: L10n.FolderPicker.prompt)
        panel.message = String(localized: L10n.FolderPicker.message)
        let response = await panel.begin()
        return response == .OK ? panel.url : nil
    }
}
