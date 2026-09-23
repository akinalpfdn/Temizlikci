import Foundation
import Testing
@testable import Temizlikci

nonisolated private final class StubChecker: UpdateChecking, @unchecked Sendable {
    var release: Release?
    var failure: Error?
    private(set) var calls = 0

    func latestRelease() async throws -> Release? {
        calls += 1
        if let failure { throw failure }
        return release
    }
}

/// Keeps preferences in memory, so tests never write the app's real defaults.
private final class MemoryPreferences: UpdatePreferences {
    var checksAutomatically = true
    var lastCheck: Date?
    var dismissedVersion: String?
}

@Suite("Update check")
struct UpdateTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func release(_ version: String) -> Release {
        Release(
            version: AppVersion(version)!,
            pageURL: URL(string: "https://github.com/akinalpfdn/Temizlikci/releases/tag/v\(version)")!,
            downloadURL: URL(string: "https://github.com/akinalpfdn/Temizlikci/releases/download/v\(version)/Temizlikci.dmg")!
        )
    }

    private func model(current: String = "0.1.0", checker: StubChecker, preferences: MemoryPreferences, opened: @escaping (URL) -> Void = { _ in }) -> UpdateModel {
        UpdateModel(current: AppVersion(current), checker: checker, preferences: preferences, openURL: opened)
    }

    @Test("should order versions by number, ignoring a leading v and missing parts")
    func versions() {
        #expect(AppVersion("v0.2.0")! > AppVersion("0.1.9")!)
        #expect(AppVersion("1.10")! > AppVersion("1.9.9")!)
        #expect(AppVersion("1.4") == AppVersion("1.4.0"))
        #expect(AppVersion("v2.0.0-beta.1") == AppVersion("2.0.0"))
        #expect(AppVersion("latest") == nil)
    }

    @Test("should read GitHub's response and prefer the attached disk image for Download")
    func parsesRelease() throws {
        let json = """
        {"tag_name":"v0.2.0","html_url":"https://github.com/akinalpfdn/Temizlikci/releases/tag/v0.2.0",
         "draft":false,"prerelease":false,
         "assets":[{"name":"notes.txt","browser_download_url":"https://example.com/notes.txt"},
                   {"name":"Temizlikci-0.2.0.dmg","browser_download_url":"https://example.com/Temizlikci-0.2.0.dmg"}]}
        """
        let parsed = try #require(Release.fromGitHub(Data(json.utf8)))

        #expect(parsed.version == AppVersion("0.2.0"))
        #expect(parsed.downloadURL.lastPathComponent == "Temizlikci-0.2.0.dmg")

        let noImage = #"{"tag_name":"v0.3.0","html_url":"https://github.com/x/y/releases/tag/v0.3.0","assets":[]}"#
        #expect(Release.fromGitHub(Data(noImage.utf8))?.downloadURL.absoluteString == "https://github.com/x/y/releases/tag/v0.3.0")
        #expect(Release.fromGitHub(Data(#"{"message":"Not Found"}"#.utf8)) == nil)
    }

    @Test("should check at launch at most once a day, and never when turned off")
    func throttle() async {
        let checker = StubChecker()
        let preferences = MemoryPreferences()
        let subject = model(checker: checker, preferences: preferences)

        await subject.checkIfDue(now: now)
        await subject.checkIfDue(now: now.addingTimeInterval(60 * 60))
        #expect(checker.calls == 1)

        await subject.checkIfDue(now: now.addingTimeInterval(25 * 60 * 60))
        #expect(checker.calls == 2)

        preferences.checksAutomatically = false
        await subject.checkIfDue(now: now.addingTimeInterval(80 * 60 * 60))
        #expect(checker.calls == 2)
    }

    @Test("should offer a newer version, open its disk image on Download, and stay quiet once dismissed")
    func offerAndDismiss() async {
        let checker = StubChecker()
        checker.release = release("0.2.0")
        let preferences = MemoryPreferences()
        var opened: [URL] = []
        let subject = model(checker: checker, preferences: preferences) { opened.append($0) }

        await subject.checkIfDue(now: now)
        #expect(subject.available?.version == AppVersion("0.2.0"))
        subject.download()
        #expect(opened.last?.lastPathComponent == "Temizlikci.dmg")

        subject.dismiss()
        #expect(subject.available == nil)
        await subject.checkIfDue(now: now.addingTimeInterval(2 * 24 * 60 * 60))
        #expect(subject.available == nil, "a dismissed version doesn't come back")

        checker.release = release("0.3.0")
        await subject.checkIfDue(now: now.addingTimeInterval(4 * 24 * 60 * 60))
        #expect(subject.available?.version == AppVersion("0.3.0"), "a later version does")
    }

    @Test("should say nothing on an automatic check that fails or finds nothing new, but answer a manual one")
    func quietVersusManual() async {
        let checker = StubChecker()
        checker.release = release("0.1.0")
        let subject = model(checker: checker, preferences: MemoryPreferences())

        await subject.checkIfDue(now: now)
        #expect(subject.manualResult == nil)

        await subject.checkNow(now: now)
        #expect(subject.manualResult == .upToDate("0.1.0"))

        checker.failure = URLError(.notConnectedToInternet)
        await subject.checkNow(now: now)
        #expect(subject.manualResult == .failed)
    }
}
