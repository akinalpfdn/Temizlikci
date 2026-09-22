import Foundation

nonisolated struct SimulatorRuntime: Sendable, Identifiable, Equatable {
    let id: String
    let platform: String
    let version: String
    let sizeBytes: Int64
    let lastUsedAt: Date?
    let isDeletable: Bool
}

nonisolated struct UnavailableSimulators: Sendable, Equatable {
    let count: Int
    let dataSize: Int64
}

nonisolated enum SimulatorToolError: LocalizedError, Equatable {
    case unavailable
    case failed(details: String)

    var errorDescription: String? {
        switch self {
        case .unavailable: String(localized: L10n.Simulators.toolUnavailable)
        case .failed: String(localized: L10n.Simulators.toolFailed)
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .unavailable: String(localized: L10n.Simulators.toolUnavailableSuggestion)
        case .failed(let details): details.isEmpty ? nil : details
        }
    }
}

/// Lists and removes simulators through `xcrun simctl`, the only safe way to change them
/// (DEVPLAN: tool-owned items are removed with their tool). Parses JSON output, not text.
nonisolated struct SimulatorService: Sendable {
    let runner: ToolRunning
    static let xcrun = URL(filePath: "/usr/bin/xcrun")

    func runtimes() async throws -> [SimulatorRuntime] {
        let data = try await simctl(["runtime", "list", "-j"])
        return try Self.parseRuntimes(data)
    }

    func unavailableDevices() async throws -> UnavailableSimulators {
        let data = try await simctl(["list", "devices", "-j"])
        return try Self.parseUnavailable(data)
    }

    func deleteUnavailableDevices() async throws {
        _ = try await simctl(["delete", "unavailable"])
    }

    func deleteRuntime(_ runtime: SimulatorRuntime) async throws {
        _ = try await simctl(["runtime", "delete", runtime.id])
    }

    private func simctl(_ arguments: [String]) async throws -> Data {
        let output: ToolOutput
        do {
            output = try await runner.run(Self.xcrun, arguments: ["simctl"] + arguments)
        } catch {
            throw SimulatorToolError.unavailable
        }
        guard output.status == 0 else {
            throw SimulatorToolError.failed(details: output.standardError.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return output.standardOutput
    }

    // MARK: Parsing

    private struct RuntimeEntry: Decodable {
        let identifier: String
        let platformIdentifier: String
        let version: String
        let sizeBytes: Int64?
        let lastUsedAt: Date?
        let deletable: Bool?
    }

    private struct DeviceList: Decodable {
        struct Device: Decodable {
            let isAvailable: Bool?
            let dataPathSize: Int64?
        }
        let devices: [String: [Device]]
    }

    static func parseRuntimes(_ data: Data) throws -> [SimulatorRuntime] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let entries = try decoder.decode([String: RuntimeEntry].self, from: data)
        return entries.values.map { entry in
            SimulatorRuntime(
                id: entry.identifier,
                platform: platformName(entry.platformIdentifier),
                version: entry.version,
                sizeBytes: entry.sizeBytes ?? 0,
                lastUsedAt: entry.lastUsedAt,
                isDeletable: entry.deletable ?? false
            )
        }
        .sorted { $0.sizeBytes > $1.sizeBytes }
    }

    static func parseUnavailable(_ data: Data) throws -> UnavailableSimulators {
        let list = try JSONDecoder().decode(DeviceList.self, from: data)
        let unavailable = list.devices.values.flatMap { $0 }.filter { $0.isAvailable == false }
        return UnavailableSimulators(count: unavailable.count, dataSize: unavailable.reduce(0) { $0 + ($1.dataPathSize ?? 0) })
    }

    /// "com.apple.platform.iphonesimulator" → "iOS". Platform names are product names, not translated.
    static func platformName(_ identifier: String) -> String {
        switch identifier {
        case "com.apple.platform.iphonesimulator": "iOS"
        case "com.apple.platform.watchsimulator": "watchOS"
        case "com.apple.platform.appletvsimulator": "tvOS"
        case "com.apple.platform.xrsimulator": "visionOS"
        default: identifier
        }
    }
}
