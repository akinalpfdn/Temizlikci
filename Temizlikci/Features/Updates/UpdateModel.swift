import AppKit
import Foundation
import Observation

/// Tells the person when a newer version is published. It never downloads or installs anything by
/// itself: Download opens the disk image in the browser (developer decision, 2026-09-23).
@MainActor
@Observable
final class UpdateModel {
    /// Automatic checks happen at most this often.
    static let interval: TimeInterval = 24 * 60 * 60

    /// A newer release the person hasn't dismissed.
    private(set) var available: Release?
    private(set) var isChecking = false
    /// The outcome of a check the person asked for, shown as an alert; automatic checks stay silent.
    var manualResult: ManualResult?

    enum ManualResult: Identifiable, Equatable {
        case upToDate(String)
        case newer(Release)
        case failed

        var id: String {
            switch self {
            case .upToDate: "upToDate"
            case .newer(let release): release.version.description
            case .failed: "failed"
            }
        }
    }

    let current: AppVersion
    private let checker: UpdateChecking
    private let preferences: UpdatePreferences
    private let openURL: (URL) -> Void

    init(
        current: AppVersion? = nil,
        checker: UpdateChecking = GitHubReleases(),
        preferences: UpdatePreferences = DefaultsUpdatePreferences(),
        openURL: @escaping (URL) -> Void = { NSWorkspace.shared.open($0) }
    ) {
        let bundleVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        self.current = current ?? bundleVersion.flatMap(AppVersion.init) ?? AppVersion("0")!
        self.checker = checker
        self.preferences = preferences
        self.openURL = openURL
    }

    var checksAutomatically: Bool {
        get { preferences.checksAutomatically }
        set { preferences.checksAutomatically = newValue }
    }

    /// At launch: checks when automatic checks are on and the last one was a day or more ago.
    func checkIfDue(now: Date = Date()) async {
        guard preferences.checksAutomatically else { return }
        if let last = preferences.lastCheck, now.timeIntervalSince(last) < Self.interval { return }
        await check(now: now, manual: false)
    }

    /// From the menu: always checks, and always reports the outcome.
    func checkNow(now: Date = Date()) async {
        await check(now: now, manual: true)
    }

    func download() {
        guard let available else { return }
        openURL(available.downloadURL)
    }

    func openReleaseNotes() {
        guard let available else { return }
        openURL(available.pageURL)
    }

    /// Hides the banner for this version; a later version shows it again.
    func dismiss() {
        preferences.dismissedVersion = available?.version.description
        available = nil
    }

    private func check(now: Date, manual: Bool) async {
        guard !isChecking else { return }
        isChecking = true
        defer { isChecking = false }
        do {
            let release = try await checker.latestRelease()
            preferences.lastCheck = now
            guard let release, current < release.version else {
                if manual { manualResult = .upToDate(current.description) }
                return
            }
            if manual {
                available = release
                manualResult = .newer(release)
            } else if preferences.dismissedVersion != release.version.description {
                available = release
            }
        } catch {
            // Offline or GitHub unreachable: an automatic check says nothing and tries again next launch.
            if manual { manualResult = .failed }
        }
    }
}
