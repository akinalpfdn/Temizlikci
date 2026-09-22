import SwiftUI

/// A brief, optional, interactive introduction to the sunburst (HIG Onboarding): shown once after the
/// first scan, skippable, and always available from the Help menu. The chart is a real, clickable
/// sunburst on example data; nothing in it touches the disk.
struct ChartIntroView: View {
    let onDone: () -> Void
    @State private var sample = ChartIntroView.makeSampleModel()

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.large) {
            Text(L10n.Intro.title).font(.title2.weight(.semibold))
            HStack(alignment: .top, spacing: Spacing.xLarge) {
                VStack(spacing: Spacing.small) {
                    SunburstView(model: sample)
                        .frame(width: 280, height: 280)
                    Text(L10n.Intro.tryIt).font(Typography.chartCaption).foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    tip("circle.circle", L10n.Intro.rings)
                    tip("chart.pie", L10n.Intro.size)
                    tip("cursorarrow.click.2", L10n.Intro.interaction)
                    tip("sparkles", L10n.Intro.highlight)
                }
                .frame(width: 280, alignment: .leading)
            }
            HStack {
                Spacer()
                Button(action: onDone) { Text(L10n.Intro.done) }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(Spacing.xLarge)
        .task { if sample.phase == .idle { sample.startScan() } }
    }

    private func tip(_ symbol: String, _ text: LocalizedStringResource) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
            Image(systemName: symbol).foregroundStyle(.tint).frame(width: 20).accessibilityHidden(true)
            Text(text).fixedSize(horizontal: false, vertical: true)
        }
    }

    private static func makeSampleModel() -> LocationScanModel {
        LocationScanModel(
            location: ScanLocation(url: SampleTree.root, displayName: String(localized: L10n.Intro.sampleName), isWholeVolume: false),
            volumeInfo: SystemVolumeInfo(),
            access: SampleAccess(),
            revealer: SampleRevealer(),
            trash: SampleTrash(),
            ledger: TrashLedger(trash: SampleTrash()),
            ruleEngine: RuleEngine(rules: []),
            snapshots: SampleSnapshots(),
            makeScanner: { _ in SampleScanner() }
        )
    }
}

/// Example data for the introduction, with localized folder names. Built with plain helper calls:
/// nested closures here made the type checker take minutes.
nonisolated private enum SampleTree {
    static let root = URL(filePath: "/Example", directoryHint: .isDirectory)

    static func make() -> FileNode {
        let photos = folder(L10n.Intro.samplePhotos, in: root)
        let vacation = folder(L10n.Intro.sampleVacation, in: photos)
        let family = folder(L10n.Intro.sampleFamily, in: photos)
        let projects = folder(L10n.Intro.sampleProjects, in: root)
        let game = folder(L10n.Intro.sampleGame, in: projects)
        let website = folder(L10n.Intro.sampleWebsite, in: projects)
        let music = folder(L10n.Intro.sampleMusic, in: root)
        let apps = folder(L10n.Intro.sampleApps, in: root)
        let caches = folder(L10n.Intro.sampleCaches, in: root)

        let photoFolders: [FileNode] = [
            directory(vacation, [file("IMG_0001.mov", in: vacation, gigabytes: 9), file("IMG_0002.mov", in: vacation, gigabytes: 5)]),
            directory(family, [file("IMG_0100.heic", in: family, gigabytes: 6)]),
        ]
        let projectFolders: [FileNode] = [
            directory(game, [file("Assets.pak", in: game, gigabytes: 8)]),
            directory(website, [file("video.mp4", in: website, gigabytes: 3)]),
        ]
        let topLevel: [FileNode] = [
            directory(photos, photoFolders),
            directory(projects, projectFolders),
            directory(music, [file("Library.musiclibrary", in: music, gigabytes: 7)]),
            directory(apps, [file("Editor.app", in: apps, gigabytes: 4)]),
            directory(caches, [file("cache.db", in: caches, gigabytes: 2)]),
        ]
        return directory(root, topLevel)
    }

    private static func folder(_ name: LocalizedStringResource, in parent: URL) -> URL {
        parent.appending(path: String(localized: name), directoryHint: .isDirectory)
    }

    private static func directory(_ url: URL, _ children: [FileNode]) -> FileNode {
        FileNode.directory(url: url, modificationDate: nil, children: children)
    }

    private static func file(_ name: String, in parent: URL, gigabytes: Int64) -> FileNode {
        FileNode.file(url: parent.appending(path: name), allocatedSize: gigabytes * 1_000_000_000, modificationDate: nil)
    }
}

nonisolated private struct SampleScanner: DiskScanning {
    func scan(_ root: URL) -> AsyncThrowingStream<ScanEvent, Error> {
        AsyncThrowingStream { continuation in
            let tree = SampleTree.make()
            continuation.yield(.finished(ScanResult(root: tree, duration: .zero, fileCount: tree.fileCount, directoryCount: 10, inaccessibleCount: 0)))
            continuation.finish()
        }
    }
}

nonisolated private struct SampleAccess: FullDiskAccessChecking {
    func hasFullDiskAccess() -> Bool { true }
}

private struct SampleRevealer: FileRevealing {
    func reveal(_ url: URL) {}
}

/// The example must never move anything; every Trash operation fails.
private struct SampleTrash: Trashing {
    func moveToTrash(_ url: URL) throws -> URL { throw TrashError.failed(name: url.lastPathComponent) }
    func putBack(_ trashedURL: URL, to originalURL: URL) throws { throw TrashError.putBackFailed(name: originalURL.lastPathComponent) }
    func showTrashInFinder() {}
}

/// The example keeps no history.
nonisolated private struct SampleSnapshots: SnapshotStoring {
    func recent(forLocation path: String, limit: Int) throws -> [ScanSnapshot] { [] }
    func save(_ snapshot: ScanSnapshot) throws {}
    func prune(location path: String, keeping count: Int) throws {}
}
