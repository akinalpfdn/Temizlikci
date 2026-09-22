import SwiftUI

/// The inspector for an insight view: the item picked in Developer or Large Files, looked up in the
/// scan that view shows.
struct InsightInspectorView: View {
    let main: MainViewModel

    var body: some View {
        if let scan = main.insightScan, let item = main.inspected {
            switch item {
            case .project(let id):
                if let project = scan.project(withID: id) {
                    ProjectInspectorView(project: project, scan: scan, main: main)
                } else {
                    empty
                }
            case .node(let id):
                if let node = scan.nodeAnywhere(withID: id) {
                    NodeDetailsView(scan: scan, node: node)
                } else {
                    empty
                }
            }
        } else {
            empty
        }
    }

    private var empty: some View {
        ContentUnavailableView {
            Label { Text(L10n.Inspector.noSelectionTitle) } icon: { Image(systemName: "info.circle") }
        } description: {
            Text(L10n.Inspector.noSelectionMessage)
        }
    }
}

/// A project: when it was last worked on, what it holds, and — for a Git repository — the work that
/// exists only on this Mac, so nobody deletes a project with unpushed commits by mistake.
struct ProjectInspectorView: View {
    let project: DeveloperProject
    let scan: LocationScanModel
    let main: MainViewModel

    private var git: GitStatusModel { main.gitStatus }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                header
                details
                if project.evidence == .git { gitSection }
                Text(L10n.Projects.onlyBuildOutput)
                    .font(Typography.chartCaption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                VStack(spacing: Spacing.small) {
                    Button { scan.reveal(project.node) } label: {
                        Text(L10n.Details.revealInFinder).frame(maxWidth: .infinity)
                    }
                    ForEach(main.editors(for: project)) { target in
                        Button { main.open(target) } label: {
                            Text(target.editor.openTitle).frame(maxWidth: .infinity)
                        }
                    }
                }
                .controlSize(.large)
            }
            .padding(Spacing.large)
        }
        .task(id: project.id) { git.load(project) }
    }

    private var header: some View {
        HStack(spacing: Spacing.medium) {
            Image(systemName: "shippingbox")
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text(project.name).font(.headline).textSelection(.enabled)
                Text(project.evidence.title).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            LabeledContent { Text(Formatting.bytes(project.node.allocatedSize)) } label: { Text(L10n.Details.size) }
            if project.reclaimableSize > 0 {
                LabeledContent { Text(Formatting.bytes(project.reclaimableSize)) } label: { Text(L10n.Projects.buildOutput) }
            }
            if let lastTouched = project.lastTouched {
                LabeledContent {
                    Text(lastTouched.formatted(date: .abbreviated, time: .omitted))
                } label: {
                    Text(L10n.Projects.lastWorkedOn)
                }
            }
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text(L10n.Details.path).foregroundStyle(.secondary)
                Text(project.url.path(percentEncoded: false))
                    .font(Typography.chartCaption)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var gitSection: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text(L10n.Git.title).font(.headline)
            if let state = git.state(of: project) {
                GitSummary(state: state)
                GitDetails(state: state)
            } else if git.isLoading(project) {
                HStack(spacing: Spacing.xSmall) {
                    ProgressView().controlSize(.small)
                    Text(L10n.Git.reading).foregroundStyle(.secondary)
                }
            } else {
                Text(L10n.Git.unreadable)
                    .font(Typography.chartCaption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
    }
}

/// One line that answers "would I lose anything?", with a symbol so it never relies on color.
struct GitSummary: View {
    let state: GitState

    var body: some View {
        if state.hasLocalOnlyWork {
            Label { Text(L10n.Git.localWork) } icon: { Image(systemName: "exclamationmark.triangle.fill") }
                .foregroundStyle(StatusPalette.attention)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Label { Text(L10n.Git.allPushed) } icon: { Image(systemName: "checkmark.circle") }
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct GitDetails: View {
    let state: GitState

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            LabeledContent {
                Text(verbatim: state.branch ?? String(localized: L10n.Git.detached))
            } label: {
                Text(L10n.Git.branch)
            }
            if !state.hasRemote {
                row(L10n.Git.noRemote, value: nil)
            }
            if state.unpushedCommits > 0 {
                row(L10n.Git.unpushedCommits, value: state.unpushedCommits)
            }
            if state.behind > 0 {
                row(L10n.Git.behind, value: state.behind)
            }
            if state.staged > 0 { row(L10n.Git.staged, value: state.staged) }
            if state.unstaged > 0 { row(L10n.Git.unstaged, value: state.unstaged) }
            if state.untracked > 0 { row(L10n.Git.untracked, value: state.untracked) }
            if state.conflicted > 0 { row(L10n.Git.conflicted, value: state.conflicted) }
            if state.stashes > 0 { row(L10n.Git.stashes, value: state.stashes) }
            if !state.unpushedBranches.isEmpty {
                Text(L10n.Git.branchesOnlyHere).foregroundStyle(.secondary).padding(.top, Spacing.xxSmall)
                ForEach(state.unpushedBranches, id: \.name) { branch in
                    HStack(spacing: Spacing.small) {
                        Text(verbatim: branch.name).lineLimit(1).truncationMode(.middle)
                        Spacer(minLength: Spacing.xSmall)
                        Text(Formatting.count(branch.commits)).monospacedDigit().fixedSize()
                    }
                    .font(Typography.chartCaption)
                }
            }
        }
    }

    /// The label may wrap in the narrow inspector; the number never does.
    private func row(_ title: LocalizedStringResource, value: Int?) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
            Text(title).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Spacing.xSmall)
            if let value {
                Text(Formatting.count(value))
                    .monospacedDigit()
                    .fixedSize()
            }
        }
    }
}

extension EditorTarget.Editor {
    var openTitle: LocalizedStringResource {
        switch self {
        case .xcode: L10n.Projects.openInXcode
        case .androidStudio: L10n.Projects.openInAndroidStudio
        case .visualStudioCode: L10n.Projects.openInVSCode
        }
    }
}
