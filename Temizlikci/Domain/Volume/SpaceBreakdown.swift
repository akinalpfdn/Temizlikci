import Foundation

/// One named part of the space a whole-volume scan could not attribute to a folder.
nonisolated struct SpacePart: Sendable, Identifiable, Equatable {
    enum Kind: Sendable, Equatable {
        /// Another volume in the same APFS container (VM swap, Preboot, Recovery, Update).
        case systemVolume(name: String)
        /// A mounted disk image living on this disk, whose contents the scan steps over
        /// (simulator runtimes are stored this way).
        case mountedImage(name: String)
        /// Space macOS will hand back when it needs it: snapshots, caches, redownloadable files.
        case purgeable
        /// Used space still unaccounted for after the named parts.
        case remainder
    }

    let kind: Kind
    let size: Int64

    var id: String {
        switch kind {
        case .systemVolume(let name): "volume:" + name
        case .mountedImage(let name): "image:" + name
        case .purgeable: "purgeable"
        case .remainder: "remainder"
        }
    }
}

/// What makes up the "Other Used Space" segment. Parts always add up to `total`: whatever the
/// named parts don't explain stays visible as the remainder.
nonisolated struct SpaceBreakdown: Sendable, Equatable {
    let total: Int64
    let parts: [SpacePart]
    /// True when Full Disk Access is missing, so some folders are counted in the remainder.
    let hasUnreadableFolders: Bool

    /// Builds the breakdown from what the system reports.
    /// - Parameters:
    ///   - unattributed: used space the scan did not attribute to any folder.
    ///   - purgeable: available-for-important-usage minus plain available capacity.
    ///   - volumes: volumes of the scanned disk's container that the scan doesn't walk.
    ///   - images: mounted disk images stored on the scanned disk.
    static func make(
        unattributed: Int64,
        purgeable: Int64,
        volumes: [(name: String, size: Int64)],
        images: [(name: String, size: Int64)],
        hasUnreadableFolders: Bool
    ) -> SpaceBreakdown {
        var parts: [SpacePart] = []
        parts += volumes.filter { $0.size > 0 }.map { SpacePart(kind: .systemVolume(name: $0.name), size: $0.size) }
        parts += images.filter { $0.size > 0 }.map { SpacePart(kind: .mountedImage(name: $0.name), size: $0.size) }
        if purgeable > 0 { parts.append(SpacePart(kind: .purgeable, size: purgeable)) }
        parts.sort { $0.size > $1.size }

        // The figures come from different sources (capacity, the APFS container, mounted volumes),
        // so the named parts can overshoot. Scaling them would invent numbers; instead the total
        // grows to hold them, and what is left over stays honest as the remainder.
        let named = parts.reduce(0) { $0 + $1.size }
        let total = max(unattributed, named)
        let remainder = total - named
        if remainder > 0 { parts.append(SpacePart(kind: .remainder, size: remainder)) }
        return SpaceBreakdown(total: total, parts: parts, hasUnreadableFolders: hasUnreadableFolders)
    }
}
