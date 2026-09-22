import Foundation
import Testing
@testable import Temizlikci

nonisolated private struct Markers: MarkerChecking {
    let files: Set<String>
    func folder(_ folder: URL, contains marker: String) -> Bool { files.contains(marker) }
}

@Suite("Project editors")
struct ProjectEditorsTests {
    private let root = URL(filePath: "/Work/app", directoryHint: .isDirectory)

    private func project(folders: [String] = []) -> DeveloperProject {
        DeveloperProject(
            node: .directory(url: root, modificationDate: nil, children: folders.map {
                .directory(url: root.appending(path: $0, directoryHint: .isDirectory), modificationDate: nil, children: [])
            }),
            idPath: [], evidence: .git, artifacts: [], lastTouched: nil
        )
    }

    @Test("should open a workspace in Xcode before a project file, so CocoaPods setups keep their pods")
    func workspaceFirst() {
        let targets = ProjectEditors.targets(for: project(folders: ["App.xcodeproj", "App.xcworkspace"]), markers: Markers(files: []))

        #expect(targets.first?.editor == .xcode)
        #expect(targets.first?.url.lastPathComponent == "App.xcworkspace")
    }

    @Test("should open a project file, or a Swift package's folder, when there is no workspace")
    func projectFileOrPackage() {
        let withProject = ProjectEditors.targets(for: project(folders: ["App.xcodeproj"]), markers: Markers(files: []))
        #expect(withProject.first?.url.lastPathComponent == "App.xcodeproj")

        let package = ProjectEditors.targets(for: project(), markers: Markers(files: ["Package.swift"]))
        #expect(package.first == EditorTarget(editor: .xcode, url: root))
    }

    @Test("should offer Android Studio for Gradle and Flutter projects, and Visual Studio Code for everything")
    func androidAndCode() {
        let gradle = ProjectEditors.targets(for: project(), markers: Markers(files: ["build.gradle.kts"]))
        #expect(gradle.map(\.editor) == [.androidStudio, .visualStudioCode])

        let flutter = ProjectEditors.targets(for: project(folders: ["App.xcworkspace"]), markers: Markers(files: ["pubspec.yaml"]))
        #expect(flutter.map(\.editor) == [.xcode, .androidStudio, .visualStudioCode])

        let plain = ProjectEditors.targets(for: project(), markers: Markers(files: []))
        #expect(plain.map(\.editor) == [.visualStudioCode])
    }
}
