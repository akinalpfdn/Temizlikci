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
    case xcode, simulators, swift, android, flutter, node, rust, go, python, dotnet, java, docker, unity, editors, homebrew, appData
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
        // Swift Package Manager, Xcode caches and CocoaPods
        CleanupRule(id: "swift.swiftpmCache", ecosystem: .swift, safety: .safe, matcher: .path("~/Library/Caches/org.swift.swiftpm"), reason: L10n.Cleanup.reasonSwiftPMCache, action: .moveToTrash),
        CleanupRule(id: "swift.xcodeCache", ecosystem: .xcode, safety: .safe, matcher: .path("~/Library/Caches/com.apple.dt.Xcode"), reason: L10n.Cleanup.reasonXcodeCache, action: .moveToTrash),
        CleanupRule(id: "swift.cocoapodsCache", ecosystem: .swift, safety: .safe, matcher: .path("~/Library/Caches/CocoaPods"), reason: L10n.Cleanup.reasonCocoaPodsCache, action: .moveToTrash),
        CleanupRule(id: "swift.pods", ecosystem: .swift, safety: .safe, matcher: .projectFolder(name: "Pods", marker: "Podfile"), reason: L10n.Cleanup.reasonPods, action: .moveToTrash),
        CleanupRule(id: "swift.packageBuild", ecosystem: .swift, safety: .safe, matcher: .projectFolder(name: ".build", marker: "Package.swift"), reason: L10n.Cleanup.reasonSwiftPMBuild, action: .moveToTrash),
        // Rust
        CleanupRule(id: "rust.registry", ecosystem: .rust, safety: .safe, matcher: .path("~/.cargo/registry"), reason: L10n.Cleanup.reasonCargoRegistry, action: .moveToTrash),
        CleanupRule(id: "rust.target", ecosystem: .rust, safety: .safe, matcher: .projectFolder(name: "target", marker: "Cargo.toml"), reason: L10n.Cleanup.reasonCargoTarget, action: .moveToTrash),
        CleanupRule(id: "rust.toolchains", ecosystem: .rust, safety: .tool, matcher: .path("~/.rustup"), reason: L10n.Cleanup.reasonRustup, action: .none),
        // Python
        CleanupRule(id: "python.pipCache", ecosystem: .python, safety: .safe, matcher: .path("~/Library/Caches/pip"), reason: L10n.Cleanup.reasonPipCache, action: .moveToTrash),
        CleanupRule(id: "python.uvCache", ecosystem: .python, safety: .tool, matcher: .path("~/.cache/uv"), reason: L10n.Cleanup.reasonUvCache, action: .none),
        // .NET and Java
        CleanupRule(id: "dotnet.packages", ecosystem: .dotnet, safety: .tool, matcher: .path("~/.nuget/packages"), reason: L10n.Cleanup.reasonNuGet, action: .none),
        CleanupRule(id: "java.maven", ecosystem: .java, safety: .safe, matcher: .path("~/.m2/repository"), reason: L10n.Cleanup.reasonMaven, action: .moveToTrash),
        CleanupRule(id: "java.gradleBuild", ecosystem: .java, safety: .safe, matcher: .projectFolder(name: "build", marker: "build.gradle"), reason: L10n.Cleanup.reasonGradleBuild, action: .moveToTrash),
        CleanupRule(id: "java.gradleBuildKts", ecosystem: .java, safety: .safe, matcher: .projectFolder(name: "build", marker: "build.gradle.kts"), reason: L10n.Cleanup.reasonGradleBuild, action: .moveToTrash),
        // Go modules
        CleanupRule(id: "go.modCache", ecosystem: .go, safety: .tool, matcher: .path("~/go/pkg/mod"), reason: L10n.Cleanup.reasonGoModCache, action: .none),
        // Docker
        CleanupRule(id: "docker.data", ecosystem: .docker, safety: .tool, matcher: .path("~/Library/Containers/com.docker.docker/Data"), reason: L10n.Cleanup.reasonDocker, action: .none),
        // JavaScript toolchains
        CleanupRule(id: "node.yarnCache", ecosystem: .node, safety: .safe, matcher: .path("~/Library/Caches/Yarn"), reason: L10n.Cleanup.reasonYarnCache, action: .moveToTrash),
        CleanupRule(id: "node.yarnBerryCache", ecosystem: .node, safety: .safe, matcher: .path("~/.yarn/berry/cache"), reason: L10n.Cleanup.reasonYarnCache, action: .moveToTrash),
        CleanupRule(id: "node.pnpmStore", ecosystem: .node, safety: .tool, matcher: .path("~/Library/pnpm/store"), reason: L10n.Cleanup.reasonPnpmStore, action: .none),
        CleanupRule(id: "node.bunCache", ecosystem: .node, safety: .safe, matcher: .path("~/.bun/install/cache"), reason: L10n.Cleanup.reasonBunCache, action: .moveToTrash),
        CleanupRule(id: "node.electronCache", ecosystem: .node, safety: .safe, matcher: .path("~/Library/Caches/electron"), reason: L10n.Cleanup.reasonElectronCache, action: .moveToTrash),
        CleanupRule(id: "node.gypCache", ecosystem: .node, safety: .safe, matcher: .path("~/Library/Caches/node-gyp"), reason: L10n.Cleanup.reasonNodeGyp, action: .moveToTrash),
        CleanupRule(id: "node.playwright", ecosystem: .node, safety: .safe, matcher: .path("~/Library/Caches/ms-playwright"), reason: L10n.Cleanup.reasonPlaywright, action: .moveToTrash),
        // Editors and Unity
        CleanupRule(id: "editors.jetbrains", ecosystem: .editors, safety: .safe, matcher: .path("~/Library/Caches/JetBrains"), reason: L10n.Cleanup.reasonJetBrains, action: .moveToTrash),
        CleanupRule(id: "unity.library", ecosystem: .unity, safety: .safe, matcher: .projectFolder(name: "Library", marker: "ProjectSettings"), reason: L10n.Cleanup.reasonUnityLibrary, action: .moveToTrash),
        // App data
        CleanupRule(id: "appData.containers", ecosystem: .appData, safety: .keep, matcher: .path("~/Library/Containers"), reason: L10n.Cleanup.reasonAppData, action: .none),
        CleanupRule(id: "appData.groupContainers", ecosystem: .appData, safety: .keep, matcher: .path("~/Library/Group Containers"), reason: L10n.Cleanup.reasonAppData, action: .none),
    ]
}
