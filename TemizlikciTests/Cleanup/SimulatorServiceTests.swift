import Foundation
import Testing
@testable import Temizlikci

/// Returns canned simctl output keyed by the argument list, and records what ran.
nonisolated final class StubToolRunner: ToolRunning, @unchecked Sendable {
    var outputs: [[String]: ToolOutput] = [:]
    var launchFails = false
    private(set) var ran: [[String]] = []

    func run(_ executable: URL, arguments: [String]) async throws -> ToolOutput {
        ran.append(arguments)
        if launchFails { throw CocoaError(.executableNotLoadable) }
        return outputs[arguments] ?? ToolOutput(status: 0, standardOutput: Data(), standardError: "")
    }

    static func ok(_ json: String) -> ToolOutput {
        ToolOutput(status: 0, standardOutput: Data(json.utf8), standardError: "")
    }
}

struct SimulatorServiceTests {
    static let runtimesJSON = """
    {"8E387153-D291-4BE0-A717-ED519FC5479F": {"build": "23F77", "deletable": true, "identifier": "8E387153-D291-4BE0-A717-ED519FC5479F",
     "lastUsedAt": "2026-09-21T19:52:10Z", "platformIdentifier": "com.apple.platform.iphonesimulator", "sizeBytes": 8494282293,
     "state": "Ready", "version": "26.5"},
     "39F9FD3A-2D90-4E11-873B-CEC9E20C864E": {"deletable": false, "identifier": "39F9FD3A-2D90-4E11-873B-CEC9E20C864E",
     "platformIdentifier": "com.apple.platform.watchsimulator", "sizeBytes": 4000, "version": "26.5"}}
    """
    static let devicesJSON = """
    {"devices": {"com.apple.CoreSimulator.SimRuntime.iOS-18-3": [
       {"udid": "A", "isAvailable": false, "dataPathSize": 6383165440, "name": "iPhone 17 Pro", "state": "Shutdown"},
       {"udid": "B", "isAvailable": false, "dataPathSize": 1000, "name": "iPhone SE", "state": "Shutdown"}],
     "com.apple.CoreSimulator.SimRuntime.iOS-26-5": [
       {"udid": "C", "isAvailable": true, "dataPathSize": 500, "name": "iPhone 17", "state": "Shutdown"}]}}
    """

    @Test("should read runtimes from simctl's JSON, largest first, with platform names")
    func parseRuntimes() throws {
        let runtimes = try SimulatorService.parseRuntimes(Data(Self.runtimesJSON.utf8))

        #expect(runtimes.map(\.platform) == ["iOS", "watchOS"])
        #expect(runtimes.first?.sizeBytes == 8_494_282_293)
        #expect(runtimes.first?.isDeletable == true)
        #expect(runtimes.first?.lastUsedAt != nil)
        #expect(runtimes.last?.isDeletable == false)
    }

    @Test("should count unavailable devices and their data")
    func parseUnavailable() throws {
        let unavailable = try SimulatorService.parseUnavailable(Data(Self.devicesJSON.utf8))

        #expect(unavailable == UnavailableSimulators(count: 2, dataSize: 6_383_166_440))
    }

    @Test("should run simctl with argument arrays for each action")
    func commands() async throws {
        let runner = StubToolRunner()
        let service = SimulatorService(runner: runner)
        let runtime = SimulatorRuntime(id: "RUNTIME-ID", platform: "iOS", version: "26.5", sizeBytes: 1, lastUsedAt: nil, isDeletable: true)

        try await service.deleteUnavailableDevices()
        try await service.deleteRuntime(runtime)

        #expect(runner.ran == [["simctl", "delete", "unavailable"], ["simctl", "runtime", "delete", "RUNTIME-ID"]])
    }

    @Test("should explain when simctl can't run and pass its error text along when it fails")
    func errors() async {
        let missing = StubToolRunner()
        missing.launchFails = true
        await #expect(throws: SimulatorToolError.unavailable) { try await SimulatorService(runner: missing).deleteUnavailableDevices() }

        let failing = StubToolRunner()
        failing.outputs[["simctl", "delete", "unavailable"]] = ToolOutput(status: 1, standardOutput: Data(), standardError: "Device busy\n")
        await #expect(throws: SimulatorToolError.failed(details: "Device busy")) { try await SimulatorService(runner: failing).deleteUnavailableDevices() }
    }
}

@MainActor
struct SimulatorsModelTests {
    @Test("should load runtimes and unavailable devices, and reload after deleting")
    func loadAndDelete() async {
        let runner = StubToolRunner()
        runner.outputs[["simctl", "runtime", "list", "-j"]] = StubToolRunner.ok(SimulatorServiceTests.runtimesJSON)
        runner.outputs[["simctl", "list", "devices", "-j"]] = StubToolRunner.ok(SimulatorServiceTests.devicesJSON)
        let model = SimulatorsModel(service: SimulatorService(runner: runner))

        await model.load()
        #expect(model.runtimes.count == 2)
        #expect(model.unavailable.count == 2)
        #expect(!model.didChangeDisk)

        await model.deleteUnavailableDevices()
        #expect(model.didChangeDisk)
        #expect(runner.ran.contains(["simctl", "delete", "unavailable"]))
        #expect(model.error == nil)
    }
}
