import Foundation

/// Reads a repository's local-only work with the Git that ships with the developer tools.
nonisolated protocol GitInspecting: Sendable {
    /// `nil` when Git isn't available or the folder isn't a repository.
    func state(of repository: URL) async -> GitState?
}

nonisolated struct GitInspector: GitInspecting {
    static let git = URL(filePath: "/usr/bin/git")
    static let xcodeSelect = URL(filePath: "/usr/bin/xcode-select")
    /// Branches without an upstream are counted one by one; beyond this many, the rest are skipped.
    static let branchLimit = 12

    let runner: ToolRunning

    init(runner: ToolRunning = ProcessToolRunner()) {
        self.runner = runner
    }

    func state(of repository: URL) async -> GitState? {
        // `/usr/bin/git` is a shim: without the developer tools it opens an install dialog. Asking
        // `xcode-select` first never does.
        guard let tools = try? await runner.run(Self.xcodeSelect, arguments: ["-p"]), tools.status == 0 else { return nil }

        // `--no-optional-locks` keeps `status` from rewriting .git/index, which would otherwise make a
        // project untouched for months look as if it was worked on today.
        guard let status = await git(["status", "--porcelain=v2", "--branch", "--show-stash"], in: repository) else {
            return nil
        }
        var state = GitState()
        state.applyStatus(status)

        let remotes = await git(["remote"], in: repository) ?? ""
        state.hasRemote = !remotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let unpushed = await git(["rev-list", "--count", "--branches", "--not", "--remotes"], in: repository)
        state.unpushedCommits = Int(unpushed?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "") ?? 0

        if state.hasRemote, state.unpushedCommits > 0,
           let refs = await git(["for-each-ref", "--format=%(refname:short)%09%(upstream:short)%09%(upstream:track)", "refs/heads"], in: repository) {
            let branches = GitState.branchesToCheck(refs)
            var result = branches.ahead
            for name in branches.withoutUpstream.prefix(Self.branchLimit) {
                let count = await git(["rev-list", "--count", name, "--not", "--remotes"], in: repository)
                let commits = Int(count?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "") ?? 0
                if commits > 0 { result.append(GitState.UnpushedBranch(name: name, commits: commits)) }
            }
            state.unpushedBranches = result.sorted { $0.commits > $1.commits }
        }
        return state
    }

    private func git(_ arguments: [String], in repository: URL) async -> String? {
        let base = ["--no-optional-locks", "-C", repository.path(percentEncoded: false)]
        guard let output = try? await runner.run(Self.git, arguments: base + arguments), output.status == 0 else { return nil }
        return String(decoding: output.standardOutput, as: UTF8.self)
    }
}

/// Git state for the projects on screen, read in the background a few at a time and kept for the
/// session. Reading is lazy: only projects someone is looking at are asked about.
@MainActor
@Observable
final class GitStatusModel {
    private(set) var states: [String: GitState] = [:]
    private(set) var loading: Set<String> = []
    /// Projects Git couldn't read (not a repository any more, or Git unavailable).
    private(set) var unreadable: Set<String> = []

    private let inspector: GitInspecting
    private var running = 0
    private var queue: [URL] = []
    static let concurrency = 3

    init(inspector: GitInspecting = GitInspector()) {
        self.inspector = inspector
    }

    func load(_ project: DeveloperProject) {
        guard project.evidence == .git else { return }
        let key = project.url.path(percentEncoded: false)
        guard states[key] == nil, !loading.contains(key), !unreadable.contains(key) else { return }
        loading.insert(key)
        queue.append(project.url)
        pump()
    }

    func state(of project: DeveloperProject) -> GitState? {
        states[project.url.path(percentEncoded: false)]
    }

    func isLoading(_ project: DeveloperProject) -> Bool {
        loading.contains(project.url.path(percentEncoded: false))
    }

    /// Forgets what was read, so the next look asks Git again (after a rescan, for example).
    func reset() {
        states = [:]
        unreadable = []
    }

    private func pump() {
        while running < Self.concurrency, !queue.isEmpty {
            let url = queue.removeFirst()
            running += 1
            let inspector = inspector
            Task { [weak self] in
                let state = await inspector.state(of: url)
                guard let self else { return }
                let key = url.path(percentEncoded: false)
                self.loading.remove(key)
                if let state { self.states[key] = state } else { self.unreadable.insert(key) }
                self.running -= 1
                self.pump()
            }
        }
    }
}
