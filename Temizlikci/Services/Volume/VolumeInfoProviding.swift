import Foundation

/// Read-only facts about mounted volumes.
protocol VolumeInfoProviding {
    func startupVolumeName() -> String?
}

struct SystemVolumeInfo: VolumeInfoProviding {
    func startupVolumeName() -> String? {
        // A missing name is not actionable for the person; callers fall back to a generic label.
        let values = try? URL(filePath: "/").resourceValues(forKeys: [.volumeLocalizedNameKey])
        return values?.volumeLocalizedName
    }
}
