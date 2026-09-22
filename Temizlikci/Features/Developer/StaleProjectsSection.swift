import SwiftUI

extension StalePeriod {
    var title: LocalizedStringResource {
        switch self {
        case .month: L10n.Projects.periodMonth
        case .quarter: L10n.Projects.periodQuarter
        case .halfYear: L10n.Projects.periodHalfYear
        case .year: L10n.Projects.periodYear
        }
    }
}

extension ProjectEvidence {
    var title: LocalizedStringResource {
        switch self {
        case .git: L10n.Projects.evidenceGit
        case .xcode: L10n.Projects.evidenceXcode
        case .swiftPackage: L10n.Projects.evidenceSwiftPackage
        case .node: L10n.Projects.evidenceNode
        case .flutter: L10n.Projects.evidenceFlutter
        case .rust: L10n.Projects.evidenceRust
        case .gradle: L10n.Projects.evidenceGradle
        case .go: L10n.Projects.evidenceGo
        case .unity: L10n.Projects.evidenceUnity
        }
    }
}

/// Projects nobody has worked on for a while, with the build output they still hold.
/// Every removal is per item: there is no bulk clean (DECISIONS 2026-09-22).
struct StaleProjectsSection: View {
    let scan: LocationScanModel
    @AppStorage("staleProjectPeriod") private var periodDays = StalePeriod.quarter.rawValue
    @Environment(\.undoManager) private var undoManager

    private var period: StalePeriod { StalePeriod(rawValue: periodDays) ?? .quarter }
    private var projects: [DeveloperProject] { scan.staleProjects(after: period) }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack {
                Text(L10n.Projects.title).font(.headline)
                Spacer()
                Picker(selection: $periodDays) {
                    ForEach(StalePeriod.allCases) { option in
                        Text(option.title).tag(option.rawValue)
                    }
                } label: {
                    Text(L10n.Projects.periodLabel)
                }
                .pickerStyle(.menu)
                .fixedSize()
            }
            if projects.isEmpty {
                Text(L10n.Projects.empty)
                    .foregroundStyle(.secondary)
                    .padding(Spacing.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.background.secondary, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(projects.enumerated()), id: \.element.id) { index, project in
                        if index > 0 { Divider() }
                        row(project)
                    }
                }
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
            }
        }
    }

    private func row(_ project: DeveloperProject) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.medium) {
                VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                    HStack(spacing: Spacing.xSmall) {
                        Text(project.name).font(.body.weight(.medium))
                        Text(project.evidence.title)
                            .font(Typography.badge)
                            .foregroundStyle(.secondary)
                    }
                    Text(project.url.path(percentEncoded: false))
                        .font(Typography.chartCaption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Text(lastTouched(project))
                        .font(Typography.chartCaption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: Spacing.medium)
                VStack(alignment: .trailing, spacing: Spacing.xxSmall) {
                    Text(L10n.Projects.total(Formatting.bytes(project.node.allocatedSize))).font(Typography.listSize)
                    if project.reclaimableSize > 0 {
                        Text(L10n.Cleanup.reclaimable(Formatting.bytes(project.reclaimableSize)))
                            .font(Typography.chartCaption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            artifacts(of: project)
        }
        .padding(Spacing.medium)
    }

    @ViewBuilder
    private func artifacts(of project: DeveloperProject) -> some View {
        if project.artifacts.isEmpty {
            Text(L10n.Projects.noArtifacts)
                .font(Typography.chartCaption)
                .foregroundStyle(.secondary)
        } else {
            DisclosureGroup {
                ForEach(project.artifacts) { artifact in
                    HStack(spacing: Spacing.medium) {
                        Text(artifact.node.name)
                        Spacer()
                        SafetyBadge(level: artifact.rule.safety)
                        Text(Formatting.bytes(artifact.node.allocatedSize))
                            .font(Typography.listSize)
                            .frame(minWidth: 72, alignment: .trailing)
                        if artifact.rule.action == .moveToTrash, artifact.rule.safety == .safe {
                            Button { scan.moveToTrash(artifact, undoManager: undoManager) } label: { Text(L10n.Trash.moveToTrash) }
                        }
                    }
                    .padding(.vertical, Spacing.xxSmall)
                }
            } label: {
                Text(L10n.Projects.buildOutput).font(Typography.badge)
            }
        }
    }

    private func lastTouched(_ project: DeveloperProject) -> LocalizedStringResource {
        guard let date = project.lastTouched else { return L10n.Projects.unknownActivity }
        return L10n.Projects.lastTouched(date.formatted(date: .abbreviated, time: .omitted))
    }
}
