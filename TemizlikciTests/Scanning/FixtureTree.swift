import Foundation

/// A throwaway folder tree under the temporary directory. Tests must never touch real locations;
/// everything here is created inside `root` and removed when the fixture is released.
nonisolated final class FixtureTree {
    let root: URL
    private var mountPoints: [URL] = []
    private var lockedFolders: [URL] = []

    init() throws {
        root = FileManager.default.temporaryDirectory
            .appending(path: "TemizlikciTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    deinit {
        for mountPoint in mountPoints { Self.runTool("/usr/bin/hdiutil", ["detach", mountPoint.path(percentEncoded: false), "-force"]) }
        for folder in lockedFolders { chmod(folder.path(percentEncoded: false), 0o755) }
        // Cleanup failure only leaves a folder in the temporary directory, which the system purges.
        try? FileManager.default.removeItem(at: root)
    }

    @discardableResult
    func folder(_ path: String) throws -> URL {
        let url = root.appending(path: path, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Writes `bytes` of non-zero data so the file can't be stored sparsely.
    @discardableResult
    func file(_ path: String, bytes: Int) throws -> URL {
        let url = root.appending(path: path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(repeating: 0xA5, count: bytes).write(to: url)
        return url
    }

    func hardLink(_ path: String, to target: URL) throws {
        try FileManager.default.linkItem(at: target, to: root.appending(path: path))
    }

    func symbolicLink(_ path: String, to target: URL) throws {
        try FileManager.default.createSymbolicLink(at: root.appending(path: path), withDestinationURL: target)
    }

    /// Makes a folder unreadable; permissions are restored before cleanup.
    func lock(_ url: URL) {
        chmod(url.path(percentEncoded: false), 0o000)
        lockedFolders.append(url)
    }

    /// Mounts a small disk image at `path`, like a simulator runtime inside a scanned folder.
    func mountImage(at path: String) throws -> URL {
        let image = root.appending(path: "image-\(UUID().uuidString).dmg")
        let mountPoint = try folder(path)
        guard Self.runTool("/usr/bin/hdiutil", ["create", "-size", "4m", "-fs", "HFS+", "-volname", "Fixture", image.path(percentEncoded: false)]) == 0,
              Self.runTool("/usr/bin/hdiutil", ["attach", "-nobrowse", "-mountpoint", mountPoint.path(percentEncoded: false), image.path(percentEncoded: false)]) == 0
        else { throw CocoaError(.fileWriteUnknown) }
        mountPoints.append(mountPoint)
        // The image file itself is not part of what the test measures.
        try FileManager.default.moveItem(at: image, to: FileManager.default.temporaryDirectory.appending(path: image.lastPathComponent))
        return mountPoint
    }

    /// Space on disk measured independently of the scanner, from `lstat` block counts.
    static func allocatedSize(of url: URL) -> Int64 {
        var info = stat()
        guard lstat(url.path(percentEncoded: false), &info) == 0 else { return 0 }
        return Int64(info.st_blocks) * 512
    }

    @discardableResult
    private static func runTool(_ path: String, _ arguments: [String]) -> Int32 {
        let process = Process()
        process.executableURL = URL(filePath: path)
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do { try process.run() } catch { return -1 }
        process.waitUntilExit()
        return process.terminationStatus
    }
}
