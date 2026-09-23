import Foundation

/// A version number like 1.4.2. Tags may carry a leading "v"; missing parts count as zero, so
/// "1.4" equals "1.4.0".
nonisolated struct AppVersion: Sendable, Comparable, CustomStringConvertible {
    let parts: [Int]

    init?(_ text: String) {
        var trimmed = text.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("v") || trimmed.hasPrefix("V") { trimmed.removeFirst() }
        // Anything after a hyphen or plus is a pre-release or build label, which the latest-release
        // endpoint never returns; it's ignored for ordering.
        let core = trimmed.split(whereSeparator: { $0 == "-" || $0 == "+" }).first.map(String.init) ?? ""
        let numbers = core.split(separator: ".").map { Int($0) }
        guard !numbers.isEmpty, !numbers.contains(nil) else { return nil }
        parts = numbers.compactMap { $0 }
    }

    var description: String { parts.map(String.init).joined(separator: ".") }

    static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        let count = max(lhs.parts.count, rhs.parts.count)
        for index in 0..<count {
            let left = index < lhs.parts.count ? lhs.parts[index] : 0
            let right = index < rhs.parts.count ? rhs.parts[index] : 0
            if left != right { return left < right }
        }
        return false
    }

    static func == (lhs: AppVersion, rhs: AppVersion) -> Bool { !(lhs < rhs) && !(rhs < lhs) }
}

/// A published release: what it is and where to get it.
nonisolated struct Release: Sendable, Equatable {
    let version: AppVersion
    /// The release page on GitHub, with the notes.
    let pageURL: URL
    /// The disk image to download; the release page when no image is attached.
    let downloadURL: URL

    static func == (lhs: Release, rhs: Release) -> Bool {
        lhs.version == rhs.version && lhs.pageURL == rhs.pageURL && lhs.downloadURL == rhs.downloadURL
    }

    /// Reads GitHub's "latest release" response. Returns `nil` for anything that isn't a usable release.
    static func fromGitHub(_ data: Data) -> Release? {
        struct Payload: Decodable {
            struct Asset: Decodable {
                let name: String
                let browser_download_url: URL
            }
            let tag_name: String
            let html_url: URL
            let draft: Bool?
            let prerelease: Bool?
            let assets: [Asset]?
        }
        guard let payload = try? JSONDecoder().decode(Payload.self, from: data),
              payload.draft != true, payload.prerelease != true,
              let version = AppVersion(payload.tag_name)
        else { return nil }
        let image = payload.assets?.first { $0.name.lowercased().hasSuffix(".dmg") }
        return Release(version: version, pageURL: payload.html_url, downloadURL: image?.browser_download_url ?? payload.html_url)
    }
}
