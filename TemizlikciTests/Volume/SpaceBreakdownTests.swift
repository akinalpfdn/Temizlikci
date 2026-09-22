import Foundation
import Testing
@testable import Temizlikci

nonisolated private struct StubDiskSpace: DiskSpaceReading {
    let apfs: [ApfsContainer]
    let mounts: [MountedFileSystem]

    func containers() async throws -> [ApfsContainer] { apfs }
    func mountedFileSystems() -> [MountedFileSystem] { mounts }
}

@Suite("Other Used Space")
struct SpaceBreakdownTests {
    private let gb = Int64(1_000_000_000)

    /// A Mac like the developer's: system and data volumes are scanned, VM/Preboot/Recovery are not,
    /// and a simulator runtime is a separate container mounted inside the disk.
    private func reader() -> StubDiskSpace {
        StubDiskSpace(
            apfs: [
                ApfsContainer(reference: "disk3", volumes: [
                    ApfsVolume(name: "Macintosh HD", device: "disk3s1", roles: ["System"], capacityInUse: 12 * gb),
                    ApfsVolume(name: "Data", device: "disk3s5", roles: ["Data"], capacityInUse: 380 * gb),
                    ApfsVolume(name: "VM", device: "disk3s6", roles: ["VM"], capacityInUse: 18 * gb),
                    ApfsVolume(name: "Preboot", device: "disk3s2", roles: ["Preboot"], capacityInUse: 9 * gb),
                ]),
                ApfsContainer(reference: "disk5", volumes: [
                    ApfsVolume(name: "iOS 26.5 Simulator", device: "disk5s1", roles: [], capacityInUse: 17 * gb),
                ]),
            ],
            mounts: [
                MountedFileSystem(mountPoint: "/", device: "/dev/disk3s1s1"),
                MountedFileSystem(mountPoint: "/System/Volumes/VM", device: "/dev/disk3s6"),
                MountedFileSystem(mountPoint: "/Library/Developer/CoreSimulator/Volumes/iOS_26.5", device: "/dev/disk5s1"),
            ]
        )
    }

    private func usage(purgeable: Int64) -> VolumeUsage {
        VolumeUsage(
            totalCapacity: 500 * gb, availableCapacity: 60 * gb,
            availableForImportantUsage: 60 * gb + purgeable
        )
    }

    @Test("should name the volumes and mounted images the scan can't walk, and keep the rest honest")
    func namedParts() async {
        let builder = SpaceBreakdownBuilder(reader: reader())

        let breakdown = await builder.breakdown(unattributed: 60 * gb, usage: usage(purgeable: 5 * gb), hasUnreadableFolders: false)

        #expect(breakdown.parts.map(\.kind) == [
            .systemVolume(name: "VM"), .mountedImage(name: "iOS 26.5 Simulator"),
            .systemVolume(name: "Preboot"), .purgeable, .remainder,
        ])
        #expect(breakdown.parts.map(\.size) == [18 * gb, 17 * gb, 9 * gb, 5 * gb, 11 * gb])
        #expect(breakdown.parts.reduce(0) { $0 + $1.size } == breakdown.total)
    }

    @Test("should never leave a negative remainder when the named parts add up to more than the estimate")
    func partsExceedEstimate() async {
        let builder = SpaceBreakdownBuilder(reader: reader())

        let breakdown = await builder.breakdown(unattributed: 10 * gb, usage: usage(purgeable: 0), hasUnreadableFolders: true)

        #expect(!breakdown.parts.contains { $0.kind == .remainder })
        #expect(breakdown.total == 44 * gb)
        #expect(breakdown.parts.reduce(0) { $0 + $1.size } == breakdown.total)
        #expect(breakdown.hasUnreadableFolders)
    }

    @Test("should fall back to capacity figures alone when the disk's layout can't be read")
    func withoutDiskutil() async {
        let builder = SpaceBreakdownBuilder(reader: StubDiskSpace(apfs: [], mounts: []))

        let breakdown = await builder.breakdown(unattributed: 20 * gb, usage: usage(purgeable: 3 * gb), hasUnreadableFolders: false)

        #expect(breakdown.parts.map(\.kind) == [.purgeable, .remainder])
        #expect(breakdown.parts.map(\.size) == [3 * gb, 17 * gb])
        #expect(breakdown.total == 20 * gb)
    }

    @Test("should read this Mac's own layout without any privileges")
    func readsRealDisk() async throws {
        let service = DiskSpaceService()
        let mounts = service.mountedFileSystems()
        #expect(mounts.contains { $0.mountPoint == "/" })

        let containers = try await service.containers()
        let startup = try #require(containers.first { $0.volumes.contains { $0.roles.contains("Data") } })
        #expect(startup.volumes.contains { $0.roles.contains("System") })
        #expect(startup.volumes.allSatisfy { $0.capacityInUse >= 0 })
    }
}
