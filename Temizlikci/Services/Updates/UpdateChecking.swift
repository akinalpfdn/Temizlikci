import Foundation

/// Asks where the newest release is. Nothing is downloaded or installed here.
nonisolated protocol UpdateChecking: Sendable {
    /// The newest published release, or `nil` when there is none (or the repository isn't public).
    func latestRelease() async throws -> Release?
}

/// GitHub's public API, without an account: one small request that sends nothing about the Mac or
/// its files (the address GitHub sees is the only thing it learns).
nonisolated struct GitHubReleases: UpdateChecking {
    static let repository = "akinalpfdn/Temizlikci"
    static let endpoint = URL(string: "https://api.github.com/repos/\(repository)/releases/latest")!

    func latestRelease() async throws -> Release? {
        var request = URLRequest(url: Self.endpoint, timeoutInterval: 10)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { return nil }
        // 404: no release yet, or the repository is private.
        guard http.statusCode == 200 else { return nil }
        return Release.fromGitHub(data)
    }
}

/// What the update check remembers between launches.
protocol UpdatePreferences: AnyObject {
    var checksAutomatically: Bool { get set }
    var lastCheck: Date? { get set }
    /// A version the person dismissed: its banner doesn't come back.
    var dismissedVersion: String? { get set }
}

final class DefaultsUpdatePreferences: UpdatePreferences {
    static let automaticKey = "checksForUpdatesAutomatically"
    private let defaults = UserDefaults.standard

    var checksAutomatically: Bool {
        get { defaults.object(forKey: Self.automaticKey) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Self.automaticKey) }
    }

    var lastCheck: Date? {
        get { defaults.object(forKey: "lastUpdateCheck") as? Date }
        set { defaults.set(newValue, forKey: "lastUpdateCheck") }
    }

    var dismissedVersion: String? {
        get { defaults.string(forKey: "dismissedUpdateVersion") }
        set { defaults.set(newValue, forKey: "dismissedUpdateVersion") }
    }
}
