import Foundation

nonisolated enum SafetyLevel: String, Sendable, CaseIterable {
    /// Regenerates on its own; Move to Trash is fine.
    case safe
    /// Must be removed through its owning tool so that tool's state stays consistent.
    case tool
    /// Personal or irreplaceable data; the app never offers to delete it.
    case keep
}

nonisolated enum Ecosystem: String, Sendable, CaseIterable {
    case xcode, simulators, android, flutter, node, go, homebrew, appData
}

/// What the app offers to do with a matched item.
nonisolated enum CleanupAction: Sendable, Equatable {
    case moveToTrash
    case manageSimulators
    case openAndroidStudio
    case none
}

/// How a rule recognizes a folder.
nonisolated enum RuleMatcher: Sendable, Equatable {
    /// An exact folder path; `~` stands for the home folder.
    case path(String)
    /// Folders directly inside `parent` whose names start with `prefix` and contain `containing`.
    case childOf(parent: String, prefix: String, containing: String)
    /// A project folder: named `name`, next to a `marker` file (e.g. `build` beside `pubspec.yaml`).
    case projectFolder(name: String, marker: String)
}

/// One kind of developer artifact (Strategy pattern): how to find it, how safe it is, why, and what to do.
nonisolated struct CleanupRule: Sendable, Identifiable {
    let id: String
    let ecosystem: Ecosystem
    let safety: SafetyLevel
    let matcher: RuleMatcher
    let reason: LocalizedStringResource
    let action: CleanupAction
}

nonisolated extension CleanupRule {
    /// The built-in catalog. Order doesn't matter: exact paths win over project-folder names.
    static let catalog: [CleanupRule] = [
        // Xcode
        CleanupRule(id: "xcode.derivedData", ecosystem: .xcode, safety: .safe, matcher: .path("~/Library/Developer/Xcode/DerivedData"), reason: L10n.Cleanup.reasonDerivedData, action: .moveToTrash),
        CleanupRule(id: "xcode.iosDeviceSupport", ecosystem: .xcode, safety: .safe, matcher: .path("~/Library/Developer/Xcode/iOS DeviceSupport"), reason: L10n.Cleanup.reasonDeviceSupport, action: .moveToTrash),
        CleanupRule(id: "xcode.watchosDeviceSupport", ecosystem: .xcode, safety: .safe, matcher: .path("~/Library/Developer/Xcode/watchOS DeviceSupport"), reason: L10n.Cleanup.reasonDeviceSupport, action: .moveToTrash),
        CleanupRule(id: "xcode.tvosDeviceSupport", ecosystem: .xcode, safety: .safe, matcher: .path("~/Library/Developer/Xcode/tvOS DeviceSupport"), reason: L10n.Cleanup.reasonDeviceSupport, action: .moveToTrash),
        CleanupRule(id: "xcode.visionosDeviceSupport", ecosystem: .xcode, safety: .safe, matcher: .path("~/Library/Developer/Xcode/visionOS DeviceSupport"), reason: L10n.Cleanup.reasonDeviceSupport, action: .moveToTrash),
        CleanupRule(id: "xcode.previews", ecosystem: .xcode, safety: .safe, matcher: .path("~/Library/Developer/Xcode/UserData/Previews"), reason: L10n.Cleanup.reasonPreviews, action: .moveToTrash),
        CleanupRule(id: "xcode.documentationCache", ecosystem: .xcode, safety: .safe, matcher: .path("~/Library/Developer/Xcode/DocumentationCache"), reason: L10n.Cleanup.reasonDocumentationCache, action: .moveToTrash),
        CleanupRule(id: "xcode.archives", ecosystem: .xcode, safety: .keep, matcher: .path("~/Library/Developer/Xcode/Archives"), reason: L10n.Cleanup.reasonArchives, action: .none),
        // Simulators
        CleanupRule(id: "simulators.devices", ecosystem: .simulators, safety: .tool, matcher: .path("~/Library/Developer/CoreSimulator/Devices"), reason: L10n.Cleanup.reasonSimulatorDevices, action: .manageSimulators),
        CleanupRule(id: "simulators.runtimeVolumes", ecosystem: .simulators, safety: .tool, matcher: .path("/Library/Developer/CoreSimulator"), reason: L10n.Cleanup.reasonSimulatorRuntimes, action: .manageSimulators),
        CleanupRule(id: "simulators.runtimeAssets", ecosystem: .simulators, safety: .tool, matcher: .childOf(parent: "/System/Library/AssetsV2", prefix: "com_apple_MobileAsset_", containing: "SimulatorRuntime"), reason: L10n.Cleanup.reasonSimulatorRuntimes, action: .manageSimulators),
        // Android
        CleanupRule(id: "android.gradleCaches", ecosystem: .android, safety: .safe, matcher: .path("~/.gradle/caches"), reason: L10n.Cleanup.reasonGradleCaches, action: .moveToTrash),
        CleanupRule(id: "android.emulators", ecosystem: .android, safety: .tool, matcher: .path("~/.android/avd"), reason: L10n.Cleanup.reasonAndroidEmulators, action: .openAndroidStudio),
        CleanupRule(id: "android.systemImages", ecosystem: .android, safety: .tool, matcher: .path("~/Library/Android/sdk/system-images"), reason: L10n.Cleanup.reasonAndroidSystemImages, action: .openAndroidStudio),
        // Flutter & Dart
        CleanupRule(id: "flutter.build", ecosystem: .flutter, safety: .safe, matcher: .projectFolder(name: "build", marker: "pubspec.yaml"), reason: L10n.Cleanup.reasonFlutterBuild, action: .moveToTrash),
        CleanupRule(id: "flutter.dartTool", ecosystem: .flutter, safety: .safe, matcher: .projectFolder(name: ".dart_tool", marker: "pubspec.yaml"), reason: L10n.Cleanup.reasonDartTool, action: .moveToTrash),
        CleanupRule(id: "flutter.pubCache", ecosystem: .flutter, safety: .safe, matcher: .path("~/.pub-cache"), reason: L10n.Cleanup.reasonPubCache, action: .moveToTrash),
        // Node.js
        CleanupRule(id: "node.modules", ecosystem: .node, safety: .safe, matcher: .projectFolder(name: "node_modules", marker: "package.json"), reason: L10n.Cleanup.reasonNodeModules, action: .moveToTrash),
        CleanupRule(id: "node.next", ecosystem: .node, safety: .safe, matcher: .projectFolder(name: ".next", marker: "package.json"), reason: L10n.Cleanup.reasonNextBuild, action: .moveToTrash),
        CleanupRule(id: "node.npmCache", ecosystem: .node, safety: .safe, matcher: .path("~/.npm/_cacache"), reason: L10n.Cleanup.reasonNpmCache, action: .moveToTrash),
        // Go & Homebrew
        CleanupRule(id: "go.buildCache", ecosystem: .go, safety: .safe, matcher: .path("~/Library/Caches/go-build"), reason: L10n.Cleanup.reasonGoBuild, action: .moveToTrash),
        CleanupRule(id: "homebrew.cache", ecosystem: .homebrew, safety: .safe, matcher: .path("~/Library/Caches/Homebrew"), reason: L10n.Cleanup.reasonHomebrewCache, action: .moveToTrash),
        // App data
        CleanupRule(id: "appData.containers", ecosystem: .appData, safety: .keep, matcher: .path("~/Library/Containers"), reason: L10n.Cleanup.reasonAppData, action: .none),
        CleanupRule(id: "appData.groupContainers", ecosystem: .appData, safety: .keep, matcher: .path("~/Library/Group Containers"), reason: L10n.Cleanup.reasonAppData, action: .none),
    ]
}
