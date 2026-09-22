import Foundation

nonisolated struct ToolOutput: Sendable {
    let status: Int32
    let standardOutput: Data
    let standardError: String
}

/// Runs a command-line tool with an argument array (never through a shell), off the main actor.
nonisolated protocol ToolRunning: Sendable {
    func run(_ executable: URL, arguments: [String]) async throws -> ToolOutput
}

nonisolated struct ProcessToolRunner: ToolRunning {
    func run(_ executable: URL, arguments: [String]) async throws -> ToolOutput {
        let process = Process()
        let output = Pipe()
        let errors = Pipe()
        process.executableURL = executable
        process.arguments = arguments
        process.standardOutput = output
        process.standardError = errors

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                process.terminationHandler = { finished in
                    let stdout = output.fileHandleForReading.readDataToEndOfFile()
                    let stderr = errors.fileHandleForReading.readDataToEndOfFile()
                    continuation.resume(returning: ToolOutput(
                        status: finished.terminationStatus,
                        standardOutput: stdout,
                        standardError: String(decoding: stderr, as: UTF8.self)
                    ))
                }
                do {
                    try process.run()
                } catch {
                    process.terminationHandler = nil
                    continuation.resume(throwing: error)
                }
            }
        } onCancel: {
            process.terminate()
        }
    }
}
