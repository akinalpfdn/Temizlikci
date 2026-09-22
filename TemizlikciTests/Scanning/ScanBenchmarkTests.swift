import Foundation
import Testing
@testable import Temizlikci

/// Read-only comparison against `du -skx` on a real folder. Opt-in, because it reads real data and
/// can take minutes. Uses the same access-aware configuration as the app, so without Full Disk
/// Access it never opens consent-prompting folders. `du` is skipped when such folders sit inside
/// the root, because `du` would trigger those prompts. Run with:
/// `TEST_RUNNER_TEMIZLIKCI_BENCH_PATH=~/Documents TEST_RUNNER_TEMIZLIKCI_BENCH_REPORT=/tmp/bench.txt xcodebuild … test -only-testing:TemizlikciTests/ScanBenchmarkTests`
/// The report goes to `TEMIZLIKCI_BENCH_REPORT` because test-process output doesn't reach xcodebuild's log.
struct ScanBenchmarkTests {
    nonisolated private static let benchPath = ProcessInfo.processInfo.environment["TEMIZLIKCI_BENCH_PATH"]
    nonisolated private static let reportPath = ProcessInfo.processInfo.environment["TEMIZLIKCI_BENCH_REPORT"]

    @Test("should match du within 1% without being slower", .enabled(if: benchPath != nil), .timeLimit(.minutes(30)))
    func compareWithDu() async throws {
        let root = URL(filePath: try #require(Self.benchPath), directoryHint: .isDirectory)
        let configuration = ScanConfiguration.forScan(access: SystemFullDiskAccessChecker())
        let rootPath = ScanConfiguration.comparablePath(of: root)
        let rootPrefix = rootPath == "/" ? "/" : rootPath + "/"
        let protectedInside = configuration.unreadFolders.contains { $0.hasPrefix(rootPrefix) }
        let clock = ContinuousClock()
        let heapBefore = Self.heapInUse()

        let scanStart = clock.now
        var result: ScanResult?
        for try await event in FileSystemScanner(configuration: configuration).scan(root) {
            if case .finished(let finished) = event { result = finished }
        }
        let scanned = try #require(result)
        let scanDuration = scanStart.duration(to: clock.now)
        let peakMemory = Self.peakResidentBytes()
        let retainedHeap = Self.heapInUse() - heapBefore

        // The app matches cleanup rules right after a scan; measure that pass too (Lore knownIssue 101).
        let rulesStart = clock.now
        let heapBeforeRules = Self.heapInUse()
        let matches = RuleEngine().matches(in: scanned.root)
        let rulesDuration = rulesStart.duration(to: clock.now)
        let rulesHeap = Self.heapInUse() - heapBeforeRules
        let peakAfterRules = Self.peakResidentBytes()

        var report = """
        BENCHMARK \(root.path(percentEncoded: false))
          scanner: \(scanned.root.allocatedSize) bytes, \(scanned.fileCount) files, \(scanned.directoryCount) folders, \(scanned.inaccessibleCount) inaccessible, \(scanDuration)
          peak resident memory (process, after scan): \(peakMemory / 1_048_576) MB
          heap retained by the result: \(retainedHeap / 1_048_576) MB (\(retainedHeap / Int64(max(scanned.directoryCount, 1))) bytes per folder)
          rules: \(matches.count) matches in \(rulesDuration); heap still held after the pass: \(rulesHeap / 1_048_576) MB; peak after rules: \(peakAfterRules / 1_048_576) MB
        """
        if protectedInside {
            report += "\n  du -skx: skipped (consent-prompting folders inside the root)"
            try Self.write(report)
            return
        }

        let duStart = clock.now
        let duBytes = try Self.duAllocatedBytes(of: root)
        let duDuration = duStart.duration(to: clock.now)
        let difference = abs(Double(scanned.root.allocatedSize - duBytes)) / Double(max(duBytes, 1))
        report += "\n  du -skx: \(duBytes) bytes, \(duDuration)\n  difference: \(String(format: "%.3f", difference * 100))%"
        try Self.write(report)

        #expect(difference < 0.01)
        #expect(scanDuration <= duDuration)
    }

    private static func write(_ report: String) throws {
        guard let reportPath else { return }
        try report.write(to: URL(filePath: reportPath), atomically: true, encoding: .utf8)
    }

    private static func duAllocatedBytes(of root: URL) throws -> Int64 {
        let process = Process()
        let output = Pipe()
        process.executableURL = URL(filePath: "/usr/bin/du")
        process.arguments = ["-skx", root.path(percentEncoded: false)]
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        try process.run()
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        let text = String(decoding: data, as: UTF8.self)
        let kilobytes = try #require(text.split(separator: "\t").first.flatMap { Int64($0) })
        return kilobytes * 1024
    }

    /// Bytes currently allocated in the default malloc zone. Unlike peak RSS this is stable between
    /// runs, so it measures what the result tree itself keeps alive.
    private static func heapInUse() -> Int64 {
        var statistics = malloc_statistics_t()
        malloc_zone_statistics(nil, &statistics)
        return Int64(statistics.size_in_use)
    }

    /// Peak resident set size of the test process in bytes (`ru_maxrss` is bytes on macOS).
    private static func peakResidentBytes() -> Int64 {
        var usage = rusage()
        getrusage(RUSAGE_SELF, &usage)
        return Int64(usage.ru_maxrss)
    }
}
