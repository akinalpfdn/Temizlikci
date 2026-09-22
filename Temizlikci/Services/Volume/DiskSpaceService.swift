import Darwin
import Foundation

/// A volume of an APFS container, as `diskutil` reports it.
nonisolated struct ApfsVolume: Sendable, Equatable {
    let name: String
    /// BSD name, e.g. `disk3s6`.
    let device: String
    let roles: [String]
    let capacityInUse: Int64

    /// Volumes the scan walks: the system volume and the data volume are one file system under `/`.
    var isScanned: Bool { roles.contains("System") || roles.contains("Data") }
}

nonisolated struct ApfsContainer: Sendable, Equatable {
    /// BSD name of the container, e.g. `disk3`.
    let reference: String
    let volumes: [ApfsVolume]
}

/// A mounted file system, from the kernel's mount table.
nonisolated struct MountedFileSystem: Sendable, Equatable {
    /// Where it is mounted, e.g. `/System/Volumes/VM`.
    let mountPoint: String
    /// What is mounted, e.g. `/dev/disk3s6`.
    let device: String

    /// BSD name without the `/dev/` prefix.
    var bsdName: String { device.hasPrefix("/dev/") ? String(device.dropFirst(5)) : device }
}

/// Reads how a disk's space is divided between volumes, without asking for any permission.
nonisolated protocol DiskSpaceReading: Sendable {
    func containers() async throws -> [ApfsContainer]
    func mountedFileSystems() -> [MountedFileSystem]
}

nonisolated struct DiskSpaceService: DiskSpaceReading {
    static let diskutil = URL(filePath: "/usr/sbin/diskutil")

    let runner: ToolRunning

    init(runner: ToolRunning = ProcessToolRunner()) {
        self.runner = runner
    }

    /// `diskutil apfs list` needs no privileges and reports each volume's own usage, which the
    /// capacity APIs cannot: every volume in a container reports the container's free space.
    func containers() async throws -> [ApfsContainer] {
        let output = try await runner.run(Self.diskutil, arguments: ["apfs", "list", "-plist"])
        guard output.status == 0,
              let plist = try PropertyListSerialization.propertyList(from: output.standardOutput, format: nil) as? [String: Any],
              let containers = plist["Containers"] as? [[String: Any]]
        else { return [] }
        return containers.compactMap { container in
            guard let reference = container["ContainerReference"] as? String else { return nil }
            let volumes = (container["Volumes"] as? [[String: Any]] ?? []).compactMap { volume -> ApfsVolume? in
                guard let device = volume["DeviceIdentifier"] as? String else { return nil }
                return ApfsVolume(
                    name: volume["Name"] as? String ?? device,
                    device: device,
                    roles: volume["Roles"] as? [String] ?? [],
                    capacityInUse: (volume["CapacityInUse"] as? NSNumber)?.int64Value ?? 0
                )
            }
            return ApfsContainer(reference: reference, volumes: volumes)
        }
    }

    func mountedFileSystems() -> [MountedFileSystem] {
        var table: UnsafeMutablePointer<statfs>?
        let count = getmntinfo(&table, MNT_NOWAIT)
        guard count > 0, let table else { return [] }
        return (0..<Int(count)).map { index in
            var entry = table[index]
            let mountPoint = withUnsafePointer(to: &entry.f_mntonname) {
                String(cString: UnsafeRawPointer($0).assumingMemoryBound(to: CChar.self))
            }
            let device = withUnsafePointer(to: &entry.f_mntfromname) {
                String(cString: UnsafeRawPointer($0).assumingMemoryBound(to: CChar.self))
            }
            return MountedFileSystem(mountPoint: mountPoint, device: device)
        }
    }
}

/// Turns the raw readings into the breakdown shown for "Other Used Space".
nonisolated struct SpaceBreakdownBuilder: Sendable {
    let reader: DiskSpaceReading

    init(reader: DiskSpaceReading = DiskSpaceService()) {
        self.reader = reader
    }

    /// - Parameters:
    ///   - unattributed: used space the scan did not attribute to a folder.
    ///   - usage: capacity figures for the scanned volume.
    ///   - root: the scanned volume's mount point, normally `/`.
    func breakdown(
        unattributed: Int64, usage: VolumeUsage, root: String = "/", hasUnreadableFolders: Bool
    ) async -> SpaceBreakdown {
        let purgeable = usage.availableForImportantUsage.map { max(0, $0 - usage.availableCapacity) } ?? 0
        let mounts = reader.mountedFileSystems()
        let containers = (try? await reader.containers()) ?? []

        guard let rootDevice = mounts.first(where: { $0.mountPoint == root })?.bsdName,
              let container = containers.first(where: { $0.volumes.contains { rootDevice.hasPrefix($0.device) } })
        else {
            return SpaceBreakdown.make(
                unattributed: unattributed, purgeable: purgeable, volumes: [], images: [],
                hasUnreadableFolders: hasUnreadableFolders
            )
        }

        // Volumes of the same container that the scan never walks: VM swap, Preboot, Recovery, Update.
        let volumes = container.volumes.filter { !$0.isScanned }.map { (name: $0.name, size: $0.capacityInUse) }

        // Disk images stored on this disk and mounted inside it: simulator runtimes live here, and
        // the scan steps over their mount points, so their space would otherwise be unexplained.
        let ownDevices = Set(container.volumes.map(\.device))
        let mountedElsewhere = mounts.filter { mount in
            mount.mountPoint != root && mount.mountPoint.hasPrefix(root == "/" ? "/" : root + "/")
                && !ownDevices.contains(where: { mount.bsdName.hasPrefix($0) })
        }
        let images = containers
            .filter { other in
                other.reference != container.reference
                    && other.volumes.contains { volume in mountedElsewhere.contains { $0.bsdName.hasPrefix(volume.device) } }
            }
            .flatMap(\.volumes)
            .filter { volume in mountedElsewhere.contains { $0.bsdName.hasPrefix(volume.device) } }
            .map { (name: $0.name, size: $0.capacityInUse) }

        return SpaceBreakdown.make(
            unattributed: unattributed, purgeable: purgeable, volumes: volumes, images: images,
            hasUnreadableFolders: hasUnreadableFolders
        )
    }
}
