import Foundation

/// An app that can open a project, and what to hand it.
nonisolated struct EditorTarget: Sendable, Equatable, Identifiable {
    enum Editor: String, Sendable, CaseIterable {
        case xcode, androidStudio, visualStudioCode

        var bundleIdentifier: String {
            switch self {
            case .xcode: WorkspaceAppOpener.xcode
            case .androidStudio: WorkspaceAppOpener.androidStudio
            case .visualStudioCode: WorkspaceAppOpener.visualStudioCode
            }
        }
    }

    let editor: Editor
    /// The workspace, project file or folder the editor should open.
    let url: URL

    var id: Editor { editor }
}

/// Picks the editors that make sense for a project, most specific first.
nonisolated enum ProjectEditors {
    static let gradleMarkers = ["build.gradle", "build.gradle.kts", "settings.gradle", "settings.gradle.kts"]

    static func targets(for project: DeveloperProject, markers: MarkerChecking) -> [EditorTarget] {
        var targets: [EditorTarget] = []
        let folders = project.node.children.filter { $0.kind == .directory }
        // Xcode opens a workspace in preference to a project file, so CocoaPods setups keep their pods;
        // a Swift package opens as its folder.
        if let workspace = folders.first(where: { $0.url.pathExtension == "xcworkspace" }) {
            targets.append(EditorTarget(editor: .xcode, url: workspace.url))
        } else if let xcodeProject = folders.first(where: { $0.url.pathExtension == "xcodeproj" }) {
            targets.append(EditorTarget(editor: .xcode, url: xcodeProject.url))
        } else if markers.folder(project.url, contains: "Package.swift") {
            targets.append(EditorTarget(editor: .xcode, url: project.url))
        }
        // Android Studio opens Gradle builds and Flutter projects from their root folder.
        let isGradle = gradleMarkers.contains { markers.folder(project.url, contains: $0) }
        let isFlutter = markers.folder(project.url, contains: "pubspec.yaml")
        if isGradle || isFlutter {
            targets.append(EditorTarget(editor: .androidStudio, url: project.url))
        }
        targets.append(EditorTarget(editor: .visualStudioCode, url: project.url))
        return targets
    }
}
