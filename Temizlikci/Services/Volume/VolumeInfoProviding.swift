import Foundation

/// Capacity figures for the volume that holds a location. On APFS, "used" covers every volume in
/// the container, so `usedCapacity` minus a scan's total is the space no scanned folder accounts for
/// (the sealed system volume's snapshots, purgeable files, other volumes, unreadable folders).
nonisolated struct VolumeUsage: Sendable, Equatable {
    let totalCapacity: Int64
    let availableCapacity: Int64
    /// What macOS can free for important work, including purgeable space. `nil` when unavailable.
    let availableForImportantUsage: Int64?

    var usedCapacity: Int64 { totalCapacity - availableCapacity }

    /// Used space that a scan of the whole volume did not attribute to any folder.
    func unattributed(scannedSize: Int64) -> Int64 {
        max(0, usedCapacity - scannedSize)
    }
}

/// Read-only facts about mounted volumes.
protocol VolumeInfoProviding {
    func startupVolumeName() -> String?
    func usage(ofVolumeContaining url: URL) throws -> VolumeUsage
}

struct SystemVolumeInfo: VolumeInfoProviding {
    func startupVolumeName() -> String? {
        // A missing name is not actionable for the person; callers fall back to a generic label.
        let values = try? URL(filePath: "/").resourceValues(forKeys: [.volumeLocalizedNameKey])
        return values?.volumeLocalizedName
    }

    func usage(ofVolumeContaining url: URL) throws -> VolumeUsage {
        let values = try url.resourceValues(forKeys: [
            .volumeTotalCapacityKey, .volumeAvailableCapacityKey, .volumeAvailableCapacityForImportantUsageKey,
        ])
        return VolumeUsage(
            totalCapacity: Int64(values.volumeTotalCapacity ?? 0),
            availableCapacity: Int64(values.volumeAvailableCapacity ?? 0),
            availableForImportantUsage: values.volumeAvailableCapacityForImportantUsage
        )
    }
}
