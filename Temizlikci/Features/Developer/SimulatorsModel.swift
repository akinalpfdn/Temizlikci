import Foundation
import Observation

/// Installed simulator runtimes and unavailable devices, and the simctl actions that remove them.
@MainActor
@Observable
final class SimulatorsModel {
    private(set) var runtimes: [SimulatorRuntime] = []
    private(set) var unavailable = UnavailableSimulators(count: 0, dataSize: 0)
    private(set) var isWorking = false
    private(set) var hasLoaded = false
    var error: LocationScanModel.ActionError?
    /// Set after a deletion so the chart can say its sizes are outdated.
    private(set) var didChangeDisk = false

    private let service: SimulatorService

    init(service: SimulatorService) {
        self.service = service
    }

    func load() async {
        isWorking = true
        defer { isWorking = false }
        do {
            runtimes = try await service.runtimes()
            unavailable = try await service.unavailableDevices()
            hasLoaded = true
        } catch {
            report(error)
        }
    }

    func deleteUnavailableDevices() async {
        await perform { try await self.service.deleteUnavailableDevices() }
    }

    func delete(_ runtime: SimulatorRuntime) async {
        await perform { try await self.service.deleteRuntime(runtime) }
    }

    private func perform(_ action: () async throws -> Void) async {
        isWorking = true
        do {
            try await action()
            didChangeDisk = true
        } catch {
            report(error)
        }
        isWorking = false
        await load()
    }

    private func report(_ error: Error) {
        let described = error as? LocalizedError
        self.error = LocationScanModel.ActionError(
            message: described?.errorDescription ?? error.localizedDescription,
            suggestion: described?.recoverySuggestion
        )
    }
}
