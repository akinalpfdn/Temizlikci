import Foundation

/// Work in a Git repository that exists only on this Mac: what would be lost if the folder went away.
nonisolated struct GitState: Sendable, Equatable {
    /// The checked-out branch, or `nil` when HEAD is detached.
    var branch: String?
    var upstream: String?
    /// Commits on the current branch that its upstream doesn't have.
    var ahead = 0
    var behind = 0
    var staged = 0
    var unstaged = 0
    var untracked = 0
    var conflicted = 0
    var stashes = 0
    /// Commits on any local branch that no remote-tracking branch contains.
    var unpushedCommits = 0
    var hasRemote = true
    /// Local branches with commits that exist nowhere else, with how many.
    var unpushedBranches: [UnpushedBranch] = []

    struct UnpushedBranch: Sendable, Equatable {
        let name: String
        let commits: Int
    }

    var hasUncommittedChanges: Bool { staged + unstaged + untracked + conflicted > 0 }

    /// True when deleting the folder would lose something: uncommitted files, stashes, or commits
    /// that were never pushed.
    var hasLocalOnlyWork: Bool {
        hasUncommittedChanges || stashes > 0 || unpushedCommits > 0 || !hasRemote
    }

    // MARK: Parsing

    /// Reads `git status --porcelain=v2 --branch --show-stash`.
    mutating func applyStatus(_ output: String) {
        for line in output.split(separator: "\n", omittingEmptySubsequences: true) {
            if line.hasPrefix("# branch.head ") {
                let head = String(line.dropFirst("# branch.head ".count))
                branch = head == "(detached)" ? nil : head
            } else if line.hasPrefix("# branch.upstream ") {
                upstream = String(line.dropFirst("# branch.upstream ".count))
            } else if line.hasPrefix("# branch.ab ") {
                let parts = line.dropFirst("# branch.ab ".count).split(separator: " ")
                if parts.count == 2 {
                    ahead = Int(parts[0].dropFirst()) ?? 0
                    behind = Int(parts[1].dropFirst()) ?? 0
                }
            } else if line.hasPrefix("# stash ") {
                stashes = Int(line.dropFirst("# stash ".count)) ?? 0
            } else if line.hasPrefix("1 ") || line.hasPrefix("2 ") {
                // "1 XY ...": X is the index (staged) side, Y the work tree (unstaged) side; "." = unchanged.
                let fields = line.split(separator: " ", maxSplits: 2)
                guard fields.count >= 2, fields[1].count == 2 else { continue }
                let xy = Array(fields[1])
                if xy[0] != "." { staged += 1 }
                if xy[1] != "." { unstaged += 1 }
            } else if line.hasPrefix("u ") {
                conflicted += 1
            } else if line.hasPrefix("? ") {
                untracked += 1
            }
        }
    }

    /// Reads `git for-each-ref --format=%(refname:short)%09%(upstream:short)%09%(upstream:track) refs/heads`
    /// and returns the branches whose commits may exist only here: ahead of their upstream, or with no
    /// upstream at all (their counts are filled in separately).
    static func branchesToCheck(_ output: String) -> (ahead: [UnpushedBranch], withoutUpstream: [String]) {
        var ahead: [UnpushedBranch] = []
        var withoutUpstream: [String] = []
        for line in output.split(separator: "\n", omittingEmptySubsequences: true) {
            let fields = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
            guard let name = fields.first, !name.isEmpty else { continue }
            let upstream = fields.count > 1 ? fields[1] : ""
            let track = fields.count > 2 ? fields[2] : ""
            if upstream.isEmpty {
                withoutUpstream.append(name)
            } else if let range = track.range(of: #"ahead (\d+)"#, options: .regularExpression) {
                let number = track[range].split(separator: " ").last.flatMap { Int($0) } ?? 0
                if number > 0 { ahead.append(UnpushedBranch(name: name, commits: number)) }
            }
        }
        return (ahead, withoutUpstream)
    }
}
