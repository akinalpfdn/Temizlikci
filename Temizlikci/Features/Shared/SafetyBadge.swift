import SwiftUI

extension SafetyLevel {
    var title: LocalizedStringResource {
        switch self {
        case .safe: L10n.Cleanup.safe
        case .tool: L10n.Cleanup.tool
        case .keep: L10n.Cleanup.keep
        }
    }

    var symbol: String {
        switch self {
        case .safe: "checkmark.circle"
        case .tool: "wrench.and.screwdriver"
        case .keep: "lock.shield"
        }
    }

    /// Text color for the label; status colors never carry meaning alone (always with symbol + text).
    var ink: Color {
        switch self {
        case .safe: StatusPalette.safeInk
        case .tool: StatusPalette.toolInk
        case .keep: .secondary
        }
    }
}

/// "Safe to Remove" / "Remove with Tool" / "Keep", with a symbol.
struct SafetyBadge: View {
    let level: SafetyLevel

    var body: some View {
        Label { Text(level.title) } icon: { Image(systemName: level.symbol) }
            .labelStyle(.titleAndIcon)
            .font(Typography.badge)
            .foregroundStyle(level.ink)
    }
}

extension Ecosystem {
    var title: LocalizedStringResource {
        switch self {
        case .xcode: L10n.Cleanup.ecosystemXcode
        case .simulators: L10n.Cleanup.ecosystemSimulators
        case .android: L10n.Cleanup.ecosystemAndroid
        case .flutter: L10n.Cleanup.ecosystemFlutter
        case .node: L10n.Cleanup.ecosystemNode
        case .swift: L10n.Cleanup.ecosystemSwift
        case .rust: L10n.Cleanup.ecosystemRust
        case .python: L10n.Cleanup.ecosystemPython
        case .dotnet: L10n.Cleanup.ecosystemDotNet
        case .java: L10n.Cleanup.ecosystemJava
        case .docker: L10n.Cleanup.ecosystemDocker
        case .unity: L10n.Cleanup.ecosystemUnity
        case .editors: L10n.Cleanup.ecosystemEditors
        case .go: L10n.Cleanup.ecosystemGo
        case .homebrew: L10n.Cleanup.ecosystemHomebrew
        case .appData: L10n.Cleanup.ecosystemAppData
        }
    }
}
