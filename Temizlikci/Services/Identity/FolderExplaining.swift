import Foundation
import FoundationModels

/// Why the on-device explanation isn't offered right now.
nonisolated enum ExplanationUnavailable: Sendable, Equatable {
    case deviceNotSupported
    case appleIntelligenceOff
    case modelNotReady

    var message: LocalizedStringResource {
        switch self {
        case .deviceNotSupported: L10n.Identity.unavailableDevice
        case .appleIntelligenceOff: L10n.Identity.unavailableNotEnabled
        case .modelNotReady: L10n.Identity.unavailableNotReady
        }
    }
}

/// What the model is told about a folder. Only names and sizes — never file contents.
nonisolated struct FolderDescription: Sendable, Equatable {
    let name: String
    /// The path with the home folder replaced by `~`, so a user name is never part of the prompt.
    let path: String
    let size: String
    /// Names of the largest items inside, at most a handful.
    let contents: [String]
}

/// Writes a sentence or two about a folder nothing else recognized.
nonisolated protocol FolderExplaining: Sendable {
    /// `nil` when explanations are available; otherwise the reason they aren't.
    var unavailable: ExplanationUnavailable? { get }
    func explain(_ folder: FolderDescription) async throws -> String
}

/// Uses Apple's on-device model. Nothing leaves the Mac, and the model is only asked about folders
/// the deterministic identifier didn't recognize (HIG "Generative AI": on-device where possible,
/// scoped prompts, never drive destructive actions).
nonisolated struct OnDeviceFolderExplainer: FolderExplaining {
    /// Keeps the answer short, factual about its own uncertainty, and free of advice to delete.
    static let instructions = """
        You explain folders on a Mac to a developer who is looking at what uses disk space.
        You are given a folder's name, its path, its size and the names of the largest items inside it.
        Answer in at most two short sentences: what software most likely created this folder and what \
        it is used for. Write plainly, in English, with no lists and no headings.
        If the name gives you no real clue, say that it isn't a folder you recognize rather than guessing.
        Never advise deleting, removing or cleaning anything, and never say whether it is safe to remove.
        """

    var unavailable: ExplanationUnavailable? {
        switch SystemLanguageModel.default.availability {
        case .available:
            nil
        case .unavailable(.deviceNotEligible):
            .deviceNotSupported
        case .unavailable(.appleIntelligenceNotEnabled):
            .appleIntelligenceOff
        case .unavailable(.modelNotReady):
            .modelNotReady
        case .unavailable:
            .modelNotReady
        }
    }

    func explain(_ folder: FolderDescription) async throws -> String {
        let session = LanguageModelSession(instructions: Self.instructions)
        let contents = folder.contents.isEmpty ? "(empty)" : folder.contents.joined(separator: ", ")
        let prompt = """
            Folder name: \(folder.name)
            Path: \(folder.path)
            Size: \(folder.size)
            Largest items inside: \(contents)
            """
        let response = try await session.respond(
            to: prompt,
            options: GenerationOptions(temperature: 0.2, maximumResponseTokens: 160)
        )
        return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension FolderDescription {
    /// Builds the prompt input from a scanned folder, with the home folder masked.
    static func describing(_ node: FileNode, home: URL = URL.homeDirectory, limit: Int = 8) -> FolderDescription {
        var homePath = home.path(percentEncoded: false)
        if homePath.count > 1, homePath.hasSuffix("/") { homePath.removeLast() }
        let path = node.path.hasPrefix(homePath) ? "~" + node.path.dropFirst(homePath.count) : node.path
        let contents = node.children
            .filter { $0.kind == .directory || $0.kind == .file }
            .prefix(limit)
            .map(\.name)
        return FolderDescription(
            name: node.name, path: path, size: Formatting.bytes(node.allocatedSize), contents: Array(contents)
        )
    }
}
