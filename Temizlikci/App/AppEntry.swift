import AppKit
import SwiftUI

/// Chooses the app to run. When the process only hosts unit tests, it runs a windowless app with
/// no Dock icon, so running the test suite doesn't open Temizlikci windows on the developer's Mac.
@main
enum AppEntry {
    static func main() {
        if isHostingTests {
            TestHostApp.main()
        } else {
            TemizlikciApp.main()
        }
    }

    private static var isHostingTests: Bool {
        let environment = ProcessInfo.processInfo.environment
        return environment["XCTestConfigurationFilePath"] != nil || environment["XCTestBundlePath"] != nil
    }
}

private struct TestHostApp: App {
    init() {
        NSApplication.shared.setActivationPolicy(.prohibited)
    }

    var body: some Scene {
        Settings { EmptyView() }
    }
}
