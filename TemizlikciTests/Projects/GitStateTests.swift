import Foundation
import Testing
@testable import Temizlikci

@Suite("Git state")
struct GitStateTests {
    @Test("should read branch, ahead/behind, stashes and each kind of change from porcelain v2")
    func parsesStatus() {
        let output = """
        # branch.oid 1234567890abcdef
        # branch.head main
        # branch.upstream origin/main
        # branch.ab +2 -1
        # stash 3
        1 M. N... 100644 100644 100644 aaa bbb staged.swift
        1 .M N... 100644 100644 100644 aaa bbb edited.swift
        1 MM N... 100644 100644 100644 aaa bbb both.swift
        2 R. N... 100644 100644 100644 aaa bbb R100 new.swift\told.swift
        u UU N... 100644 100644 100644 100644 aaa bbb ccc conflict.swift
        ? notes.txt
        ? scratch/
        """
        var state = GitState()
        state.applyStatus(output)

        #expect(state.branch == "main")
        #expect(state.upstream == "origin/main")
        #expect(state.ahead == 2)
        #expect(state.behind == 1)
        #expect(state.stashes == 3)
        #expect(state.staged == 3)
        #expect(state.unstaged == 2)
        #expect(state.conflicted == 1)
        #expect(state.untracked == 2)
        #expect(state.hasLocalOnlyWork)
    }

    @Test("should treat a clean, pushed repository as having nothing to lose, and a detached HEAD as no branch")
    func cleanAndDetached() {
        var clean = GitState()
        clean.applyStatus("# branch.oid abc\n# branch.head main\n# branch.upstream origin/main\n# branch.ab +0 -0\n")
        #expect(!clean.hasLocalOnlyWork)

        var detached = GitState()
        detached.applyStatus("# branch.oid abc\n# branch.head (detached)\n")
        #expect(detached.branch == nil)
    }

    @Test("should flag a repository with no remote even when its files are committed")
    func noRemote() {
        var state = GitState()
        state.hasRemote = false
        #expect(state.hasLocalOnlyWork)
    }

    @Test("should list branches ahead of their upstream and those without one")
    func branches() {
        let output = "main\torigin/main\t\nfeature\torigin/feature\t[ahead 4]\nmixed\torigin/mixed\t[ahead 1, behind 2]\nspike\t\t\ngone\torigin/gone\t[gone]\n"

        let result = GitState.branchesToCheck(output)

        #expect(result.ahead == [GitState.UnpushedBranch(name: "feature", commits: 4), GitState.UnpushedBranch(name: "mixed", commits: 1)])
        #expect(result.withoutUpstream == ["spike"])
    }
}

/// Runs the real Git on throwaway repositories in a temporary folder — never on the developer's.
@Suite("Git inspector", .serialized)
struct GitInspectorTests {
    private func git(_ arguments: [String], in folder: URL) throws {
        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/git")
        process.arguments = ["-C", folder.path(percentEncoded: false)] + arguments
        process.environment = [
            "GIT_AUTHOR_NAME": "Test", "GIT_AUTHOR_EMAIL": "test@example.invalid",
            "GIT_COMMITTER_NAME": "Test", "GIT_COMMITTER_EMAIL": "test@example.invalid",
            "HOME": folder.path(percentEncoded: false),
        ]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        #expect(process.terminationStatus == 0, "git \(arguments.joined(separator: " ")) failed")
    }

    private func repository(in fixture: FixtureTree) throws -> URL {
        let repo = fixture.root.appending(path: "repo", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: repo, withIntermediateDirectories: true)
        try git(["init", "-q", "-b", "main"], in: repo)
        try Data("one".utf8).write(to: repo.appending(path: "a.txt"))
        try git(["add", "a.txt"], in: repo)
        try git(["commit", "-q", "-m", "first"], in: repo)
        return repo
    }

    @Test("should report a repository without a remote, its untracked files and its stash")
    func localOnlyWork() async throws {
        let fixture = try FixtureTree()
        let repo = try repository(in: fixture)
        try Data("two".utf8).write(to: repo.appending(path: "a.txt"))
        try git(["stash", "-q"], in: repo)
        try Data("new".utf8).write(to: repo.appending(path: "b.txt"))

        let state = try #require(await GitInspector().state(of: repo))

        #expect(state.branch == "main")
        #expect(!state.hasRemote)
        #expect(state.stashes == 1)
        #expect(state.untracked == 1)
        #expect(state.hasLocalOnlyWork)
    }

    @Test("should count commits that no remote has, per branch")
    func unpushedCommits() async throws {
        let fixture = try FixtureTree()
        let remote = fixture.root.appending(path: "remote.git", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: remote, withIntermediateDirectories: true)
        try git(["init", "-q", "--bare"], in: remote)
        let repo = try repository(in: fixture)
        try git(["remote", "add", "origin", remote.path(percentEncoded: false)], in: repo)
        try git(["push", "-q", "-u", "origin", "main"], in: repo)
        try git(["checkout", "-q", "-b", "spike"], in: repo)
        try Data("spike".utf8).write(to: repo.appending(path: "c.txt"))
        try git(["add", "c.txt"], in: repo)
        try git(["commit", "-q", "-m", "only here"], in: repo)

        let state = try #require(await GitInspector().state(of: repo))

        #expect(state.hasRemote)
        #expect(state.unpushedCommits == 1)
        #expect(state.unpushedBranches == [GitState.UnpushedBranch(name: "spike", commits: 1)])
        #expect(!state.hasUncommittedChanges)
    }

    @Test("should never rewrite the index, so reading a project doesn't make it look recently worked on")
    func readsWithoutWriting() async throws {
        let fixture = try FixtureTree()
        let repo = try repository(in: fixture)
        let index = repo.appending(path: ".git/index")
        let old = Date(timeIntervalSince1970: 1_700_000_000)
        try FileManager.default.setAttributes([.modificationDate: old], ofItemAtPath: index.path(percentEncoded: false))
        // Touch the work tree so a normal `git status` would want to refresh the index.
        try FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: repo.appending(path: "a.txt").path(percentEncoded: false))

        _ = await GitInspector().state(of: repo)

        let after = try FileManager.default.attributesOfItem(atPath: index.path(percentEncoded: false))[.modificationDate] as? Date
        #expect(after == old)
    }
}
